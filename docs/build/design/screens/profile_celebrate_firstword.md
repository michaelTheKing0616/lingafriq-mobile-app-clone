# P3-018 Profile, the wardrobe, celebrations, and the first spoken word

Status: Draft. A visual reviewer has not approved the frames. `docs/plan/CARD_STATUS.tsv` keeps P3-018 at Draft.

## Visual review

Not recorded. The frames are ready to check. No approval is written here.

This is the screen spec for five surfaces:

- Profile, reached as Me.
- The avatar wardrobe, opened from the Wardrobe row.
- The onboarding first spoken word.
- Level up, a rare celebration.
- Lesson complete, a rare celebration.

Sources: `docs/source/ELEVATION.md` §3.3 (lines 814-819), §5.2 (lines 1038-1060), and §3.4 (lines 848-849). Tokens: `design/tokens/tokens.json`. Type: `lib/design/typography.dart` and `lib/design/text/target_text.dart`. The greeting contour is the one already drawn in `docs/build/design/screens/tone_wordcard_lens.md`. This spec does not draw the six teaching contours.

These are token frames, not illustrated scenes. No portrait is drawn.

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
| Mark box | `LingAfriqTokens.spacing24` |
| Celebration box | `LingAfriqTokens.spacing64` |
| Card radius | `LingAfriqTokens.radiusmd` |
| Pill radius | `LingAfriqTokens.radiuspill` |
| Hairline | `LingAfriqTokens.strokehairline` |
| Strong stroke | `LingAfriqTokens.strokeregular` |
| Display | `type.display`: family `LingAfriqType.displayFamily`, size `type.display.size`, height `type.display.height` |
| Body | `type.body`: family `LingAfriqType.bodyFamily`, size `LingAfriqType.bodySize`, height `LingAfriqType.targetHeight` |
| Target language | `LingAfriqType.target`: family Andika (`LingAfriqType.targetFamily`), size `LingAfriqType.targetSize`, height `LingAfriqType.targetHeight` |
| Level up duration | `motion.rare.durationMs.levelUp`, exposed as `LingAfriqTokens.motionRareLevelUp` |
| Lesson complete duration | `motion.rare.durationMs.lessonComplete`, exposed as `LingAfriqTokens.motionRareLessonComplete` |
| Celebration easing | `motion.rare.easing`, exposed as `LingAfriqTokens.motionRareEasing` |

Body and display sit on the real bundled files: `LingAfriqText` (Noto Sans) and `LingAfriqDisplay` (Nunito). Target-language lines sit on bundled Andika. Weight stays the loaded face. Do not invent a second family.

`motion.rare.allowedUses` lists `lesson-complete` and `level-up`. Those are the only celebrations on this spec. Profile, the wardrobe, and the first spoken word do not run `motion.product` or `motion.rare`. This spec cites the duration tokens. It does not write the duration as a number.

The example target line is `Ẹ kú àárọ̀`. Its gloss is Good morning. Diacritics stay inside the line box. Nothing clips them.

## Shared rules

- Width is 390 px. Content scrolls on a phone. The exported image is the full column at 390 px so glyphs are not cut off in the evidence.
- Every control is at least `LingAfriqTokens.spacing48` in both axes and has a visible label. A painted mark also has a semantics label written in this spec.
- Text inside a `surfaceContainer` control uses `onSurface`, because that is the body pair on `surfaceContainer`. `onSurfaceVariant` is used only on the page role `surface`.
- Text uses a body pair from `colorRamps.pairs`. Meaning is never colour alone. A chosen look has a check and the word On. Error has a cross and the word danger names. Offline has an info mark and words. The rare frame has the word Rare. Sample feedback has the word Sample. The mark is drawn, not a font icon.
- Copy is short, grade-7 English. It makes no boastful claim. It uses a period or a comma in place of a long dash. The frames show no score, no percent, no XP, no league rank, and no confidence number.
- At 200% text, `TextScaler.linear(2)` doubles `type.display`, `type.body`, and `LingAfriqType.target`. Padding, radius, stroke, contour boxes, and the celebration box stay on the token scale. Controls grow with the label and stay at least `LingAfriqTokens.spacing48`. Lines wrap inside the 390 px width. No glyph is clipped.
- A quiet control is fill `surfaceContainer`, text `onSurface`, radius `LingAfriqTokens.radiusmd`, padding horizontal `LingAfriqTokens.spacing16` and vertical `LingAfriqTokens.spacing12`, minimum `LingAfriqTokens.spacing48`, full content width. It is not accent.
- A filled accent control uses the same padding, radius, and minimum size. Fill `accent`. Text `onAccent`. Body style.
- A note pill is text, not a button. Fill `surfaceContainer`. Text `onSurface`. Body style. Radius `LingAfriqTokens.radiuspill`. Padding horizontal `LingAfriqTokens.spacing16`, vertical `LingAfriqTokens.spacing8`. Minimum height and width `LingAfriqTokens.spacing48`.
- A disc is a circle. Its box is at least `LingAfriqTokens.spacing48` wide and tall. Padding inside the disc is `LingAfriqTokens.spacing8`. The mark inside is `LingAfriqTokens.spacing24`. Stroke width is `LingAfriqTokens.strokeregular`.

