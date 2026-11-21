# P3-016 Tone Lens, Word Card, and the Lens camera

Status: Draft. No visual review is recorded. `docs/plan/CARD_STATUS.tsv` keeps P3-016 as Draft.

This is the screen spec for three surfaces:

- Tone Lens is the pitch contour above a target-language word.
- Word Card opens from a long-press on any target-language word.
- Lens is the camera. The modes are Point & Say, Live Translate, and Import Media.

Sources: `docs/source/ELEVATION.md` §3.4 (lines 835-839), §7.4 (lines 1445-1446), the unsure state at line 2078, §17.1 (lines 2213-2228), and §17.6 (lines 2343-2384). Tokens: `design/tokens/tokens.json` and `lib/design/typography.dart`. Target lines follow `lib/design/text/target_text.dart`: bundled Andika, at least 18 sp, leading 1.5.

These are token frames, not illustrated scenes. The frames draw the elevated Lens. They do not copy the current camera screen.

## Tokens

Colour is a color ramp role. The role names used here are `surface`, `surfaceContainer`, `onSurface`, `onSurfaceVariant`, `accent`, `onAccent`, `danger`, `onDanger`, `info`, and `onInfo`.

Light frames use `colorRamps.modes.light`. Dark frames use `colorRamps.modes.dark`. Text uses a `colorRamps.pairs` row whose level is `body` (4.5:1). `accent` on `surface` is the large pair only, so accent is never body-size text. Accent means the primary action, so each data frame has one filled accent control.

The legacy token `LingAfriqTokens.surface` is not the page background. The page background is the ramp role `surface`.

| Job | Token |
| --- | --- |
| Frame width | 390 px viewport |
| Page padding | `LingAfriqTokens.spacing16` |
| Tight gap | `LingAfriqTokens.spacing4` |
| Row gap | `LingAfriqTokens.spacing8` |
| Stack gap | `LingAfriqTokens.spacing12` |
| Section gap | `LingAfriqTokens.spacing16` |
| Block gap | `LingAfriqTokens.spacing24` |
| Minimum control | `LingAfriqTokens.spacing48` wide and tall |
| Contour box | height `LingAfriqTokens.spacing48`, inset `LingAfriqTokens.spacing8` |
| Contour dash | dash `LingAfriqTokens.spacing16`, gap `LingAfriqTokens.spacing8` |
| Card radius | `LingAfriqTokens.radiusmd` |
| Pill radius | `LingAfriqTokens.radiuspill` |
| Strong stroke | `LingAfriqTokens.strokeregular` |
| Display | `type.display`: family `LingAfriqType.displayFamily`, size `type.display.size`, height `type.display.height` |
| Body | `type.body`: family `LingAfriqType.bodyFamily`, size `LingAfriqType.bodySize`, height `LingAfriqType.targetHeight` |
| Target language | `LingAfriqType.target`: family Andika (`LingAfriqType.targetFamily`), size `LingAfriqType.targetSize`, height `LingAfriqType.targetHeight` |

Body and display sit on the real bundled files: `LingAfriqText` (Noto Sans) and `LingAfriqDisplay` (Nunito). Target-language lines sit on bundled Andika. Weight stays the loaded face. Do not invent a second family.

The example word is `Ẹ kú àárọ̀`. Its meaning on these frames is Good morning. The Lens object is `ọ̀gẹ̀dẹ̀`. Its meaning on these frames is Plantain. Diacritics stay inside the line box. Nothing clips them.

Product motion tokens (`motion.product` instant, fast, base, slow, and `motion.rare`) are not run on these frames. Reduced motion is the platform flag `MediaQuery.disableAnimations`. The frame does not add animation of its own.

## Shared rules

