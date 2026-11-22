charter: v2

# Art directions

Card P3-003. Three directions for a later choice (ADR-010). This file does not choose one.

Sources: `docs/source/ELEVATION.md` §3.4 (lines 825-851), `design/tokens/tokens.json` `colorRamps`, `design/tokens/color_roles.md`, `docs/build/design/PRINCIPLES.md` (LP-01 through LP-09), and ADR-012.

The Today heroes are the loaded plan from `docs/build/design/screens/today_path_lesson.md`: one plan, the minute pill, due reviews, the next lesson with `Ẹ kú àárọ̀`, one speaking row, and one Start button. Width is 390 CSS pixels. Page padding is 16. Controls are at least 48. The button radius is 12. The pill radius is 999.

## Shared rules

Each direction has one accent ramp. Its only meaning is primary action. Start is the only accent fill on the Today hero. Accent is not used as body text. The large pair is accent on surface. The body pair on the button is onAccent on accent.

Meaning ramps stay on the shipped hues. Success keeps the check. Warning keeps the triangle. Danger keeps the cross. Info keeps the info mark. A state is never color alone (LP-05 for tone, and the same rule for the four meanings).

Dark surfaces use their own ramp steps: surface is step 800, surfaceContainer is step 700. Those steps are not the mirror of the light steps, and they are not an RGB invert of the light surface.

Lightness steps are the shipped scale: 0.97, 0.93, 0.86, 0.77, 0.67, 0.57, 0.48, 0.40, 0.32, 0.24, 0.17. Chroma that falls outside sRGB is clamped with the same routine as `test/design/color_contrast_test.dart`. Clamped steps are marked.

A craft motif may sit on one surface of a screen, as the identity of that unit or region. The Today unit is the Yoruba morning greeting, so the only tradition eligible for this screen is Yoruba adire. The minute pill, the review row, the speaking row, and Start stay plain. A stripe repeated on every card is outside these directions.

The target line is Andika at 18px or larger, line-height 1.5. UI text is Noto Sans. Scripts Andika does not cover use the bundled Noto faces. ADR-012 still names Nunito as the product display face. These directions do not add a family and do not edit that decision. The hero title is set in Noto Sans so the frame shows the Andika and Noto pairing.

## Principles

| id | How the three heroes keep it |
| --- | --- |
| LP-01 | The greeting is on the screen before Start. The learner meets the line, then the plan asks for it. |
| LP-02 | Due reviews names words that are ready for a later session. The frame shows no score. |
| LP-03 | These frames are the loaded plan. They are a lesson the learner can tell from a failed load. |
| LP-04 | The speaking row asks the learner to say one greeting out loud. |
| LP-05 | Andika draws the tone marks. Night Study also draws a contour in the text color. The contour is a shape. |
| LP-06 | The frame has no confidence chip. An unsure check is not hidden as a number. |
| LP-07 | The cultural moment is the greeting. Craft, where it appears, names that unit. |
| LP-08 | Today stays one plan. It is not restyled as a chat, a status, or a clip. |
| LP-09 | The frame has no star count and no save badge. The words of the line are what the learner keeps. |

## Review checklist

This checklist is the packet for EXT-14. EXT-14 has not returned. No consultant is named. No quote is recorded. No licence is recorded. Sign-off for every direction is Pending.

| check | what this packet shows | sign-off |
| --- | --- | --- |
| The motif matches the language of the unit | The unit is a Yoruba morning greeting. The only drawn craft study is an adire placement study, and only in Ink Lesson. | Pending |
| One surface | The study sits under the greeting, on the Next lesson row. The other rows are plain. | Pending |
| No repeated stripe | The pill, the review row, the speaking row, and Start have no pattern. | Pending |
| Artist named only with a contract | No person is named. | Pending |
| Licence recorded only from a document | Licence is not recorded. | Pending |
| Target text | Andika, 18px or 22px, line-height 1.5, marks visible. | Pending |
| Tone is a shape | Marks are in the letters. Night Study adds a text-color contour read from those marks. | Pending |
| People | No person is drawn. | Pending |

## Shared meaning ramps

These four ramps are part of every direction. Steps below are the shipped values in `design/tokens/tokens.json`.

### success

Hue 150. Requested chroma 0.14. Meaning: success. Cue: check.

