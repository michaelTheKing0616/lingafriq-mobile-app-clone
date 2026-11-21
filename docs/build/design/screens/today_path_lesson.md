# P3-015 Today, Path, and the lesson player

Status: Draft. The frames below are the hi-fi. A T4 reviewer has not approved them, so `docs/plan/CARD_STATUS.tsv` stays Draft. See the card report.

This is the screen spec for three surfaces:

- Today is one plan of 10 to 15 minutes.
- Path is the lesson map.
- The lesson player is the session for that plan.

Sources: `docs/source/ELEVATION.md` §3.3 (lines 792-823), §17.1 (lines 2171-2182), §17.4 (lines 2309-2318), and §18.1 (lines 2450-2460). Tokens: `design/tokens/tokens.json` and `lib/design/typography.dart`.

## Progress is the store the path already has

Path, Today, and the lesson player read one lesson record.

- Node state comes from `resolvePathNodeState` in `lib/widgets/learning_path/path_node_state.dart`.
- `PathLessonProgress.isCompleted` is the completion flag the path already stores on the lesson (`LearningPathScreen` `_sectionCompleted`, and the lesson section `isCompleted` flag the lesson player already writes).
- Review due comes from `PathPacingOverlay.reviewDueLessonIds` (the scheduler overlay already passed into that resolver).
- The current lesson is the node that resolver marks `PathNodeVisualState.current`.
- Today’s next lesson is that current node. Today’s due reviews are that same review-due set.
- The lesson player writes completion back through the lesson section completion the path already reads.

`learningPathProvider` stays the personal plan. These screens do not copy it, do not add a table, and do not add a percent or a confidence field. `PathNodeVisualState.skipped` already exists on the resolver. This hi-fi does not draw a fifth style and does not write that set.

Open anyway opens the lesson player for that lesson. It does not mark the earlier lesson done.

## Tokens

Colour is a color ramp role. The role names are `surface`, `surfaceContainer`, `onSurface`, `onSurfaceVariant`, `accent`, `onAccent`, `success`, `onSuccess`, `warning`, `onWarning`, `danger`, `onDanger`, `info`, and `onInfo`.

Light frames use `colorRamps.modes.light`. Dark frames use `colorRamps.modes.dark`. The pairs that pass body contrast (4.5:1) are the `level: body` rows in `colorRamps.pairs`. This spec uses only those pairs for text. `accent` on `surface` is the large pair only, so accent is never body-size text. Accent means the primary action, so the filled accent control is the one primary button on the screen.

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
| Card radius | `LingAfriqTokens.radiusmd` |
| Pill radius | `LingAfriqTokens.radiuspill` |
| Hairline | `LingAfriqTokens.strokehairline` |
| Strong stroke | `LingAfriqTokens.strokeregular` |
| Display | `type.display`: family `LingAfriqType.displayFamily`, size `type.display.size`, height `type.display.height` |
| Body | `type.body`: family `LingAfriqType.bodyFamily`, size `LingAfriqType.bodySize`, height `LingAfriqType.targetHeight` |
| Target language | `LingAfriqType.target`: family Andika (`LingAfriqType.targetFamily`), size `LingAfriqType.targetSize`, height `LingAfriqType.targetHeight` |

Body and display sit on the real bundled files: `LingAfriqText` (Noto Sans) and `LingAfriqDisplay` (Nunito). Target-language lines sit on bundled Andika. Weight stays the loaded face. Do not invent a second family.

Product motion tokens (`motion.product` instant, fast, base, slow, and `motion.rare`) are not run on these frames. Reduced motion is the platform flag `MediaQuery.disableAnimations`. The frame does not add animation of its own.

## Shared rules