## Greeting contour

The Tone Lens greeting contour is reused from `docs/build/design/screens/tone_wordcard_lens.md`. This spec does not draw high, mid, low, rising, falling, and downstep as six teaching rows.

The contour uses one stroke. The stroke role is `onSurface`. The stroke width is `LingAfriqTokens.strokeregular`. The box is `LingAfriqTokens.spacing48` tall and the full content width. The line sits `LingAfriqTokens.spacing8` in from the box edges. Caps are round. The contour is not a button.

The greeting contour is the tone of `Ẹ kú àárọ̀`, left to right, in one box. Four equal parts, gap `LingAfriqTokens.spacing4`.

1. Mid, a level line through the centre, for `Ẹ`.
2. High, a level line along the top inset, for `kú`.
3. Rising, from the bottom inset to the top inset, for `àá`.
4. Low, a level line along the bottom inset, for `rọ̀`.

Semantics label: `Tone on Ẹ kú àárọ̀. Mid, then high, then rising, then low.`

## Celebration mark

The mark stands for the celebration. It is strokes in a box. It is not a font icon. The box is `LingAfriqTokens.spacing64` wide and tall. The stroke role is `onSurface`. The stroke width is `LingAfriqTokens.strokeregular`. Caps are round. The ring sits `LingAfriqTokens.spacing8` in from the box edge. The mark is not a button.

Mid travel, on the rare-motion frame:

- An open arc starts at the top of the ring and runs three quarters of a turn. It does not close.
- Four short rays run from the centre toward the top, the right, the bottom, and the left. Each ray stops halfway to the ring.
- Semantics label: `Celebration mark. Mid travel.`

End state, on the reduced-motion frame:

- A closed ring.
- Four rays run outward from the ring toward the top, the right, the bottom, and the left. They stop `LingAfriqTokens.spacing4` in from the box edge.
- Semantics label: `Celebration mark. End state.`

The two pictures are not the same pixels. Reduced motion keeps this end state. The celebration is gentler, and it is not removed. The frame is not blank.

Level up runs for `LingAfriqTokens.motionRareLevelUp` (`motion.rare.durationMs.levelUp`). Lesson complete runs for `LingAfriqTokens.motionRareLessonComplete` (`motion.rare.durationMs.lessonComplete`). Both use `LingAfriqTokens.motionRareEasing` (`motion.rare.easing`).

## Profile

Profile is the Me surface from §3.3. The rows, in order, are Wardrobe, Progress, Achievements, Settings, and All features. Wardrobe is a quiet row. Its visible label is `Wardrobe`. Its semantics label is `Open wardrobe`.

Avatar creation is optional. The line is `Avatar can wait until after lesson 2.` The quiet control is `Skip for now`. Semantics label: `Skip avatar for now`.

Progress is words. The line is `Morning greetings.` It is not a bar. It shows no number.

`All features` is the only filled accent button. Semantics label: `Open all features`.

### profile-light.png

Roles: `colorRamps.modes.light`. Background role `surface`. Padding `LingAfriqTokens.spacing16`. Column, top aligned.

