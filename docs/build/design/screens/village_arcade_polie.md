# P3-017 Village map, Arcade shelf, and Polie voice

Status: Draft. A visual reviewer has not approved these frames. `docs/plan/CARD_STATUS.tsv` stays `Draft`.

This is the screen spec for three surfaces:

- Village is a list of places. It is not a decorative map drawing.
- Arcade is the game list. Games sit on skill shelves.
- Polie is the voice screen. The learner holds to talk. Polie speaks back.

Sources: `docs/source/ELEVATION.md` §3.3 (lines 802-813), §17.1 (lines 2183-2201), the sitemap (lines 2251-2275), §17.4 (lines 2309-2318), the Arcade shelves in §18.5 (line 4295), the game homes in §18.5, and Polie (lines 3996-4003). Tokens: `design/tokens/tokens.json` and `lib/design/typography.dart`. Target lines follow `lib/design/text/target_text.dart`: bundled Andika, at least 18 sp, leading 1.5.

These are token frames, not illustrated scenes. The frames do not copy the current village, games, or chat screens.

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
| Card radius | `LingAfriqTokens.radiusmd` |
| Chip radius | `LingAfriqTokens.radiuspill` |
| Strong stroke | `LingAfriqTokens.strokeregular` |
| Display | `type.display`: family `LingAfriqType.displayFamily`, size `type.display.size`, height `type.display.height` |
| Body | `type.body`: family `LingAfriqType.bodyFamily`, size `LingAfriqType.bodySize`, height `LingAfriqType.targetHeight` |
| Target language | `LingAfriqType.target`: family Andika (`LingAfriqType.targetFamily`), size `LingAfriqType.targetSize`, height `LingAfriqType.targetHeight` |

Body and display sit on the real bundled files: `LingAfriqText` (Noto Sans) and `LingAfriqDisplay` (Nunito). Target-language lines sit on bundled Andika. Weight stays the loaded face. Do not invent a second family.

The example target line is `Ẹ kú àárọ̀`. Its gloss on the Polie speaking frame is Good morning. Diacritics stay inside the line box. Nothing clips them.

Product motion tokens (`motion.product` instant, fast, base, slow, and `motion.rare`) are not run on these frames. Reduced motion is the platform flag `MediaQuery.disableAnimations`. The frame does not add animation of its own. The reduced-motion still matches the light data frame, because nothing moves.

## Shared rules

- Width is 390 px. Content scrolls on a phone. The exported image is the full column at 390 px so glyphs are not cut off in the evidence.
- Every control is at least `LingAfriqTokens.spacing48` in both axes and has a visible label. A painted mark also has a semantics label written in this spec.
- Text inside a `surfaceContainer` control uses `onSurface`, because that is the body pair on `surfaceContainer`. `onSurfaceVariant` is used only on the page role `surface`.
- Text uses a body pair from `colorRamps.pairs`. Meaning is never colour alone. Selected has a check and the word On. Locked has a lock and the word Locked. Speaking, listening, and thinking each have a drawn mark and a word. Error has a cross. Offline and AI unavailable use an info mark and words. The mark is drawn, not a font icon.
- Copy is short, grade-7 English. It makes no boastful claim. It uses a period or a comma in place of a long dash. The frames show no score, no percent, no XP, and no confidence number.
- At 200% text, `TextScaler.linear(2)` doubles `type.display`, `type.body`, and `LingAfriqType.target`. Padding, radius, stroke, and the disc box stay on the token scale. Controls grow with the label and stay at least `LingAfriqTokens.spacing48`. Lines wrap inside the 390 px width. No glyph is clipped.
- A disc is a circle. Its box is at least `LingAfriqTokens.spacing48` wide and tall. Padding inside the disc is `LingAfriqTokens.spacing8`. The mark inside is `LingAfriqTokens.spacing24`. Stroke width is `LingAfriqTokens.strokeregular` unless a smaller dot is named.

