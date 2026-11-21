# Wireflows for Today, Learn, and Speak

Status: Approved. Review recorded below. `docs/plan/CARD_STATUS.tsv` marks P3-031 Done.

## Flow review

Checked on 21 November 2026.

- Today, Learn, and Speak each list every sitemap item with an entry, a back path, and an empty next step.
- The farthest destinations are 2 taps: a lesson, Phrase DNA, a Culture shelf row, a Polie chip, a mission, a search result, Live Translate, and Import Media. The daily plan is the Today root, so it is 0 taps.
- Search and Lens are on the top bar of every hub. Word Card is a long press, not a tab.
- Back returns to that hub's root. A second-level screen does not stop on the shelf in between.
- Empty lines are plain and name one next step. No em dash, no banned boast, and no score.

These written flows are the drawing. No separate image was added. Approval stands.

This is a navigation spec. It does not change the app. Village, Play, and Me are a later card.

Sources: `docs/source/ELEVATION.md` §17.1 (lines 2171-2194) and the sitemap (lines 2234-2267). The daily plan and Path follow `docs/build/design/screens/today_path_lesson.md`. Polie and the global tools follow `docs/build/design/screens/village_arcade_polie.md`. Button labels that already ship follow `docs/build/design/COPY_DECK.md`.

## How to count a tap

The hub root is tap 0. A control on that root is 1 tap. A control on the next screen is 2 taps. Every destination in the tables below is inside that limit.

Back on a destination returns to that hub's root. The button is `Back to Today`, `Back to Learn`, or `Back to Speak`.

Search and Lens are the global top bar on every hub. Search is the search control. Lens is the camera button. Word Card opens from a long press on a target-language word. It is not a tab.

An empty state names one next step, in plain grade 7 English.

A second-level screen uses the same Back button. Magazine, Phrase DNA, a lesson, a mission, and a search result all return to the hub root.

## Today

The Today root is the daily plan. The plan holds due reviews, the next lesson, and one speaking moment. `Start` opens that lesson.

```
Today root (the daily plan)
  Start (the lesson for this plan)
  Daily Challenges
  Quests
  Events and Festivals
  Streaks
  Search (top bar)
  Lens (top bar camera)
    Point & Say
    Live Translate
    Import Media
  Word Card (long press on a target-language word)
```

### Daily plan

- Enter: Open the Today tab. On this hub, the root is the plan. 0 taps from the root.
- Back: This is the root. Daily Challenges, Quests, Events and Festivals, and Streaks return here.
- Empty: No plan yet. Next step: Open Path and start the first lesson. Button: `Open Path`.
- `Start` opens the lesson for this plan. That is 1 tap. `Back to Today` returns to this root.

### Daily Challenges

- Enter: On the Today root, tap Daily Challenges. 1 tap.
- Back: `Back to Today`.
- Empty: No challenge is waiting. Next step: Start the daily plan.

### Quests

- Enter: On the Today root, tap Quests. 1 tap.
- Back: `Back to Today`.
- Empty: No quest is waiting. Next step: Start the daily plan.

### Events and Festivals

- Enter: On the Today root, tap Events and Festivals. 1 tap.
- Back: `Back to Today`.
- Empty: No event is on the calendar. Next step: Open the daily plan.

### Streaks

- Enter: On the Today root, tap Streaks. 1 tap.
- Back: `Back to Today`.
- Empty: No streak yet. Next step: Start the daily plan.

### Search, Lens, and Word Card on Today

- Search. Enter: tap Search in the top bar. 1 tap. Back: `Back to Today`. Empty: the box is empty. Next step: Type a word or a feature name. A word opens the Word Card. A lesson or a named item in this card opens that item, and Back returns to the Today root. People, circles, and games are named on Search in §17.1. Those results are a later card.
- Lens. Enter: tap the camera button in the top bar. 1 tap. The screen opens on Point & Say. Live Translate and Import Media are on that same screen. Live Translate is the Conversation Bridge. Each of those two is a second tap, and you stay on Lens. Back: `Close` returns to the Today root. Empty: the camera sees no object. Next step: Point at one thing, or use Import Media. Button: `Point again`.
- Word Card. Enter: long-press a target-language word. This is not a tab. A word result in Search opens this same card (Search, then the word, 2 taps). Back: `Close` returns to the screen you were on. If that screen is not the Today root, its Back returns to the Today root. Empty: no word is open. Next step: Long-press a target-language word. Button: `Show a word`.

