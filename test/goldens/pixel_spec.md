# Catalogue pixel spec

Every registered use case is painted at a fixed size of 390 by 640 logical pixels, device pixel ratio 1. The same surface is compared at text scale 1.0 and 2.0, in light and dark. A pixel change fails the golden comparison.

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