A quiet control is fill `surfaceContainer`, text `onSurface`, radius `LingAfriqTokens.radiusmd`, padding horizontal `LingAfriqTokens.spacing16` and vertical `LingAfriqTokens.spacing12`, minimum `LingAfriqTokens.spacing48`, full content width. It is not accent.

A filled accent control uses the same padding, radius, and minimum size. Fill `accent`. Text `onAccent`. Body style.

## Village

Village is the list of places from §17.1 and the sitemap. The rows, in order, are Circles, Square, Chats, Status, Clips, Radio, School, Elder Hut, Corrections, and Create.

This frame does not draw a private conversation, a payment, or a minor-safety flow. The Chats row is only the place name.

An open place is one quiet row. The place name is the visible label. A short line sits under the name, in `onSurface`, because the row fill is `surfaceContainer`.

Square is not a quiet row. Its name and line sit on the page. `Open Square` is the only filled accent button.

Clips and Create are locked on this frame. §17.4 opens Clips at A2 and Create at B1. A2 and B1 are level names. They are not scores. A locked place shows the word Locked, a lock mark, the unlock line, and Preview. Preview is a quiet control. It does not use accent. The other places are open on this frame.

### village-light.png

Roles: `colorRamps.modes.light`. Background role `surface`. Padding `LingAfriqTokens.spacing16`. Column, top aligned.

1. Title `Village`. Display style. Role `onSurface`.
2. Gap `LingAfriqTokens.spacing8`. Line `A list of places.` Body style. Role `onSurfaceVariant`.
3. Gap `LingAfriqTokens.spacing16`. Rows. Gap between rows: `LingAfriqTokens.spacing12`.

**Circles.** Quiet row. Name `Circles`. Line `Study teams.` Semantics `Open Circles`.

**Square.** Name `Square` in body, role `onSurface`. Gap `LingAfriqTokens.spacing4`. Line `The feed and the rooms.` in body, role `onSurfaceVariant`. Gap `LingAfriqTokens.spacing8`. Button `Open Square`. Fill `accent`. Text `onAccent`. Semantics `Open Square`.

**Chats.** Quiet row. Name `Chats`. Line `Messages in the village.` Semantics `Open Chats`. This row does not open a conversation.

**Status.** Quiet row. Name `Status`. Line `A daily post in the language.` Semantics `Open Status`.

**Clips. Locked.** Disc fill `surfaceContainer`, lock mark in `onSurface`. Gap from the disc to the text: `LingAfriqTokens.spacing12`. Name `Clips` in body, role `onSurface`. Gap `LingAfriqTokens.spacing4`. Word `Locked` in body, role `onSurfaceVariant`. Gap `LingAfriqTokens.spacing4`. Line `Unlocks at A2.` in body, role `onSurfaceVariant`. Gap from the text block to the button: `LingAfriqTokens.spacing8`. Button `Preview`. Quiet. Semantics `Preview Clips`. The row semantics for the text block: `Clips, locked. Unlocks at A2.`

**Radio.** Quiet row. Name `Radio`. Line `Audio shows.` Semantics `Open Radio`.

**School.** Quiet row. Name `School`. Line `A class with a teacher.` Semantics `Open School`.

**Elder Hut.** Quiet row. Name `Elder Hut`. Line `A short talk with a mentor.` Semantics `Open Elder Hut`.

**Corrections.** Quiet row. Name `Corrections`. Line `A native speaker can correct you.` Semantics `Open Corrections`.

**Create. Locked.** Same lock row as Clips. Name `Create`. Word `Locked`. Line `Unlocks at B1.` Button `Preview`. Semantics `Preview Create`. Text-block semantics: `Create, locked. Unlocks at B1.`

`Open Square` is the only filled accent button.

### village-dark.png

Same layout, copy, type, and spacing as `village-light.png`. Roles come from `colorRamps.modes.dark`.

### village-200.png

Same as `village-light.png` at 200% text. Place names and unlock lines wrap inside 390 px. Every row and every Preview stays at least `LingAfriqTokens.spacing48`. `Open Square` stays the only filled accent button.