### Today tap count

Taps are counted from the Today root.

| Destination | Taps | Path |
| --- | --- | --- |
| Daily plan | 0 | Today root |
| Lesson from the daily plan | 1 | Today root, then `Start` |
| Daily Challenges | 1 | Today root, then Daily Challenges |
| Quests | 1 | Today root, then Quests |
| Events and Festivals | 1 | Today root, then Events and Festivals |
| Streaks | 1 | Today root, then Streaks |
| Search | 1 | Top bar Search |
| A search result in this card | 2 | Search, then the result |
| Lens (Point & Say) | 1 | Top bar camera. Opens on Point & Say |
| Live Translate | 2 | Lens, then Live Translate |
| Import Media | 2 | Lens, then Import Media |
| Word Card | long press | Long-press a target-language word |

## Learn

The Learn root is a list. Path and lessons is the first row. The other Learn items are rows on that same list, each within two taps.

Phrase DNA is the row §17 places with Grammar. Magazine, Heritage, History, Mannerisms, and Cultural Hub are the rows §17.1 places on the Culture shelf. Cultural Hub is one of those rows.

```
Learn root
  Path and lessons
    a lesson
  Lesson Recap
  Words and Review
  Review Rush
  Grammar
    Phrase DNA
  Listening
  Writing
  Tone Gym
  Culture shelf
    Magazine
    Heritage
    History
    Mannerisms
    Cultural Hub
  Passport
  Downloads
  Search (top bar)
  Lens (top bar camera)
    Point & Say
    Live Translate
    Import Media
  Word Card (long press on a target-language word)
```

### Path and lessons

- Enter: On the Learn root, tap Path and lessons. 1 tap.
- A lesson on that screen is the second tap. A locked lesson still offers `See a preview` and `Open the locked lesson`. `Open the locked lesson` opens that lesson.
- Back: `Back to Learn`. The lesson uses the same button.
- Empty: This path has no lessons. Next step: Try again later. Button: `Try again`.
- A lesson with nothing in it uses the lesson empty. Next step: Open Path and choose a lesson. Button: `Open Path`.

### Lesson Recap

- Enter: On the Learn root, tap Lesson Recap. 1 tap. The end of a lesson shows this same screen in place. The recap stays on the lesson you already opened.
- Back: `Back to Learn`.
- Empty: No recap yet. Next step: Open Path and start a lesson.

### Words and Review

- Enter: On the Learn root, tap Words and Review. 1 tap.
- Back: `Back to Learn`.
- Empty: No saved word yet. Next step: Long-press a target-language word and save it.

### Review Rush

- Enter: On the Learn root, tap Review Rush. 1 tap.
- Back: `Back to Learn`.
- Empty: No words are ready. Next step: Open Words and Review.

### Grammar

- Enter: On the Learn root, tap Grammar. 1 tap.
- Phrase DNA is a row on Grammar. That row is the second tap.
- Back: `Back to Learn`. Phrase DNA uses the same button.
- Empty: No pattern yet. Next step: Open Path and start a lesson.
- Phrase DNA empty: no frame yet. Next step: Open Grammar.

### Listening

- Enter: On the Learn root, tap Listening. 1 tap.
- Back: `Back to Learn`.
- Empty: No clip yet. Next step: Open Path and start a lesson.

### Writing

- Enter: On the Learn root, tap Writing. 1 tap.
- Back: `Back to Learn`.
- Empty: No writing task yet. Next step: Open Path and start a lesson.

### Tone Gym

- Enter: On the Learn root, tap Tone Gym. 1 tap.
- Back: `Back to Learn`.
- Empty: No tone drill yet. Next step: Open Path and start a lesson.

