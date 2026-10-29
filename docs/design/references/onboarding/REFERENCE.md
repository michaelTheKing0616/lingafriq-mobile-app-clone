# Onboarding reference pack (LingAfriq) · checked 2026-10-28 (Africa/Lagos, UTC+1)
Layout and pattern inspiration only. Do not copy logos, icons, illustrations, exact copy or code. Recolour with brand/lingafriq (the kit shows Gold #FFC53D and Coral #E5603B; check the kit for the full tokens). Polie takes every mascot role.

## Picks (App Store US, iTunes lookup API, 2026-10-28)
| App | Ver (date, UTC) | Rating | Why it's here |
|-|-|-|-|
| Duolingo | 7.146.0 (10-26) | 4.72 / 5.5M | Gold standard for language pick and level placement: mascot asks one question per screen, big tappable rows, Continue stays disabled until you choose |
| Speak | 4.71.0 (10-26) | 4.83 / 65k | Speaking-first welcome; picks a real-life scenario as the "goal"; first-win screen with 3 big stats |
| Finch | 3.73.231 (10-23) | 4.95 / 769k | Highest-rated app in the set. Its warm mascot welcome, soft goal cards and "celebrate progress, not perfection" tone are the model for Polie |
| Headspace | 8.38.0 (10-26) | 4.84 / 974k | One clear goal leads straight to a first short session; calm hierarchy with one main button |
| Opal | 4.20 (10-19) | 4.72 / 90k | Shows the benefit before asking for a permission. Its listing displays an Apple Design Award Social Impact badge (not re-verified here) |
Award context: the 2026 Apple Design Award winners (apple.com newsroom, 2 June 2026) include no language or wellness consumer app, so the picks above are chosen on rating, scale and flow quality.

## Screenshots (all real, official App Store or Duolingo blog files)
01 opal-welcome · 02 finch-welcome-mascot · 03 speak-welcome · 04-05 duolingo-language-pick · 06 finch-goal · 07 headspace-goal-first-session · 08 speak-goal-scenario · 09-10 duolingo-level-placement · 11 opal-permission-value · 12 finch-first-win · 13 speak-first-win. Sizes and URLs are in SOURCES.md.
**Gaps, with no real screenshot:** the account and birth-year screen and the notifications pre-prompt. Store listings don't show these, so the recipes below are pattern-based.

## Recipe per step (each step: one question, one main button, progress bar on top)
1. **Welcome** (02, 03): Polie fills the top 55% and waves on load (Rive, 600 ms ease-out). Below: a 2-line promise, a main button "Get started" and a text link "I already have an account". *Upgrade:* a small "Works offline · about 2 MB per unit" low-data chip.
2. **Language pick** (04, 05): the screen asks "What do you want to learn?" Rows are 56–64 px tall, each with a flag or script badge, the name and the learner count. *Upgrade:* group by region (West, East, Southern, North Africa) with a search box, and show the name in its own script (e.g. ትግርኛ, ⵜⴰⵎⴰⵣⵉⵖⵜ). The "I speak" line is set from the device locale and can be changed.
3. **Goal** (06, 07, 08): 4 cards (Talk to family / Travel / Heritage and culture / Work). Pick one or more, then a daily time pick (5/10/15/20 min) with a plain word for each ("Casual... Serious"). The selected card gets a 2 px brand border plus a check, so colour isn't the only signal.
4. **Level placement** (09, 10): Polie's speech bubble asks the question, with 4–5 rows going from "I'm new" up to "I can hold a conversation", each with a signal-bar icon. Continue is disabled until a row is chosen. *Upgrade:* "Not sure? Take a 1-minute check" leads to 3 quick questions.
5. **Account + age** (gap): ask for the birth year on a scroll wheel. Never show a yes/no "Are you over 18?". Copy: "This helps us keep LingAfriq right for you." Under 13 (COPPA/GDPR-K) or under 18 (Nigeria NDPA 2023 defines a child as under 18 and needs parent or guardian consent, with GAID 2025 rules): switch to a kind "Ask a parent" path that collects a parent email, with no dead end and no error red. Sign-in: Google, Apple and email; phone/OTP is optional. Offer "Skip for now" so progress is saved on the device.
6. **Notifications pre-prompt** (11 pattern): a full screen shown before the OS dialog. Polie holds a sample reminder card ("Ẹ kú àárọ̀! 5 minutes of Yoruba?"), a time chip set to the time chosen in the goal step, "Turn on reminders" (this triggers the OS dialog) and "Not now". If the user declines, ask again only after the first streak.
7. **First win in under 60 s** (12, 13): one 3-exercise micro-lesson (hear, tap, say), then a celebration screen: Polie dances (Rive, about 1.2 s), confetti, 3 stat tiles (words learned, XP, day-1 streak) and "Keep going". Motion respects Reduce Motion.

## Shared upgrades
44 px minimum tap targets · Dynamic Type up to 200% · 4.5:1 text contrast · back arrow on every step · answers kept if the app closes · the whole flow works offline after the first load · copy at a 6th-grade reading level.

## Second pass (2026-10-28): real vs pattern-based
- **Real (Duolingo web, 15–26):** landing, language picker, mascot intro, "how did you hear", "why are you learning", course overview, placement ("find the best place to start"), streak day 1, streak-goal picker, create-profile prompt, age/sign-up wall (26). **Real (worker, 14):** notification / daily-reminder settings, used only as a pattern for the reminder step.
- **Pattern-based:** the native OS notification opt-in prompt, account creation beyond the age wall, a Nigerian-language picker.
- Recipe fix: Duolingo asks reason → level → daily goal *before* any account step and puts the account wall after the first win (23, 26). Keep that order: sign-up is offered after lesson 1, not before.