| step | L | C | H | hex |
| --- | --- | --- | --- | --- |
| 50 | 0.97 | 0.048452 | 150 | #DFFFE4 |
| 100 | 0.93 | 0.120514 | 150 | #ACFFBD |
| 200 | 0.86 | 0.14 | 150 | #89EB9F |
| 300 | 0.77 | 0.14 | 150 | #6CCD83 |
| 400 | 0.67 | 0.14 | 150 | #4AAD65 |
| 500 | 0.57 | 0.14 | 150 | #258D48 |
| 600 | 0.48 | 0.132318 | 150 | #007131 |
| 700 | 0.40 | 0.110342 | 150 | #005724 |
| 800 | 0.32 | 0.088413 | 150 | #003F18 |
| 900 | 0.24 | 0.066605 | 150 | #00280C |
| 950 | 0.17 | 0.047834 | 150 | #001504 |

### warning

Hue 80. Requested chroma 0.14. Meaning: warning. Cue: triangle.

| step | L | C | H | hex |
| --- | --- | --- | --- | --- |
| 50 | 0.97 | 0.027232 | 80 | #FFF4E1 |
| 100 | 0.93 | 0.064742 | 80 | #FFE4B8 |
| 200 | 0.86 | 0.13429 | 80 | #FFC761 |
| 300 | 0.77 | 0.14 | 80 | #E3A939 |
| 400 | 0.67 | 0.138835 | 80 | #C18A00 |
| 500 | 0.57 | 0.118149 | 80 | #9B6E00 |
| 600 | 0.48 | 0.099545 | 80 | #7B5600 |
| 700 | 0.40 | 0.083032 | 80 | #5F4200 |
| 800 | 0.32 | 0.066567 | 80 | #442E00 |
| 900 | 0.24 | 0.050223 | 80 | #2C1C00 |
| 950 | 0.17 | 0.036243 | 80 | #180D00 |

### danger

Hue 25. Requested chroma 0.16. Meaning: error. Cue: cross.

| step | L | C | H | hex |
| --- | --- | --- | --- | --- |
| 50 | 0.97 | 0.014677 | 25 | #FFF2F0 |
| 100 | 0.93 | 0.035412 | 25 | #FFDFDC |
| 200 | 0.86 | 0.075466 | 25 | #FFBEB8 |
| 300 | 0.77 | 0.13562 | 25 | #FF9088 |
| 400 | 0.67 | 0.16 | 25 | #E76761 |
| 500 | 0.57 | 0.16 | 25 | #C44844 |
| 600 | 0.48 | 0.16 | 25 | #A5292B |
| 700 | 0.40 | 0.16 | 25 | #8A0314 |
| 800 | 0.32 | 0.130063 | 25 | #65000A |
| 900 | 0.24 | 0.097892 | 25 | #430004 |
| 950 | 0.17 | 0.070105 | 25 | #270001 |

### info

Hue 210. Requested chroma 0.12. Meaning: info. Cue: info-mark.

| step | L | C | H | hex |
| --- | --- | --- | --- | --- |
| 50 | 0.97 | 0.026376 | 210 | #E2FAFF |
| 100 | 0.93 | 0.062336 | 210 | #B8F4FF |
| 200 | 0.86 | 0.12 | 210 | #5FE6FC |
| 300 | 0.77 | 0.12 | 210 | #3AC9DE |
| 400 | 0.67 | 0.115916 | 210 | #00A8BC |
| 500 | 0.57 | 0.098638 | 210 | #008797 |
| 600 | 0.48 | 0.083096 | 210 | #006A77 |
| 700 | 0.40 | 0.069296 | 210 | #00515C |
| 800 | 0.32 | 0.055526 | 210 | #003A42 |
| 900 | 0.24 | 0.041833 | 210 | #00242A |
| 950 | 0.17 | 0.030051 | 210 | #001317 |

Role steps for meanings, both modes, follow `colorRamps.modes` in the token file. Light uses the dark step of the ramp for the foreground (success 800, warning 800, danger 700, info 800) on surface. Dark uses step 300 of that ramp on the dark surface, with on-color at step 950.

## Type faces used by every direction