### Village state frames

Same page padding, type, and role pairs.

**village-skeleton.png.** Visible word `Loading` in body, role `onSurfaceVariant`. Semantics label: `Loading the village`. Under it, one block of height `LingAfriqTokens.spacing32`, then ten blocks of height `LingAfriqTokens.spacing48`. Fill `surfaceContainer`. Radius `LingAfriqTokens.radiusmd`. Gap `LingAfriqTokens.spacing12`. No shimmer.

**village-empty.png.** Title `Village`, display, `onSurface`. Then:

- `No places yet` in body, `onSurface`.
- Label `What happened`. Body, `onSurface`. Line `The place list is empty.` Body, `onSurfaceVariant`.
- Label `Why`. Line `No place came back.`
- Label `What to do`. Line `Try again.`
- Button `Try again`. Fill `accent`, text `onAccent`. Semantics label: `Try again`.

Section gap `LingAfriqTokens.spacing16`. Label-to-line gap `LingAfriqTokens.spacing4`. Gap before the button `LingAfriqTokens.spacing24`.

**village-error.png.** Title `Village`. Cue disc fill `danger`, cross in `onDanger`, minimum `LingAfriqTokens.spacing48`. Title line `Village did not load` in body, role `danger` (the body pair `danger` on `surface`).

- `What happened`. `The place list did not open.`
- `Why`. `The list did not come back.`
- `What to do`. `Try again.`
- Button `Try again`. Fill `accent`, text `onAccent`. Semantics label: `Try again`.

**village-offline.png.** Cue disc fill `info`, info mark in `onInfo`. Title line `You are offline` in body, role `info`.

- `What happened`. `The phone has no network.`
- `Why`. `This village list is not saved on the phone.`
- `What to do`. `Connect, then try again.`
- Button `Try again`. Fill `accent`, text `onAccent`. Semantics label: `Try again`.

**village-reduced.png.** The resting list. Same pixels as `village-light.png`. Reduced motion adds no animation, so the still matches the light data frame. `MediaQuery.disableAnimations` is on. No product motion runs.

## Arcade

The Arcade lists games on skill shelves. The shelf order is the order in §17.1 and in this card: Tone & Sound, Words, Grammar, Speaking, Culture, Traditional, Multiplayer.

Each game name already exists in §18.5. This frame does not invent a game. It does not show a score, a percent, or an XP line.

§18.5 names a Multiplayer shelf in the Arcade elevation. No feature there has the home line Play, then Multiplayer. Conversation Relay is homed on the Speaking shelf, and the same section says each person adds a spoken turn. Liar Liar is homed on the Grammar shelf, and the same section calls it a multiplayer grammar game. This frame places those two names on Multiplayer. It does not repeat them on Speaking or Grammar.

The source also says Traditional Games for the Traditional shelf. The row label here is Traditional, which is the shelf name in §17.1.

`Play` is the only filled accent button. It sits on Tone Trainer, the first game of the first shelf. Every other game is a quiet labelled row.

A game row uses `onSurface` for the name and the line, because the row fill is `surfaceContainer`. Tone Trainer is the exception. Its name and line sit on the page, so the line can use `onSurfaceVariant`, and `Play` is the control.