- Width is 390 px. Content scrolls on a phone. The exported image is the full column at 390 px so glyphs are not cut off in the evidence.
- Every control is at least `LingAfriqTokens.spacing48` in both axes and has a visible label. A painted mark also has a semantics label written in this spec.
- Text uses a body pair from `colorRamps.pairs`. Meaning is never colour alone. Selected has a check and the word On. Error has a cross. Offline has an info mark. Unsure has a broken line and the word Unsure. The mark is drawn, not a font icon.
- Copy is short, grade-7 English. It makes no boastful claim. It uses a period or a comma in place of a long dash. The frames show no score, no percent, and no confidence number.
- At 200% text, `TextScaler.linear(2)` doubles `type.display`, `type.body`, and `LingAfriqType.target`. Padding, radius, stroke, and contour boxes stay on the token scale. Controls grow with the label and stay at least `LingAfriqTokens.spacing48`. Lines wrap inside the 390 px width. No glyph is clipped.

## Contour shapes

Every contour uses one stroke. The stroke role is `onSurface`. The stroke width is `LingAfriqTokens.strokeregular`. The box is `LingAfriqTokens.spacing48` tall and the full content width. The line sits `LingAfriqTokens.spacing8` in from the box edges. Caps are round.

Colour is optional. These frames do not use it. The same stroke role is on every contour, so the shapes still differ when the colour is removed. Greyscale keeps them distinct because the line sits in a different place.

The contour is not a button.

| Name | Shape | Sample above the word |
| --- | --- | --- |
| High | A level line along the top inset. | `kú` |
| Mid | A level line through the centre. | `Ẹ` |
| Low | A level line along the bottom inset. | `rọ̀` |
| Rising | A straight line from the bottom-left inset to the top-right inset. | `àá` |
| Falling | A straight line from the top-left inset to the bottom-right inset. | `áà` |
| Downstep | A level line on the left half at the top inset, a vertical drop at the midpoint, then a level line on the right half at the bottom inset. | `bá bá` |

Downstep is a step, not a slope. The sample `bá bá` uses the same high mark twice. The step in the line is the cue.

The greeting contour is the tone of `Ẹ kú àárọ̀`, left to right, in one box. Four equal parts, gap `LingAfriqTokens.spacing4`.

1. Mid, a level line through the centre, for `Ẹ`.
2. High, a level line along the top inset, for `kú`.
3. Rising, from the bottom inset to the top inset, for `àá`.
4. Low, a level line along the bottom inset, for `rọ̀`.

The unsure mark is a broken level line through the centre. Each dash is `LingAfriqTokens.spacing16`. Each gap is `LingAfriqTokens.spacing8`. The gaps keep it distinct from the solid mid line. It is not a meter.

## Tone Lens

Tone Lens shows the six contours, then the example word, then a pronunciation check that is unsure. The check is sample data. It is not a measured score.

### tone-light.png

Roles: `colorRamps.modes.light`. Background role `surface`. Padding `LingAfriqTokens.spacing16`. Column, top aligned.

1. Title `Tone Lens`. Display style. Role `onSurface`.
2. Gap `LingAfriqTokens.spacing8`. Line `Shape shows the tone. Colour is optional.` Body style. Role `onSurfaceVariant`.
3. Gap `LingAfriqTokens.spacing16`. Six blocks. Gap between blocks: `LingAfriqTokens.spacing12`. A block is fill `surfaceContainer`, radius `LingAfriqTokens.radiusmd`, padding `LingAfriqTokens.spacing12`. Inside, top to bottom: the name in body, role `onSurface`, gap `LingAfriqTokens.spacing4`, the contour, gap `LingAfriqTokens.spacing4`, the sample in `LingAfriqType.target`, role `onSurface`. The contour sits above that sample. The block keeps the line with its word.
   - High. Sample `kú`. Semantics label: `High tone, kú`.
   - Mid. Sample `Ẹ`. Semantics label: `Mid tone, Ẹ`.
   - Low. Sample `rọ̀`. Semantics label: `Low tone, rọ̀`.
   - Rising. Sample `àá`. Semantics label: `Rising tone, àá`.
   - Falling. Sample `áà`. Semantics label: `Falling tone, áà`.
   - Downstep. Sample `bá bá`. Semantics label: `Downstep tone, bá bá`.
