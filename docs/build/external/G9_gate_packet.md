---
card_id: P9-936
gate: G9
version: "1.0.0"
date: "2026-10-28"
recommendation: NO-GO
gate_open: false
blocked_external_logged:
  - id: P9-935
    reason: Blocked-External EXT-17 (third-party penetration test not complete)
  - id: P9-928
    reason: Blocked-External EXT-25 (CSAM vendor hotline / LE escalation accounts)
open_high_findings:
  - EXT-17
  - EXT-25
evidence_links:
  safety_lead: docs/safety/INCIDENT_RESPONSE.md
  load_test: docs/build/external/loadtest_report.md
  pen_test: docs/build/EXTERNAL.md#EXT-17
  csam_vendor: docs/build/EXTERNAL.md#EXT-25
  evaluation_report: docs/build/06_TEST_STRATEGY.md
policy_matrix_tests:
  backend:
    - node-backend/src/__test__/P9-918.capabilities.test.ts
    - node-backend/src/__test__/P9-930.userSafety.test.ts
    - node-backend/src/__test__/P9-927.csamHash.test.ts
    - node-backend/src/__test__/P9-926.mediaModeration.test.ts
  mobile:
    - test/services/capability_gate_test.dart
    - test/widgets/safety/safety_actions_sheet_test.dart
---

# Gate packet — G9 Safety + social (≤400 words)

| Field | Value |
|---|---|
| Gate | G9 |
| Phase | P9 |
| Date | 2026-10-28 |
| Recommendation | **NO-GO** |

## RTM coverage delta

| Status | Before | After |
|---|---|---|
| Verified-Done (P9 safety chain) | P9-903…P9-934 Done | Unchanged |
| Blocked-External | EXT-17, EXT-25 Open | Logged; gate stays closed |
| Open | G9 not passed | G9 verification packet assembled |

## Exit criteria (03_PHASES_GATES.md)

| Criterion | Measure | Result | Evidence |
|---|---|---|---|
| Guardian hub + age tiers | Minor policy matrix enforced on API | **Pass (automated)** | `P9-912`–`P9-920` tests |
| Moderation console + report/block ≤2 taps | Tap ledger + sheet actions | **Pass (automated)** | `P9-930` mobile + backend tests |
| CSAM hash + pHash before visibility | Scan before serve on unencrypted uploads | **Pass (automated)** | `P9-927`, `P9-926` tests |
| Socket/auth load at 10k | Staging soak 30m | **Pending** | `loadtest_report.md` (no staging PASS row) |
| Safety lead + IR + training | Signed lead, tabletop date | **Pass** | `INCIDENT_RESPONSE.md`, P9-934 check |
| Third-party pen test | No open **high** findings | **Fail (blocked)** | EXT-17 Open → P9-935 not Done |

Any open high pen-test or CSAM-vendor finding keeps **gate_open: false** (AC4).

## Tests and evals

Run `scripts/safety/g9_gate_check.py --check` (policy matrix + packet integrity). Backend Jest suites listed in front matter; mobile widget tests for capability gate and safety sheet.

## Open risks

1. EXT-17 pen test not executed — minors' social must stay feature-flagged off in prod.
2. EXT-25 production CSAM vendor + hotline contacts not contracted.
3. Staging 10k socket soak not recorded PASS.

## Decisions needed from Tope

1. Schedule EXT-17 pen test scope sign-off (routes, sockets, auth, minors' surfaces).
2. Confirm CSAM vendor (EXT-25) before claiming G9 GO-WITH-CONDITIONS.