1. Title `Me`. Display style. Role `onSurface`.
2. Gap `LingAfriqTokens.spacing8`. Line `Your profile.` Body style. Role `onSurfaceVariant`.
3. Gap `LingAfriqTokens.spacing4`. Line `Avatar can wait until after lesson 2.` Body, role `onSurfaceVariant`.
4. Gap `LingAfriqTokens.spacing16`. Button `Skip for now`. Quiet. Semantics `Skip avatar for now`.
5. Gap `LingAfriqTokens.spacing16`. Quiet rows. Gap between rows: `LingAfriqTokens.spacing12`. Name in body, role `onSurface`. Line in body, role `onSurface`, because the row fill is `surfaceContainer`.
   - `Wardrobe`. Line `Pick a look later.` Semantics `Open wardrobe`.
   - `Progress`. Line `Morning greetings.` Semantics `Open progress`.
   - `Achievements`. Line `You said a greeting.` Semantics `Open achievements`.
   - `Settings`. Line `Sound and text.` Semantics `Open settings`.
6. Gap `LingAfriqTokens.spacing24`. Button `All features`. Fill `accent`. Text `onAccent`. Semantics `Open all features`.

`All features` is the only filled accent button. No portrait is drawn.

### profile-dark.png

Same layout, copy, type, and spacing as `profile-light.png`. Roles come from `colorRamps.modes.dark`.

### profile-200.png

Same as `profile-light.png` at 200% text. The rows wrap inside 390 px. `Skip for now` and `All features` stay at least `LingAfriqTokens.spacing48`. `All features` stays the only filled accent button.

### Profile state frames

Same page padding, type, and role pairs. These frames use light roles.

**profile-skeleton.png.** Visible word `Loading` in body, role `onSurfaceVariant`. Semantics label: `Loading the profile`. Under it, one block of height `LingAfriqTokens.spacing32`, then six blocks of height `LingAfriqTokens.spacing48`. Fill `surfaceContainer`. Radius `LingAfriqTokens.radiusmd`. Gap `LingAfriqTokens.spacing12`. No shimmer.

**profile-empty.png.** Title `Me`, display, `onSurface`. Then:

- `No profile yet` in body, `onSurface`.
- Label `What happened`. Body, `onSurface`. Line `This profile is empty.` Body, `onSurfaceVariant`.
- Label `Why`. Line `You have not saved a lesson yet.`
- Label `What to do`. Line `Say the first word.`
- Button `Say the first word`. Fill `accent`, text `onAccent`. Semantics label: `Say the first word`.

Section gap `LingAfriqTokens.spacing16`. Label-to-line gap `LingAfriqTokens.spacing4`. Gap before the button `LingAfriqTokens.spacing24`.

**profile-error.png.** Title `Me`. Cue disc fill `danger`, cross in `onDanger`, minimum `LingAfriqTokens.spacing48`. Title line `Profile did not load` in body, role `danger` (the body pair `danger` on `surface`).

- `What happened`. `The profile did not open.`
- `Why`. `The profile did not come back.`
- `What to do`. `Try again.`
- Button `Try again`. Fill `accent`, text `onAccent`. Semantics label: `Try again`.

**profile-offline.png.** Cue disc fill `info`, info mark in `onInfo`. Title line `You are offline` in body, role `info`.

- `What happened`. `The phone has no network.`
- `Why`. `This profile is not saved on the phone.`
- `What to do`. `Connect, then try again.`
- Button `Try again`. Fill `accent`, text `onAccent`. Semantics label: `Try again`.

**profile-reduced.png.** The resting profile. Same pixels as `profile-light.png`. Profile adds no motion of its own, so the still matches the light data frame. `MediaQuery.disableAnimations` is on. No product motion runs. `motion.rare` does not run.

## Wardrobe

Wardrobe opens from the Wardrobe row on Me. Three named looks are quiet rows: Head wrap, Short hair, and No portrait. The data frame has one look chosen. Head wrap is on. The chosen row has a check, the word `On`, and a stroke `LingAfriqTokens.strokeregular` in `onSurface`. The other rows have no check, no On, and no stroke. Meaning is not colour alone.