| Shelf | Game | Line | Control |
| --- | --- | --- | --- |
| Tone & Sound | Tone Trainer | Hear a tone and pick the word. | `Play`, accent. Semantics `Play Tone Trainer`. |
| Tone & Sound | Word Match (audio) | Hear a word and match it. | Quiet row. Semantics `Open Word Match (audio)`. |
| Words | Word Match | Match a word to its meaning. | Quiet row. Semantics `Open Word Match`. |
| Words | Memory Map | Turn a tile and hear the word. | Quiet row. Semantics `Open Memory Map`. |
| Grammar | Fill in the Blank | Type the missing word. | Quiet row. Semantics `Open Fill in the Blank`. |
| Grammar | Grammar Detective | Find what is wrong in the sentence. | Quiet row. Semantics `Open Grammar Detective`. |
| Speaking | Market Bargaining | Talk with a trader about a price. | Quiet row. Semantics `Open Market Bargaining`. |
| Speaking | Pronunciation Duel | Say a word with a friend. | Quiet row. Semantics `Open Pronunciation Duel`. |
| Culture | Proverb Unlocker | Put a proverb back together. | Quiet row. Semantics `Open Proverb Unlocker`. |
| Culture | Quiz Chef | Follow a recipe in the language. | Quiet row. Semantics `Open Quiz Chef`. |
| Traditional | Ayo (mancala) | Play the board and answer a word. | Quiet row. Semantics `Open Ayo (mancala)`. |
| Traditional | Snakes & Ladders (cultural) | Move on the board and answer. | Quiet row. Semantics `Open Snakes & Ladders (cultural)`. |
| Multiplayer | Conversation Relay | Each person adds one spoken turn. | Quiet row. Semantics `Open Conversation Relay`. |
| Multiplayer | Liar Liar | Spot the sentence that is wrong. | Quiet row. Semantics `Open Liar Liar`. |

### arcade-light.png

Roles: `colorRamps.modes.light`. Background role `surface`. Padding `LingAfriqTokens.spacing16`. Column, top aligned.

1. Title `Arcade`. Display style. Role `onSurface`.
2. Gap `LingAfriqTokens.spacing8`. Line `Games sit on skill shelves.` Body style. Role `onSurfaceVariant`.
3. Gap `LingAfriqTokens.spacing24`. Shelves, in the table order. Gap between shelves: `LingAfriqTokens.spacing24`.

A shelf heading is body, role `onSurface`. Gap under the heading: `LingAfriqTokens.spacing8`. Gap between the two games: `LingAfriqTokens.spacing12`.

Tone Trainer, under Tone & Sound:

- Name `Tone Trainer` in body, role `onSurface`.
- Gap `LingAfriqTokens.spacing4`. Line `Hear a tone and pick the word.` in body, role `onSurfaceVariant`.
- Gap `LingAfriqTokens.spacing8`. Button `Play`, the filled accent control.

Each other game is one quiet row. The name is the first line. The table line is the second line. Both are body, role `onSurface`.

### arcade-dark.png

Same layout, copy, type, and spacing as `arcade-light.png`. Roles come from `colorRamps.modes.dark`.

### arcade-200.png

Same as `arcade-light.png` at 200% text. Shelf names and game lines wrap inside 390 px. `Play` and every game row stay at least `LingAfriqTokens.spacing48`. `Play` stays the only filled accent button.

### Arcade state frames

**arcade-skeleton.png.** Visible word `Loading` in body, role `onSurfaceVariant`. Semantics label: `Loading the arcade`. Under it, seven groups. Each group is one block of height `LingAfriqTokens.spacing32` and two blocks of height `LingAfriqTokens.spacing48`. Fill `surfaceContainer`. Radius `LingAfriqTokens.radiusmd`. Gap `LingAfriqTokens.spacing12`. No shimmer.

**arcade-empty.png.** Title `Arcade`. `No games yet`.

- `What happened`. `The shelves have no games.`
- `Why`. `No game came back.`
- `What to do`. `Try again.`
- Button `Try again`, accent / `onAccent`. Semantics `Try again`.

**arcade-error.png.** Title `Arcade`. Danger disc with a cross. `Arcade did not load` in role `danger`.

- `What happened`. `The game list did not open.`
- `Why`. `The list did not come back.`
- `What to do`. `Try again.`
- Button `Try again`. Semantics `Try again`.

**arcade-offline.png.** Info disc. `You are offline` in role `info`.

- `What happened`. `The phone has no network.`
- `Why`. `These games are not saved on the phone.`
- `What to do`. `Connect, then try again.`
- Button `Try again`. Semantics `Try again`.

