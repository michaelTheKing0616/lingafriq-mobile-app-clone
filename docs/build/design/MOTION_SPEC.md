# Motion, sound, and haptics

Status: Draft. P3-029 stays Draft. EXT-16 is still an external blocker, and a reviewer has not approved this spec.

This is a specification. The sound cues are specified. They are not shipped. No audio file is added.

## Sources

- `docs/source/ELEVATION.md` §3.4, lines 848-849. Celebrations stay in the rare tier. Answer feedback uses haptic plus sound. Reduced motion is gentler.
- `docs/source/ELEVATION.md` §10.3, lines 1679-1689, and the market scene at line 1506. The talking drum is the instrument already named there (Yoruba dùndún, Akan atumpan, ambient talking drums).
- `docs/source/ELEVATION.md` §13.7, lines 1938-1939. A sound-only cue keeps a haptic or a visual alternative. Reduced motion stays.
- `design/tokens/tokens.json` `motion.product` and `motion.rare`.
- `lib/design/tokens.g.dart`: `LingAfriqTokens.motionProductEasing`, `LingAfriqTokens.motionProductInstant`, `LingAfriqTokens.motionProductFast`, `LingAfriqTokens.motionProductBase`, `LingAfriqTokens.motionProductSlow`, `LingAfriqTokens.motionRareEasing`, `LingAfriqTokens.motionRareLessonComplete`, `LingAfriqTokens.motionRareLevelUp`.
- `docs/build/design/screens/profile_celebrate_firstword.md`, Celebration mark, Level up, and Lesson complete. Those frames are already approved. This spec cites them. It does not redraw them.

Colour is a role in `colorRamps.modes`. This spec writes no hex.

## Rare tier

The rare tier is only lesson complete and level up. `motion.rare.allowedUses` lists `lesson-complete` and `level-up`. No other event uses this tier.

Lesson complete runs for `LingAfriqTokens.motionRareLessonComplete` (`motion.rare.durationMs.lessonComplete`). Level up runs for `LingAfriqTokens.motionRareLevelUp` (`motion.rare.durationMs.levelUp`). Both use `LingAfriqTokens.motionRareEasing` (`motion.rare.easing`).

Those are the token names. This spec does not write a new duration. The numbers stay in `design/tokens/tokens.json`.

`LingAfriqTokens.motionRareEasing` is the curve string already stored on `motion.rare.easing`: `cubic-bezier(0.23,1,0.32,1)`.

Reduced motion keeps the end state and is gentler. It is not removed and not a blank screen. The flag is `MediaQuery.disableAnimations`. The travel does not play. The words stay. The duration token stays the rare token named above.

The celebration mark is the one already drawn in `docs/build/design/screens/profile_celebrate_firstword.md` under Celebration mark. Mid travel is the open arc. The end state is the closed ring with the rays at the end. This spec does not add a PNG.

Level up points at the existing frames:

- Rare-motion still: `docs/build/design/screens/levelup-light.png`. The mark is mid travel. `levelup-dark.png` and `levelup-200.png` use that same mark.
- Reduced-motion still: `docs/build/design/screens/levelup-reduced.png`. The words stay: Rare, Lesson unit complete, Unit 2. Family, Next is the Family unit., and Continue. The mark is the end state. The pixels are not the same as `levelup-light.png`.

Lesson complete points at the existing frames:

- Rare-motion still: `docs/build/design/screens/lesson-complete-light.png`. The mark is mid travel. `lesson-complete-dark.png` and `lesson-complete-200.png` use that same mark.
- Reduced-motion still: `docs/build/design/screens/lesson-complete-reduced.png`. The words stay: Rare, Lesson complete, You said the greeting., and Back to Today. The mark is the end state. The pixels are not the same as `lesson-complete-light.png`.

## Product tier

Every product motion uses `motion.product.easing`. That value is the curve string already in the token file, `cubic-bezier(0.23,1,0.32,1)`, exposed as `LingAfriqTokens.motionProductEasing`. It is the same curve string as `LingAfriqTokens.motionRareEasing`.

Each product motion below is one of instant, fast, base, or slow. The file sets `motion.product.durationMs` to instant 80, fast 160, base 240, and slow 300. None of those is over 300 ms. Slow is the ceiling already in the file. This spec adds no other product duration.

| Motion | Token |
| --- | --- |
| Answer feedback, correct or incorrect | `LingAfriqTokens.motionProductFast` |
| Choice press | `LingAfriqTokens.motionProductInstant` |
| Panel open, such as a word card or a sheet | `LingAfriqTokens.motionProductBase` |
| Inline note, such as a hint, an error, or an offline line | `LingAfriqTokens.motionProductSlow` |

Answer feedback is the fast token. `motion.product.durationMs.fast` is 160 in the file. The name to cite is `LingAfriqTokens.motionProductFast`.

The exported screen stills do not play these motions. When the product runs one, the duration is the token in the table.

