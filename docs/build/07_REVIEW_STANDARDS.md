charter: v2

# 07 — Review standard

Reviewer is a different model than the Worker (never the same model + same prompt). Tier rules: reviewer ≥ worker tier when blast ≥ 2; ≥ T2 for any `p0_area`; T4 (Fable) for safety, legal, payments, credentials, design gates, ADRs.

## Verdicts
Verdict vocabulary is fixed by `templates/reviewer_brief.md`: `PASS` | `FIX (n items)` | `BLOCK`.

| Verdict | Meaning | Next |
|---|---|---|
| `PASS` | all ACs proven by Tester evidence; no Major finding | card → Done |
| `FIX (n items)` | Major/Minor items listed with `file:line` and checklist # | same Worker fixes; re-review by same Reviewer; second `FIX` on the same item ⇒ new Worker (different model) |
| `BLOCK` | hard-stop violated, security/privacy flaw, fabricated output, minor-safety gap, or scope/spec conflict | Orchestrator; `CONFLICTS.md` / `DECISIONS.md`; card returns to `Draft` if the spec is wrong |

## Checklist (every item answered; `N/A` must say why)
| # | Check | Evidence required |
|---|---|---|
| 1 | Every `acceptance_criteria` GWT has a named passing test | Tester `AC<n>: PASS` lines |
| 2 | Spec-Tests were red before the change (spec-before-code) | Tester Mode A report |
| 3 | No files outside `allowlist` touched | diff path list |
| 4 | Hard-stop tags satisfied (provider card Done, not merely referenced) | card status lookup |
| 5 | No fake success, placeholder, stub, or `TODO` in shipped paths | lint output |
| 6 | Source anchors in card match what was built; no invented requirements | spot-check 2 anchors |
| 7 | Errors handled on every async path; no silent catch; no secrets logged | code read |
| 8 | Input validated at boundaries; authz per endpoint; least privilege | code read + authz tests |
| 9 | UX: states kit present; a11y semantics; token compliance; copy rules | widget tests + lints |
| 10 | UI (when `visual_evidence_required`): matches approved hi-fi; golden diffs explained | design-gate sheet |
| 11 | Performance budget not regressed on hot paths | perf CI line |
| 12 | Migration reversible; feature flag default-off until gate | migration test |
| 13 | Docs/ADR updated when behaviour or decision changed | diff |
| 14 | Token budget respected; `LEDGER.csv` row present | ledger |
| 15 | Report carries `charter: v2` | header |

## Severity
| Severity | Definition | Effect |
|---|---|---|
| Blocker | hard-stop violated, security/privacy flaw, fabricated output, minor-safety gap | `BLOCK` |
| Major | AC unproven, missing state, untested async error path, allowlist breach | `FIX` |
| Minor | naming, comment, small UX polish inside spec | `FIX` (may land with the Major fixes; alone it still blocks Done until fixed) |
| Note | suggestion, follow-up card proposed | no effect; Orchestrator may open a card |

## Report format
Exactly the ≤20-line block in `templates/reviewer_brief.md` (`charter: v2`, card, reviewer tier, verdict, numbered items with `file:line` + checklist #, top risk). Out-of-scope defects found go to a new card, never fixed inline.

## Epic and gate review (Fable)
- Epic integration: run the epic's cross-card e2e; verify every child card Done; verify RTM rows for the epic now map to tests (`check_rtm_coverage.py --write`).
- Gate packet (`templates/gate_packet.md`): exit criteria table with pass/fail per row, open EXT blockers, decisions pending, UX/UI scorecards (hub gates), risks. Tope approves; nobody else.
- Honest-by-design: any criterion not met is written as `FAIL` with the gap, never softened.