**arcade-reduced.png.** The resting shelves. Same pixels as `arcade-light.png`. Reduced motion adds no animation, so the still matches the light data frame. `MediaQuery.disableAnimations` is on. No product motion runs.

## Polie

Polie is voice first. The learner holds to talk. The data frame is the speaking state. Polie says `Ẹ kú àárọ̀`. The learner sees `Hold to talk`.

The mode chips, in order, are Chat, Explain, Correct me, Roleplay, Story, and Translate. Chat is selected. Selection is a check plus the word On, and a stroke. It is not colour alone.

A chip is full content width. Fill `surfaceContainer`. Text `onSurface`. Radius `LingAfriqTokens.radiuspill`. Padding horizontal `LingAfriqTokens.spacing16`, vertical `LingAfriqTokens.spacing12`. Minimum `LingAfriqTokens.spacing48`. Text aligns to the start. Gap between chips: `LingAfriqTokens.spacing8`.

The selected chip adds a stroke `LingAfriqTokens.strokeregular` in `onSurface`, a check in `onSurface` at `LingAfriqTokens.spacing24`, and the word `On` under the name. Semantics `Chat, on`. The other chips have no stroke, no check, and no On. Semantics are the chip name: `Explain`, `Correct me`, `Roleplay`, `Story`, `Translate`.

### Header

The header is a disc plus words. The disc fill is `surfaceContainer`. The mark is `onSurface`. The word is body, role `onSurface`. The line under the word is body, role `onSurfaceVariant`. Gap from the disc to the words: `LingAfriqTokens.spacing12`.

| State | Word | Mark | Line |
| --- | --- | --- | --- |
| Speaking | Speaking | Two arcs, open to the right | Polie is speaking. |
| Listening | Listening | A mic | You are talking. |
| Thinking | Thinking | Three dots in a row | Polie is thinking. |

The speaking frame and the listening frame are exported. Thinking uses this same header. This card does not export a thinking still. The three states stay distinct without colour, because each one has its own word and its own mark.

The speaking mark does not pulse. The listening mark does not move.

### polie-light.png

This is the speaking state. Roles: `colorRamps.modes.light`. Background role `surface`. Padding `LingAfriqTokens.spacing16`. Column, top aligned.

1. Title `Polie`. Display style. Role `onSurface`.
2. Gap `LingAfriqTokens.spacing8`. Line `Talk with Polie.` Body, role `onSurfaceVariant`.
3. Gap `LingAfriqTokens.spacing16`. Speaking header. Disc semantics: `Polie is speaking`.
4. Gap `LingAfriqTokens.spacing16`. The six chips. Chat is On.
5. Gap `LingAfriqTokens.spacing16`. Label `Polie says`. Body, role `onSurface`.
6. Gap `LingAfriqTokens.spacing4`. `Ẹ kú àárọ̀` in `LingAfriqType.target`, role `onSurface`. The line box uses `LingAfriqType.targetHeight` so the tone marks stay visible.
7. Gap `LingAfriqTokens.spacing4`. Line `Good morning.` Body, role `onSurfaceVariant`.
8. Gap `LingAfriqTokens.spacing24`. Button `Hold to talk`. Fill `accent`. Text `onAccent`. Semantics `Hold to talk to Polie`.

`Hold to talk` is the only filled accent button.

### polie-dark.png

Same layout, copy, type, and spacing as `polie-light.png`. Roles come from `colorRamps.modes.dark`. This is still the speaking state.

### polie-200.png

Same as `polie-light.png` at 200% text. `Ẹ kú àárọ̀` stays fully visible. Chip labels wrap inside 390 px. `Hold to talk` stays at least `LingAfriqTokens.spacing48`. The target line is still Andika at the `LingAfriqType.target` token, scaled by `TextScaler.linear(2)`.

### polie-listening.png

Light roles only. This extra state is not repeated in dark or at 200%.

Same title, subtitle, and chips as `polie-light.png`. Chat stays On.