4. Gap `LingAfriqTokens.spacing24`. One more block, same fill, radius, and padding.
   - Label `This word`. Body, `onSurface`.
   - Gap `LingAfriqTokens.spacing4`. The greeting contour.
   - Gap `LingAfriqTokens.spacing4`. `Ẹ kú àárọ̀` in `LingAfriqType.target`, role `onSurface`.
   - Semantics label: `Tone on Ẹ kú àárọ̀. Mid, then high, then rising, then low.`
   - Gap `LingAfriqTokens.spacing4` under the block. Line `Mid, then high, then rising, then low.` Body, `onSurfaceVariant` on `surface`.
5. Gap `LingAfriqTokens.spacing24`. Pill `Sample`. Fill role `surfaceContainer`. Text role `onSurface`. Body style. Radius `LingAfriqTokens.radiuspill`. Padding horizontal `LingAfriqTokens.spacing16`, vertical `LingAfriqTokens.spacing8`. Minimum height `LingAfriqTokens.spacing48`. This is text, not a button. Semantics label: `Sample data`.
6. Gap `LingAfriqTokens.spacing12`. The unsure mark. Semantics label: `Unsure. This is sample data.`
7. Gap `LingAfriqTokens.spacing12`. Word `Unsure`. Body, `onSurface`.
8. Gap `LingAfriqTokens.spacing4`. Line `This is sample data.` Body, `onSurfaceVariant`.
9. Gap `LingAfriqTokens.spacing4`. Line `The check is unsure.` Body, `onSurfaceVariant`.
10. Gap `LingAfriqTokens.spacing4`. Line `Say the word again in a quiet place.` Body, `onSurfaceVariant`.
11. Gap `LingAfriqTokens.spacing24`. Button visible label `Try again`. Fill `accent`. Text `onAccent`. Body style. Radius `LingAfriqTokens.radiusmd`. Padding horizontal `LingAfriqTokens.spacing16`, vertical `LingAfriqTokens.spacing12`. Minimum `LingAfriqTokens.spacing48`. Full content width. Semantics label: `Try the word again`.

`Try again` is the only filled accent button. The block shows no number. It does not overlay a learner contour on a native contour. When the check is unsure, the frame says so and asks for another try.

### tone-dark.png

Same layout, copy, type, and spacing as `tone-light.png`. Roles come from `colorRamps.modes.dark`.

### tone-200.png

Same as `tone-light.png` at 200% text. `Ẹ kú àárọ̀` and the six samples stay fully visible. The names wrap inside 390 px. `Try again` stays at least `LingAfriqTokens.spacing48`.

### Tone Lens state frames

Same page padding, type, and role pairs. Dark uses `colorRamps.modes.dark` with the same layout.

**tone-skeleton.png.** Visible word `Loading` in body, role `onSurfaceVariant`. Semantics label: `Loading Tone Lens`. Under it, eight full-width blocks, fill `surfaceContainer`, radius `LingAfriqTokens.radiusmd`, gap `LingAfriqTokens.spacing12`. Heights, in order: six times `LingAfriqTokens.spacing48`, then `LingAfriqTokens.spacing32`, then `LingAfriqTokens.spacing48`. No shimmer.

**tone-empty.png.** Title `Tone Lens`, display, `onSurface`. Then:

- `No word yet` in body, `onSurface`.
- Label `What happened`. Body, `onSurface`. Line `There is no word to mark.` Body, `onSurfaceVariant`.
- Label `Why`. Line `Tone Lens needs a target-language word.`
- Label `What to do`. Line `Long-press a word.`
- Button `Show a word`. Fill `accent`, text `onAccent`. Semantics label: `Show a word`.

Section gap `LingAfriqTokens.spacing16`.