| role | family | file | size on the hero | line-height |
| --- | --- | --- | --- | --- |
| Target Latin and tone marks | Andika | `assets/google_fonts/Andika-Regular.ttf` | 18px, or 22px in Courtyard | 1.5 |
| UI | Noto Sans | `assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf`, Medium, SemiBold | Title 22px / 1.25 SemiBold. Body 16px / 1.5. | 1.5 for body |
| Ethiopic | Noto Sans Ethiopic | `assets/fonts/lingafriq/NotoSansEthiopic-Regular.ttf` | 18px when that script is the target line | 1.5 |
| N'Ko | Noto Sans N'Ko | `assets/fonts/lingafriq/NotoSansNKo-Regular.ttf` | 18px when that script is the target line | 1.5 |
| Tifinagh | Noto Sans Tifinagh | `assets/fonts/lingafriq/NotoSansTifinagh-Regular.ttf` | 18px when that script is the target line | 1.5 |
| Adlam | Noto Sans Adlam | `assets/fonts/lingafriq/NotoSansAdlam-Regular.ttf` | 18px when that script is the target line | 1.5 |
| Vai | Noto Sans Vai | `assets/fonts/lingafriq/NotoSansVai-Regular.ttf` | 18px when that script is the target line | 1.5 |
| Bamum | Noto Sans Bamum | `assets/fonts/lingafriq/NotoSansBamum-Regular.ttf` | 18px when that script is the target line | 1.5 |
| Arabic | Noto Sans Arabic | `assets/fonts/lingafriq/NotoSansArabic-Regular.ttf` | 18px when that script is the target line | 1.5 |
| Osmanya | Noto Sans Osmanya | `assets/fonts/lingafriq/NotoSansOsmanya-Regular.ttf` | 18px when that script is the target line | 1.5 |

The Today line is Latin with tone marks, so the hero uses Andika for `Ẹ kú àárọ̀` and Noto Sans for the English. The other Noto files are the pairing for a target line in those scripts. They are not drawn on these six frames.

## Ink Lesson

id: ink-lesson

### Moodboard

A morning exercise book. The paper is the cool neutral already in the token file, hue 272.2352. One indigo action, the same hue, used once for Start. The page stays quiet so the greeting can be read. The only drawing is a small ring swatch under that greeting, a placement study for Yoruba adire on this one unit. Light is even. There is no sunset, no animal mascot, and no pattern field.

### Palette

Neutral and accent are the shipped ramps. Meaning ramps are the shared ramps above.

Neutral. Hue 272.2352. Requested chroma 0.012. No step is clamped.

| step | L | C | H | hex |
| --- | --- | --- | --- | --- |
| 50 | 0.97 | 0.012 | 272.2352 | #F2F5FE |
| 100 | 0.93 | 0.012 | 272.2352 | #E5E8F0 |
| 200 | 0.86 | 0.012 | 272.2352 | #CED1D9 |
| 300 | 0.77 | 0.012 | 272.2352 | #B1B4BC |
| 400 | 0.67 | 0.012 | 272.2352 | #92959D |
| 500 | 0.57 | 0.012 | 272.2352 | #75777F |
| 600 | 0.48 | 0.012 | 272.2352 | #5B5D65 |
| 700 | 0.40 | 0.012 | 272.2352 | #45474E |
| 800 | 0.32 | 0.012 | 272.2352 | #313339 |
| 900 | 0.24 | 0.012 | 272.2352 | #1D1F25 |
| 950 | 0.17 | 0.012 | 272.2352 | #0E0F15 |

Accent. Hue 272.2352. Requested chroma 0.16. Meaning: primary action. Clamped steps: 50, 100, 200, 300, 900, 950.

| step | L | C | H | hex |
| --- | --- | --- | --- | --- |
| 50 | 0.97 | 0.014092 | 272.2352 | #F2F5FF |
| 100 | 0.93 | 0.033386 | 272.2352 | #E0E7FF |
| 200 | 0.86 | 0.068652 | 272.2352 | #C1CFFF |
| 300 | 0.77 | 0.116923 | 272.2352 | #9AAFFF |
| 400 | 0.67 | 0.16 | 272.2352 | #748CF6 |
| 500 | 0.57 | 0.16 | 272.2352 | #596CD4 |
| 600 | 0.48 | 0.16 | 272.2352 | #4151B6 |
| 700 | 0.40 | 0.16 | 272.2352 | #2E389C |
| 800 | 0.32 | 0.16 | 272.2352 | #1D1F82 |
| 900 | 0.24 | 0.154811 | 272.2352 | #110066 |
| 950 | 0.17 | 0.110324 | 272.2352 | #07003E |

