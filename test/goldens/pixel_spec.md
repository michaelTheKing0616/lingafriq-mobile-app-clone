# Catalogue pixel spec

Every registered use case is painted at a fixed size of 390 by 640 logical pixels, device pixel ratio 1. The same surface is compared at text scale 1.0 and 2.0, in light and dark. A pixel change fails the golden comparison.

The first three use cases are also compared at dark text scale 2.0. Core controls are compared at light 1.0, dark 1.0, and light 2.0. Text at scale 2.0 wraps inside the 390 width. Glyphs stay visible.

The theme seed is LingAfriqTokens.navy. Light and dark come from that seed. Body text uses LingAfriqType.bodyFamily. Target-language text uses LingAfriqType.target.

## targetText

Widget: TargetText.

States: data. The data state shows Ẹ kú àárọ̀.

Golden size: 390 by 640.

Spacing: the line box is LingAfriqType.targetSize with LingAfriqType.targetHeight, so the leading is 1.5. The frame does not add padding around the phrase.

Token ids:

- LingAfriqType.target
- LingAfriqType.targetFamily
- LingAfriqType.targetSize
- LingAfriqType.targetHeight
- LingAfriqType.scriptFallback
- LingAfriqTokens.navy

## diacriticKeyboard

Widget: DiacriticKeyboard.

States:

- yoruba. Language yo. This is DiacriticKeyboardStatus.ready, the Yoruba long-press row, with the variant strip closed.
- noLayout. Language am. This is DiacriticKeyboardStatus.noLayout. The field stays editable and the typed notice is shown.

Golden size: 390 by 640.

Spacing:

- LingAfriqTokens.spacing16 around the column and inside the notice
- LingAfriqTokens.spacing8 between the field, the row, and the keys
- LingAfriqTokens.spacing4 inside each key
- LingAfriqTokens.spacing48 minimum key width and height
- LingAfriqTokens.radiussm key corner
- LingAfriqTokens.elevationLightsm on a light key
- LingAfriqTokens.elevationDarksm on a dark key
- The notice uses vertical LingAfriqTokens.spacing8

Token ids:

- LingAfriqTokens.spacing16
- LingAfriqTokens.spacing8
- LingAfriqTokens.spacing4
- LingAfriqTokens.spacing48
- LingAfriqTokens.radiussm
- LingAfriqTokens.elevationLightsm
- LingAfriqTokens.elevationDarksm
- LingAfriqTokens.navy
- LingAfriqType.target
- LingAfriqType.bodyFamily
- LingAfriqType.bodySize
- LingAfriqType.targetHeight
- LingAfriqType.scriptFallback

## readingOption

Widget: ReadingOptionTile. The catalogue and the golden wrap it in a Scaffold.

States:

- off. The switch is off. The title uses the body face.
- on. The switch is on. The title and subtitle use Andika, with letter spacing LingAfriqTokens.spacing4 / 16 and word spacing LingAfriqTokens.spacing4 / 8.

Golden size: 390 by 640.

Spacing:

- LingAfriqTokens.spacing16 horizontal padding
- LingAfriqTokens.spacing12 vertical padding
- LingAfriqTokens.spacing4 between the title and the subtitle
- LingAfriqTokens.spacing8 between the text and the switch

Token ids:

- LingAfriqTokens.spacing16
- LingAfriqTokens.spacing12
- LingAfriqTokens.spacing4
- LingAfriqTokens.spacing8
- LingAfriqTokens.navy
- LingAfriqType.ui
- LingAfriqType.targetNow
- LingAfriqType.targetFamily
- LingAfriqType.bodyFamily
- LingAfriqType.target

## lingButton

Widget: LingButton. Role accent. The label is commonActionContinue.

States: default, pressed, focused, disabled, loading.

Golden size: 390 by 640. Frames: light 1.0, dark 1.0, light 2.0.

The page background is the ramp role surface (LingAfriqTokens.roleLightSurface or LingAfriqTokens.roleDarkSurface). It is not LingAfriqTokens.surface.

Spacing:

- LingAfriqTokens.spacing16 page padding and horizontal padding inside the control
- LingAfriqTokens.spacing12 vertical padding inside the control
- LingAfriqTokens.spacing8 between the progress mark and the label
- LingAfriqTokens.spacing4 between the label and the unavailable word, and as the focused gap
- LingAfriqTokens.spacing48 minimum width and height
- LingAfriqTokens.radiussm corner

