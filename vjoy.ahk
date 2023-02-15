#Include util.ahk
A_HotkeyInterval := 0

; Globals
global AcquiredDevice := 0
global DeviceProperties := {
	AXIS: {X: 0, Y: 0, Z: 0, RX: 0, RY: 0, RZ: 0},
	RANGE: {X: [0,0], Y: [0,0], Z: [0,0], RX: [0,0], RY: [0,0], RZ: [0,0]},
	BUTTONS: 0,
	POV: {CONTINUOUS: 0, DISCRETE: 0}
}

global BindsName := ""
global BindsAuthor := ""
global Binds := Map()
global BindRequirements := {AXIS: {X: 0, Y: 0, Z: 0, RX: 0, RY: 0, RZ: 0}, BUTTONS: 0, POV: {CONTINUOUS: 0, DISCRETE: 0}}

; Consts
VJOY_MAX_DEVICES := 16
AXISES := Map("X", 0x30, "Y", 0x31, "Z", 0x32, "RX", 0x33, "RY", 0x34, "RZ", 0x35)

DEG2RAD := 0.017453292519943295
RAD2DEG := 57.29577951308232

; Configure Registry access
if (A_Is64bitOS && A_PtrSize != 8) {
	SetRegView 64
}

vJoyDir := IniRead(SettingsPath, "settings", "vJoyDir", "")
dllPath := IniRead(SettingsPath, "settings", "vJoyDLL", "")
if (dllPath == "") {
	if (vJoyDir == "") {
		try {
			vJoyDir := RegRead("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{8E31F76F-74C3-47F1-9550-E041EEDC5FBB}_is1", "InstallLocation")
		} catch as e {
			MsgBox "vJoy does not appear to be installed.`n`n" AppName " will close immediately.", "Error - " AppName, 16
			ExitApp 1
		}

		IniWrite(vJoyDir, SettingsPath, "settings", "vJoyDir")
	}

	dllKey := A_PtrSize != 8 ? "DllX86Location" : "DllX64Location"
	try {
		dllDir := RegRead("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{8E31F76F-74C3-47F1-9550-E041EEDC5FBB}_is1", dllKey)
		dllPath := dllDir "\vJoyInterface.dll"
	} catch as e {
		MsgBox "Installed vJoy version is too old. Ensure you install a version newer than 2.0.4.`n`n" AppName " will close immediately.", "Error - " AppName, 16
		ExitApp 2
	}

	IniWrite(dllPath, SettingsPath, "settings", "vJoyDLL")
}

hModule := DllCall("LoadLibrary", "Str", dllPath)
if (!hModule) {
	MsgBox "Could not load vJoy DLL " dllPath "`n`n" AppName " will close immediately.", "Error - " AppName, 16
	ExitApp 3
}

GetHandle(method) {
	return DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "vJoyInterface", "Ptr"), "AStr", method, "Ptr")
}

_SetBtn := GetHandle("SetBtn")
SetButton(rID, bID, state) {
	return DllCall(_SetBtn, "Int", state, "UInt", rID, "UInt", bID)
}

_SetAxis := GetHandle("SetAxis")
SetAxis(rID, aID, value) {
	return DllCall(_SetAxis, "Int", value, "UInt", rID, "UInt", aID)
}

_SetContPov := GetHandle("SetContPov")
SetContPov(rID, cID, value) {
	return DllCall(_SetContPov, "Int", value, "UInt", rID, "UChar", cID)
}

_SetDiscPov := GetHandle("SetDiscPov")
SetDiscPov(rID, dID, value) {
	return DllCall("vJoyInterface\SetDiscPov", "Int", value, "UInt", rID, "UChar", dID)
}

LoadBinds() {
	UnhookAll()

	global BindsName := ""
	global BindsAuthor := ""
	Binds.Clear()
	for axis, in AXISES {
		BindRequirements.AXIS.%axis% := 0
	}
	BindRequirements.BUTTONS := 0
	BindRequirements.POV.CONTINUOUS := 0
	BindRequirements.POV.DISCRETE := 0

	if (FileExist(selectedConfigFile) == "") {
		return 0
	}

	SplitPath selectedConfigFile, &fileName
	BindsName := IniRead(selectedConfigFile, "meta", "name", fileName)
	BindsAuthor := IniRead(selectedConfigFile, "meta", "author", "unknown")

	bindsSection := IniRead(selectedConfigFile, "binds")

	Loop Parse, bindsSection, "`n", "`r" {
		index := InStr(A_LoopField, "=")
		if (Index > 1) {
			key := SubStr(A_LoopField, 1, Index - 1)
			value := IniRead(selectedConfigFile, "binds", Key, "")
			keyName := GetKeyName(Key)
			actions := []

			BUTTON_LOOP:
			Loop Parse, Value, " " {
				for axis, in AXISES {
					if (StringStartsWith(A_LoopField, axis)) {
						isPercent := StringEndsWith(A_LoopField, "%")
						amount := isPercent ? SubStr(A_LoopField, StrLen(axis) + 1, -1) : SubStr(A_LoopField, StrLen(axis) + 1)
						if (IsNumber(amount)) {
							amount *= 1
							if (isPercent) {
								amount /= 100
							}

							actions.Push([axis, amount])
							BindRequirements.AXIS.%axis% := 1
						}
						
						continue BUTTON_LOOP
					}
				}

				if (StringStartsWith(A_LoopField, "B")) {
					button := SubStr(A_LoopField, 2)
					if (IsInteger(button) && button > 0) {
						button := button|0
						actions.Push(["B", button])
						if (button > BindRequirements.BUTTONS) {
							BindRequirements.BUTTONS := button
						}
					}

					continue
				}

				if (StringStartsWith(A_LoopField, "C")) {
					angle := SubStr(A_LoopField, 2)
					if (angle = "up") {
						angle := 0
					} else if (angle = "right") {
						angle := 90
					} else if (angle = "down") {
						angle := 180
					} else if (angle = "left") {
						angle := 270
					}

					if (IsNumber(angle)) {
						angle := Mod(angle|0, 360)
						actions.Push(["C", angle])
						BindRequirements.POV.CONTINUOUS := 1
					}

					continue
				}

				if (StringStartsWith(A_LoopField, "D")) {
					direction := SubStr(A_LoopField, 2)
					if (direction = "up") {
						direction := 1
					} else if (direction = "right") {
						direction := 2
					} else if (direction = "down") {
						direction := 3
					} else if (direction = "left") {
						direction := 4
					}

					if (IsInteger(direction) && direction > 0 && direction < 5) {
						actions.Push(["D", direction|0])
						BindRequirements.POV.DISCRETE := 1
					}

					continue
				}
			}

			if (actions.Length > 0) {
				Binds[keyName] := actions
			}
		}
	}
}