**tone-error.png.** Title `Tone Lens`. Cue disc fill `danger`, cross in `onDanger`, minimum `LingAfriqTokens.spacing48`. Title line `Tone Lens did not load` in body, role `danger` (the body pair `danger` on `surface`).

- `What happened`. `The tone shapes did not open.`
- `Why`. `This word has no saved tone on the phone.`
- `What to do`. `Try again.`
- Button `Try again`. Fill `accent`, text `onAccent`. Semantics label: `Try again`.

**tone-offline.png.** Cue disc fill `info`, info mark in `onInfo`. Title line `You are offline` in body, role `info`.

- `What happened`. `The phone has no network.`
- `Why`. `The tone for this word is not saved on the phone.`
- `What to do`. `Connect, then try again.`
- Button `Try again`. Fill `accent`, text `onAccent`. Semantics label: `Try again`.

**tone-reduced.png.** The resting Tone Lens. Same pixels as `tone-light.png`. Reduced motion adds no animation, so the still matches the light data frame. `MediaQuery.disableAnimations` is on. The contour does not draw on. No product motion runs.

## Word Card

The Word Card opens from a long-press on any target-language word. The frame is that card. It shows the word, the meaning, play audio, the Tone Lens, one example, Save, and Practise.

`Practise` is the only filled accent button. Save, Play audio, and Close use `surfaceContainer` and `onSurface`.

### wordcard-light.png

Roles: `colorRamps.modes.light`. Background `surface`. Padding `LingAfriqTokens.spacing16`.

1. Button visible `Close`. Fill `surfaceContainer`, text `onSurface`, radius `LingAfriqTokens.radiusmd`, padding `LingAfriqTokens.spacing12`, minimum `LingAfriqTokens.spacing48`. Semantics `Close the word card`. Aligned to the start. Not accent.
2. Gap `LingAfriqTokens.spacing12`. Title `Word Card`. Display, `onSurface`.
3. Gap `LingAfriqTokens.spacing8`. Line `Opened by a long press.` Body, `onSurfaceVariant`.
4. Gap `LingAfriqTokens.spacing16`. Label `Tone Lens`. Body, `onSurface`.
5. Gap `LingAfriqTokens.spacing4`. The greeting contour. It sits above the word.
6. Gap `LingAfriqTokens.spacing4`. `Ẹ kú àárọ̀` in `LingAfriqType.target`, `onSurface`.
7. Gap `LingAfriqTokens.spacing4`. Line `Mid, then high, then rising, then low.` Body, `onSurfaceVariant`. Semantics `Tone Lens for Ẹ kú àárọ̀`.
8. Gap `LingAfriqTokens.spacing16`. Label `Meaning`. Body, `onSurface`.
9. Gap `LingAfriqTokens.spacing4`. Line `Good morning.` Body, `onSurfaceVariant`.
10. Gap `LingAfriqTokens.spacing16`. Button visible `Play audio`. Fill `surfaceContainer`, text `onSurface`, radius `LingAfriqTokens.radiusmd`, minimum `LingAfriqTokens.spacing48`. Full content width. Semantics `Play Ẹ kú àárọ̀`.
11. Gap `LingAfriqTokens.spacing16`. Label `Example`. Body, `onSurface`.
12. Gap `LingAfriqTokens.spacing4`. `Ẹ kú àárọ̀` in `LingAfriqType.target`, `onSurface`.
13. Gap `LingAfriqTokens.spacing4`. Line `You say this in the morning.` Body, `onSurfaceVariant`.
14. Gap `LingAfriqTokens.spacing24`. Button visible `Save`. Fill `surfaceContainer`, text `onSurface`. Semantics `Save this word`.
15. Gap `LingAfriqTokens.spacing8`. Button visible `Practise`. Fill `accent`, text `onAccent`. Semantics `Practise this word`.

Play audio is one control with a visible label. The card on this frame does not add a second speaker or a dialect chip.

### wordcard-dark.png

Same layout and copy. Roles: `colorRamps.modes.dark`.

### wordcard-200.png

