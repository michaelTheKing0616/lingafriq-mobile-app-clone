# Wireflows for Play, Village, and Me

Status: Approved. Review recorded below. `docs/plan/CARD_STATUS.tsv` marks P3-032 Done.

## Flow review

Checked on 21 November 2026.

- Play, Village, and Me each list every destination with an entry, a back path, and an empty next step. Games are the fourteen names already on the Arcade spec. Tone Forge and Verify stay off the rows because those specs do not list them.
- The farthest rows are 2 taps. The Arcade, the Village map, and Profile are the hub roots.
- Search and Lens are on the top bar of every hub. Word Card is a long press, not a tab. Back returns to that hub's root.
- Clips shows Locked and Unlocks at A2. Create shows Locked and Unlocks at B1. An adult can preview and open anyway. Open anyway does not mark the earlier lesson done.
- A minor, under 13, does not get Open anyway on Chats, Square, Radio, Clips, or Create. Those paths say a guardian must open them. The guardian screens are not drawn. Leagues has no rank. Plus has no payment.

These written flows are the drawing. Approval stands.

This is a navigation spec. It does not change the app.

Sources: `docs/source/ELEVATION.md` §17.1 (lines 2190-2228) and the sitemap (lines 2260-2278). Age assurance is §5.2 (lines 1054-1060). Unlocking is §17.4 (lines 2308-2320). Shelves, games, and places follow `docs/build/design/screens/village_arcade_polie.md`. Me and the wardrobe follow `docs/build/design/screens/profile_celebrate_firstword.md`. The counting rules follow `docs/build/design/WIREFLOWS_TODAY_LEARN_SPEAK.md`.

## How to count a tap

The hub root is tap 0. A control on that root is 1 tap. A control on the next screen is 2 taps. Every destination in the tables below is inside that limit.

Back on a destination returns to that hub's root. The button is `Back to Play`, `Back to Village`, or `Back to Me`.

Search and Lens are the global top bar on every hub. Search is the search control. Lens is the camera button. Word Card opens from a long press on a target-language word. It is not a tab.

An empty state names one next step, in plain grade 7 English.

A second-level screen uses the same Back button. A game, a search result, Live Translate, and Import Media all return to the hub root.

A locked place shows the word Locked and the unlock line. It also shows Preview. An adult can tap Open anyway. Open anyway does not mark the earlier lesson done. On the Village list, Preview and Open anyway sit on the place row. Each of those is 1 tap from the Village root. On All features, the same controls are the second tap.

## Play

The Play root is the Arcade. The sitemap calls this root Arcade shelves. The tree lists the seven shelves in order. The Arcade spec writes the first shelf as Tone & Sound.

The Arcade picture shows the shelves on one page. This flow still counts a shelf as the first tap and a game as the second tap.

A game name comes from the Arcade spec. This flow uses only those game names. Tone Forge is a sitemap name, and it is not one of those games.

Search and Lens are the top bar. Word Card is a long press, not a tab.

An empty shelf names one next step.

```
Play root (the Arcade)
  Tone and Sound
    Tone Trainer
    Word Match (audio)
  Words
    Word Match
    Memory Map
  Grammar
    Fill in the Blank
    Grammar Detective
  Speaking
    Market Bargaining
    Pronunciation Duel
  Culture
    Proverb Unlocker
    Quiz Chef
  Traditional
    Ayo (mancala)
    Snakes & Ladders (cultural)
  Multiplayer
    Conversation Relay
    Liar Liar
  Search (top bar)
  Lens (top bar camera)
    Point & Say
    Live Translate
    Import Media
  Word Card (long press on a target-language word)
```

### Arcade shelves

- Enter: Open the Play tab. On this hub, the root is the Arcade. 0 taps from the root.
- Back: This is the root. The seven shelves return here.
- Empty: No games yet. Next step: Try again. Button: `Try again`.

### Tone and Sound

Tone Trainer is one game. Word Match (audio) is the other game. A game is the second tap.

