charter: v2

# P3-001 benchmark baselines

G3 pass is not claimed.

Products: Duolingo, Speak, Babbel, Memrise. One row per product per metric. A numeric row has a value, a unit, a source URL or a local screenshot path, and a date. A row with no primary source is tagged [Unverified] and the value is blank. Speak, Babbel, and Memrise have no files under `docs/build/benchmark/`; those rows say no-screenshot.

Census: 12 searches, 3 numeric rows (B01, B02, B03), 17 [Unverified] rows. The numeric count is under 12.

## Queries

1. Duolingo onboarding steps before first lesson site:blog.duolingo.com
2. Duolingo "first lesson" onboarding taps OR screens OR steps count 2024 OR 2025 OR 2026
3. Speak app onboarding "first" speak seconds OR minutes steps official site:speak.com
4. Babbel onboarding first lesson steps OR minutes site:babbel.com
5. Memrise onboarding steps first lesson OR "learn your first" site:memrise.com
6. Duolingo lesson feedback animation milliseconds OR "ms" latency design
7. Memrise getting started onboarding "steps" OR "questions" OR "minutes" site:memrise.com OR site:help.memrise.com
8. Duolingo accessibility "text size" OR "font size" OR "Dynamic Type" minimum site:duolingo.com
9. Babbel speech recognition "real-time" feedback milliseconds OR seconds pronunciation site:babbel.com
10. Speak app onboarding steps questions before first lesson site:speak.com
11. Duolingo "speaking" "seconds" OR "minutes" "first lesson" site:blog.duolingo.com
12. Memrise "speak" OR pronunciation "feedback" "seconds" OR "real-time" site:memrise.com

Stopped at 12. No 13th search.

Pages opened to read a hit from the queries above. These opens are not searches:

- https://www.speak.com/blog/how-speak-reinvents-language-learning (query 3)
- https://www.babbel.com/how-babbel-works (query 4)
- https://support.babbel.com/hc/en-us/articles/19211305815570-Speech-recognition (query 9)
- https://blog.duolingo.com/covering-all-the-bases-duolingos-approach-to-speaking-skills/ (query 11)
- https://www.memrise.com/jtbd (query 7)

## Numeric baselines

### B01 — Duolingo — onboarding step count

| Field | Entry |
|---|---|
| id | B01 |
| product | Duolingo |
| metric | onboarding step count |
| value | 5 |
| unit | count |
| date | 2026-10-23 |
| tag | |

Count method: opened web welcome captures whose address bar shows `duolingo.com/welcome`. README capture date 2026-10-21. README pixel size 1920x1200. The value is the number of those files opened on 2026-10-23.

- `docs/build/benchmark/duolingo/all/03-onboarding-duo-intro-web.png` — duolingo.com/welcome — "Hi there! I'm Duo!" — one CONTINUE
- `docs/build/benchmark/duolingo/all/04-onboarding-party-started-web.png` — duolingo.com/welcome — "Let's get this party started!" — one CONTINUE
- `docs/build/benchmark/duolingo/all/05-onboarding-how-did-you-hear-web.png` — duolingo.com/welcome?welcomeStep=hdyhau — "How did you hear about Duolingo?"
- `docs/build/benchmark/duolingo/all/06-onboarding-why-learning-web.png` — duolingo.com/welcome?welcomeStep=learningReason — "Yay! Fun is my specialty!"
- `docs/build/benchmark/duolingo/all/07-onboarding-course-overview-web.png` — duolingo.com/welcome?welcomeStep=courseOverview — "Here's what you can achieve!"

Opened and kept out of B01, because each is a different surface:

- `docs/build/benchmark/duolingo/all/14-onboarding-find-best-place-to-start-web.png` — duolingo.com/learn — "Now let's find the best place to start!"
- `docs/build/benchmark/duolingo/all/18-onboarding-blog.png` — chess level question
- `docs/build/benchmark/duolingo/all/19-onboarding-blog.png` — course picker
- `docs/build/benchmark/duolingo/all/20-onboarding-blog.png` — Turkish level question
- `docs/build/benchmark/duolingo/10-onboarding.png` — App Store courses frame

Scorecard reading: 5 is the opened `duolingo.com/welcome` sequence. A citation of B01 uses that sequence.

### B02 — Speak — seconds to first spoken output

| Field | Entry |
|---|---|
| id | B02 |
| product | Speak |
| metric | seconds to first spoken output |
| value | 10 |
| unit | s |
| date | 2026-03-24 |
| screenshots | no-screenshot |

Source: https://www.speak.com/blog/how-speak-reinvents-language-learning — Santiago Gustin, "How Speak reinvents language learning", dated March 24, 2026. Quote: "we get you speaking within 10 seconds of starting your first lesson."

Scorecard reading: 10 s is Speak's stated upper bound. The clock starts when the first lesson starts.

### B03 — Duolingo — taps to first lesson

| Field | Entry |
|---|---|
| id | B03 |
| product | Duolingo |
| metric | taps to first lesson |
| value | 3 |
| unit | count |
| date | 2026-10-23 |
| tag | |

Count method: on screens opened 2026-10-23, count one tap when the in-app UI shows exactly one primary forward control. Browser chrome is outside the count. The value is the sum of the unambiguous screens. Source paths:

- `docs/build/benchmark/duolingo/all/03-onboarding-duo-intro-web.png` — CONTINUE
- `docs/build/benchmark/duolingo/all/04-onboarding-party-started-web.png` — CONTINUE
- `docs/build/benchmark/duolingo/all/07-onboarding-course-overview-web.png` — CONTINUE. A back arrow is also visible. It is a back control, so the primary forward control is CONTINUE.

Excluded as ambiguous:

- `docs/build/benchmark/duolingo/all/05-onboarding-how-did-you-hear-web.png` — eight source options and CONTINUE
- `docs/build/benchmark/duolingo/all/06-onboarding-why-learning-web.png` — seven reason options and CONTINUE
- `docs/build/benchmark/duolingo/all/14-onboarding-find-best-place-to-start-web.png` — "Start from scratch" and "Find my level"; CONTINUE is shown disabled
- `docs/build/benchmark/duolingo/all/08-lesson-exercise-multiple-choice-web.png` — duolingo.com/lesson; SKIP, CHECK, and three answer cards
- `docs/build/benchmark/duolingo/all/10-lesson-incorrect-feedback-banner-web.png` — duolingo.com/lesson; the still is overlapped, so a single forward control is not clear
- `docs/build/benchmark/duolingo/all/11-lesson-correct-feedback-banner-web.png` — duolingo.com/lesson; CONTINUE, TOO EASY, TOO DIFFICULT, and REPORT

Scorecard reading: 3 is the number of opened screens with exactly one primary forward control. It is the sum of those screens. Screens already on duolingo.com/lesson are inside a lesson.

## Unverified

Value blank. No measured figure from an opened capture or from a page already opened.

| product | metric | value | unit | tag | date | screenshots | source |
|---|---|---|---|---|---|---|---|
| Duolingo | seconds to first spoken output |  | s | [Unverified] |  | not cited | https://blog.duolingo.com/covering-all-the-bases-duolingos-approach-to-speaking-skills/ (2026-02-09) says speaking exercises start in the first lesson and states no seconds figure. |
| Duolingo | minimum body text size |  | sp | [Unverified] |  | not cited | No glyph pixel height was measured. README lists the opened web files at 1920x1200. No conversion to sp is shown. |
| Duolingo | feedback latency |  | ms | [Unverified] |  | not cited | `docs/build/benchmark/duolingo/all/10-lesson-incorrect-feedback-banner-web.png` and `docs/build/benchmark/duolingo/all/11-lesson-correct-feedback-banner-web.png` show no millisecond number. A still supplies no latency. |
| Speak | taps to first lesson |  | count | [Unverified] |  | no-screenshot | Queries 3 and 10 returned no tap count. |
| Speak | onboarding step count |  | count | [Unverified] |  | no-screenshot | Queries 3 and 10 returned no onboarding step count. |
| Speak | minimum body text size |  | sp | [Unverified] |  | no-screenshot | No primary source states a body size in sp. |
| Speak | feedback latency |  | ms | [Unverified] |  | no-screenshot | The Speak page in B02 says feedback is immediate and states no millisecond figure. |
| Babbel | taps to first lesson |  | count | [Unverified] |  | no-screenshot | https://www.babbel.com/how-babbel-works states no tap count. The page has no publication date. |
| Babbel | seconds to first spoken output |  | s | [Unverified] |  | no-screenshot | The same Babbel page says speaking practice starts on day one and states no seconds figure. Lesson length on that page is a different metric and is not recorded here. |
| Babbel | onboarding step count |  | count | [Unverified] |  | no-screenshot | The same Babbel page has a getting-started guide and does not state an in-app onboarding screen count. |
| Babbel | minimum body text size |  | sp | [Unverified] |  | no-screenshot | No primary source states a body size in sp. |
| Babbel | feedback latency |  | ms | [Unverified] |  | no-screenshot | https://support.babbel.com/hc/en-us/articles/19211305815570-Speech-recognition says learners "receive instant feedback" and states no millisecond figure. |
| Memrise | taps to first lesson |  | count | [Unverified] |  | no-screenshot | Queries 5 and 7 returned no tap count. |
| Memrise | seconds to first spoken output |  | s | [Unverified] |  | no-screenshot | https://www.memrise.com/jtbd places first out-loud phrases on a later day ("Day 2 / Start saying your first phrases out loud"). That timeline is not a seconds figure, and it is not converted into seconds. |
| Memrise | onboarding step count |  | count | [Unverified] |  | no-screenshot | https://www.memrise.com/jtbd uses "Three steps" for its learning method (words, voices, speaking). That is not an onboarding screen count. |
| Memrise | minimum body text size |  | sp | [Unverified] |  | no-screenshot | No primary source states a body size in sp. |
| Memrise | feedback latency |  | ms | [Unverified] |  | no-screenshot | https://www.memrise.com/jtbd says "instant, helpful feedback" and states no millisecond figure. https://www.memrise.com/blog/pronunciation-buddy (query 12) also says "instant feedback" and states no millisecond figure. |

## Scorecard contract

Later UX or UI scorecard targets must cite one of these row ids:

- B01
- B02
- B03

A target cites the id and the scorecard reading on that row.

[Unverified] slots have no id and no value. A target cannot cite them as a number to meet or beat. That covers seconds to first spoken output for Duolingo, Babbel, and Memrise; taps to first lesson and onboarding step count for Speak, Babbel, and Memrise; minimum body text size for all four products; and feedback latency for all four products.

B02's clock starts at the first lesson. The UX Scorecard "First spoken word" clock starts at first launch. A target that cites B02 keeps Speak's clock.

G3 pass is not claimed.