; This ensures we unbind every key we've ever bound
global BoundKeys := []
UnhookAll() {
	for ,key in BoundKeys {
		Hotkey key, "Off"
		Hotkey key " up", "Off"
	}
}

HookAll() {
	UnhookAll()

	for key, in Binds {
		Hotkey key, PollBinds, "On"
		Hotkey key " up", PollBinds, "On"
		BoundKeys.Push(key)
	}

	PollBinds()
}

global LAST_STATE := Map()

global pollAxisValues := Map()
global pollButtons := Map()
PollBinds(*) {
	for axis, in AXISES {
		pollAxisValues[axis] := 0
	}

	Loop DeviceProperties.BUTTONS {
		pollButtons[A_Index] := 0
	}

	cPovX := 0
	cPovY := 0

	dPovUp := 0
	dPovDown := 0
	dPovRight := 0
	dPovLeft := 0

	; Process keys
	for key, actions in Binds {
		if (GetKeyState(key,"P")) {
			for ,action in actions {
				if (action[1] == "B") {
					pollButtons[action[2]] := 1
					continue
				}
				
				if (action[1] == "C") {
					cPovX += Cos(action[2] * DEG2RAD)
					cPovY += Sin(action[2] * DEG2RAD)
					continue
				}
				
				if (action[1] == "D") {
					if (action[2] == 1) {
						dPovUp := 1
					} else if (action[2] == 2) {
						dPovRight := 1
					} else if (action[2] == 3) {
						dPovDown := 1
					} else if (action[2] == 4) {
						dPovLeft := 1
					}
					continue
				}

				for axis, in AXISES {
					if (action[1] == axis) {
						pollAxisValues[action[1]] += action[2]
					}
				}
			}
		}
	}

	; Update axises
	for axis,aID in AXISES {
		if (!DeviceProperties.AXIS.%axis%) {
			continue
		}

		t := (1 + Clamp(pollAxisValues[axis], -1, 1))/2

		min := DeviceProperties.RANGE.%axis%[1]
		max := DeviceProperties.RANGE.%axis%[2]
		value := Round((1 - t) * min + max * t)

		if (!LAST_STATE.Has(axis) || LAST_STATE[axis] != value) {
			SetAxis(AcquiredDevice, aID, value)
			LAST_STATE[axis] := value
		}
	}

	; Update buttons
	Loop DeviceProperties.BUTTONS {
		button := A_Index
		state := pollButtons[A_Index]

		if (!LAST_STATE.Has(button) || LAST_STATE[button] != state) {
			SetButton(AcquiredDevice, button, state)
			LAST_STATE[button] := state
		}
	}

	; Update continous pov
	if (DeviceProperties.POV.CONTINUOUS) {
		value := -1
		squaredHypot := cPovX * cPovX + cPovY * cPovY
		if ((cPovX != 0 || cPovY != 0) && squaredHypot > 0.01) {
			angle := Atan2(cPovY, cPovX) * RAD2DEG
			value := Mod(Round(angle + 360), 360) * 100
		}

		if (!LAST_STATE.Has("C") || LAST_STATE["C"] != value) {
			SetContPov(AcquiredDevice, 1, value)
			LAST_STATE["C"] := value
		}
	}

	; Update discrete pov
	if (DeviceProperties.POV.DISCRETE) {
		value := -1
		if (dPovUp && !dPovDown) {
			value := 1
		} else if (dPovDown && !dPovUp) {
			value := 3
		} else if (dPovRight && !dPovLeft) {
			value := 2
		} else if (dPovLeft && !dPovRight) {
			value := 4
		}
		
		if (!LAST_STATE.Has("D") || LAST_STATE["D"] != value) {
			SetDiscPov(AcquiredDevice, 1, value)
			LAST_STATE["D"] := value
		}
	}
}