- Enter: On the Arcade root, tap Tone and Sound. 1 tap.
- Back: `Back to Play`. A game uses the same button.
- Empty: This shelf has no game. Next step: Open the Arcade.
- A game with nothing in it. Next step: Open Tone and Sound.

### Words

Word Match is one game. Memory Map is the other game. A game is the second tap. Word Match (audio) is on Tone and Sound.

- Enter: On the Arcade root, tap Words. 1 tap.
- Back: `Back to Play`. A game uses the same button.
- Empty: This shelf has no game. Next step: Open the Arcade.
- A game with nothing in it. Next step: Open Words.

### Grammar

Fill in the Blank is one game. Grammar Detective is the other game. A game is the second tap.

- Enter: On the Arcade root, tap Grammar. 1 tap.
- Back: `Back to Play`. A game uses the same button.
- Empty: This shelf has no game. Next step: Open the Arcade.
- A game with nothing in it. Next step: Open Grammar.

### Speaking

Market Bargaining is one game on this shelf. You can tap Pronunciation Duel on this shelf when you want that game. A game is the second tap.

- Enter: On the Arcade root, tap Speaking. 1 tap.
- Back: `Back to Play`. A game uses the same button.
- Empty: This shelf has no game. Next step: Open the Arcade.
- A game with nothing in it. Next step: Open Speaking.

### Culture

Proverb Unlocker is one game. Quiz Chef is the other game. A game is the second tap.

- Enter: On the Arcade root, tap Culture. 1 tap.
- Back: `Back to Play`. A game uses the same button.
- Empty: This shelf has no game. Next step: Open the Arcade.
- A game with nothing in it. Next step: Open Culture.

### Traditional

Ayo (mancala) is one game. Snakes & Ladders (cultural) is the other game here. A game is the second tap. The shelf name is Traditional.

- Enter: On the Arcade root, tap Traditional. 1 tap.
- Back: `Back to Play`. A game uses the same button.
- Empty: This shelf has no game. Next step: Open the Arcade.
- A game with nothing in it. Next step: Open the Traditional shelf.

### Multiplayer

Conversation Relay is one game on this shelf. Liar Liar is the other game. A game is the second tap. The Arcade spec places those two names here only.

- Enter: On the Arcade root, tap Multiplayer. 1 tap.
- Back: `Back to Play`. A game uses the same button.
- Empty: This shelf has no game. Next step: Open the Arcade.
- A game with nothing in it. Next step: Open the Multiplayer shelf.

### Tone Forge

The sitemap names Tone Forge under Play. The Arcade spec does not list this name on a shelf. This flow does not add a game.

- Enter: There is no Tone Forge row on the Arcade or on Tone and Sound. It is not a tap.
- Back: No Tone Forge screen is drawn, so this flow has no Back button for it.
- Empty: No game by this name is on a shelf. Next step: Open Tone and Sound.

### Search, Lens, and Word Card on Play

Search and Lens are the top bar. Word Card is a long press, not a tab.

- Search. Enter: tap Search in the top bar. 1 tap. Back: `Back to Play`. Empty: the box is empty. Next step: Type a word or a feature name. A word opens the Word Card. A game or a named item in this card opens that item, and Back returns to the Play root. Search does not open Tone Forge. People, circles, and lessons open on their own hubs. This card does not redraw those screens.
- Lens. Enter: tap the camera button in the top bar. 1 tap. The screen opens on Point & Say. Live Translate and Import Media are the second tap on that same screen. Live Translate is the Conversation Bridge. Back: `Close` returns to the Play root. Empty: the camera sees no object. Next step: Point at one thing, or use Import Media. Button: `Point again`.
- Word Card. Enter: long-press a target-language word. This is not a tab. Search can open this same card in 2 taps. Back: `Close` returns to the screen you were on, and that screen's Back returns to the Play root. Empty: no word is open. Next step: Long-press a target-language word. Button: `Show a word`.

### Play tap count

Taps are counted from the Play root.

