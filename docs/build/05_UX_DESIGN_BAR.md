charter: v2

# 05 — UX and UI bar (two first-class workstreams; measurably beyond Duolingo)

UX (flows, feedback, a11y, performance) and UI (visual design) are spec'd, built as components and reviewed **before** screens are assembled. Cards: `docs/build/cards/P3/` (sub-epics `E-P3-DESIGN-WORKFLOW`, `E-P3-TOKENS`, `E-P3-COMPONENTS`). Targets marked *proposed* were approved by Tope under D8.

## Design workflow (cards in this order; each depends on the previous)
| # | Card | Output | Owner / review |
|---|---|---|---|
| 1 | Competitive benchmark | `docs/build/design/BENCHMARK.md`: Duolingo + 2–3 others; measurable baselines (first-win time, feedback latency, celebration frequency, text size, states coverage); capped searches; screenshots only from `docs/build/benchmark/` if Tope supplies them | T2 / T4 |
| 2 | Principles + journey maps | learn it / say it / live it | T2 / T4 |
| 3 | Art direction | 2–3 directions → ADR-010; African craft (adire, uli/nsibidi, kente, bogolan, Ndebele, tilf) sparingly, credited, consultant-reviewed (EXT-14) | T4 decides |
| 4 | Tokens JSON | one source for app, admin, Rive: OKLCH ramps, 4-pt grid, type scale, radius/elevation/stroke, motion | T2 / T2 + T0 lint |
| 5 | Hi-fi signature screens | light + dark: Today, Path map, Lesson player, Tone Lens + pronunciation feedback, Word Card, Lens camera, Village map, Arcade shelf, Polie voice, Profile/wardrobe, celebration/level-up, onboarding first word | T2 / **T4** |
| 6 | Component catalogue | Widgetbook or equivalent; every state; pixel specs; goldens 100%/200%, light/dark; custom icon set; illustration system | T2 / T2 |
| 7 | Motion, sound, haptics spec | easing `cubic-bezier(0.23,1,0.32,1)`, ≤300 ms, stagger rules, rare-tier celebrations, culturally resonant sound palette (mutable), haptic map | T2 / T4 |
| 8 | Copy deck + voice guide | grade-7, verb-first buttons, no em dashes in UI strings, banned: World-class / Elite / Seamless, no emoji-as-icons | T1 draft / T2 |
| 9 | Wireflows per hub | Today, Learn, Speak, Play, Village, Me | T2 / T2 |
| 10 | Usability protocol | tasks, SUS, device matrix (Tecno/Infinix class; NG/KE/ZA) | T2 / T4 |
| 11 | Build | feature cards inherit the system | per card |
| 12 | Usability test + iterate | hub gates | T2 / T4 |

## UX Scorecard (G3 and every hub gate; every dimension has a number and a test)
| Dimension | Target | Test |
|---|---|---|
| First spoken word | ≤60 s from first launch, no account | e2e timer on reference device |
| Cold start | <2 s to first meaningful frame (Tecno/Infinix class) | perf trace in CI device lab |
| Answer feedback | ≤160 ms with haptic + sound; celebrations rare tier; product motion ≤300 ms | widget timing test; motion lint |
| Real speaking feedback | GOP + per-syllable tone, learner contour over native; "unsure" state; never a fabricated number | scorer evals (G8); fake-success lint |
| Tone Lens | same component everywhere; never colour-only | component lint + goldens |
| Target-language text | ≥18 sp, leading ≥1.5, bundled Andika/Noto, no runtime font fetch, stacked diacritics verified | goldens at 100%/200%; network assertion |
| Content honesty | Beta / Expert / Native labels, "Synthetic voice" tag, "Report a mistake" on every item | content tests; widget tests |
| Accessibility | WCAG 2.2 AA; 200% text no clipping; reduced motion gentler not zero; captions/transcripts; semantics; visual pitch feedback | a11y test suite; audit (EXT-27) |
| Performance | 60 fps (graceful 30); download <40 MB; offline-first with visible sync state | frame-cost CI; APK size gate; outbox e2e |
| Ethical engagement | no energy gates in core lessons; hearts opt-in; one reminder/day with quiet hours; no fake social proof or loot boxes | guardrail verification card P10-913 |
| States | skeleton, empty (points forward), error (what/why/next), offline, AI unavailable, content under review on **every** screen | states-kit widget test per screen |
| Copy | grade-7; verb-first; no em dashes; banned words; no emoji icons | T0 copy lint on ARB |
| Cultural craft | pattern libraries per culture, sparing, credited, consultant-reviewed; avatar bible (skin tones ≥10, regional hair/headwear, disability representation) | consultant sign-off (EXT-14) |
| Usability *proposed, D8* | task success ≥90% on core flows; SUS ≥85; low-end Android NG/KE/ZA | usability protocol card |

## UI Scorecard (G3 and every hub gate; Reviewer scores against approved hi-fis + benchmark)
| Dimension | Pass criterion | Evidence |
|---|---|---|
| Visual hierarchy | one primary action per screen; target-language text dominant; 5-second test on key screens | design-gate sheet |
| Consistency | 100% token compliance: zero hard-coded colours, sizes, fonts, strings | T0 lint (build-blocking) |
| Craft | no clipped/colliding diacritics at 100% and 200%; grid alignment; consistent icon stroke; no layout jumps | goldens |
| Distinctiveness *proposed, D8* | blind comparison vs Duolingo-equivalent screens: preferred by ≥60% of a ≥20-person NG/KE/ZA panel | panel protocol |
| Delight | celebrations, mascot reactions, sound, haptics within rare tier; never block the learner | motion lint; widget tests |
| Brand coherence | same look across lessons, chat, games, personas, dictionary, admin (shared tokens JSON) | token diff admin vs app |
| Dark mode / themes | designed, contrast-checked, golden-tested for every screen | goldens |
| Cultural integrity | patterns, avatars, imagery signed off by the cultural consultant; no cliché | EXT-14 sign-off |
| Device fidelity | correct on low-end Android and large tablets | device-lab goldens |

## Review and evidence rules
- Fable (T4) reviews: art direction, signature hi-fis, every design-gate packet. Routine screens: T2 against hi-fis + golden diffs.
- Visual evidence (golden images or a design-gate sheet) is produced **only** by cards with `visual_evidence_required: true`. No agent screenshots otherwise.
- Hub gate passes only if every dimension is equal-or-better than the benchmark **and** the signature differentiators are present: real tone scoring, honest labels, Tone Lens, heritage mode, ethical retention.
- Art and assets (Rive `.riv`, illustration packs, voices, music) are human deliverables tracked as `Blocked-External` (EXT-16, EXT-13); the plan owns briefs, contracts, AvatarDirector, contract and golden tests.