- Width is 390 px. The device viewport height is 844 px. Content scrolls. The exported image is the full column at 390 px so glyphs are not cut off in the evidence.
- Every control is at least `LingAfriqTokens.spacing48` in both axes and has a visible label or, for a painted mark, a semantics label written in this spec.
- Text uses a body pair from `colorRamps.pairs`. Meaning colour is never the only cue. Done has a check. Review due has a triangle. Locked has a lock. Error has a cross. Offline and loading notes use an info mark. The mark is drawn, not a font icon.
- Copy is short, grade-7 English. It makes no boastful claim. It uses a period or a comma in place of a long dash. It shows no score, no percent, no XP, and no confidence number.
- At 200% text, `TextScaler.linear(2)` doubles `type.display`, `type.body`, and `LingAfriqType.target`. Padding, radius, and stroke stay on the token scale. Controls grow with the label and stay at least `LingAfriqTokens.spacing48`. Lines wrap inside the 390 px width. No glyph is clipped.

Challenges, events, and the streak keep the homes named in §17.1. Culture cards and games keep their own homes. Today shows the plan and one Start button.

## Today

Today shows one plan. The example plan is 12 minutes, inside the 10 to 15 minute rule. The minute total is the real sum of the parts that are present. If a sum would leave that range, shorten the plan until it fits. If a part is absent, omit that row. Start stays the only filled accent button.

The example frame has all three parts, because that is the plan this card draws.

### today-light.png

Roles: `colorRamps.modes.light`. Background role `surface`. Padding `LingAfriqTokens.spacing16`. Column, top aligned.

1. Title `Today`. Display style. Role `onSurface`.
2. Gap `LingAfriqTokens.spacing8`. Line `One plan for today.` Body style. Role `onSurfaceVariant`.
3. Gap `LingAfriqTokens.spacing16`. Pill `12 minutes`. Fill role `surfaceContainer`. Text role `onSurface`. Body style. Radius `LingAfriqTokens.radiuspill`. Padding horizontal `LingAfriqTokens.spacing16`, vertical `LingAfriqTokens.spacing8`. Minimum height `LingAfriqTokens.spacing48`. This is text, not a button. Semantics label: `About 12 minutes`.
4. Gap `LingAfriqTokens.spacing24`. Three rows. Gap between rows: `LingAfriqTokens.spacing12`. A row is not a button.
   - Disc: minimum `LingAfriqTokens.spacing48`, fill `surfaceContainer`, number in `onSurface`, body style, radius `LingAfriqTokens.radiuspill`. Padding inside the disc: `LingAfriqTokens.spacing8`.
   - Gap after the disc: `LingAfriqTokens.spacing12`.
   - Row 1. Number `1`. Title `Due reviews` in `onSurface`. Line `Three words are ready to review.` in `onSurfaceVariant`.
   - Row 2. Number `2`. Title `Next lesson`. Line `Morning greetings`. Target line `Ẹ kú àárọ̀` in `LingAfriqType.target`, role `onSurface`.
   - Row 3. Number `3`. Title `Speaking`. Line `Say one greeting out loud.`
   - Title and line gap: `LingAfriqTokens.spacing4`.
5. Gap `LingAfriqTokens.spacing24`. Button visible label `Start`. Fill `accent`. Text `onAccent`. Body style. Radius `LingAfriqTokens.radiusmd`. Padding horizontal `LingAfriqTokens.spacing16`, vertical `LingAfriqTokens.spacing12`. Minimum `LingAfriqTokens.spacing48`. Full content width. Semantics label: `Start the 12 minute plan`.

Start is the only control on this frame. It opens the lesson player at step 1 of this plan.

### today-dark.png

Same layout, copy, type, and spacing as `today-light.png`. Roles come from `colorRamps.modes.dark`.

### today-200.png

Same as `today-light.png` at 200% text. `12 minutes` and `Ẹ kú àárọ̀` stay fully visible. `Start` stays one line at this copy length. The rows wrap inside 390 px.

### Today state frames

Same page padding, type, and role pairs. Dark uses `colorRamps.modes.dark` with the same layout.

