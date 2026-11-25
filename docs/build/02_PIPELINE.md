charter: v2

# 02 — Pipeline: Orchestrator → Worker → Tester → Reviewer

## 5.1 Roles

| Role | Tier | Receives | Does | Emits | Never |
|---|---|---|---|---|---|
| Orchestrator | T4 | RTM, LEDGER, STATE, gate results | plans, writes/validates cards, routes, sequences, enforces gates, resolves conflicts | cards, gate packets (≤1 page), DECISIONS/STATE/RTM/LEDGER updates | implements, unless a card failed twice at T3 with evidence |
| Worker | per card | `worker_brief.md` + card + allowlisted files + anchor excerpts | implements exactly one card inside its file allowlist | diff + report ≤15 lines (`charter: v2`, ACs claimed, files touched, budget used, open questions) | touches files outside the allowlist, writes tests for spec-first cards, reads transcripts |
| Tester | ≤T2 (T3 for security/DSP/crypto) | `tester_brief.md` + card (ACs, test_plan) + test dirs | derives tests from ACs **before** build (Spec-Tests), runs them after build | report ≤15 lines: pass/fail per AC, failing names + minimal trace, coverage on touched domain code | reads the Worker's diff when writing tests; weakens an AC |
| Reviewer | = Worker tier (+1 when blast ≥2; ≥T2 on P0) | `reviewer_brief.md` + card + diff + Tester report + RTM anchors | checks against the card, anchors, charter and `07_REVIEW_STANDARDS.md` | verdict ≤20 lines: `PASS` / `FIX (≤N itemised)` / `BLOCK` + single most important risk | is the Worker's session; rewrites code |

## 5.2 Card lifecycle
`Draft → Ready (DoR) → Spec-Tests (Tester) → Build (Worker) → Test (Tester) → Review (Reviewer) → Done (evidence) → Epic-integration → Phase gate`

- S cards with blast ≤1 may let the Worker write tests; the Tester only runs them. All other cards are spec-first.
- Maximum 2 fix loops per card, then the Orchestrator decides (re-scope, split, escalate).
- Status values: `Draft | Ready | Spec-Tests | Build | Test | Review | Fix | Done | Blocked-External | Waived`.

**Definition of Ready:** `req_ids` validated against RTM · testable Given/When/Then ACs with ids · `difficulty`, `tiers`, `token_budget` set · `file_allowlist` (≤12 files) and `context_anchors` set · every `depends_on` card Done · `ux_spec` present if user-facing · gate assigned.

**Definition of Done:** all ACs pass with Tester evidence · Reviewer `PASS` · no No-Partial markers (TODO, stub, "for now", "simulate", mock-as-real, placeholder text, swallowed catch, fake-success) in the diff · RTM rows updated to `Verified-Done` (or `Blocked-External` / `Waived-by-Tope`) · LEDGER row written · every unfinished or partial item appended to `OPEN_WORK.md` · docs/changelog touched only where behaviour changed.

## 5.3 Routing
See `04_ROUTING.md`. Each card records `difficulty`, `tiers.{worker,tester,reviewer}` and a one-line `justification`.

## 5.4 Escalation and de-escalation
| Event | Action |
|---|---|
| Failure #1 | same tier retries once with a **new hypothesis** written from the failure digest; same prompt is never resent |
| Failure #2 | T2 triager reads logs only → ≤10-line digest (symptom, evidence, 2 hypotheses tried, 1 untried) → reassign one tier up |
| Needs T4 to implement | planning defect: Orchestrator splits or re-specs the card |
| Task class passes first time ≥2 in a row | Orchestrator logs "try one tier lower" in `04_ROUTING.md` |
| 80% of budget | agent stops, reports, waits for Orchestrator |
| 100% of budget | agent halts; Orchestrator re-scopes or splits |

## 5.5 Budgets and limits
| Size | Token budget | Typical |
|---|---|---|
| S | ≤30k | one file, one behaviour, ≤3 ACs |
| M | ≤80k | ≤6 files, one route/screen/service |
| L | ≤200k | ≤12 files, one subsystem slice |
| XL | not allowed | split before Ready |

Initial values; calibrate from the first 10 cards (compare `LEDGER.csv` actuals), then lock. WIP limit: 3 parallel lanes. File allowlist ≤~12 files. Context allowlist = RTM anchors (line ranges) only.

## Handoff packet (what every agent gets, in this order, nothing else)
1. Brief template (stable prefix, starts with `charter: v2` and the one-line pointer to the rule file).
2. The card YAML.
3. Allowlisted file paths (Worker) / test paths (Tester) / diff path + Tester report (Reviewer).
4. Anchor excerpts: `docs/source/<DOC>.md` line ranges from `context_anchors`, pasted as excerpts ≤60 lines each.
5. Skill paths (≤3 + one role skill) from the card's `skills:` block, resolved against the skills root in `08_SKILLS_MAP.md`. Paths only; the agent reads them itself.

## Templates
`docs/build/templates/card.yaml` · `feature_card_base.yaml` · `worker_brief.md` · `tester_brief.md` · `reviewer_brief.md` · `gate_packet.md` · `failure_digest.md` · `adr.md`

## T0 tooling for this pipeline (`scripts/plan/`)
| Script | Purpose |
|---|---|
| `convert_sources.py` | PDFs → anchored Markdown + `ANCHORS.txt` (run once) |
| `segment_rtm.py` | mechanical RTM rows (P0, F-nnn facets, D1–D5, UNV) |
| `merge_rtm.py` | merge/validate parts → `RTM.csv` |
| `validate_cards.py` | card schema, DoR fields, size cap, req_id existence, allowlist size, charter marker |
| `check_rtm_coverage.py` | every RTM row has ≥1 card or an EXTERNAL/DECISIONS entry; prints unmapped |
| `check_dependencies.py` | card graph acyclic; hard-stop ordering (§7.3) respected |
| `../check_agent_files.py` | `charter: v2` marker on agent-facing files |