| mode | role | ramp | step | hex |
| --- | --- | --- | --- | --- |
| light | surface | neutral | 50 | #F2F5FE |
| light | surfaceContainer | neutral | 100 | #E5E8F0 |
| light | onSurface | neutral | 900 | #1D1F25 |
| light | onSurfaceVariant | neutral | 700 | #45474E |
| light | accent | accent | 700 | #2E389C |
| light | onAccent | accent | 50 | #F2F5FF |
| dark | surface | neutral | 800 | #313339 |
| dark | surfaceContainer | neutral | 700 | #45474E |
| dark | onSurface | neutral | 100 | #E5E8F0 |
| dark | onSurfaceVariant | neutral | 300 | #B1B4BC |
| dark | accent | accent | 300 | #9AAFFF |
| dark | onAccent | accent | 950 | #07003E |

An RGB invert of light surface `#F2F5FE` is `#0D0A01`. Dark surface is `#313339`.

Body pairs on these roles are above 4.5:1. Accent on surface is above 3:1 and is used only for the large Start control.

### Type pairing

Andika Regular at 18px, line-height 1.5, for `Ẹ kú àárọ̀`. Noto Sans SemiBold at 22px / 1.25 for Today. Noto Sans Regular at 16px / 1.5 for the plan lines and the pill. Noto Sans SemiBold at 16px for the row titles and for Start. Other scripts use the Noto files in the shared table, at 18px / 1.5, when the target line is in that script.

### Icon language

Open circles, 48px, a 2px stroke in onSurface, number in Noto Sans. The stroke is the shape. The circle is not filled. No emoji. Start is the only filled shape, and the fill is the accent.

### Illustration language

Flat geometry in one ink, the text color. The only drawing on Today is a 32px square under the greeting: four open rings in a two-by-two repeat. It is a placement study for a Yoruba adire commission on this unit. It is not a named cloth. No person is drawn. No landscape is drawn. The credit is in `ART_CREDITS.md`.

### Today heroes

| mode | file | pixels |
| --- | --- | --- |
| light | `docs/build/design/art/ink-lesson-today-light.png` | 390×509 |
| dark | `docs/build/design/art/ink-lesson-today-dark.png` | 390×509 |

The swatch is on the Next lesson row only.

### Sign-off

Pending. EXT-14 has not returned.

## Courtyard

id: courtyard

### Moodboard

Shade on warm plaster. The neutral ramp sits at hue 78, a low chroma, so the page reads as clay paper rather than yellow warning. The action is a well blue, hue 250, used once for Start. The cultural moment is the Yoruba line itself, set larger than the title. No cloth is drawn. Light is soft and even.

### Palette

Meaning ramps are the shared ramps above. Neutral and accent are particular to this direction.

Neutral. Hue 78. Requested chroma 0.02. No step is clamped.

| step | L | C | H | hex |
| --- | --- | --- | --- | --- |
| 50 | 0.97 | 0.02 | 78 | #FDF4E7 |
| 100 | 0.93 | 0.02 | 78 | #EFE7D9 |
| 200 | 0.86 | 0.02 | 78 | #D8D0C3 |
| 300 | 0.77 | 0.02 | 78 | #BBB3A6 |
| 400 | 0.67 | 0.02 | 78 | #9C9488 |
| 500 | 0.57 | 0.02 | 78 | #7E766A |
| 600 | 0.48 | 0.02 | 78 | #645C51 |
| 700 | 0.40 | 0.02 | 78 | #4E473C |
| 800 | 0.32 | 0.02 | 78 | #393227 |
| 900 | 0.24 | 0.02 | 78 | #251E14 |
| 950 | 0.17 | 0.02 | 78 | #140E06 |

Accent. Hue 250. Requested chroma 0.14. Meaning: primary action. Clamped steps: 50, 100, 200, 300, 600, 700, 800, 900, 950.

