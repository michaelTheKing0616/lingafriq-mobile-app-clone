# Lesson flow reference pack (LingAfriq) · checked 2026-10-28 (Africa/Lagos, UTC+1)
Layout and pattern inspiration only. Do not copy logos, icons, illustrations, exact copy or code. Recolour with brand/lingafriq; Polie gives the feedback.

## Picks (App Store US lookup, 2026-10-28)
| App | Ver | Rating | Why |
|-|-|-|-|
| Duolingo | 7.146.0 | 4.72 / 5.5M | Defines the exercise grammar: a thin progress bar, a one-line instruction, a word bank of chips and a fixed Check button at the bottom |
| Speak | 4.71.0 | 4.83 / 65k | Best speaking exercise and instant feedback on what you said; a stats-based finish screen |
| Drops | 39.19 | 4.71 / 72k | Fast, picture-led word drills and match practice; bold colour per topic |
| Babbel | 22.20.0 | 4.72 / 757k | A clear menu of review modes (listening, speaking, flashcards, writing) |
| Busuu | 30.31.0 | 4.71 / 101k | Exercises with real native video, and a "Lesson completed" summary |

## Screenshots per element
Tap the words / word bank: 01, 03 · multiple choice (images): 02, 04 · conversation/dialogue: 05 · match/word drill: 06, 07 · exercise types menu: 08 · speak + feedback: 09, 10 · listen (video): 11 · completion: 12, 13.
**Gaps, with no real screenshot:** listen-and-type and fill-the-gap as separate screens, the correct and incorrect feedback sheets, and the hearts/lives counter. Store images don't show these states, so the recipe below is pattern-based.

## Recipe (shared frame)
Top bar: ✕ close, a progress bar (8 px, rounded, gold fill), hearts with count. Instruction in 20 px bold. Content area. A fixed bottom area with the full-width Check button, turned off until an answer is chosen.
- **Multiple choice:** a 2×2 grid of picture cards (02, 04), with audio on tap. **Tap the words:** answer lines with chips below (01, 03); chips move up with a 200 ms spring. **Match pairs:** 2 columns of 5. A right pair turns green and fades out; a wrong pair shakes (6 px, 300 ms). **Listen and type:** big play button, a "slow" button, a text field with a diacritics bar (ẹ ọ ṣ à á). **Fill the gap:** a sentence with a blank chip and 3–4 options. **Speak (09, 10):** hold-to-talk mic with a live sound wave, then words coloured by score with a "Try again".
- **Feedback sheet:** rises from the bottom (250 ms ease-out). Correct: green, "Nice!" plus Polie's nod, Continue. Wrong: coral (not alarm red), "Correct answer:" in bold, a meaning line, "Got it". Every sheet has an icon and text, not colour alone, and the answer is read aloud.
- **Hearts:** lose one on a wrong answer (heart cracks, 400 ms). At zero, a kind sheet offers "Practise to earn a heart" or "Wait". No hard paywall in the middle of a lesson.
- **Completion (12, 13):** Polie celebrates (Rive, 1.2 s) with 3 stat tiles (XP, accuracy, time), each counting up (600 ms), then the streak update and Continue.

## Upgrades for LingAfriq
Whole lessons download ahead, and every exercise works offline (speech scoring on the phone, or queued until online). Tone marks are checked kindly (a missing tone counts as "almost"). A low-data mode leaves out video exercises. Pidgin or English explanations can be turned on. Haptics stay light, with sound on/off in the top bar.

## Second pass (2026-10-28): real captures added (Duolingo live web app, 14–23)
| Element | Status | Files |
|-|-|-|
| Multiple choice | real | 02, 04, 14 |
| Listen + tap (Tap what you hear) | real | 15 |
| "Can't listen now" fallback | real | 16: yellow banner that skips audio exercises for a while |
| Correct feedback | real | 17: green full-width bottom bar, check icon, "Continue" |
| Incorrect feedback + correct answer | real | 18, 19, 20: pink/red bottom bar, ✕ icon, "Correct solution:" + answer, red button |
| Quit confirm | real | 21: modal with mascot, "keep learning" main button, "end session" text button |
| Completion celebration | real | 22: characters + "Lesson complete!" + 2 stat tiles + Continue |
| Write / word bank | real | 23 |
| Hearts counter | real (small, top right of 14–20); a hearts-empty modal wasn't visible in the capture | 14–20 |
| Match pairs, fill-the-gap, listen-and-type (keyboard) | still pattern-based (waiting on the browser worker) | |
**Recipe changes from the real captures:** the feedback is a full-width bottom bar, not a rising sheet, and it replaces the Check area: correct = green with Continue, incorrect = red/coral with "Correct solution". LingAfriq keeps coral rather than red. Add a "Can't listen now" text button under audio exercises, which turns them off for 15 min (important for noisy places or no headphones). Ask "Are you sure?" on quitting, with the main button set to keep learning.

### Update: browser worker captures (2026-10-28), files 24–31, real
- Listen + word bank with the hearts count in the header (24), listen-and-type keyboard (25), translate with word bank (26), translate with keyboard (28, 29, incl. the "3 in a row" combo cue): **real**.
- Correct banner with "report" + difficulty links (27); mistake-review interstitial (30); out-of-hearts modal (31: Super unlimited hearts / refill with gems): **real**. This replaces the earlier hearts-modal note on 20.
- Still pattern-based: fill-the-gap, match pairs. The completion art is real from the earlier App Store/web set (22).
- Recipe fix: keep a small report flag on the feedback bar, add a "review your mistakes" step before the lesson ends, and make the out-of-hearts screen offer a free route (practice to earn a heart) before any upsell.