### Culture shelf

- Enter: On the Learn root, tap Culture shelf. 1 tap. The shelf lists Magazine, Heritage, History, Mannerisms, and Cultural Hub. Each name is the second tap.
- Back: `Back to Learn`. Each row uses the same button.
- Empty: The shelf has nothing on it. Next step: Open Path and start a lesson.
- A row with nothing in it. Next step: Open the Culture shelf.

### Passport

- Enter: On the Learn root, tap Passport. 1 tap.
- Back: `Back to Learn`.
- Empty: Passport has nothing to show yet. Next step: Open Path and start a lesson.

### Downloads

- Enter: On the Learn root, tap Downloads. 1 tap.
- Back: `Back to Learn`.
- Empty: Nothing is saved on the phone. Next step: Open Path and choose a lesson to save.

### Search, Lens, and Word Card on Learn

- Search. Enter: tap Search in the top bar. 1 tap. Back: `Back to Learn`. Empty: the box is empty. Next step: Type a word or a feature name. A word opens the Word Card. A lesson or a named item in this card opens that item, and Back returns to the Learn root. People, circles, and games are a later card.
- Lens. Enter: tap the camera button in the top bar. 1 tap. The screen opens on Point & Say. Live Translate and Import Media are the second tap on that same screen. Live Translate is the Conversation Bridge. Back: `Close` returns to the Learn root. Empty: the camera sees no object. Next step: Point at one thing, or use Import Media. Button: `Point again`.
- Word Card. Enter: long-press a target-language word. This is not a tab. Search can open this same card in 2 taps. Back: `Close` returns to the screen you were on, and that screen's Back returns to the Learn root. Empty: no word is open. Next step: Long-press a target-language word. Button: `Show a word`.

### Learn tap count

Taps are counted from the Learn root.

| Destination | Taps | Path |
| --- | --- | --- |
| Path and lessons | 1 | Learn root, then Path and lessons |
| A lesson | 2 | Learn root, Path and lessons, then the lesson |
| Lesson Recap | 1 | Learn root, then Lesson Recap |
| Words and Review | 1 | Learn root, then Words and Review |
| Review Rush | 1 | Learn root, then Review Rush |
| Grammar | 1 | Learn root, then Grammar |
| Phrase DNA | 2 | Learn root, Grammar, then Phrase DNA |
| Listening | 1 | Learn root, then Listening |
| Writing | 1 | Learn root, then Writing |
| Tone Gym | 1 | Learn root, then Tone Gym |
| Culture shelf | 1 | Learn root, then Culture shelf |
| Magazine | 2 | Learn root, Culture shelf, then Magazine |
| Heritage | 2 | Learn root, Culture shelf, then Heritage |
| History | 2 | Learn root, Culture shelf, then History |
| Mannerisms | 2 | Learn root, Culture shelf, then Mannerisms |
| Cultural Hub | 2 | Learn root, Culture shelf, then Cultural Hub |
| Passport | 1 | Learn root, then Passport |
| Downloads | 1 | Learn root, then Downloads |
| Search | 1 | Top bar Search |
| A search result in this card | 2 | Search, then the result |
| Lens (Point & Say) | 1 | Top bar camera. Opens on Point & Say |
| Live Translate | 2 | Lens, then Live Translate |
| Import Media | 2 | Lens, then Import Media |
| Word Card | long press | Long-press a target-language word |

## Speak

The Speak root is a list. Polie is the first row. The six tutor modes are chips on the Polie screen: Chat, Explain, Correct me, Roleplay, Story, and Translate. A chip stays on Polie.

Code-Switch and Respect are the two coaches on one screen. Personas and Missions is one screen, and a mission is a row on it.

```
Speak root
  Polie
    Chat
    Explain
    Correct me
    Roleplay
    Story
    Translate
  Scenarios
  Personas and Missions
    a mission
  Shadowing
  Code-Switch and Respect
  Speak Missions
  Coach insights
  Search (top bar)
  Lens (top bar camera)
    Point & Say
    Live Translate
    Import Media
  Word Card (long press on a target-language word)
```