The line `This is optional.` is on the page. No portrait is drawn. The row `No portrait` is a name, not a picture.

`Save look` is the only filled accent button on the data frames. Semantics label: `Save this look`.

### wardrobe-light.png

Roles: `colorRamps.modes.light`. Background role `surface`. Padding `LingAfriqTokens.spacing16`. Column, top aligned.

1. Title `Wardrobe`. Display style. Role `onSurface`.
2. Gap `LingAfriqTokens.spacing8`. Line `This is optional.` Body, role `onSurfaceVariant`.
3. Gap `LingAfriqTokens.spacing16`. Three quiet rows. Gap between rows: `LingAfriqTokens.spacing12`.
   - `Head wrap`. The row is on. Check in `onSurface`. Word `On`. Stroke `LingAfriqTokens.strokeregular` in `onSurface`. Semantics `Head wrap, on`.
   - `Short hair`. Line `Hair cut short.` Semantics `Choose Short hair`.
   - `No portrait`. Line `No picture.` Semantics `Choose No portrait`.
4. Gap `LingAfriqTokens.spacing24`. Button `Save look`. Fill `accent`. Text `onAccent`. Semantics `Save this look`.

### wardrobe-dark.png

Same layout, copy, type, and spacing as `wardrobe-light.png`. Roles come from `colorRamps.modes.dark`. Head wrap stays on.

### wardrobe-200.png

Same as `wardrobe-light.png` at 200% text. Look names wrap inside 390 px. Each row and `Save look` stay at least `LingAfriqTokens.spacing48`. `Save look` stays the only filled accent button.

### wardrobe-empty.png

No look is chosen yet. Light roles.

1. Title `Wardrobe`. Display, `onSurface`.
2. Gap `LingAfriqTokens.spacing8`. Line `This is optional.` Body, `onSurfaceVariant`.
3. Gap `LingAfriqTokens.spacing16`. `No look chosen yet` in body, `onSurface`.
4. Gap `LingAfriqTokens.spacing16`. The three quiet rows. None has a check, the word On, or a stroke.
   - `Head wrap`. Line `A cloth on the head.` Semantics `Choose Head wrap`.
   - `Short hair`. Line `Hair cut short.` Semantics `Choose Short hair`.
   - `No portrait`. Line `No picture.` Semantics `Choose No portrait`.
5. Gap `LingAfriqTokens.spacing16`. `What happened`. Line `No look is chosen.`
6. `Why`. Line `You have not picked one.`
7. `What to do`. Line `Pick a look, or skip for now.`
8. Gap `LingAfriqTokens.spacing24`. Button `Skip for now`. Fill `accent`, text `onAccent`. Semantics `Skip avatar for now`.

There is nothing to save, so this frame does not show `Save look`. `Skip for now` is the one filled accent button.

### wardrobe-reduced.png

The resting wardrobe. Same pixels as `wardrobe-light.png`. Wardrobe adds no motion of its own, so the still matches the light data frame. `MediaQuery.disableAnimations` is on. No product motion runs. `motion.rare` does not run.

## First spoken word

This is the instant first win from §5.2. Polie greets in the language. The Tone Lens greeting contour sits above `Ẹ kú àárọ̀`. The learner hears it, then says it back. No account is required yet.

The title says the learner speaks now: `You speak now`.

The visible annotation is `Speak within 60 seconds.` That line is the product target. It is not a measured score and not a running timer. A line under it says `This is a target, not a timer.`

Sample feedback is labelled `Sample`. It is about one syllable. The heard `kú` was mid, and the high tone sits up. The syllable `kú` uses `LingAfriqType.target`. The English around it uses body. There is no number.

`Hear it` is a quiet control. Semantics label: `Hear Ẹ kú àárọ̀`. `I said it` is the only filled accent button. Semantics label: `I said the greeting`. That tap does not show a score.

### firstword-light.png

Roles: `colorRamps.modes.light`. Background role `surface`. Padding `LingAfriqTokens.spacing16`. Column, top aligned.

