# Colour roles

Navy `#2E3A87` stays the legacy brand token. The accent ramp uses that hue (272.2352) and is the only accent. Its only meaning is primary action.

Dark surfaces use their own ramp steps. They are not the mirror step of the light role, and they are not an RGB invert of the light hex.

| Mode | Role | Group | Ramp | Step | Hex |
| --- | --- | --- | --- | --- | --- |
| light | surface | surface | neutral | 50 | #F2F5FE |
| light | surfaceContainer | surface | neutral | 100 | #E5E8F0 |
| light | onSurface | text | neutral | 900 | #1D1F25 |
| light | onSurfaceVariant | text | neutral | 700 | #45474E |
| light | accent | accent | accent | 700 | #2E389C |
| light | onAccent | text | accent | 50 | #F2F5FF |
| light | success | meaning | success | 800 | #003F18 |
| light | onSuccess | text | success | 50 | #DFFFE4 |
| light | warning | meaning | warning | 800 | #442E00 |
| light | onWarning | text | warning | 50 | #FFF4E1 |
| light | danger | meaning | danger | 700 | #8A0314 |
| light | onDanger | text | danger | 50 | #FFF2F0 |
| light | info | meaning | info | 800 | #003A42 |
| light | onInfo | text | info | 50 | #E2FAFF |
| dark | surface | surface | neutral | 800 | #313339 |
| dark | surfaceContainer | surface | neutral | 700 | #45474E |
| dark | onSurface | text | neutral | 100 | #E5E8F0 |
| dark | onSurfaceVariant | text | neutral | 300 | #B1B4BC |
| dark | accent | accent | accent | 300 | #9AAFFF |
| dark | onAccent | text | accent | 950 | #07003E |
| dark | success | meaning | success | 300 | #6CCD83 |
| dark | onSuccess | text | success | 950 | #001504 |
| dark | warning | meaning | warning | 300 | #E3A939 |
| dark | onWarning | text | warning | 950 | #180D00 |
| dark | danger | meaning | danger | 300 | #FF9088 |
| dark | onDanger | text | danger | 950 | #270001 |
| dark | info | meaning | info | 300 | #3AC9DE |
| dark | onInfo | text | info | 950 | #001317 |

## Meaning cues

State is never colour alone.

| Ramp | Meaning | Non-colour cue |
| --- | --- | --- |
| success | success | check |
| warning | warning | triangle |
| danger | error | cross |
| info | info | info-mark |

Accent meaning is `primary-action`. The control that uses it is a filled button, so the action is not identified by colour alone.

## Pairs

Body pairs need 4.5:1. Large and icon pairs need 3:1.

| Mode | Foreground | Background | Level |
| --- | --- | --- | --- |
| light | onSurface | surface | body |
| light | onSurface | surfaceContainer | body |
| light | onSurfaceVariant | surface | body |
| light | onAccent | accent | body |
| light | accent | surface | large |
| light | onSuccess | success | body |
| light | success | surface | body |
| light | onWarning | warning | body |
| light | warning | surface | body |
| light | onDanger | danger | body |
| light | danger | surface | body |
| light | onInfo | info | body |
| light | info | surface | body |
| dark | onSurface | surface | body |
| dark | onSurface | surfaceContainer | body |
| dark | onSurfaceVariant | surface | body |
| dark | onAccent | accent | body |
| dark | accent | surface | large |
| dark | onSuccess | success | body |
| dark | success | surface | body |
| dark | onWarning | warning | body |
| dark | warning | surface | body |
| dark | onDanger | danger | body |
| dark | danger | surface | body |
| dark | onInfo | info | body |
| dark | info | surface | body |

sRGB gamut clamping is logged for 39 ramp steps in `colorRamps.gamutClamp`.