**today-skeleton.png.** Visible word `Loading` in body, role `onSurfaceVariant`. Semantics label: `Loading today's plan`. Under it, six full-width blocks, fill `surfaceContainer`, radius `LingAfriqTokens.radiusmd`, gap `LingAfriqTokens.spacing12`. Heights, in order: `LingAfriqTokens.spacing32`, `LingAfriqTokens.spacing48`, then three times `LingAfriqTokens.spacing48`, then `LingAfriqTokens.spacing48`. No shimmer.

**today-empty.png.** Title `Today`, display, `onSurface`. Then:

- `No plan yet` in body, `onSurface`.
- Label `What happened`. Body, `onSurface`. Line `Today has nothing queued.` Body, `onSurfaceVariant`.
- Label `Why`. Line `There is no review due, and no lesson is chosen.`
- Label `What to do`. Line `Open Path and start the first lesson.`
- Button `Open Path`. Fill `accent`, text `onAccent`. Semantics label: `Open Path`.

Section gap `LingAfriqTokens.spacing16`.

**today-error.png.** Title `Today`. Cue disc fill `danger`, cross in `onDanger`, minimum `LingAfriqTokens.spacing48`. Title line `Today did not load` in body, role `danger` (the body pair `danger` on `surface`).

- `What happened`. `The plan did not open.`
- `Why`. `The lesson list did not come back.`
- `What to do`. `Try again.`
- Button `Try again`. Fill `accent`, text `onAccent`. Semantics label: `Try again`.

**today-offline.png.** Cue disc fill `info`, info mark in `onInfo`. Title line `You are offline` in body, role `info`.

- `What happened`. `The phone has no network.`
- `Why`. `This plan is not saved on the phone.`
- `What to do`. `Connect, then try again.`
- Button `Try again`. Fill `accent`, text `onAccent`. Semantics label: `Try again`.

**today-reduced.png.** The resting plan. Same pixels as `today-light.png`. Reduced motion adds no animation, so the still matches the light data frame. `MediaQuery.disableAnimations` is on. No product motion runs.

## Path

Path is a vertical lesson map. The first lesson is at the bottom. Later lessons sit above it. That matches `pathNodeYFromBottom` in `path_node_state.dart`. The page opens scrolled to the current node. The frame shows four nodes so each state is visible.

Node states drawn here: done, current, locked, review due. They are `PathNodeVisualState.done`, `.current`, `.locked`, and `.reviewDue`.

A locked lesson still opens. The locked row shows the unlock line, Preview, and Open anyway. Open anyway opens the lesson player for that lesson.

### path-light.png

Roles: `colorRamps.modes.light`. Background `surface`. Padding `LingAfriqTokens.spacing16`.

1. Title `Path`. Display, `onSurface`.
2. Gap `LingAfriqTokens.spacing16`. Unit block, fill `surfaceContainer`, radius `LingAfriqTokens.radiusmd`, padding `LingAfriqTokens.spacing16`.
   - `Unit 1. Greetings` body, `onSurface`.
   - Gap `LingAfriqTokens.spacing4`. `I can greet someone in the morning.` body, `onSurfaceVariant`.
3. Gap `LingAfriqTokens.spacing24`. Nodes, top to bottom:

**Lesson 4. Family names. Locked.** Disc minimum `LingAfriqTokens.spacing48`, fill `surfaceContainer`, lock mark in `onSurface`. Word `Locked` in body, role `onSurfaceVariant`. Line `Unlocks after Morning greetings.` in `onSurfaceVariant`. Then two full-width buttons, gap `LingAfriqTokens.spacing8`, fill `surfaceContainer`, text `onSurface`, radius `LingAfriqTokens.radiusmd`, minimum `LingAfriqTokens.spacing48`.

- Visible `Preview`. Semantics `Preview Family names`.
- Visible `Open anyway`. Semantics `Open Family names anyway`.