| Destination | Taps | Path |
| --- | --- | --- |
| Arcade shelves | 0 | Play root |
| Tone and Sound | 1 | Play root, then Tone and Sound |
| Tone Trainer | 2 | Play root, Tone and Sound, then Tone Trainer |
| Word Match (audio) | 2 | Play root, Tone and Sound, then Word Match (audio) |
| Words | 1 | Play root, then Words |
| Word Match | 2 | Play root, Words, then Word Match |
| Memory Map | 2 | Play root, Words, then Memory Map |
| Grammar | 1 | Play root, then Grammar |
| Fill in the Blank | 2 | Play root, Grammar, then Fill in the Blank |
| Grammar Detective | 2 | Play root, Grammar, then Grammar Detective |
| Speaking | 1 | Play root, then Speaking |
| Market Bargaining | 2 | Play root, Speaking, then Market Bargaining |
| Pronunciation Duel | 2 | Play root, Speaking, then Pronunciation Duel |
| Culture | 1 | Play root, then Culture |
| Proverb Unlocker | 2 | Play root, Culture, then Proverb Unlocker |
| Quiz Chef | 2 | Play root, Culture, then Quiz Chef |
| Traditional | 1 | Play root, then Traditional |
| Ayo (mancala) | 2 | Play root, Traditional, then Ayo (mancala) |
| Snakes & Ladders (cultural) | 2 | Play root, Traditional, then Snakes & Ladders (cultural) |
| Multiplayer | 1 | Play root, then Multiplayer |
| Conversation Relay | 2 | Play root, Multiplayer, then Conversation Relay |
| Liar Liar | 2 | Play root, Multiplayer, then Liar Liar |
| Tone Forge | not a row | Sitemap name only. The Arcade spec does not list this game. |
| Search | 1 | Top bar Search |
| A search result in this card | 2 | Search, then the result |
| Lens (Point & Say) | 1 | Top bar camera. Opens on Point & Say |
| Live Translate | 2 | Lens, then Live Translate |
| Import Media | 2 | Lens, then Import Media |
| Word Card | long press | Long-press a target-language word |

## Village

The Village root is the place list. The sitemap calls this root the Village map. Village is a list of places. It is not a decorative map drawing.

The tree lists the places in this order. The first places are Circles, Square, Chats, and Status. Then come Clips, Radio, School, and Elder Hut. Corrections and Create are last.

Search and Lens are the top bar. Word Card is a long press, not a tab.

Age assurance runs before this list. Under 13 goes to the guardian flow. This spec marks that gate. It does not draw the guardian screens.

A minor here means under 13. A minor does not get Open anyway on five paths. The paths are Chats, Square, Radio, Clips, and Create. Those five paths are guardian-gated. The minor sees the word Locked and the button Preview. The line is `A guardian must open this.`

Clips unlocks at A2. Create unlocks at B1. A2 and B1 are level names. They are not scores. A locked place shows the word Locked and the unlock line. It also shows Preview. An adult can tap Open anyway. Open anyway does not mark the earlier lesson done.

```
Age assurance
  Under 13: guardian flow (not drawn)
Village root (the place list, the Village map)
  Circles
  Square
  Chats
  Status
  Clips (locked, Unlocks at A2)
  Radio
  School
  Elder Hut
  Corrections
  Create (locked, Unlocks at B1)
  Search (top bar)
  Lens (top bar camera)
    Point & Say
    Live Translate
    Import Media
  Word Card (long press on a target-language word)
```

### Village map

- Enter: Open the Village tab. On this hub, the root is the place list. 0 taps from the root. Age assurance runs first. Under 13 goes to the guardian flow. That flow is not drawn.
- Back: This is the root. The places return here.
- Empty: No places yet. Next step: Try again. Button: `Try again`.

### Circles

- Enter: On the Village root, tap Circles. 1 tap.
- Back: `Back to Village`.
- Empty: No circle yet. Next step: Open the Village map.

### Square

