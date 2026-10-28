charter: v2

# ADR-037 — Moonshot start gate (RM-STOP-01 / RM-MS-10)

Status: **Accepted** (Tope, 2026-10-28). Records ELEVATION §16.4 moonshots and §16.5 RM-STOP-01; unblocks P13-005–P13-011 **design** cards only at Draft — not implementation Ready.

## Decision

No **moonshot** plan card may move to status `Ready`, `Spec-Tests`, `Build`, `Test`, `Review`, or `Done` until **RM-STOP-01** is satisfied: all **151** user-facing feature cards (`F-001`…`F-151`) are **Done** in `docs/plan/CARD_STATUS.tsv` **and** each mapped screen in `docs/build/REPO_MAP.md` is **reachable** from `lib/main.dart` (connected in the shell graph).

Moonshot cards (this gate applies):

| Card | Title |
| --- | --- |
| P13-005 | Living Archive path to 95+ languages |
| P13-006 | Open tone corpus and on-device tone model |
| P13-007 | Grandma Mode family dialect recordings |
| P13-008 | Living history and AR grounded in archives |
| P13-009 | Ajami, Nsibidi, Adinkra and Ge'ez script journeys |
| P13-010 | Heritage Language Fund mechanics |
| P13-011 | Verified native teacher marketplace |

Design-only work (markdown, ADRs, partnership one-pagers) may continue in **Draft** without this proof. Starting moonshot **build** is what RM-STOP-01 blocks.

### Sign-off owner and evidence

| Field | Value |
| --- | --- |
| **Owner (RM-STOP-01)** | **Tope** |
| **Machine evidence** | `docs/build/moonshot/rm_stop_01_evidence.json` (refreshed by `scripts/plan/moonshot_start_gate.py --refresh`) |
| **Connectivity source** | `docs/build/REPO_MAP.md` § Features F-001…151 (`reachable` per row) |
| **Feature completion source** | `docs/plan/CARD_STATUS.tsv` (`F-*` rows) |

Tope sets `tope_signed_off: true` and `signed_off_at` in the evidence JSON only after machine checks pass. Until then, `moonshot_start_gate.py` refuses moonshot status promotion and logs `MOONSHOT_START_REFUSED`.

### Alternatives considered

- **Product OK without reachability:** Rejected — RM-STOP-01 explicitly requires features “finished **and connected**”.
- **Skip ADR and gate in CI:** Rejected — moonshots are 9–24 month items; early start risk is organisational, not technical.

## Consequences

- P13-005–P13-011 depend on P13-004; they stay Draft for build until evidence + Tope sign-off.
- EXT-28, EXT-29, EXT-30 remain Open; this ADR does not authorise spend on moonshot vendors.
- CI may run `python3 scripts/plan/moonshot_start_gate.py --gate` on release branches (non-zero exit while RM-STOP-01 open).