**Lesson 3. Morning greetings. Now.** Disc fill `surfaceContainer`, number `3` in `onSurface`, stroke `LingAfriqTokens.strokeregular` in `onSurface`. Word `Now` in body, `onSurface`. Target `Ẹ kú àárọ̀` in `LingAfriqType.target`, `onSurface`. Button visible `Start`, fill `accent`, text `onAccent`. Semantics `Start Morning greetings`.

**Lesson 2. Market words. Review due.** Disc fill `warning`, triangle in `onWarning`. Word `Review due` in body, role `warning`.

**Lesson 1. Hello. Done.** Disc fill `success`, check in `onSuccess`. Word `Done` in body, role `success`. No line under this disc.

The rail between discs is role `onSurfaceVariant`, width `LingAfriqTokens.strokehairline`. It runs from the bottom of one disc to the top of the next. Gap from disc to text: `LingAfriqTokens.spacing12`. Gap under each node’s text block: `LingAfriqTokens.spacing16`.

Start is the only filled accent button. Preview and Open anyway are labelled controls. They do not use accent.

Semantics for a node use the same facts as `pathNodeSemanticsLabel`: lesson number, title, and state. The locked node adds Open anyway.

### path-dark.png

Same layout and copy. Roles: `colorRamps.modes.dark`.

### path-200.png

Same as `path-light.png` at 200% text. Lesson titles wrap inside the column. Preview, Open anyway, and Start stay at least `LingAfriqTokens.spacing48` and grow with the label. The target line `Ẹ kú àárọ̀` is not clipped.

### Path state frames

**path-skeleton.png.** Word `Loading`, body, `onSurfaceVariant`. Semantics `Loading the path`. Then a unit block and four rows. Each row is a disc of minimum `LingAfriqTokens.spacing48` and a full-width bar of height `LingAfriqTokens.spacing32`. Fill `surfaceContainer`, radius `LingAfriqTokens.radiusmd`, gap `LingAfriqTokens.spacing12`. No shimmer.

**path-empty.png.** Title `Path`. `No lessons yet`.

- `What happened`. `This path has no lessons.`
- `Why`. `The lesson list is empty.`
- `What to do`. `Try again later.`
- Button `Try again`, accent / `onAccent`. Semantics `Try again`.

**path-error.png.** Title `Path`. Danger disc with a cross. `Path did not load` in role `danger`.

- `What happened`. `The lesson map did not open.`
- `Why`. `The lesson list failed to load.`
- `What to do`. `Try again.`
- Button `Try again`. Semantics `Try again`.

**path-offline.png.** Info disc. `You are offline` in role `info`.

- `What happened`. `The phone has no network.`
- `Why`. `This path is not saved on the phone.`
- `What to do`. `Connect, then try again.`
- Button `Try again`. Semantics `Try again`.

**path-reduced.png.** Same pixels as `path-light.png`. No trail draw, no hop, no pulse. Reduced motion adds no animation.

## Lesson player

The lesson player is the session for the Today plan. It plays three steps, in order:

1. Due reviews.
2. Next lesson.
3. Speaking.

The header keeps `12 minutes` visible on the data frame. The step label is text (`Step 1 of 3`), not a percent. The current segment uses role `onSurface`. Waiting segments use `surfaceContainer`. Accent is only the primary button.

Step 2 uses the same chrome. Title `Next lesson`. Body `Read the greeting. Then tap the matching line.` Target `Ẹ kú àárọ̀`. Primary button `Check`, semantics `Check this answer`.

Step 3 uses the same chrome. Title `Speaking`. Body `Say the greeting out loud.` Target `Ẹ kú àárọ̀`. Primary button visible `I said it`, semantics `I said the greeting`. That tap marks the speaking step complete on the same lesson record. It does not show a score.

The exported data frames show step 1.

### lesson-light.png

Roles: `colorRamps.modes.light`. Background `surface`. Padding `LingAfriqTokens.spacing16`.