1. Title `You speak now`. Display style. Role `onSurface`.
2. Gap `LingAfriqTokens.spacing8`. Line `Polie greets you in the language.` Body, role `onSurfaceVariant`.
3. Gap `LingAfriqTokens.spacing4`. Line `No account yet.` Body, role `onSurfaceVariant`.
4. Gap `LingAfriqTokens.spacing16`. Label `Tone Lens`. Body, role `onSurface`.
5. Gap `LingAfriqTokens.spacing4`. The greeting contour.
6. Gap `LingAfriqTokens.spacing4`. `Ẹ kú àárọ̀` in `LingAfriqType.target`, role `onSurface`. The line box uses `LingAfriqType.targetHeight` so the tone marks stay visible.
7. Gap `LingAfriqTokens.spacing4`. Line `Good morning.` Body, role `onSurfaceVariant`.
8. Gap `LingAfriqTokens.spacing4`. Line `Mid, then high, then rising, then low.` Body, role `onSurfaceVariant`.
9. Gap `LingAfriqTokens.spacing16`. Note pill `Speak within 60 seconds.` Semantics `Product target. Speak within 60 seconds. Not a timer.`
10. Gap `LingAfriqTokens.spacing4`. Line `This is a target, not a timer.` Body, role `onSurfaceVariant`.
11. Gap `LingAfriqTokens.spacing16`. Button `Hear it`. Quiet. Semantics `Hear Ẹ kú àárọ̀`.
12. Gap `LingAfriqTokens.spacing24`. Note pill `Sample`. Semantics `Sample data`.
13. Gap `LingAfriqTokens.spacing12`. Line `We heard this syllable.` Body, role `onSurface`.
14. Gap `LingAfriqTokens.spacing4`. `kú` in `LingAfriqType.target`, role `onSurface`.
15. Gap `LingAfriqTokens.spacing4`. Line `It was mid. The high tone sits up.` Body, role `onSurfaceVariant`.
16. Gap `LingAfriqTokens.spacing24`. Button `I said it`. Fill `accent`. Text `onAccent`. Semantics `I said the greeting`.

`I said it` is the only filled accent button. The sample block shows no number.

### firstword-dark.png

Same layout, copy, type, and spacing as `firstword-light.png`. Roles come from `colorRamps.modes.dark`.

### firstword-200.png

Same as `firstword-light.png` at 200% text. `Ẹ kú àárọ̀` and `kú` stay fully visible. Lines wrap inside 390 px. `Hear it` and `I said it` stay at least `LingAfriqTokens.spacing48`. The target lines are still Andika at the `LingAfriqType.target` token, scaled by `TextScaler.linear(2)`.

### First spoken word state frames

The data frame is the speaking moment. Empty, error, and offline do not show `Ẹ kú àárọ̀`. They do not show the 60 second line.

**firstword-skeleton.png.** Visible word `Loading` in body, role `onSurfaceVariant`. Semantics label: `Loading the first word`. Under it, one block of height `LingAfriqTokens.spacing32`, then five blocks of height `LingAfriqTokens.spacing48`. Fill `surfaceContainer`. Radius `LingAfriqTokens.radiusmd`. Gap `LingAfriqTokens.spacing12`. No shimmer.

**firstword-empty.png.** Title `You speak now`. `No word yet`.

- `What happened`. `There is no greeting to say.`
- `Why`. `No word came back.`
- `What to do`. `Try again.`
- Button `Try again`, accent / `onAccent`. Semantics `Try again`.

**firstword-error.png.** Title `You speak now`. Danger disc with a cross. `The first word did not open` in role `danger`.

- `What happened`. `The greeting did not load.`
- `Why`. `The word did not come back.`
- `What to do`. `Try again.`
- Button `Try again`. Semantics `Try again`.

**firstword-offline.png.** Title `You speak now`. Info disc. `You are offline` in role `info`.

- `What happened`. `The phone has no network.`
- `Why`. `This greeting is not saved on the phone.`
- `What to do`. `Connect, then try again.`
- Button `Try again`. Semantics `Try again`.

**firstword-reduced.png.** The resting first word. Same pixels as `firstword-light.png`. The first spoken word adds no motion of its own, so the still matches the light data frame. `MediaQuery.disableAnimations` is on. The contour does not draw on. No product motion runs. `motion.rare` does not run.

