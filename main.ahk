#SingleInstance Force
global AppName := "Keyboard to vJoy"
DirCreate A_AppData "\" AppName
global SettingsPath := A_AppData "\" AppName "\settings.ini"
;@Ahk2Exe-IgnoreBegin
TraySetIcon(A_ScriptDir "\icon.ico")
;@Ahk2Exe-IgnoreEnd
#Include vjoy.ahk

; Load App Settings
global selectedConfigFile := IniRead(SettingsPath, "settings", "bindConfig", "")
global selectedVJoyDevice := IniRead(SettingsPath, "settings", "vJoyDevice", "1")
global closeToTray := IniRead(SettingsPath, "settings", "closeToTray", "false")

; Create GUI
interface := Gui("-MaximizeBox -Resize", AppName)
interface.OnEvent("Close", GUI_Close)
GUI_Close(*) {
	if (closeToTray != "true") {
		UnhookAll()
		if (AcquiredDevice) {
			DllCall("vJoyInterface\RelinquishVJD", "UInt", AcquiredDevice)
		}
		ExitApp 0
	}
}

; Create config display box
configGroupBox := interface.AddGroupBox("x10 w320","Selected Keybind Configuration")
global bindsMetaText := interface.AddText("xp+9 yp+16 w282","Loading...`n")
UpdateBindsMetaText(*) {
	global BindsName
	global BindsAuthor

	if (BindsName == "" && BindsAuthor == "" && Binds.Count == 0) {
		bindsMetaText.Text := "No keybind configuration selected."
		return
	}
	
	bindsMetaText.Text := BindsName " by " BindsAuthor "`n" Binds.Count " keybinds for " BindRequirements.BUTTONS.Length " buttons"
}

; Create vJoy device picker
global DeviceDropdownMap := []
global deviceDropdown := interface.AddDropDownList("Disabled x10 yp+48 w100")
deviceDropdown.OnEvent("Change", VJoyDevice_Change)
VJoyDevice_Change(*) {
	global selectedVJoyDevice := DeviceDropdownMap[deviceDropdown.Value]
	IniWrite(selectedVJoyDevice, SettingsPath, "settings", "vJoyDevice")
}

UpdateAvailableDevices() {
	deviceDropdown.Delete()
	if (!DllCall("vJoyInterface\vJoyEnabled")) {
		deviceDropdown.Enabled := false
		; TODO: Display "vJoy disabled" message
		return
	}

	Select := 0
	DeviceDropdownMap.Length := 0
	Loop VJOY_MAX_DEVICES {
		if (DllCall("vJoyInterface\isVJDExists", "UInt", A_Index)) {
			deviceDropdown.Add(["vJoy Device " A_Index])
			DeviceDropdownMap.Push(A_Index)
			if (A_Index == selectedVJoyDevice) {
				Select := A_Index
			}
		}
	}

	if (Select > 0) {
		deviceDropdown.Value := Select
	} else {
		deviceDropdown.Value := 1
	}

	deviceDropdown.Enabled := true
}

; Create browser for config button
global browse := interface.AddButton("yp-1 x120 w110", "Browse for config...")
browse.OnEvent("Click", Browse_Click)
Browse_Click(*) {
	global selectedConfigFile := FileSelect(3, , "Select Bind Configuration File", "*.ini")
	IniWrite(selectedConfigFile, SettingsPath, "settings", "bindConfig")
	LoadBinds()
	UpdateBindsMetaText()
}

; Create button to enable all keybinds
global toggleEnableButton := interface.AddButton("yp+0 x240 w90","Enable Binds")
toggleEnableButton.OnEvent("Click", ToggleEnable_Click)

ToggleEnable_Click(*) {
	global AcquiredDevice

	if (AcquiredDevice == 0) {
		acquired := DllCall("vJoyInterface\AcquireVJD", "UInt", selectedVJoyDevice)
		if (!acquired) {
			MsgBox "Could not acquire vJoy Device.", "Error - " AppName
			return
		}

		AcquiredDevice := selectedVJoyDevice
		DllCall("vJoyInterface\ResetVJD", "UInt", AcquiredDevice)

		for axis,aID in AXISES {
			DeviceProperties.AXIS.%axis% := DllCall("vJoyInterface\GetVJDAxisExist", "UInt", AcquiredDevice, "UInt", aID)
			DllCall("vJoyInterface\GetVJDAxisMin", "UInt", AcquiredDevice, "UInt", aID, "Int*", &min := 0)
			DllCall("vJoyInterface\GetVJDAxisMax", "UInt", AcquiredDevice, "UInt", aID, "Int*", &max := 0)
			DeviceProperties.RANGE.%axis%[1] := min
			DeviceProperties.RANGE.%axis%[2] := max
		}

		DeviceProperties.BUTTONS := DllCall("vJoyInterface\GetVJDButtonNumber", "UInt", AcquiredDevice)
		DeviceProperties.POV.CONTINUOUS := DllCall("vJoyInterface\GetVJDContPovNumber", "UInt", AcquiredDevice)
		DeviceProperties.POV.DISCRETE := DllCall("vJoyInterface\GetVJDDiscPovNumber", "UInt", AcquiredDevice)

		HookAll()
		deviceDropdown.Enabled := false
		browse.Enabled := false
		toggleEnableButton.Text := "Disable Binds"
	} else {
		DllCall("vJoyInterface\RelinquishVJD", "UInt", AcquiredDevice)
		UnhookAll()
		AcquiredDevice := 0

		deviceDropdown.Enabled := true
		browse.Enabled := true
		toggleEnableButton.Text := "Enable Binds"
	}
}

; Create close to tray toggle option
global closeToTrayToggle := interface.AddCheckBox("x10 " (closeToTray == "true" ? "Checked" : ""), " Close to tray")
closeToTrayToggle.OnEvent("click", CloseToTray_Click)
CloseToTray_Click(*) {
	global closeToTray := closeToTrayToggle.Value ? "true" : "false"
	IniWrite(closeToTray, SettingsPath, "settings", "closeToTray")
	UpdateTrayBehavior()
}

; statusBar := interface.AddStatusBar(, "")
; try {
; 	productString := StrGet(DllCall("vJoyInterface\GetvJoyProductString"))
; 	manufacturerString := StrGet(DllCall("vJoyInterface\GetvJoyManufacturerString"))
; 	serialNumberString := StrGet(DllCall("vJoyInterface\GetvJoySerialNumberString"))
; 	statusBar.SetText(productString "-" manufacturerString "-" serialNumberString)
; }

ShowGUI(*) {
	interface.Show()
}

; Configure systray
A_IconTip := AppName
A_TrayMenu.Delete()
A_TrayMenu.Add("Show", ShowGUI)
A_TrayMenu.Add("Exit", (*) => ExitApp(0))

A_TrayMenu.ClickCount := 1
A_TrayMenu.Default := "Show"

UpdateTrayBehavior() {
	if (closeToTray == "true") {
		A_IconHidden := false
		Persistent 1
	} else {
		A_IconHidden := true
		Persistent 0
	}
}

; Finish app setup
UpdateTrayBehavior()
UpdateAvailableDevices()

LoadBinds()
UpdateBindsMetaText()

; Show interface
ShowGUI()