Token ids:

- LingAfriqTokens.roleLightSurface
- LingAfriqTokens.roleDarkSurface
- LingAfriqTokens.roleLightOnSurface
- LingAfriqTokens.roleDarkOnSurface
- LingAfriqTokens.roleLightSurfaceContainer
- LingAfriqTokens.roleDarkSurfaceContainer
- LingAfriqTokens.roleLightAccent
- LingAfriqTokens.roleDarkAccent
- LingAfriqTokens.roleLightOnAccent
- LingAfriqTokens.roleDarkOnAccent
- LingAfriqTokens.spacing16
- LingAfriqTokens.spacing12
- LingAfriqTokens.spacing8
- LingAfriqTokens.spacing4
- LingAfriqTokens.spacing48
- LingAfriqTokens.radiussm
- LingAfriqTokens.strokeregular
- LingAfriqTokens.strokehairline
- LingAfriqTokens.motionProductFast
- LingAfriqTokens.motionProductSlow
- LingAfriqTokens.motionProductEasing
- LingAfriqType.bodyFamily
- LingAfriqType.bodySize
- LingAfriqType.targetHeight

default fills with the accent role and paints onAccent. pressed blends onSurface onto that fill and drops elevation to none. focused keeps the accent fill and adds an accent ring of LingAfriqTokens.strokeregular outside a LingAfriqTokens.spacing4 gap. disabled fills with the container role, paints onSurface, draws an onSurface hairline, shows the unavailable word, and clears the enabled semantics flag. loading keeps the label and shows a progress mark. The mark holds still when animations are disabled. Product motion uses LingAfriqTokens.motionProductFast, or LingAfriqTokens.motionProductSlow when motion is reduced. Both are at most 300 ms. Reduced motion still moves.

## lingCard

Widget: LingCard. The child is TargetText with Ẹ kú àárọ̀.

States: default, pressed, focused, disabled, loading.

Golden size: 390 by 640. Frames: light 1.0, dark 1.0, light 2.0.

Spacing:

- LingAfriqTokens.spacing16 page padding and padding inside the card
- LingAfriqTokens.spacing8 between the status and the phrase
- LingAfriqTokens.spacing4 focused gap
- LingAfriqTokens.spacing48 minimum width and height
- LingAfriqTokens.radiusmd corner
- LingAfriqTokens.elevationLightsm resting shadow on a light card
- LingAfriqTokens.elevationDarksm resting shadow on a dark card
- LingAfriqTokens.elevationLightnone when pressed or disabled
- LingAfriqTokens.elevationDarknone when pressed or disabled

Token ids:

- LingAfriqTokens.roleLightSurface
- LingAfriqTokens.roleDarkSurface
- LingAfriqTokens.roleLightSurfaceContainer
- LingAfriqTokens.roleDarkSurfaceContainer
- LingAfriqTokens.roleLightOnSurface
- LingAfriqTokens.roleDarkOnSurface
- LingAfriqTokens.roleLightAccent
- LingAfriqTokens.roleDarkAccent
- LingAfriqTokens.spacing16
- LingAfriqTokens.spacing8
- LingAfriqTokens.spacing4
- LingAfriqTokens.spacing48
- LingAfriqTokens.radiusmd
- LingAfriqTokens.elevationLightsm
- LingAfriqTokens.elevationDarksm
- LingAfriqTokens.elevationLightnone
- LingAfriqTokens.elevationDarknone
- LingAfriqTokens.strokeregular
- LingAfriqType.target
- LingAfriqType.bodyFamily

The card fill is the container role. pressed blends onSurface onto that fill. focused adds the accent ring. disabled shows the unavailable word and clears the enabled semantics flag. loading keeps the phrase and shows a progress mark.

## lingTextField

Widget: LingTextField. The label is commonActionSave.

States: default, pressed, focused, disabled, loading.

Golden size: 390 by 640. Frames: light 1.0, dark 1.0, light 2.0.

Spacing:

- LingAfriqTokens.spacing16 page padding and horizontal padding inside the field
- LingAfriqTokens.spacing12 vertical padding inside the field
- LingAfriqTokens.spacing8 between the label and the field
- LingAfriqTokens.spacing4 before the unavailable word
- LingAfriqTokens.spacing48 minimum width and height of the field
- LingAfriqTokens.radiussm corner

