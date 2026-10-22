charter: v2

# Gate packet — G0 Plan approved

| Field | Value |
|---|---|
| Gate | G0 |
| Phase | P0 Intake |
| Date | 2026-10-21 |
| Recommendation | **GO** — approve the Master Build Plan; start P1 Containment |

## RTM coverage delta
| Status | Before (Checkpoint 1) | After (Stage E) |
|---|---|---|
| Mapped to cards | 0 | 2,955 |
| Blocked-External | 0 | 5 (partnerships, contributor pay: EXT-11, EXT-03) |
| Waived-by-Tope | 0 | 0 |
| Unmapped | 2,960 | **0** |

## Exit criteria (from `03_PHASES_GATES.md`)
| Criterion | Measure | Result | Evidence |
|---|---|---|---|
| RTM 100% mapped | `check_rtm_coverage.py` unmapped = 0 | PASS | `COVERAGE_REPORT.md` |
| All cards validate, size caps, tier rules | `validate_cards.py` | PASS (1,079) | same |
| Dependencies acyclic, §7.3 hard-stop ordering | `check_dependencies.py` | PASS | same |
| Routing table, budgets, charter enforcement | `04_ROUTING.md`, `02_PIPELINE.md`, `.cursor/rules/00-token-economy.mdc`, `scripts/check_agent_files.py` | PASS (1,092 files carry `charter: v2`) | `check_agent_files.py` |
| D1–D5 answered | `DECISIONS.md` | PASS (D1–D10 signed) | `DECISIONS.md` |
| C1–C3 resolved | `CONFLICTS.md` | PASS (C1–C5, ADR-001…003) | `CONFLICTS.md` |
| Companion-doc gaps listed | `EXTERNAL.md` | PASS (EXT-01) | `EXTERNAL.md` |
| UX/UI bar, test strategy, review standard written | `05_UX_DESIGN_BAR.md`, `06_TEST_STRATEGY.md`, `07_REVIEW_STANDARDS.md` | PASS | files |

## Tests and evals
Plan-stage only: 4 T0 audit scripts green; no app code changed in this run. Spec-first test strategy in `06_TEST_STRATEGY.md`; hard-stop proofs listed there.

## Budget vs actual (`LEDGER.csv`)
| Tier | Cards/tasks | Attempts | Tokens | Overruns |
|---|---|---|---|---|
| T4 Fable | orchestration, skeleton, docs 05–07, audit, 42 gate-critical reviews | 1 | n/a (not exposed) | 0 |
| T2 Sonnet | 16 RTM extractions · 14 engineering card slices | 1 each | n/a | 0 retries |
| T1 Composer | 8 feature-card slices (151 cards) | 1 each | n/a | 0 retries |
| T0 scripts | convert, segment, merge, slice, scaffold, validate, deps, coverage, charter | — | 0 | — |

## Open risks (≤5)
1. `LINGAFRIQ_AI_MODEL_STACK.md` absent — 28 cards cite EXT-01; model choices stay as written in Elevation until it arrives.
2. Native validators, voice talent and cultural consultant (EXT-13/14) gate every content wave and the design system; recruit at G1, not G4.
3. Live-server facts are `[Unverified]` (EXT-23); P1 cards assume the worst case.
4. ~320 status `.md` files in repo root pre-date this plan; RM-STOP-03 bans adding more — cleanup is P2-040, not done here.
5. Token totals not exposed per subagent; the ledger records attempts/outcomes only.

## Decisions needed from Tope
None block G0. D11–D19 in `DECISIONS.md` each block one card and carry a recommendation; signing them in one batch at G0 avoids nine later interrupts.