Same as `wordcard-light.png` at 200% text. `Ẹ kú àárọ̀` stays fully visible. `Play audio`, `Save`, and `Practise` stay at least `LingAfriqTokens.spacing48` and grow with the label. Lines wrap inside 390 px.

### Word Card state frames

**wordcard-skeleton.png.** Word `Loading`, body, `onSurfaceVariant`. Semantics `Loading the word card`. Blocks, fill `surfaceContainer`, radius `LingAfriqTokens.radiusmd`, gap `LingAfriqTokens.spacing12`. Heights, in order: `LingAfriqTokens.spacing32`, `LingAfriqTokens.spacing48`, `LingAfriqTokens.spacing32`, `LingAfriqTokens.spacing48`, `LingAfriqTokens.spacing48`, `LingAfriqTokens.spacing32`, `LingAfriqTokens.spacing48`, `LingAfriqTokens.spacing48`. No shimmer.

**wordcard-empty.png.** Title `Word Card`. `No word yet`.

- `What happened`. `No word is open.`
- `Why`. `A long press has not chosen a word.`
- `What to do`. `Long-press a target-language word.`
- Button `Show a word`, accent / `onAccent`. Semantics `Show a word`.

**wordcard-error.png.** Title `Word Card`. Danger disc with a cross. `Word Card did not open` in role `danger`.

- `What happened`. `The card did not load.`
- `Why`. `The meaning did not come back.`
- `What to do`. `Try again.`
- Button `Try again`. Semantics `Try again`.

**wordcard-offline.png.** Info disc. `You are offline` in role `info`.

- `What happened`. `The phone has no network.`
- `Why`. `This word is not saved on the phone.`
- `What to do`. `Connect, then try again.`
- Button `Try again`. Semantics `Try again`.

**wordcard-reduced.png.** Same pixels as `wordcard-light.png`. Reduced motion adds no animation, so the still matches the light data frame. `MediaQuery.disableAnimations` is on.

## Lens camera

Lens is the camera in the top bar. This frame is Point & Say, with the other two modes visible as labelled controls. Point & Say turns one object into a word with tones. The word is `ọ̀gẹ̀dẹ̀`, meaning Plantain. The tone is low, so the contour is the low line. The frame does not show a raw English detector label. It does not show a model score.

The photo is checked, then deleted. The line on the frame states that rule. It is not a boast.

Live Translate reads a sign or speech into the target language. Import Media picks a photo or a clip, uses it for the check, then deletes it. Those two modes are labelled on this frame. Their results are not separate exports. Neither mode shows a score.

`Say it` is the only filled accent button.

### lens-light.png

Roles: `colorRamps.modes.light`. Background `surface`. Padding `LingAfriqTokens.spacing16`.

1. Button visible `Close`. Fill `surfaceContainer`, text `onSurface`, radius `LingAfriqTokens.radiusmd`, padding `LingAfriqTokens.spacing12`, minimum `LingAfriqTokens.spacing48`. Semantics `Close the lens`. Aligned to the start. Not accent.
2. Gap `LingAfriqTokens.spacing12`. Title `Lens`. Display, `onSurface`.
3. Gap `LingAfriqTokens.spacing8`. Line `Point at one thing.` Body, `onSurfaceVariant`.
4. Gap `LingAfriqTokens.spacing16`. Three full-width buttons, gap `LingAfriqTokens.spacing8`, radius `LingAfriqTokens.radiusmd`, minimum `LingAfriqTokens.spacing48`, padding `LingAfriqTokens.spacing12`.
   - `Point & Say`. Fill `surfaceContainer`, text `onSurface`. Stroke `LingAfriqTokens.strokeregular` in `onSurface`. A check in `onSurface`, size `LingAfriqTokens.spacing24`. The word `On` in body, `onSurface`, under the name. Semantics `Point and Say, on`.
   - `Live Translate`. Fill `surfaceContainer`, text `onSurface`. No stroke. Semantics `Live Translate`.
   - `Import Media`. Fill `surfaceContainer`, text `onSurface`. No stroke. Semantics `Import Media`.