Token ids:

- LingAfriqTokens.roleLightSurface
- LingAfriqTokens.roleDarkSurface
- LingAfriqTokens.roleLightSurfaceContainer
- LingAfriqTokens.roleDarkSurfaceContainer
- LingAfriqTokens.roleLightOnSurface
- LingAfriqTokens.roleDarkOnSurface
- LingAfriqTokens.roleLightOnSurfaceVariant
- LingAfriqTokens.roleDarkOnSurfaceVariant
- LingAfriqTokens.roleLightAccent
- LingAfriqTokens.roleDarkAccent
- LingAfriqTokens.spacing16
- LingAfriqTokens.spacing12
- LingAfriqTokens.spacing8
- LingAfriqTokens.spacing4
- LingAfriqTokens.spacing48
- LingAfriqTokens.radiussm
- LingAfriqTokens.strokeregular
- LingAfriqTokens.strokehairline
- LingAfriqType.bodyFamily
- LingAfriqType.bodySize
- LingAfriqType.targetHeight

default fills with the container role and a hairline in the onSurfaceVariant role. pressed blends onSurface onto that fill. focused uses an accent border of LingAfriqTokens.strokeregular. disabled shows the unavailable word, clears the enabled semantics flag, and turns the field off. loading keeps the label and shows a progress mark in the field.

## lingListRow

Widget: LingListRow. The label is commonActionSave. Quiet, so the fill is the container role.

States: default, pressed, focused, disabled, loading.

Golden size: 390 by 640. Frames: light 1.0, dark 1.0, light 2.0.

Spacing:

- LingAfriqTokens.spacing16 horizontal padding
- LingAfriqTokens.spacing12 vertical padding
- LingAfriqTokens.spacing8 between the progress mark and the label
- LingAfriqTokens.spacing4 between the label and the unavailable word, and as the focused gap
- LingAfriqTokens.spacing24 trailing icon
- LingAfriqTokens.spacing48 minimum width and height
- LingAfriqTokens.radiussm corner

Token ids:

- LingAfriqTokens.roleLightSurfaceContainer
- LingAfriqTokens.roleDarkSurfaceContainer
- LingAfriqTokens.roleLightOnSurface
- LingAfriqTokens.roleDarkOnSurface
- LingAfriqTokens.roleLightAccent
- LingAfriqTokens.roleDarkAccent
- LingAfriqTokens.spacing16
- LingAfriqTokens.spacing12
- LingAfriqTokens.spacing8
- LingAfriqTokens.spacing4
- LingAfriqTokens.spacing24
- LingAfriqTokens.spacing48
- LingAfriqTokens.radiussm
- LingAfriqTokens.strokeregular
- LingAfriqType.bodyFamily

default is the container role, not accent. pressed blends onSurface onto that fill. focused adds the accent ring. disabled shows the unavailable word and clears the enabled semantics flag. loading keeps the label and shows a progress mark.

## lingBottomSheet

Widget: LingBottomSheet. The sheet label is commonActionShowMore. The action is LingButton with commonActionContinue.

States: default, pressed, focused, disabled, loading.

Golden size: 390 by 640. Frames: light 1.0, dark 1.0, light 2.0.

Spacing:

- LingAfriqTokens.spacing16 inside the sheet
- LingAfriqTokens.spacing8 between the label and the action
- LingAfriqTokens.spacing4 handle height and focused gap
- LingAfriqTokens.spacing32 handle width
- LingAfriqTokens.spacing48 minimum action size
- LingAfriqTokens.radiuslg top corner
- LingAfriqTokens.radiuspill handle corner
- LingAfriqTokens.radiussm action corner
- LingAfriqTokens.elevationLightsm resting shadow on a light sheet
- LingAfriqTokens.elevationDarksm resting shadow on a dark sheet

Token ids:

- LingAfriqTokens.roleLightSurface
- LingAfriqTokens.roleDarkSurface
- LingAfriqTokens.roleLightSurfaceContainer
- LingAfriqTokens.roleDarkSurfaceContainer
- LingAfriqTokens.roleLightOnSurface
- LingAfriqTokens.roleDarkOnSurface
- LingAfriqTokens.roleLightOnSurfaceVariant
- LingAfriqTokens.roleDarkOnSurfaceVariant
- LingAfriqTokens.roleLightAccent
- LingAfriqTokens.roleDarkAccent
- LingAfriqTokens.roleLightOnAccent
- LingAfriqTokens.roleDarkOnAccent
- LingAfriqTokens.spacing16
- LingAfriqTokens.spacing8
- LingAfriqTokens.spacing4
- LingAfriqTokens.spacing32
- LingAfriqTokens.spacing48
- LingAfriqTokens.radiuslg
- LingAfriqTokens.radiuspill
- LingAfriqTokens.radiussm
- LingAfriqTokens.elevationLightsm
- LingAfriqTokens.elevationDarksm
- LingAfriqType.bodyFamily

The sheet panel uses the container role. The action uses the accent role. pressed blends onSurface onto each fill. focused adds the accent ring. disabled shows the unavailable word on the action and clears the enabled semantics flag. loading keeps both labels and shows a progress mark on the action.

## lingDialog

Widget: LingDialog. The title is commonActionTryAgain. The action is LingButton with commonActionClose.

States: default, pressed, focused, disabled, loading.

Golden size: 390 by 640. Frames: light 1.0, dark 1.0, light 2.0.

Spacing:

- LingAfriqTokens.spacing16 page padding and padding inside the dialog
- LingAfriqTokens.spacing8 between the title and the action
- LingAfriqTokens.spacing4 focused gap
- LingAfriqTokens.spacing48 minimum action size
- LingAfriqTokens.radiusmd corner
- LingAfriqTokens.elevationLightmd resting shadow on a light dialog
- LingAfriqTokens.elevationDarkmd resting shadow on a dark dialog

Token ids:

- LingAfriqTokens.roleLightSurface
- LingAfriqTokens.roleDarkSurface
- LingAfriqTokens.roleLightSurfaceContainer
- LingAfriqTokens.roleDarkSurfaceContainer
- LingAfriqTokens.roleLightOnSurface
- LingAfriqTokens.roleDarkOnSurface
- LingAfriqTokens.roleLightAccent
- LingAfriqTokens.roleDarkAccent
- LingAfriqTokens.roleLightOnAccent
- LingAfriqTokens.roleDarkOnAccent
- LingAfriqTokens.spacing16
- LingAfriqTokens.spacing8
- LingAfriqTokens.spacing4
- LingAfriqTokens.spacing48
- LingAfriqTokens.radiusmd
- LingAfriqTokens.elevationLightmd
- LingAfriqTokens.elevationDarkmd
- LingAfriqType.bodyFamily

The dialog panel uses the container role. The action uses the accent role. pressed blends onSurface onto each fill. focused adds the accent ring. disabled shows the unavailable word on the action and clears the enabled semantics flag. loading keeps the title and the action label and shows a progress mark.

## lingChip

Widget: LingChip. The label is commonActionShowMore. Quiet, so the fill is the container role, not accent.

States: default, pressed, focused, disabled, loading.

Golden size: 390 by 640. Frames: light 1.0, dark 1.0, light 2.0.

Spacing:

- LingAfriqTokens.spacing16 page padding and horizontal padding inside the chip
- LingAfriqTokens.spacing12 vertical padding inside the chip
- LingAfriqTokens.spacing8 between the progress mark and the label
- LingAfriqTokens.spacing4 between the label and the unavailable word, and as the focused gap
- LingAfriqTokens.spacing48 minimum width and height
- LingAfriqTokens.radiuspill corner

Token ids:

- LingAfriqTokens.roleLightSurface
- LingAfriqTokens.roleDarkSurface
- LingAfriqTokens.roleLightSurfaceContainer
- LingAfriqTokens.roleDarkSurfaceContainer
- LingAfriqTokens.roleLightOnSurface
- LingAfriqTokens.roleDarkOnSurface
- LingAfriqTokens.roleLightAccent
- LingAfriqTokens.roleDarkAccent
- LingAfriqTokens.spacing16
- LingAfriqTokens.spacing12
- LingAfriqTokens.spacing8
- LingAfriqTokens.spacing4
- LingAfriqTokens.spacing48
- LingAfriqTokens.radiuspill
- LingAfriqTokens.strokeregular
- LingAfriqType.bodyFamily

default is the container role. pressed blends onSurface onto that fill. focused adds the accent ring. disabled shows the unavailable word and clears the enabled semantics flag. loading keeps the label and shows a progress mark.