1. Button visible `Close`. Fill `surfaceContainer`, text `onSurface`, radius `LingAfriqTokens.radiusmd`, padding `LingAfriqTokens.spacing12`, minimum `LingAfriqTokens.spacing48`. Semantics `Close lesson`. Aligned to the start. Not accent.
2. Gap `LingAfriqTokens.spacing12`. `Today` display, `onSurface`.
3. Gap `LingAfriqTokens.spacing4`. `12 minutes` body, `onSurface`. Semantics `About 12 minutes`.
4. Gap `LingAfriqTokens.spacing16`. Three segments in a row, gap `LingAfriqTokens.spacing4`, height `LingAfriqTokens.spacing8`, radius `LingAfriqTokens.radiuspill`. Segment 1 fill `onSurface`. Segments 2 and 3 fill `surfaceContainer`.
5. Gap `LingAfriqTokens.spacing8`. `Step 1 of 3` body, `onSurfaceVariant`.
6. Gap `LingAfriqTokens.spacing16`. `Due reviews` display, `onSurface`.
7. Gap `LingAfriqTokens.spacing8`. `Hear the word. Then tap it.` body, `onSurface`.
8. Gap `LingAfriqTokens.spacing16`. `Ẹ kú àárọ̀` in `LingAfriqType.target`, `onSurface`.
9. Gap `LingAfriqTokens.spacing16`. Three choice controls, full width, gap `LingAfriqTokens.spacing8`, fill `surfaceContainer`, text `onSurface`, radius `LingAfriqTokens.radiusmd`, padding `LingAfriqTokens.spacing12`, minimum `LingAfriqTokens.spacing48`.
   - `Ẹ kú àárọ̀` in `LingAfriqType.target`. Semantics `Ẹ kú àárọ̀`.
   - `Good night` in body. Semantics `Good night`.
   - `Thank you` in body. Semantics `Thank you`.
10. Gap `LingAfriqTokens.spacing24`. Button `Check`, fill `accent`, text `onAccent`. Semantics `Check this answer`.

Check is the only filled accent button. Choosing a line does not show a score.

### lesson-dark.png

Same layout and copy. Roles: `colorRamps.modes.dark`.

### lesson-200.png

Same as `lesson-light.png` at 200% text. The Andika line, the three choices, and `12 minutes` wrap or grow inside 390 px. Nothing is clipped.

### Lesson state frames

**lesson-skeleton.png.** Word `Loading`, body, `onSurfaceVariant`. Semantics `Loading the lesson`. Blocks, fill `surfaceContainer`, radius `LingAfriqTokens.radiusmd`, gap `LingAfriqTokens.spacing12`: one bar height `LingAfriqTokens.spacing32`, three segments height `LingAfriqTokens.spacing8`, two bars height `LingAfriqTokens.spacing32`, three bars height `LingAfriqTokens.spacing48`, one bar height `LingAfriqTokens.spacing48`. No shimmer.

**lesson-empty.png.** Title `Lesson`, display, `onSurface`. `No lesson in this plan`.

- `What happened`. `The session has no lesson.`
- `Why`. `You have not chosen a lesson.`
- `What to do`. `Open Path and choose a lesson.`
- Button `Open Path`, accent / `onAccent`. Semantics `Open Path`.

**lesson-error.png.** Title `Lesson`. Danger disc, cross in `onDanger`. `Lesson did not open` in role `danger`.

- `What happened`. `The lesson stopped before the first word.`
- `Why`. `The lesson file is missing on this phone.`
- `What to do`. `Try again. If it fails, go back to Path and pick another lesson.`
- Button `Try again`, accent / `onAccent`. Semantics `Try again`.
- Gap `LingAfriqTokens.spacing8`. Button `Back to Path`, fill `surfaceContainer`, text `onSurface`. Semantics `Back to Path`.

**lesson-offline.png.** Title `Lesson`. Info disc, info mark in `onInfo`. `You are offline` in role `info`.

- `What happened`. `The phone has no network.`
- `Why`. `This lesson is not saved on the phone.`
- `What to do`. `Connect, then try again.`
- Button `Try again`, accent / `onAccent`. Semantics `Try again`.
- Button `Back to Today`, fill `surfaceContainer`, text `onSurface`. Semantics `Back to Today`.