### Polie

- Enter: On the Speak root, tap Polie. 1 tap.
- A mode chip is the second tap and stays on Polie. The chips are Chat, Explain, Correct me, Roleplay, Story, and Translate.
- Back: `Back to Speak`.
- Empty: Polie has not spoken. Next step: Hold to talk when you are ready. Button: `Hold to talk`.

### Scenarios

- Enter: On the Speak root, tap Scenarios. 1 tap.
- Back: `Back to Speak`.
- Empty: No scenario yet. Next step: Open Polie and hold to talk.

### Personas and Missions

- Enter: On the Speak root, tap Personas and Missions. 1 tap.
- A mission is a row on that screen. The row is the second tap.
- Back: `Back to Speak`. A mission uses the same button.
- Empty: No persona yet. Next step: Open Polie and hold to talk.
- A mission with nothing in it. Next step: Open Personas and Missions.

### Shadowing

- Enter: On the Speak root, tap Shadowing. 1 tap.
- Back: `Back to Speak`.
- Empty: No line to say along. Next step: Open Polie and hold to talk.

### Code-Switch and Respect

- Enter: On the Speak root, tap Code-Switch and Respect. 1 tap. Both coaches are on this screen.
- Back: `Back to Speak`.
- Empty: Neither coach has a line yet. Next step: Open Polie and hold to talk.

### Speak Missions

- Enter: On the Speak root, tap Speak Missions. 1 tap.
- Back: `Back to Speak`.
- Empty: No speaking mission yet. Next step: Open Polie and hold to talk.

### Coach insights

- Enter: On the Speak root, tap Coach insights. 1 tap.
- Back: `Back to Speak`.
- Empty: No speaking yet to look back on. Next step: Open Polie and hold to talk.

### Search, Lens, and Word Card on Speak

- Search. Enter: tap Search in the top bar. 1 tap. Back: `Back to Speak`. Empty: the box is empty. Next step: Type a word or a feature name. A word opens the Word Card. A named item in this card opens that item, and Back returns to the Speak root. People, circles, and games are a later card.
- Lens. Enter: tap the camera button in the top bar. 1 tap. The screen opens on Point & Say. Live Translate and Import Media are the second tap on that same screen. Live Translate is the Conversation Bridge. Back: `Close` returns to the Speak root. Empty: the camera sees no object. Next step: Point at one thing, or use Import Media. Button: `Point again`.
- Word Card. Enter: long-press a target-language word. This is not a tab. Search can open this same card in 2 taps. Back: `Close` returns to the screen you were on, and that screen's Back returns to the Speak root. Empty: no word is open. Next step: Long-press a target-language word. Button: `Show a word`.

### Speak tap count

Taps are counted from the Speak root.

| Destination | Taps | Path |
| --- | --- | --- |
| Polie | 1 | Speak root, then Polie |
| A tutor mode chip | 2 | Speak root, Polie, then the chip on that screen |
| Scenarios | 1 | Speak root, then Scenarios |
| Personas and Missions | 1 | Speak root, then Personas and Missions |
| A mission | 2 | Speak root, Personas and Missions, then the mission |
| Shadowing | 1 | Speak root, then Shadowing |
| Code-Switch and Respect | 1 | Speak root, then Code-Switch and Respect |
| Speak Missions | 1 | Speak root, then Speak Missions |
| Coach insights | 1 | Speak root, then Coach insights |
| Search | 1 | Top bar Search |
| A search result in this card | 2 | Search, then the result |
| Lens (Point & Say) | 1 | Top bar camera. Opens on Point & Say |
| Live Translate | 2 | Lens, then Live Translate |
| Import Media | 2 | Lens, then Import Media |
| Word Card | long press | Long-press a target-language word |

## What is in two taps

Every sitemap item for Today, Learn, and Speak is in the tables above, within two taps of its hub root. The farthest rows are 2 taps: a lesson, Phrase DNA, a Culture shelf row, a Polie chip, a mission, a search result, Live Translate, and Import Media. Word Card uses a long press. It is not a tab.