Stagger, when a list enters together: each step waits `LingAfriqTokens.motionProductInstant`, and the list still settles by `LingAfriqTokens.motionProductSlow`. No delay outside those two tokens is used.

Reduced motion on a product motion keeps the end state and is gentler. It is not removed and not a blank screen. The travel does not play. The settled UI stays on screen. The duration token stays the product token for that motion.

## Sound palette

The palette is mutable. Sound can be off. When sound is off, the visual alternative in the haptic map still shows.

Eight cues follow. For each one the credit line is the same, because nothing has been recorded. No artist is named. No sound file is named. No price is set.

| Event | Instrument family | Reason | Credit |
| --- | --- | --- | --- |
| Correct answer | talking drum | A short talking-drum stroke confirms the answer, the same timbre `ELEVATION.md` uses when a phrase is drummed so tone is heard as speech (Yoruba dùndún and Akan atumpan, §10.3). | Not recorded. Credit waits on EXT-16. |
| Incorrect answer | shekere | A dry shekere shake marks the miss as a cue to try again, a West African gourd rattle that keeps time beside speech. | Not recorded. Credit waits on EXT-16. |
| Choice selected | mbira | One mbira tine marks that a choice landed, a single note from a southern African lamellophone that can repeat on every tap. | Not recorded. Credit waits on EXT-16. |
| Hint | flute | A short flute tone marks help, in a different family from the talking drum that marks a right answer. | Not recorded. Credit waits on EXT-16. |
| Lesson complete | talking drum | Lesson complete is rare, so the talking drum returns as a short phrase for spoken tone, and it plays only on this celebration. | Not recorded. Credit waits on EXT-16. |
| Level up | flute | Level up is the other rare celebration, and a flute phrase marks it in a different family from the talking drum on lesson complete. | Not recorded. Credit waits on EXT-16. |
| Microphone open | shekere | A shekere grain marks the moment the microphone opens, a time-keeping shake beside the learner's voice. | Not recorded. Credit waits on EXT-16. |
| Microphone close | mbira | A single mbira release marks that the speaking turn ended, after the shekere that opened the microphone. | Not recorded. Credit waits on EXT-16. |

## Haptic map

Every feedback event has one haptic pattern and one visual alternative for when haptics are off. The pattern is one of selection, light, medium, or success. The visual alternative is a token colour role, or the celebration mark already drawn. It is not a new illustration.

The role sits with the words the screen already shows. The mark sits with the words already on the level-up and lesson-complete frames. Colour is not the only cue.

| Event | Haptic pattern | Visual alternative when haptics are off |
| --- | --- | --- |
| Correct answer | success | colour role `success` |
| Incorrect answer | medium | colour role `danger` |
| Choice selected | selection | colour role `onSurface` |
| Hint | light | colour role `info` |
| Lesson complete | success | the celebration mark on `docs/build/design/screens/lesson-complete-light.png`, or the end state on `docs/build/design/screens/lesson-complete-reduced.png` when reduced motion is on |
| Level up | success | the celebration mark on `docs/build/design/screens/levelup-light.png`, or the end state on `docs/build/design/screens/levelup-reduced.png` when reduced motion is on |
| Microphone open | light | colour role `accent` on the speak control |
| Microphone close | selection | colour role `onSurface` |

When haptics are off, that visual alternative shows. When sound is off, the same visual alternative shows. When both are off, the visual alternative still shows.

Answer feedback starts the haptic, the cue, and the motion together. The motion duration is `LingAfriqTokens.motionProductFast`.

## Acceptance

| Acceptance | Result |
| --- | --- |
| AC1. Celebrations are limited to lesson complete and level up, and each has a duration and a reduced-motion variant. | Met. The rare tier is those two events. Durations are `LingAfriqTokens.motionRareLessonComplete` and `LingAfriqTokens.motionRareLevelUp`. Easing is `LingAfriqTokens.motionRareEasing`. Reduced motion keeps the end state on `levelup-reduced.png` and `lesson-complete-reduced.png`. It is gentler. It is not removed and not a blank screen. |
| AC2. The sound palette lists at least 8 cues with source instruments, a culturally resonant rationale, and credit to artists via EXT-16. | Met as a specification. Eight cues are listed. Each names talking drum, shekere, mbira, or flute, with one reason. Each carries the line "Not recorded. Credit waits on EXT-16." |
| AC3. Each feedback event maps to one haptic pattern and one visual alternative. | Met. The haptic map gives each of the eight events one pattern and one visual alternative. |
| AC4. Each product-tier motion uses the token curve and is at most 300 ms. | Met. Each listed product motion uses `motion.product.easing` and one of instant, fast, base, or slow. The file values are 80, 160, 240, and 300. Answer feedback uses `LingAfriqTokens.motionProductFast`. |

A reviewer has not approved this spec. `P3-029` stays Draft.

## Left open on purpose

EXT-16 is still an external blocker. The recordings are not in the repo. Artist names, a licence, and a price wait on EXT-16. This spec does not invent them. The cues stay specified, and they are not shipped.