| step | L | C | H | hex |
| --- | --- | --- | --- | --- |
| 50 | 0.97 | 0.014757 | 250 | #EEF6FF |
| 100 | 0.93 | 0.034941 | 250 | #D7EAFF |
| 200 | 0.86 | 0.071770 | 250 | #AED5FF |
| 300 | 0.77 | 0.122050 | 250 | #75BAFF |
| 400 | 0.67 | 0.14 | 250 | #499AE7 |
| 500 | 0.57 | 0.14 | 250 | #277BC6 |
| 600 | 0.48 | 0.136022 | 250 | #0060A6 |
| 700 | 0.40 | 0.113445 | 250 | #004982 |
| 800 | 0.32 | 0.090926 | 250 | #00345F |
| 900 | 0.24 | 0.068552 | 250 | #00203E |
| 950 | 0.17 | 0.049358 | 250 | #001024 |

| mode | role | ramp | step | hex |
| --- | --- | --- | --- | --- |
| light | surface | neutral | 50 | #FDF4E7 |
| light | surfaceContainer | neutral | 100 | #EFE7D9 |
| light | onSurface | neutral | 900 | #251E14 |
| light | onSurfaceVariant | neutral | 700 | #4E473C |
| light | accent | accent | 700 | #004982 |
| light | onAccent | accent | 50 | #EEF6FF |
| dark | surface | neutral | 800 | #393227 |
| dark | surfaceContainer | neutral | 700 | #4E473C |
| dark | onSurface | neutral | 100 | #EFE7D9 |
| dark | onSurfaceVariant | neutral | 300 | #BBB3A6 |
| dark | accent | accent | 300 | #75BAFF |
| dark | onAccent | accent | 950 | #001024 |

An RGB invert of light surface `#FDF4E7` is `#020B18`. Dark surface is `#393227`.

Body pairs on these roles are above 4.5:1. Accent on surface is above 3:1 and is the Start control only.

### Type pairing

Andika Regular at 22px, line-height 1.5, for `Ẹ kú àárọ̀`. The spoken line is larger than the 18px floor and larger than the body. Noto Sans SemiBold at 22px / 1.25 for Today. Noto Sans Regular at 16px / 1.5 for the plan lines. Noto Sans SemiBold at 16px for row titles and Start. Other scripts use the shared Noto files at 18px / 1.5 when the target line is in that script.

### Icon language

Solid 48px tiles, radius 8, fill surfaceContainer, number in onSurface. The tile is a place marker. It carries no pattern. Start remains the only accent fill.

### Illustration language

When a later screen needs a picture, it is one everyday object in two flat fills, with no scene and no cloth. The Today heroes draw no picture. The Yoruba line is the image. No craft motif is on these frames. A later unit may carry one region mark when the tradition matches that unit, on one surface, with a credit line. That mark is not drawn here.

### Today heroes

| mode | file | pixels |
| --- | --- | --- |
| light | `docs/build/design/art/courtyard-today-light.png` | 390×475 |
| dark | `docs/build/design/art/courtyard-today-dark.png` | 390×475 |

### Sign-off

Pending. EXT-14 has not returned.

## Night Study

id: night-study

### Moodboard

A room after dusk, used for one more line. Neutrals are warm, hue 48, and the dark steps are the home of the direction. Light mode is the same warm ramp at the light steps, not a gray page with the colors flipped. The action is violet ink, hue 300, used once for Start. The drawing is the pitch contour over the greeting, in the text color.

### Palette

Meaning ramps are the shared ramps above. Neutral and accent are particular to this direction.

Neutral. Hue 48. Requested chroma 0.022. Step 50 is clamped to chroma 0.016253. Later steps hold 0.022.

| step | L | C | H | hex |
| --- | --- | --- | --- | --- |
| 50 | 0.97 | 0.016253 | 48 | #FFF2EC |
| 100 | 0.93 | 0.022 | 48 | #F5E4DB |
| 200 | 0.86 | 0.022 | 48 | #DECDC5 |
| 300 | 0.77 | 0.022 | 48 | #C1B0A8 |
| 400 | 0.67 | 0.022 | 48 | #A1928A |
| 500 | 0.57 | 0.022 | 48 | #83746C |
| 600 | 0.48 | 0.022 | 48 | #695A53 |
| 700 | 0.40 | 0.022 | 48 | #52443E |
| 800 | 0.32 | 0.022 | 48 | #3D3029 |
| 900 | 0.24 | 0.022 | 48 | #281C16 |
| 950 | 0.17 | 0.022 | 48 | #170C07 |