5. Gap `LingAfriqTokens.spacing16`. Viewfinder. Fill `surfaceContainer`, radius `LingAfriqTokens.radiusmd`, padding `LingAfriqTokens.spacing16`. Inside it, a box with stroke `LingAfriqTokens.strokeregular` in `onSurface`, radius `LingAfriqTokens.radiusmd`, padding `LingAfriqTokens.spacing12`.
   - The low contour.
   - Gap `LingAfriqTokens.spacing4`. Word `Low`. Body, `onSurface`.
   - Gap `LingAfriqTokens.spacing4`. `ọ̀gẹ̀dẹ̀` in `LingAfriqType.target`, `onSurface`.
   - Gap `LingAfriqTokens.spacing4`. Line `Plantain.` Body, `onSurface`.
   - Semantics `Low tone on ọ̀gẹ̀dẹ̀. Plantain.`
6. Gap `LingAfriqTokens.spacing12`. Line `The photo is checked, then deleted.` Body, `onSurfaceVariant`.
7. Gap `LingAfriqTokens.spacing24`. Button `Say it`. Fill `accent`, text `onAccent`. Semantics `Say ọ̀gẹ̀dẹ̀`.
8. Gap `LingAfriqTokens.spacing8`. Button `Open word`. Fill `surfaceContainer`, text `onSurface`. Semantics `Open the word card for ọ̀gẹ̀dẹ̀`.

The recognition box does not move on this still. Open word opens the Word Card for `ọ̀gẹ̀dẹ̀`.

### lens-dark.png

Same layout and copy. Roles: `colorRamps.modes.dark`.

### lens-200.png

Same as `lens-light.png` at 200% text. `ọ̀gẹ̀dẹ̀` stays fully visible. The three mode labels stay visible and wrap inside 390 px. Each control stays at least `LingAfriqTokens.spacing48`.

### Lens state frames

**lens-skeleton.png.** Word `Loading`, body, `onSurfaceVariant`. Semantics `Loading the lens`. Blocks, fill `surfaceContainer`, radius `LingAfriqTokens.radiusmd`, gap `LingAfriqTokens.spacing12`. Heights, in order: `LingAfriqTokens.spacing48`, `LingAfriqTokens.spacing48`, `LingAfriqTokens.spacing48`, `LingAfriqTokens.spacing64`, `LingAfriqTokens.spacing48`. No shimmer.

**lens-empty.png.** Title `Lens`. `Nothing in view`.

- `What happened`. `The camera sees no object.`
- `Why`. `Nothing is close enough to name.`
- `What to do`. `Point at one thing, or use Import Media.`
- Button `Point again`, accent / `onAccent`. Semantics `Point the camera again`.

**lens-error.png.** Title `Lens`. Danger disc with a cross. `The camera did not name it` in role `danger`.

- `What happened`. `No word came back.`
- `Why`. `The picture was too dark to read.`
- `What to do`. `Add light, then try again.`
- Button `Try again`. Semantics `Try again`.

This frame does not show a model score or a percent.

**lens-offline.png.** Info disc. `You are offline` in role `info`.

- `What happened`. `The phone has no network.`
- `Why`. `This object is not in the offline pack.`
- `What to do`. `Connect, then point again.`
- Button `Try again`. Semantics `Try again`.

**lens-reduced.png.** Same pixels as `lens-light.png`. The recognition box does not move. Reduced motion adds no animation, so the still matches the light data frame. `MediaQuery.disableAnimations` is on.

## Accessibility

