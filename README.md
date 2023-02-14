# Keyboard to vJoy

Keyboard to vJoy is a Windows application that allows you to bind keys to vJoy
buttons, axes, and POVs (d-pads) using .ini configuration files.

```ini
[meta]
name=Example
author=DaeCatt

[binds]
; Binds the fact buttons on a gamepad to ZXCV
Z=B1
X=B2
C=B3
V=B4

; Binds WS to the Y axis on the left joystick, and AD to the X axis on the left joystick.
W=Y1
A=X-1
S=Y-1
D=X1

; Binds IJ to the Y axis on the right joystick, and JL to the X axis on the right joystick.
I=RZ1
J=Z-1
K=RZ-1
L=Z-1

; Binds the keyboard arrows to the _C_ontinuos POV (d-pad).
Up=Cup
Left=Cleft
Down=Cdown
Right=Cright
```

## Syntax

Under the _binds_ section in your configuration .ini each bind is defined by the
name of the key and what buttons and axes it affects:

```
key_name=button_code axis_code pov_code
```

### Buttons

A button code is simply `B` followed by the button number (starting at 1).

```
B(1-128)
```

Keyboard to VJoy will only be able to press up to the amount of buttons you have
configured your joystick to have. Modern gamepads are expected to have 14 buttons,
according to the Windows USB controller test these are numbered:

| Number | PlayStation |
| -----: | ----------- |
|      1 | Square      |
|      2 | X           |
|      3 | Circle      |
|      4 | Triangle    |
|      5 | L1          |
|      6 | R1          |
|      7 | L2          |
|      8 | R2          |
|      9 | Share       |
|     10 | Options     |
|     11 | L3          |
|     12 | R3          |
|     13 | Touchpad    |
|     14 | PS Button   |

### Axes

An axis code is the name of the axis (`X`, `Y`, `Z`, `RX`, `RY`, or `RZ`)
followed by an amount as either a number [-1, 1] or a percentage [-100%, 100%].

```
; X 10%
X0.1 or X10% or X.1
; Y -100%
Y-1 or Y-100%
```

| Axis | PlayStation   |
| ---: | ------------- |
|    X | Left stick X  |
|    Y | Left stick Y  |
|    Z | Right stick X |
|   RZ | Right stick Y |
|   RX | L2 analog     |
|   RY | R2 analog     |

### POVs (D-Pad)

vJoy supports two kinds of D-Pads and Keyboard to vJoy can bind to either,
though using continuos is highly recommend.

**C**ontinuos

A continuos d-pad code is simply `C` followed by either `up`, `right`, `down`,
`left` or a number indicating the angle (0 for up, 90 for right, 180 for down,
270 for left).

If multiple keys are controlling a continuos d-pad the average angle is used,
unless the average is undefined in which case the d-pad is released. For example
`C0 C270` results in `C315`, while `C0 C180` results in the d-pad being
released.

**D**iscrete

A discrete d-pad code is simply `D` followed by either `up`, `right`, `down`,
`left` or a direction number (1 for up, 2 for right, 3 for down, 4 for left).

Discrete d-pads acts as a button with 5 states, and does not support diagonals.

## Known Issues

### No Axes Correlation

Keyboard to vJoy does not normalize axes, which means that the following bind:

```ini
A=X1 Y1
```

Will result in the left joystick moving outside the expected circle it would
normally be limited to.

### All Axes Return to Center

Keyboard to vJoy currently returns all axes to the center, including the axes
used for analog triggers. As such analog triggers will be considered 50% held
by default, and moving the axis to -100% is required to set it to 0.