## Level up

Level up is rare-tier motion. `motion.rare.allowedUses` includes `level-up`. The duration is `LingAfriqTokens.motionRareLevelUp`. The frame does not show a level number as a score. The next unit is named in words: `Unit 2. Family`.

`levelup-light.png` is the rare-motion frame. The same mid-travel mark is on `levelup-dark.png` and `levelup-200.png`. A separate rare file is not exported, because the light frame is that still.

The visible word on the rare frame is `Rare`. The line is `Lesson unit complete`. The primary button is `Continue`. Semantics label: `Continue to the Family unit`.

### levelup-light.png

Roles: `colorRamps.modes.light`. Background role `surface`. Padding `LingAfriqTokens.spacing16`. Column, top aligned. This is the rare-motion frame.

1. Note pill `Rare`. Semantics `Rare tier motion`.
2. Gap `LingAfriqTokens.spacing16`. The celebration mark, mid travel.
3. Gap `LingAfriqTokens.spacing16`. Title `Lesson unit complete`. Display, role `onSurface`.
4. Gap `LingAfriqTokens.spacing8`. Line `Unit 2. Family`. Body, role `onSurface`. Semantics `Next unit. Unit 2. Family.`
5. Gap `LingAfriqTokens.spacing4`. Line `Next is the Family unit.` Body, role `onSurfaceVariant`.
6. Gap `LingAfriqTokens.spacing24`. Button `Continue`. Fill `accent`. Text `onAccent`. Semantics `Continue to the Family unit`.

`Continue` is the only filled accent button. The duration cited for this frame is `motion.rare.durationMs.levelUp`.

### levelup-dark.png

Same layout, copy, type, spacing, and mid-travel mark as `levelup-light.png`. Roles come from `colorRamps.modes.dark`. This is still the rare-motion still.

### levelup-200.png

Same as `levelup-light.png` at 200% text. `Lesson unit complete` and `Unit 2. Family` wrap inside 390 px. The celebration box stays `LingAfriqTokens.spacing64`. `Continue` stays at least `LingAfriqTokens.spacing48`. The mark is still mid travel.

### Level up state frames

**levelup-skeleton.png.** Visible word `Loading` in body, role `onSurfaceVariant`. Semantics label: `Loading the celebration`. Under it, one block of height `LingAfriqTokens.spacing48`, one block of height `LingAfriqTokens.spacing64`, two blocks of height `LingAfriqTokens.spacing32`, and one block of height `LingAfriqTokens.spacing48`. Fill `surfaceContainer`. Radius `LingAfriqTokens.radiusmd`. Gap `LingAfriqTokens.spacing12`. No shimmer. The celebration mark is not drawn.

**levelup-empty.png.** Title `Level up`, display, `onSurface`. `No next unit`.

- `What happened`. `There is no next unit.`
- `Why`. `The path did not name one.`
- `What to do`. `Go back to Today.`
- Button `Back to Today`, accent / `onAccent`. Semantics `Back to Today`.

This frame does not show `Rare`, the mark, or `Unit 2. Family`.

**levelup-error.png.** Title `Level up`. Danger disc with a cross. `Level up did not open` in role `danger`.

- `What happened`. `The celebration did not start.`
- `Why`. `The next unit did not come back.`
- `What to do`. `Try again.`
- Button `Try again`. Semantics `Try again`.

**levelup-offline.png.** Title `Level up`. Info disc. `You are offline` in role `info`.

- `What happened`. `The phone has no network.`
- `Why`. `The next unit is not saved on the phone.`
- `What to do`. `Connect, then try again.`
- Button `Try again`. Semantics `Try again`.

**levelup-reduced.png.** Same words as `levelup-light.png`: `Rare`, `Lesson unit complete`, `Unit 2. Family`, `Next is the Family unit.`, and `Continue`. The mark is the end state, not mid travel. Reduced motion is gentler, and it is not removed. The still is not a blank screen. `MediaQuery.disableAnimations` is on, so this export does not play the travel. The duration token stays `LingAfriqTokens.motionRareLevelUp`. The pixels are not the same as `levelup-light.png`.