- Minimum control size is `LingAfriqTokens.spacing48`.
- Every control in this spec has a visible label and a semantics label. Painted cues (check, cross, info mark, contour, broken line) sit beside words.
- Body text uses a `colorRamps.pairs` row whose level is `body` (4.5:1). The pairs used are `onSurface` on `surface`, `onSurface` on `surfaceContainer`, `onSurfaceVariant` on `surface`, `onAccent` on `accent`, `onDanger` on `danger`, `danger` on `surface`, `onInfo` on `info`, and `info` on `surface`.
- Target lines use `LingAfriqType.target`. The line box uses that leading so the tone marks stay visible.
- 200% text wraps. It does not clip.
- Reduced motion runs no extra animation. Duration is not taken from `motion.product` or `motion.rare`. The reduced-motion still matches the light data frame.

## Card report

Frames are painted by `test/design/tone_wordcard_lens_frames_test.dart`. The test loads ramp roles from `design/tokens/tokens.json`, spacing and radius from `LingAfriqTokens`, and type from `LingAfriqType`. It loads bundled Andika, `LingAfriqText`, and `LingAfriqDisplay`, and paints at 390 px. The PNG files are the only images that test compares. Updating them does not touch any other golden.

The test also paints the six contours in one stroke colour and checks that their greyscale pictures differ.

| Acceptance | Result |
| --- | --- |
| AC1. H, M, L, rising, falling, and downstep are distinct in greyscale, and colour is optional. | Met. The shape table uses one `onSurface` stroke. The test checks the six greyscale pictures differ. |
| AC2. Pronunciation feedback includes an unsure state, labelled as sample data, with no invented precision number. | Met. `tone-light.png` shows `Sample`, `Unsure`, and `This is sample data.` It shows no number. |
| AC3. The Word Card opens from a long-press on any word, and the Lens shows Point & Say, Live Translate, and Import Media. | Met. `wordcard-light.png` says it opened by a long press. `lens-light.png` labels the three modes. |
| AC4. Light and dark frames at 390 px, and a 200% text frame, exported under `docs/build/design/screens/`. | Met when the PNG files from the test exist and are 390 px wide. |
| AC5. Every colour, size, font, and radius references a token. None is hard-coded. | Met in this spec. No hex values. Sizes and radii cite `LingAfriqTokens` or `type.*`. Fonts cite `LingAfriqType`. Colours cite ramp roles. |
| AC6. Skeleton, empty, error, offline, and reduced-motion frames are included. | Met when those PNG files exist. Each surface has them, named in the sections above. |
| AC7. A T4 reviewer records visual approval in the card report. | Unmet. The frames are ready to check. No T4 approval is recorded. |

`docs/plan/CARD_STATUS.tsv` stays `Draft` because AC7 is unmet.

On purpose, this spec does not draw dialect chips, a second speaker, Live Translate results, Import Media results, or the elevation states for AI unavailable and content under review. Those are outside the frames this card asked to export.

Exported files:

- `docs/build/design/screens/tone-light.png`
- `docs/build/design/screens/tone-dark.png`
- `docs/build/design/screens/tone-200.png`
- `docs/build/design/screens/tone-skeleton.png`
- `docs/build/design/screens/tone-empty.png`
- `docs/build/design/screens/tone-error.png`
- `docs/build/design/screens/tone-offline.png`
- `docs/build/design/screens/tone-reduced.png`
- `docs/build/design/screens/wordcard-light.png`
- `docs/build/design/screens/wordcard-dark.png`
- `docs/build/design/screens/wordcard-200.png`
- `docs/build/design/screens/wordcard-skeleton.png`
- `docs/build/design/screens/wordcard-empty.png`
- `docs/build/design/screens/wordcard-error.png`
- `docs/build/design/screens/wordcard-offline.png`
- `docs/build/design/screens/wordcard-reduced.png`
- `docs/build/design/screens/lens-light.png`
- `docs/build/design/screens/lens-dark.png`
- `docs/build/design/screens/lens-200.png`
- `docs/build/design/screens/lens-skeleton.png`
- `docs/build/design/screens/lens-empty.png`
- `docs/build/design/screens/lens-error.png`
- `docs/build/design/screens/lens-offline.png`
- `docs/build/design/screens/lens-reduced.png`
