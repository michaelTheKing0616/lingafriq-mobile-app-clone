charter: v2

# 04 — Model routing (cheapest correct tier)

## Tier → Cursor slug map (observed in this workspace, 21 Oct 2026)

| Tier | Class | Cursor slug used | Use for | Never for |
|---|---|---|---|---|
| T0 | no model | scripts in `scripts/plan/`, linters, test runners | linters, formatters, OpenAPI codegen, tests, RTM/card validation, placeholder/NFC/duplicate scans, dependency bumps, file moves, gitleaks, history-purge scripts (human-run for revocation) | anything needing judgement |
| T1 | Grok fast | `cursor-grok-4.6-high-fast` | ARB extraction, scaffolds, renames, simple tests, log triage, doc formatting, feature-card deltas | security, concurrency, algorithms, UX decisions |
| T2 | Grok fast | `cursor-grok-4.6-high-fast` | screens from spec, routes, integration tests, content-pipeline code, rule-based linters, most Tester and Reviewer work | cross-cutting redesigns, DSP/ML scoring, crypto |
| T3 | Grok strong | `grok-4.7-xhigh` | AI Gateway, socket authz, outbox/sync, FSRS, scoring, E2EE, moderation, reviews of safety code | boilerplate, docs, formatting |
| T4 | Grok strong | `grok-4.7-xhigh` (fresh subagent, never the orchestrator context) | ADRs, design direction, gate packets, conflicts, security/child-safety/legal final review | implementation, boilerplate, routine review |

Other families (`claude-*`, `gemini-*`, `gpt-*`, `composer-*`) only after both `cursor-grok-4.6-high-fast` and `grok-4.7-xhigh` have failed that card and the failure digest says no Grok slug can do the job. Cards keep `tiers:`; they do not name a model.

**Owner override (Tope, 2026-10-21) — every card, every role:** use a Cursor Grok slug. First `cursor-grok-4.6-high-fast`. If that slug fails the card once, one retry on `grok-4.7-xhigh` with a new hypothesis. Any other family only after both Grok slugs have failed that card and a failure digest says no Grok slug can do the job. Card `tiers:` still set difficulty; they do not select Claude, Gemini, or GPT.

**Build-phase session (from G0 GO, 2026-10-21):** the Orchestrator runs as **Grok 4.7**. T4 review is a fresh `grok-4.7-xhigh` subagent, never this context. `grok-4.7-high` is not an available slug.

## Difficulty score (per card, 0–10)
blast radius (security, child safety, money, data loss) 0–3 · ambiguity/novelty 0–2 · cross-module coupling 0–2 · algorithmic/ML/DSP/crypto depth 0–2 · size 0–1.

| Score | Worker | Tester | Reviewer |
|---|---|---|---|
| 0–2 | T0/T1 | T1 | T1 (T2 on P0 areas) |
| 3–4 | T1/T2 | T1/T2 | = Worker (T2 on P0 areas) |
| 5–6 | T2 | T2 | T2 |
| 7–8 | T3 | T2 (T3 for security/DSP/crypto) | T3 |
| 9–10 | T3 | T3 | T3 + T4 final review |

Reviewer is one tier above the Worker only when blast ≥ 2; never below T2 on P0 areas. Fable reviews only gate-critical cards (security, child safety, legal, design direction, signature screens).

## Escalation / de-escalation (02_PIPELINE.md §5.4)
Fail #1 → same tier, new hypothesis from the failure digest. Fail #2 → T2 triager writes ≤10-line digest from logs only → reassign one tier up. T4 implementation needed → planning defect: split or re-spec. Two consecutive first-time passes for a task class → record "try one tier lower" below.

## Tuning log (from LEDGER.csv, never from taste)
| Date | Task class | Observation | Change |
|---|---|---|---|
| 2026-10-21 | RTM extraction, tabular (§2 inventory) | T1 `composer-2.5-fast` passed first time (54 rows, valid) | keep T1 for tabular extraction and feature-card deltas |
| 2026-10-21 | RTM extraction, dense prose (14 chunks) | T2 passed first time on all 14; 30 hooks >12 words, fixed by T0 trim | keep T2; add T0 post-normalisation rather than rerun |
| 2026-10-21 | Engineering card drafting (14 slices, ~930 cards) | T2 passed validator + slice coverage first time; defects were cross-slice (2 missing hard-stop deps, 2 difficulty sums) — found by T0, fixed by T4 in minutes | keep T2; run `check_dependencies.py` over the whole set after every wave, not per slice |
| 2026-10-21 | Feature card deltas (8 slices, 151 cards) | T1 passed validator first time; 13 `shows_score` and 36 `under18_social` cards lacked the honest-state / minor-gate AC the brief implied but did not spell out | keep T1; briefs must state mandatory ACs per tag explicitly (fixed in `FEATURE_CARD_BRIEF.md` next revision) |
| 2026-10-21 | Every card, every role | Owner: Sonnet spec-test still running; Claude spend rejected. | Cursor Grok only. Default `cursor-grok-4.6-high-fast`. Escalate once to `grok-4.7-xhigh`. Other families only after both fail. |