## Lesson complete

Lesson complete is rare-tier motion. `motion.rare.allowedUses` includes `lesson-complete`. The duration is `LingAfriqTokens.motionRareLessonComplete`. The words are `Lesson complete` and `You said the greeting.`

`lesson-complete-light.png` is the rare-motion frame. The lesson player already uses `lesson-light.png` and the other `lesson-` state names, so these files keep the `lesson-` prefix and add `complete-` so the two specs do not share a file. A separate rare file is not exported, because the light frame is the rare-motion still.

The primary button is `Back to Today`. Semantics label: `Back to Today`.

### lesson-complete-light.png

Roles: `colorRamps.modes.light`. Background role `surface`. Padding `LingAfriqTokens.spacing16`. Column, top aligned. This is the rare-motion frame.

1. Note pill `Rare`. Semantics `Rare tier motion`.
2. Gap `LingAfriqTokens.spacing16`. The celebration mark, mid travel.
3. Gap `LingAfriqTokens.spacing16`. Title `Lesson complete`. Display, role `onSurface`.
4. Gap `LingAfriqTokens.spacing8`. Line `You said the greeting.` Body, role `onSurface`.
5. Gap `LingAfriqTokens.spacing24`. Button `Back to Today`. Fill `accent`. Text `onAccent`. Semantics `Back to Today`.

`Back to Today` is the only filled accent button. The duration cited for this frame is `motion.rare.durationMs.lessonComplete`.

### lesson-complete-dark.png

Same layout, copy, type, spacing, and mid-travel mark as `lesson-complete-light.png`. Roles come from `colorRamps.modes.dark`.

### lesson-complete-200.png

Same as `lesson-complete-light.png` at 200% text. The lines wrap inside 390 px. The celebration box stays `LingAfriqTokens.spacing64`. `Back to Today` stays at least `LingAfriqTokens.spacing48`. The mark is still mid travel. This is the 200% text frame for this surface.

### lesson-complete-reduced.png

Same words as `lesson-complete-light.png`: `Rare`, `Lesson complete`, `You said the greeting.`, and `Back to Today`. The mark is the end state. Reduced motion is gentler, and it is not removed. The still is not a blank screen. `MediaQuery.disableAnimations` is on, so this export does not play the travel. The duration token stays `LingAfriqTokens.motionRareLessonComplete`. The pixels are not the same as `lesson-complete-light.png`.

## Accessibility

- Minimum control size is `LingAfriqTokens.spacing48`.
- Every control in this spec has a visible label and a semantics label. Painted cues (check, cross, info mark, greeting contour, celebration mark) sit beside words.
- Body text uses a `colorRamps.pairs` row whose level is `body` (4.5:1). The pairs used are `onSurface` on `surface`, `onSurface` on `surfaceContainer`, `onSurfaceVariant` on `surface`, `onAccent` on `accent`, `onDanger` on `danger`, `danger` on `surface`, `onInfo` on `info`, and `info` on `surface`.
- Target lines use `LingAfriqType.target`. The line box uses that leading so the tone marks stay visible. `Ẹ kú àárọ̀` and the sample syllable `kú` are target lines.
- 200% text wraps. It does not clip.
- Profile, wardrobe, and the first spoken word add no motion of their own. Their reduced-motion still matches the light data frame.
- Level up and lesson complete use `motion.rare`. Reduced motion keeps the end state. It is gentler, and it is not removed. Those reduced frames are not the same pixels as the rare-motion frames.

## Card report

Frames are painted by `test/design/profile_celebrate_firstword_frames_test.dart`. The test loads ramp roles from `design/tokens/tokens.json`, spacing and radius from `LingAfriqTokens`, and type from `LingAfriqType`. It loads bundled Andika, `LingAfriqText`, and `LingAfriqDisplay`, and paints at 390 px. The test checks that `levelup-reduced.png` is not pixel-identical to `levelup-light.png`. The PNG files are the only images that test compares. Updating them does not touch any other golden.

