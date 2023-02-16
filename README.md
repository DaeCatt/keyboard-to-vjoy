![Keyboard to vJoy Logo](./logo.svg?raw=true)

![Screenshot displaying Keyboard to vJoy interface](./screenshot.png?raw=true)

Keyboard to vJoy is a Windows application that allows you to bind keys to vJoy
buttons, axes, and POVs (d-pads) using .ini configuration files.

**This application requires vJoy 2.0.4 or greater.**

Version [2.2.1.1](https://github.com/njz3/vJoy/releases/tag/v2.2.1.1) or later
is recommended. vJoy can be installed and enabled without rebooting.

## Bind Configuration File Syntax

Ini files _should_ start with a `meta` section to name the configuration and its
author.

```ini
[meta]
name="Configuration Name"
author="Your Name or Alias"
```

Keybinds are defined under the `binds` section in the configuration .ini. Each key
is defined by its name followed by what buttons and axes it should control.

```ini
key_name=button_code axis_code pov_code

; Examples
; A presses button 1
A=B1

; WASD controls the XY axes (usually detected as the left joystick)
W=Y1
A=X-1
S=Y-1
D=X1

; Arrow keys control a Continuos d-pad (POV)
Up=Cup
Left=Cleft
Down=Cdown
Right=Cright

; Q holds the left stick to the top left and presses button 1
Q=Y70.7% X-70.7% B1
```

### Buttons

A button code is simply `B` followed by the button number (starting at 1).

```
B(1-128)
```

Keyboard to VJoy will only be able to press up to the amount of buttons you have
configured your joystick to have in the "Configure vJoy" app.

Button numbers are arbitrary, but this is what they correspond to on a DualShock
4 and an Xbox One controller:

| Number | PlayStation | Xbox  |
| -----: | ----------- | ----- |
|      1 | Square      | A     |
|      2 | X           | B     |
|      3 | Circle      | X     |
|      4 | Triangle    | Y     |
|      5 | L1          | LB    |
|      6 | R1          | RB    |
|      7 | L2          | View  |
|      8 | R2          | Menu  |
|      9 | Share       | L3    |
|     10 | Options     | R3    |
|     11 | L3          | Home  |
|     12 | R3          | Share |
|     13 | Touchpad    |       |
|     14 | PS Button   |       |

### Axes

An axis code is the name of the axis (`X`, `Y`, `Z`, `RX`, `RY`, or `RZ`)
followed by an amount as either a number [-1, 1] or a percentage [-100%, 100%].

```ini
; X 10%
X0.1 or X10% or X.1
; Y -100%
Y-1 or Y-100%
```

While axes are named what they correspond to is not standardized. This is what
the supported axes correspond to on a DualShock 4 and an Xbox One controller:

| Axis | PlayStation   | Xbox          |
| ---: | ------------- | ------------- |
|    X | Left stick X  | Left stick X  |
|    Y | Left stick Y  | Left stick X  |
|    Z | Right stick X | Both triggers |
|   RZ | Right stick Y |               |
|   RX | L2 analog     | Right stick X |
|   RY | R2 analog     | Right stick Y |

Note: Xbox controllers merge both triggers into a single centered axis. The left
trigger moves it left while the right trigger moves it right. DirectInput
therefore cannot detect if both triggers are being used on an Xbox controller.

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
