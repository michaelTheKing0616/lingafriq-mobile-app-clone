charter: v2

# Coverage report — Master Build Plan (Stage E self-audit, 2026-10-21)

Reproduce: `python3 scripts/plan/validate_cards.py && python3 scripts/plan/check_dependencies.py && python3 scripts/plan/check_rtm_coverage.py && python3 scripts/check_agent_files.py`

## Source → RTM → cards
| Measure | Value | Check |
|---|---|---|
| Source pages | ELEVATION 96 pp (5,647 lines) · CURRICULUM 12 pp (865 lines) | `convert_sources.py` |
| RTM rows | **2,960** (ELEVATION 2,514 · CURRICULUM 446) | `merge_rtm.py` |
| Row types | requirement 2,027 · constraint 208 · metric 215 · informational 299 · external 136 · decision 56 · risk 19 | — |
| Top-level § represented | 100% of both docs (every § in `ANCHORS.txt` has ≥1 row) | `merge_rtm.py` assert |
| Unmapped rows | **0** | `check_rtm_coverage.py` |
| Rows mapped by cards | 2,960 (card→req links 3,432); 5 rows Blocked-External (Masakhane/university/diaspora partnerships, contributor licence + revenue share: EXT-11, EXT-03) | same |
| P0-1…27 mapped | 27/27 | assert |
| F-001…151 mapped | 151/151, one feature card each, `inherits: FEATURE_BASE` | assert + structural scan |
| Cards | **1,079**: build 695 · feature 151 · verification 78 · epic 57 · adr 38 · external 31 · design 29 | `validate_cards.py` OK |
| Sizes | S 373 · M 591 · L 115 · XL 0 | cap check |
| Worker tiers | T0 31 · T1 263 · T2 501 · T3 210 · T4 74 (epics + ADRs only; no implementation routed to Fable) | tier rules |
| Dependency graph | acyclic; no build card depends on a later-phase build card; later-phase *epics* allowed as ships-after gates | `check_dependencies.py` OK |
| Hard stops | all consumers (`shows_score` 23 · `under18_social` 41 · `enables_persona` 10 · `tts_tonal` 4 · `uses_source` 4 · `issues_credential` 2 · …) depend on a provider-tagged card | same |
| Honest-by-design | every `shows_score` card has an "unsure / no fabricated score" AC; every `under18_social` card has a server-side minor gate AC | scripted scan |
| No-Cut | 3 true consolidations (F-011, F-022, F-110) carry `harvest_list`; "Unrouted (REVIVE)" features correctly carry none | anchor scan |
| `ux_spec` on user-facing | 100% | validator |
| `charter: v2` | 1,092 agent-facing files, 0 missing | `check_agent_files.py` OK |
| Markers kept | `[verify]/[Unverified]` retained in 3 non-verification cards, each routed to a verification/EXT card; 78 verification cards | scan |

## Residual gaps (honest list)
| Gap | Why | Where tracked |
|---|---|---|
| `LINGAFRIQ_AI_MODEL_STACK.md` not provided | never guessed; vendor names carried as written; model-choice cards cite the companion doc as a blocker | EXT-01 |
| 31 external items (vendors, counsel, natives, artists, pen test, DPIA, stores) | human deliverables | `EXTERNAL.md` EXT-01…30 |
| 9 decisions surfaced during drafting | need Tope; none blocks G0 | `DECISIONS.md` D11–D19 |
| Token counts `n/a` in LEDGER | Cursor does not expose per-subagent token totals; attempts and outcomes recorded | `LEDGER.csv` |
| Fable read-review sample | all P0, hard-stop providers, 42 gate-critical cards (reviewer set to T4) and ~10% structural sample; remaining cards validated by T0 scripts + T2 drafter self-check, not read by T4 | this report |