| Acceptance | Result |
| --- | --- |
| AC1. Rare-tier motion frames are marked, and the reduced-motion variant is gentler and not removed. | Met. `levelup-light.png` and `lesson-complete-light.png` show the word Rare and the mid-travel mark. They cite `motion.rare`. `levelup-reduced.png` and `lesson-complete-reduced.png` keep the same words and the end state. The motion is gentler, and it is not removed. |
| AC2. The first spoken word shows the Tone Lens with the greeting, and the 60 second target is annotated. | Met. `firstword-light.png` shows the greeting contour above `Ẹ kú àárọ̀`, the gloss Good morning, and `Speak within 60 seconds.` |
| AC3. The wardrobe is reached from Me, and avatar creation is optional. | Met. `profile-light.png` has the Wardrobe row, semantics `Open wardrobe`, the line `Avatar can wait until after lesson 2.`, and `Skip for now`. `wardrobe-light.png` says `This is optional.` |
| AC4. Light and dark frames at 390 px, and a 200% text frame, exported under `docs/build/design/screens/`. | Met when the PNG files from the test exist and are 390 px wide. Profile, wardrobe, the first spoken word, level up, and lesson complete each have light, dark, and 200%. |
| AC5. Every colour, size, font, and radius references a token. None is hard-coded. | Met in this spec. No hex values. Sizes, radii, strokes, and the celebration duration cite `LingAfriqTokens`, `LingAfriqType`, `type.*`, or `motion.rare`. Colours cite ramp roles. The duration is not written as a number. |
| AC6. Skeleton, empty, error, offline, and reduced-motion frames are included for the state kit. | Met when those PNG files exist. Profile, the first spoken word, and level up include skeleton, empty, error, offline, and reduced motion. Wardrobe includes empty (no look chosen yet) and reduced motion. Lesson complete includes the rare-motion light frame and reduced motion. |
| AC7. A T4 reviewer records visual approval in the card report. | Unmet. The frames are ready to check. No T4 approval is recorded. |

`docs/plan/CARD_STATUS.tsv` stays `Draft` because AC7 is unmet.

On purpose, this spec does not draw a league, a family row, Plus, or About. It does not draw an illustrated portrait. It does not draw the six teaching contours. It does not show XP, a percent, a league rank, or a confidence number. Lesson complete does not include skeleton, empty, error, or offline frames. Wardrobe does not include skeleton, error, or offline frames. The lesson player goldens keep their own file names.

Exported files:

- `docs/build/design/screens/profile-light.png`
- `docs/build/design/screens/profile-dark.png`
- `docs/build/design/screens/profile-200.png`
- `docs/build/design/screens/profile-skeleton.png`
- `docs/build/design/screens/profile-empty.png`
- `docs/build/design/screens/profile-error.png`
- `docs/build/design/screens/profile-offline.png`
- `docs/build/design/screens/profile-reduced.png`
- `docs/build/design/screens/wardrobe-light.png`
- `docs/build/design/screens/wardrobe-dark.png`
- `docs/build/design/screens/wardrobe-200.png`
- `docs/build/design/screens/wardrobe-empty.png`
- `docs/build/design/screens/wardrobe-reduced.png`
- `docs/build/design/screens/firstword-light.png`
- `docs/build/design/screens/firstword-dark.png`
- `docs/build/design/screens/firstword-200.png`
- `docs/build/design/screens/firstword-skeleton.png`
- `docs/build/design/screens/firstword-empty.png`
- `docs/build/design/screens/firstword-error.png`
- `docs/build/design/screens/firstword-offline.png`
- `docs/build/design/screens/firstword-reduced.png`
- `docs/build/design/screens/levelup-light.png`
- `docs/build/design/screens/levelup-dark.png`
- `docs/build/design/screens/levelup-200.png`
- `docs/build/design/screens/levelup-skeleton.png`
- `docs/build/design/screens/levelup-empty.png`
- `docs/build/design/screens/levelup-error.png`
- `docs/build/design/screens/levelup-offline.png`
- `docs/build/design/screens/levelup-reduced.png`
- `docs/build/design/screens/lesson-complete-light.png`
- `docs/build/design/screens/lesson-complete-dark.png`
- `docs/build/design/screens/lesson-complete-200.png`
- `docs/build/design/screens/lesson-complete-reduced.png`
