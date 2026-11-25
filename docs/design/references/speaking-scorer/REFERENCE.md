# Speaking scorer reference pack (LingAfriq) · checked 2026-10-28 (Africa/Lagos, UTC+1)
Layout and pattern inspiration only. Do not copy logos, icons, illustrations, exact copy or code. Recolour with brand/lingafriq (Gold #FFC53D, Coral #E5603B, Nunito Black); Polie is the mascot.

## Picks (App Store US lookup, 2026-10-28)
| App | Ver | Rating | Why |
|-|-|-|-|
| ELSA Speak | 9.2.4 | 4.75 / 114k | The category leader for pronunciation scoring: a percent score plus a breakdown by skill, sounds coloured by score |
| Speak | 4.71.0 | 4.83 / 65k | The best record-and-reply flow: a big mic, a live transcript, instant fixes shown inline |
| Memrise | 2026.10.21 | 4.78 / 218k | Feedback in a friendly chat, with corrections in context |
| Google Translate | 10.44.368 | 4.29 / 84k | The clearest mic button and listening state (big circle, pulse) |

## Screenshots per element
Score reveal / breakdown: 01, 02 · record states + transcript: 03, 06 · word-by-word feedback: 04, 05.
**Gaps, with no real screenshot:** tone/phoneme highlight close-ups, the mic permission ask, the noisy-room state and the offline state. Store images don't show these, so they are pattern-based.

## Recipe
- **Record button (bottom centre, 80 px):** idle (brand fill + mic), listening (ring pulse at 1.2 s, live waveform of 24 bars driven by volume), processing (ring spinner, 1 s max on the phone), done (check). Two input styles: tap-to-toggle or hold-to-talk, plus a "Listen to Polie first" speaker button on the left and "Slow" on the right.
- **Word-by-word feedback (04, 05):** the sentence with each word coloured green, amber or coral and underlined (not colour alone). Tap a word to open a sheet with "You said / Say it like", both playable, plus a mouth tip in plain words.
- **Tone highlight (LingAfriq upgrade):** for Yoruba, Igbo and other tonal languages, a small pitch line over each syllable showing target against yours (high, mid, low), and tone marks (à á) tinted when wrong. Never just "wrong": "Your tone went up, try keeping it low".
- **Score reveal (01, 02):** the ring fills to the score (800 ms, ease-out), the number counts up, and Polie reacts (over 85 dance, 60–85 nod, under 60 encourage). Under it, 3 bars (Sounds, Tone, Flow). Buttons: "Try again" (main if under 70) or "Continue".
- **Retry:** replay both versions side by side. Up to 3 tries, then "Move on, we'll practise this later".
- **Mic permission:** a pre-prompt (Polie with a headset: "Let me hear you say it. Audio stays on your phone") → OS dialog. If declined, an exercise card offers "Skip speaking for now" and a link to Settings.
- **Noisy room:** if the volume floor is above a threshold, show the banner "It's a bit loud here — move somewhere quieter or hold the phone closer" plus "Skip for 15 min".
- **Offline:** score on the phone if the model is cached. Otherwise record, keep the attempt, and show "We'll score this when you're back online" (a queued chip).
Motion respects Reduce Motion; haptic tick on start and stop.

## Second pass (2026-10-28): real captures added
| Element | Status | Files |
|-|-|-|
| Record/speak exercise | real | 03, 08 (Duolingo web: "Speak this sentence", a wide mic bar "Click to speak") |
| Word-level feedback | real | 04, 05, 07 (ELSA Play: "Try saying '<word>'" with the target word highlighted) |
| "Can't speak now" fallback | real | 09: speaking turns into a word-bank exercise for the same sentence |
| Score reveal | real | 01, 02 |
| Mic permission ask | pattern-based (waiting on the browser worker) | |
| Tone/phoneme close-up, noisy room, offline | still pattern-based (no official images found) | |
**Recipe changes:** add "Can't speak now" under the mic. Tapping it swaps the exercise for a tap-the-words version of the same sentence (09), so it doesn't count as a loss. Highlight the target word inside the feedback bubble, as ELSA does (07).

### Update: browser worker captures (2026-10-28), files 10–15, real
- Mic permission ask: now **real** (11). The browser permission prompt comes up over the exercise, with a "try again" banner if it is refused.
- Mic in use / recording: **real** (12, 13): the mic bar turns into a live waveform while recording.
- No speech heard: **real** (14): a red banner, and a heart is lost (5→3 shown).
- Can't speak now: **real** (15): a "microphone off" banner, and speaking exercises are skipped.
- Still pattern-based: a graded-correct speaking result, tone/phoneme close-ups, noisy room, offline.
- Recipe fix: LingAfriq should NOT take a heart for "no speech heard" (that would punish a quiet mic). Show "We couldn't hear you — try again" and give unlimited retries before it counts as wrong.