Accent. Hue 300. Requested chroma 0.14. Meaning: primary action. Clamped steps: 50, 100, 200, 300, 900, 950.

| step | L | C | H | hex |
| --- | --- | --- | --- | --- |
| 50 | 0.97 | 0.016602 | 300 | #F7F3FF |
| 100 | 0.93 | 0.039368 | 300 | #EBE3FF |
| 200 | 0.86 | 0.081082 | 300 | #D9C6FF |
| 300 | 0.77 | 0.138389 | 300 | #C29FFF |
| 400 | 0.67 | 0.14 | 300 | #A37FDE |
| 500 | 0.57 | 0.14 | 300 | #8561BD |
| 600 | 0.48 | 0.14 | 300 | #6B46A0 |
| 700 | 0.40 | 0.14 | 300 | #552F86 |
| 800 | 0.32 | 0.14 | 300 | #40166D |
| 900 | 0.24 | 0.128741 | 300 | #2B0051 |
| 950 | 0.17 | 0.091999 | 300 | #170030 |

| mode | role | ramp | step | hex |
| --- | --- | --- | --- | --- |
| light | surface | neutral | 50 | #FFF2EC |
| light | surfaceContainer | neutral | 100 | #F5E4DB |
| light | onSurface | neutral | 900 | #281C16 |
| light | onSurfaceVariant | neutral | 700 | #52443E |
| light | accent | accent | 700 | #552F86 |
| light | onAccent | accent | 50 | #F7F3FF |
| dark | surface | neutral | 800 | #3D3029 |
| dark | surfaceContainer | neutral | 700 | #52443E |
| dark | onSurface | neutral | 100 | #F5E4DB |
| dark | onSurfaceVariant | neutral | 300 | #C1B0A8 |
| dark | accent | accent | 300 | #C29FFF |
| dark | onAccent | accent | 950 | #170030 |

An RGB invert of light surface `#FFF2EC` is `#000D13`. Dark surface is `#3D3029`.

Body pairs on these roles are above 4.5:1. Accent on surface is above 3:1 and is the Start control only.

### Type pairing

Andika Regular at 18px, line-height 1.5, for `Ẹ kú àárọ̀`. Noto Sans SemiBold at 22px / 1.25 for Today. Noto Sans Medium at 16px / 1.5 for the plan lines, so the warm ground keeps a clear body. Noto Sans SemiBold at 16px for row titles and Start. Other scripts use the shared Noto files at 18px / 1.5 when the target line is in that script.

### Icon language

Filled 48px circles. The fill is onSurface. The number is the surface color, cut out of the fill. The circle reads on both the light and the dark steps. Start remains the only accent fill.

### Illustration language

The picture is the pitch contour: a 2px stroke in onSurface, no fill, 128 by 16, directly above the greeting. The path is `M4 8 L28 3 L52 13 L80 3 L124 13`. It is read from the tone marks on this line: `Ẹ` unmarked as mid, `kú` acute as high, `à` grave as low, `á` acute as high, `ọ̀` grave as low. It is an orthographic shape. It is not a recorded pitch, and it is not a validated audio track. The stroke is the text color, so removing a second color leaves the same shape (LP-05). No craft motif is drawn.

### Today heroes

| mode | file | pixels |
| --- | --- | --- |
| light | `docs/build/design/art/night-study-today-light.png` | 390×489 |
| dark | `docs/build/design/art/night-study-today-dark.png` | 390×489 |

### Sign-off

Pending. EXT-14 has not returned.

## Region marks for later units

These traditions are the sparing-use set from §3.4. They are not drawn on the six Today frames. A later screen may use one of them on one surface when the unit's region matches. The credit line has to name the tradition or the contracted artist. No person is named here. Sign-off stays Pending until EXT-14 returns.

| unit region | tradition eligible for that unit |
| --- | --- |
| Yoruba | adire resist-dye |
| Igbo | uli |
| nsibidi | a writing tradition, not a stripe fill |
| Akan | kente, one band on one surface |
| Bambara | bogolan, one square on one surface |
| Ndebele | one geometry panel on one surface |
| Ethiopian | tilf, one band on one surface |

The Today sample is the Yoruba row, so this table does not put kente, bogolan, Ndebele geometry, or tilf on these heroes.