Dark error and dark offline use this same layout with `colorRamps.modes.dark`.

**lesson-reduced.png.** Same pixels as `lesson-light.png`. The segments do not move. No shimmer. Reduced motion adds no animation.

## Accessibility

- Minimum control size is `LingAfriqTokens.spacing48` (`kPathNodeMinTapTargetDp` is the same 48).
- Every control in this spec has a semantics label. Painted cues (check, triangle, lock, cross, info mark) sit beside words.
- Body text uses a `colorRamps.pairs` row whose level is `body` (4.5:1). The pairs used are `onSurface` on `surface`, `onSurface` on `surfaceContainer`, `onSurfaceVariant` on `surface`, `onAccent` on `accent`, `onSuccess` on `success`, `success` on `surface`, `onWarning` on `warning`, `warning` on `surface`, `onDanger` on `danger`, `danger` on `surface`, `onInfo` on `info`, and `info` on `surface`.
- 200% text wraps. It does not clip.
- Reduced motion runs no extra animation. Duration is not taken from `motion.product` or `motion.rare`.

## Card report

Frames are painted by `test/design/today_path_lesson_frames_test.dart`. The test loads ramp roles from `design/tokens/tokens.json`, spacing and radius from `LingAfriqTokens`, and type from `LingAfriqType`. It loads bundled Andika, `LingAfriqText`, and `LingAfriqDisplay`, and paints at 390 px. The PNG files are the only images that test compares. Updating them does not touch any other golden.

| Acceptance | Result |
| --- | --- |
| AC1. Today shows one 10 to 15 minute plan with due reviews, the next lesson, and one speaking moment, and the minute estimate is visible. | Met. `today-light.png` shows `12 minutes`, the three parts, and one Start button. |
| AC2. Light and dark frames at 390 px, and a 200% text frame, exported under `docs/build/design/screens/`. | Met when the PNG files from the test exist and are 390 px wide. |
| AC3. Every colour, size, font, and radius references a token. None is hard-coded. | Met in this spec. No hex values. Sizes and radii cite `LingAfriqTokens` or `type.*`. Fonts cite `LingAfriqType`. Colours cite ramp roles. |
| AC4. Skeleton, empty, error, offline, and reduced-motion frames are included. | Met when those PNG files exist. Each screen has them, named in the sections above. |
| AC5. A T4 reviewer records visual approval in the card report. | Unmet. The frames are ready to check. No T4 approval is recorded. |

`docs/plan/CARD_STATUS.tsv` stays `Draft` because AC5 is unmet.

Exported files:

- `docs/build/design/screens/today-light.png`
- `docs/build/design/screens/today-dark.png`
- `docs/build/design/screens/today-200.png`
- `docs/build/design/screens/today-skeleton.png`
- `docs/build/design/screens/today-empty.png`
- `docs/build/design/screens/today-error.png`
- `docs/build/design/screens/today-offline.png`
- `docs/build/design/screens/today-reduced.png`
- `docs/build/design/screens/path-light.png`
- `docs/build/design/screens/path-dark.png`
- `docs/build/design/screens/path-200.png`
- `docs/build/design/screens/path-skeleton.png`
- `docs/build/design/screens/path-empty.png`
- `docs/build/design/screens/path-error.png`
- `docs/build/design/screens/path-offline.png`
- `docs/build/design/screens/path-reduced.png`
- `docs/build/design/screens/lesson-light.png`
- `docs/build/design/screens/lesson-dark.png`
- `docs/build/design/screens/lesson-200.png`
- `docs/build/design/screens/lesson-skeleton.png`
- `docs/build/design/screens/lesson-empty.png`
- `docs/build/design/screens/lesson-error.png`
- `docs/build/design/screens/lesson-offline.png`
- `docs/build/design/screens/lesson-reduced.png`