- Enter: On the Village root, tap Square. 1 tap. The adult control is `Open Square`.
- For a minor, the row shows the word Locked and the button Preview. The line is `A guardian must open this.` A minor does not get Open anyway. This path is guardian-gated. The guardian screens are not drawn.
- Back: `Back to Village`. Preview uses the same button.
- Empty: The feed has no post yet. Next step: Open the Village map.

### Chats

- Enter: On the Village root, tap Chats. 1 tap. This row does not open a private conversation.
- For a minor, the row shows the word Locked and the button Preview. The line is `A guardian must open this.` A minor does not get Open anyway. This path is guardian-gated. The guardian screens are not drawn.
- Back: `Back to Village`. Preview uses the same button.
- Empty: No chat is waiting. Next step: Open the Village map.

### Status

- Enter: On the Village root, tap Status. 1 tap.
- Back: `Back to Village`.
- Empty: No status yet. Next step: Open the Village map.

### Clips

Clips is locked until A2. The unlock line is `Unlocks at A2.`

- Enter: On the Village root, tap Clips. 1 tap. The row shows the word Locked and the line `Unlocks at A2.` An adult can tap Preview. An adult can tap Open anyway to open Clips. It does not mark the earlier lesson done.
- A minor does not get Open anyway. The minor sees Locked, Preview, and the line `A guardian must open this.` This path is guardian-gated. The guardian screens are not drawn. The level does not remove that gate.
- Back: `Back to Village`. Preview uses the same button.
- Empty: No clip yet. Next step: Open the Village map.

### Radio

- Enter: On the Village root, tap Radio. 1 tap.
- For a minor, the row shows the word Locked and the button Preview. The line is `A guardian must open this.` A minor does not get Open anyway. This path is guardian-gated. The guardian screens are not drawn.
- Back: `Back to Village`. Preview uses the same button.
- Empty: No show is on. Next step: Open the Village map.

### School

- Enter: On the Village root, tap School. 1 tap.
- Back: `Back to Village`.
- Empty: No class yet. Next step: Open the Village map.

### Elder Hut

- Enter: On the Village root, tap Elder Hut. 1 tap.
- Back: `Back to Village`.
- Empty: No mentor talk yet. Next step: Open the Village map.

### Corrections

- Enter: On the Village root, tap Corrections. 1 tap.
- Back: `Back to Village`.
- Empty: No correction yet. Next step: Open the Village map.

### Create

Create is locked until B1. The unlock line is `Unlocks at B1.`

- Enter: On the Village root, tap Create. 1 tap. The row shows the word Locked and the line `Unlocks at B1.` An adult can tap Preview. An adult can tap Open anyway to open Create. It does not mark the earlier lesson done.
- A minor does not get Open anyway. The minor sees Locked, Preview, and the line `A guardian must open this.` This path is guardian-gated. The guardian screens are not drawn. The level does not remove that gate.
- Back: `Back to Village`. Preview uses the same button.
- Empty: Nothing to make yet. Next step: Open the Village map.

### Verify

The sitemap puts Verify on the Create line. The Village place list does not include Verify. This flow does not add a place.

- Enter: There is no Verify row. It is not a tap.
- Back: No Verify screen is drawn, so this flow has no Back button for it.
- Empty: Nothing to check on this list. Next step: Open Create.

### Search, Lens, and Word Card on Village

Search and Lens are the top bar. Word Card is a long press, not a tab.

- Search. Enter: tap Search in the top bar. 1 tap. Back: `Back to Village`. Empty: the box is empty. Next step: Type a word or a feature name. A word opens the Word Card. A person, a circle, or a place in this card opens that item, and Back returns to the Village root. A guardian-gated place stays gated for a minor. Search does not open Verify. Games and lessons open on their own hubs. This card does not redraw those screens.
- Lens. Enter: tap the camera button in the top bar. 1 tap. The screen opens on Point & Say. Live Translate and Import Media are the second tap on that same screen. Live Translate is the Conversation Bridge. Back: `Close` returns to the Village root. Empty: the camera sees no object. Next step: Point at one thing, or use Import Media. Button: `Point again`.
- Word Card. Enter: long-press a target-language word. This is not a tab. Search can open this same card in 2 taps. Back: `Close` returns to the screen you were on, and that screen's Back returns to the Village root. Empty: no word is open. Next step: Long-press a target-language word. Button: `Show a word`.