The header is the listening row. Disc semantics: `Polie is listening`. Word `Listening`. Line `You are talking.`

Gap `LingAfriqTokens.spacing16` after the chips. Line `Polie is listening.` Body, role `onSurface`. This frame does not show `Ẹ kú àárọ̀`. Polie has not answered yet.

Gap `LingAfriqTokens.spacing24`. Button `Stop`. Fill `accent`. Text `onAccent`. Semantics `Stop talking`. `Stop` is the only filled accent button on this frame.

### polie-ai-unavailable.png

Light roles only. This extra state is not repeated in dark or at 200%.

The screen is open, and the reply did not come. This frame does not show `Ẹ kú àárọ̀`. It does not invent a line for Polie.

1. Title `Polie`. Display, `onSurface`.
2. Gap `LingAfriqTokens.spacing16`. The six chips. Chat stays On. The learner can see the mode, and still has no reply.
3. Gap `LingAfriqTokens.spacing16`. Cue disc fill `info`, info mark in `onInfo`.
4. Gap `LingAfriqTokens.spacing12`. Title line `Polie is not available` in body, role `info`.
5. Gap `LingAfriqTokens.spacing16`. `What happened`. Line `No reply came back.`
6. `Why`. Line `The tutor cannot answer right now.`
7. `What to do`. Line `Try again later. Polie did not speak for you.`
8. Gap `LingAfriqTokens.spacing24` before the button. Button `Try again`. Fill `accent`. Text `onAccent`. Semantics `Try again`.

Section labels use the same gap as the other notice frames: `LingAfriqTokens.spacing16` between facts, `LingAfriqTokens.spacing4` between a label and its line.

### Polie state frames

The speaking frame is the data frame. These five are the state kit. Empty, error, and offline do not show `Ẹ kú àárọ̀`.

**polie-skeleton.png.** Visible word `Loading` in body, role `onSurfaceVariant`. Semantics label: `Loading Polie`. Under it, one block of height `LingAfriqTokens.spacing32`, then nine blocks of height `LingAfriqTokens.spacing48`. Fill `surfaceContainer`. Radius `LingAfriqTokens.radiusmd`. Gap `LingAfriqTokens.spacing12`. The blocks stand in for the title, the header, the six chips, the reply, and the button. No shimmer.

**polie-empty.png.** Title `Polie`. The six chips stay, and Chat stays On. There is no speaking header and no reply.

- `No reply yet` in body, `onSurface`.
- `What happened`. `Polie has not spoken.`
- `Why`. `You have not held to talk.`
- `What to do`. `Hold to talk when you are ready.`
- Button `Hold to talk`. Fill `accent`, text `onAccent`. Semantics `Hold to talk to Polie`.

**polie-error.png.** Title `Polie`. Danger disc with a cross. `Polie did not open` in role `danger`. The chips are not shown, because the screen did not open.

- `What happened`. `The voice screen did not load.`
- `Why`. `The tutor screen did not come back.`
- `What to do`. `Try again.`
- Button `Try again`. Semantics `Try again`.

**polie-offline.png.** Title `Polie`. Info disc. `You are offline` in role `info`. No chips. No reply.

- `What happened`. `The phone has no network.`
- `Why`. `Polie needs the network to answer.`
- `What to do`. `Connect, then try again.`
- Button `Try again`. Semantics `Try again`.

**polie-reduced.png.** The resting speaking frame. Same pixels as `polie-light.png`. Reduced motion adds no animation, so the still matches the light data frame. `MediaQuery.disableAnimations` is on. The header mark does not pulse. No product motion runs.

## Accessibility

