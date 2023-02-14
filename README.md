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