### Village tap count

Taps are counted from the Village root.

| Destination | Taps | Path |
| --- | --- | --- |
| Under 13 gate | before the root | Age assurance. The guardian flow is not drawn. |
| Village map | 0 | Village root, the place list |
| Circles | 1 | Village root, then Circles |
| Square | 1 | Village root, then Square. Guardian-gated for a minor. |
| Chats | 1 | Village root, then Chats. Guardian-gated for a minor. |
| Status | 1 | Village root, then Status |
| Clips | 1 | Village root, then Clips. Locked. Unlocks at A2. Guardian-gated for a minor. |
| Radio | 1 | Village root, then Radio. Guardian-gated for a minor. |
| School | 1 | Village root, then School |
| Elder Hut | 1 | Village root, then Elder Hut |
| Corrections | 1 | Village root, then Corrections |
| Create | 1 | Village root, then Create. Locked. Unlocks at B1. Guardian-gated for a minor. |
| Verify | not a row | Sitemap name only. The place list does not include Verify. |
| Search | 1 | Top bar Search |
| A search result in this card | 2 | Search, then the result |
| Lens (Point & Say) | 1 | Top bar camera. Opens on Point & Say |
| Live Translate | 2 | Lens, then Live Translate |
| Import Media | 2 | Lens, then Import Media |
| Word Card | long press | Long-press a target-language word |

## Me

The Me root is Profile. The sitemap calls it Profile and avatar. Wardrobe is the avatar row.

The tree lists every Me row in order. The sitemap names Leagues and Plus, so both rows are here.

Search and Lens are the top bar. Word Card is a long press, not a tab.

Wardrobe is optional, and you can set it up after lesson 2.

This hub does not show a league rank, XP, a percent, or a payment checkout. The empty path for Leagues has no rank. The empty path for Plus has no payment.

```
Me root (Profile)
  Wardrobe
  Progress
  Achievements
  Leagues
  Family
  Plus
  Settings
  All features
  About
  Search (top bar)
  Lens (top bar camera)
    Point & Say
    Live Translate
    Import Media
  Word Card (long press on a target-language word)
```

### Profile

- Enter: Open Me. On this hub, the root is Profile. 0 taps from the root. The avatar can wait until after lesson 2. `Skip for now` stays on this root.
- Back: This is the root. The rows return here.
- Empty: No profile yet. Next step: Say the first word. Button: `Say the first word`.

### Wardrobe

Wardrobe is optional, and you can set it up after lesson 2. The screen says this is optional. Head wrap, Short hair, and No portrait stay on this screen. A look is not a new screen.

- Enter: On the Me root, tap Wardrobe. 1 tap.
- Back: `Back to Me`.
- Empty: No look is chosen yet. Next step: Skip for now. Button: `Skip for now`.

### Progress

Progress is words. A filled row can say `Morning greetings.` This path shows no percent and no XP.

- Enter: On the Me root, tap Progress. 1 tap.
- Back: `Back to Me`.
- Empty: No words yet. Next step: Say the first word.

### Achievements

A filled row can say you said a greeting. This path shows no XP.

- Enter: On the Me root, tap Achievements. 1 tap.
- Back: `Back to Me`.
- Empty: No achievement yet. Next step: Say the first word.

### Leagues

The sitemap names Leagues, so the row is on the Me root. This path has no rank.

- Enter: On the Me root, tap Leagues. 1 tap.
- Back: `Back to Me`.
- Empty: No league is open. This path has no rank. Next step: Open Progress.

### Family

This row does not draw the guardian screens.

- Enter: On the Me root, tap Family. 1 tap.
- Back: `Back to Me`.
- Empty: No one is linked. Next step: Open Profile.

### Plus

The sitemap names Plus, so the row is on the Me root. This path has no payment. It does not show a payment checkout.