- Minimum control size is `LingAfriqTokens.spacing48`.
- Every control in this spec has a visible label and a semantics label. Painted cues (check, lock, cross, info mark, arcs, mic, dots) sit beside words.
- Body text uses a `colorRamps.pairs` row whose level is `body` (4.5:1). The pairs used are `onSurface` on `surface`, `onSurface` on `surfaceContainer`, `onSurfaceVariant` on `surface`, `onAccent` on `accent`, `onDanger` on `danger`, `danger` on `surface`, `onInfo` on `info`, and `info` on `surface`.
- Target lines use `LingAfriqType.target`. The line box uses that leading so the tone marks stay visible.
- 200% text wraps. It does not clip.
- Reduced motion runs no extra animation. Duration is not taken from `motion.product` or `motion.rare`. The reduced-motion still matches the light data frame.

## Card report

Frames are painted by `test/design/village_arcade_polie_frames_test.dart`. The test loads ramp roles from `design/tokens/tokens.json`, spacing and radius from `LingAfriqTokens`, and type from `LingAfriqType`. It loads bundled Andika, `LingAfriqText`, and `LingAfriqDisplay`, and paints at 390 px. The PNG files are the only images that test compares. Updating them does not touch any other golden.

| Acceptance | Result |
| --- | --- |
| AC1. Games sit on skill shelves (Tone & Sound, Words, Grammar, Speaking, Culture, Traditional, Multiplayer). | Met. `arcade-light.png` shows those seven shelves, in that order, with two named games on each. |
| AC2. Tutor modes appear as chips, and the speaking state, the listening state, and the AI-unavailable state are shown. | Met. `polie-light.png` is speaking, with the six chips and Chat On. `polie-listening.png` and `polie-ai-unavailable.png` are the other two states. |
| AC3. Light and dark frames at 390 px, and a 200% text frame, exported under `docs/build/design/screens/`. | Met when the PNG files from the test exist and are 390 px wide. |
| AC4. Every colour, size, font, and radius references a token. None is hard-coded. | Met in this spec. No hex values. Sizes and radii cite `LingAfriqTokens` or `type.*`. Fonts cite `LingAfriqType`. Colours cite ramp roles. |
| AC5. Skeleton, empty, error, offline, and reduced-motion frames are included. | Met when those PNG files exist. Each surface has them, named in the sections above. |
| AC6. A T4 reviewer records visual approval in the card report. | Unmet. The frames are ready to check. No T4 approval is recorded. |

`docs/plan/CARD_STATUS.tsv` stays `Draft` because AC6 is unmet.

On purpose, this spec does not draw a private conversation, a payment, or a minor-safety flow. It does not draw the For you today shelf or the Classroom shelf. It does not add Contribute, Verify, Market, or Café to the place list. It does not draw Scenarios, Personas, or Shadowing on the Polie frame. The thinking header is specified and is not its own export. Listening and AI unavailable are light only.

Exported files:

- `docs/build/design/screens/village-light.png`
- `docs/build/design/screens/village-dark.png`
- `docs/build/design/screens/village-200.png`
- `docs/build/design/screens/village-skeleton.png`
- `docs/build/design/screens/village-empty.png`
- `docs/build/design/screens/village-error.png`
- `docs/build/design/screens/village-offline.png`
- `docs/build/design/screens/village-reduced.png`
- `docs/build/design/screens/arcade-light.png`
- `docs/build/design/screens/arcade-dark.png`
- `docs/build/design/screens/arcade-200.png`
- `docs/build/design/screens/arcade-skeleton.png`
- `docs/build/design/screens/arcade-empty.png`
- `docs/build/design/screens/arcade-error.png`
- `docs/build/design/screens/arcade-offline.png`
- `docs/build/design/screens/arcade-reduced.png`
- `docs/build/design/screens/polie-light.png`
- `docs/build/design/screens/polie-dark.png`
- `docs/build/design/screens/polie-200.png`
- `docs/build/design/screens/polie-skeleton.png`
- `docs/build/design/screens/polie-empty.png`
- `docs/build/design/screens/polie-error.png`
- `docs/build/design/screens/polie-offline.png`
- `docs/build/design/screens/polie-reduced.png`
- `docs/build/design/screens/polie-listening.png`
- `docs/build/design/screens/polie-ai-unavailable.png`