- Enter: On the Me root, tap Plus. 1 tap.
- Back: `Back to Me`.
- Empty: Nothing to add here. This path has no payment. Next step: Open All features.

### Settings

A filled row can say `Sound and text.`

- Enter: On the Me root, tap Settings. 1 tap.
- Back: `Back to Me`.
- Empty: Nothing to change yet. Next step: Open Profile.

### All features

`All features` is the button on the Me root. A locked row on that screen shows the word Locked and the unlock line. It also shows Preview. An adult can tap Open anyway. That row is the second tap. Open anyway does not mark the earlier lesson done. A minor still has no Open anyway on five rows. The five rows are Chats, Square, Radio, Clips, and Create.

- Enter: On the Me root, tap All features. 1 tap.
- Back: `Back to Me`. A locked row uses the same button.
- Empty: No feature is listed. Next step: Open Profile.

### About

- Enter: On the Me root, tap About. 1 tap.
- Back: `Back to Me`.
- Empty: Nothing is written here yet. Next step: Open Profile.

### Search, Lens, and Word Card on Me

Search and Lens are the top bar. Word Card is a long press, not a tab.

- Search. Enter: tap Search in the top bar. 1 tap. Back: `Back to Me`. Empty: the box is empty. Next step: Type a word or a feature name. A word opens the Word Card. A named item in this card opens that item, and Back returns to the Me root. Games, people, and circles open on their own hubs. This card does not redraw those screens.
- Lens. Enter: tap the camera button in the top bar. 1 tap. The screen opens on Point & Say. Live Translate and Import Media are the second tap on that same screen. Live Translate is the Conversation Bridge. Back: `Close` returns to the Me root. Empty: the camera sees no object. Next step: Point at one thing, or use Import Media. Button: `Point again`.
- Word Card. Enter: long-press a target-language word. This is not a tab. Search can open this same card in 2 taps. Back: `Close` returns to the screen you were on, and that screen's Back returns to the Me root. Empty: no word is open. Next step: Long-press a target-language word. Button: `Show a word`.

### Me tap count

Taps are counted from the Me root.

| Destination | Taps | Path |
| --- | --- | --- |
| Profile | 0 | Me root |
| Wardrobe | 1 | Me root, then Wardrobe |
| Progress | 1 | Me root, then Progress |
| Achievements | 1 | Me root, then Achievements |
| Leagues | 1 | Me root, then Leagues. The empty path has no rank. |
| Family | 1 | Me root, then Family |
| Plus | 1 | Me root, then Plus. The empty path has no payment. |
| Settings | 1 | Me root, then Settings |
| All features | 1 | Me root, then All features |
| A locked row on All features | 2 | Me root, All features, then that row |
| About | 1 | Me root, then About |
| Search | 1 | Top bar Search |
| A search result in this card | 2 | Search, then the result |
| Lens (Point & Say) | 1 | Top bar camera. Opens on Point & Say |
| Live Translate | 2 | Lens, then Live Translate |
| Import Media | 2 | Lens, then Import Media |
| Word Card | long press | Long-press a target-language word |

## What is in two taps

Every sitemap item for Play, Village, and Me is in the tables above. A tappable destination is within two taps of its hub root. The farthest rows are 2 taps: a game, a search result, Live Translate, and Import Media. Word Card uses a long press. It is not a tab.

Tone Forge is in the Play table. The Arcade spec does not name it, so it is not a game row. Verify is in the Village table. The place list does not name it, so it is not a place row.

Locked paths are Clips and Create. Clips shows `Unlocks at A2.` Create shows `Unlocks at B1.` An adult sees the word Locked and the unlock line. An adult can tap Preview. An adult can tap Open anyway. Open anyway does not mark the earlier lesson done.

Five paths are guardian-gated for a minor. The paths are Chats, Square, Radio, Clips, and Create. A minor does not get Open anyway on those five. The minor sees the word Locked and Preview. The line is `A guardian must open this.` Under 13 goes to the guardian flow before the Village map. That flow is not drawn.
