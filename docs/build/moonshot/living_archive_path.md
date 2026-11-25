charter: v2

# Living Archive path to 95+ languages (P13-005)

Status: **Design complete** (builder, 2026-10-28). Implements ELEVATION §16.4 RM-MS-01 / RM-MS-08 and Wave 4 in `wave_roster_decision.json`. **Build** of Wave 4 kits remains blocked by ADR-037 (RM-STOP-01) until all F-001…F-151 are Done and connected.

## Goal (not a product claim)

LingAfriq targets **95+ languages** in the **Living Archive** (Wave 4) as a **long-horizon goal**. Marketing, store copy, and in-app strings must **not** state that 95+ languages are available today. Use honest readiness labels (`readiness.py` L0–L3) and wave gates (`P4-111`, `P4-112`).

## Wave 4 entry (community starter admission)

| Step | Mechanism | Card |
| --- | --- | --- |
| 1 | Candidate language copies `content/templates/later_wave_language.yaml` (four admission entries: orthography authority, licensed/PD lexicon, reference grammar, CC-BY/PD corpus) | P13-001 |
| 2 | `scripts/content/later_wave_admission.py` rejects empty entries with named missing fields | P13-001 |
| 3 | `scripts/content/lexicon_gate.py` blocks promotion **above L0** until a usable lexicon row exists in the licence register | P13-003 |
| 4 | `wave_roster_decision.json` `wave_4_start_rule` must be satisfied before bulk Wave 4 kit generation | P4-111 |

Community starters are **L0 Taste** tracks (`wave_label_rules.py`): folktales, praise poetry, songs, proverbs with contributor credit — not full A1–B1 course parity with Stage-1 languages.

## No native reviewers → L0 + honest learner label

When `native_validation.py` cannot assign two native reviewers (EXT-11 / panel shortfall):

- **Maximum readiness:** L0 (`readiness.py`).
- **Publish label:** `expert_reviewed` or lower; never `native_verified` without panel evidence.
- **Learner-facing copy** (ARB keys `content_label_l0_community`, `content_label_no_native_panel`): state that content is **community-built**, **limited depth**, and **not native-verified**; link to Contribute / Verify queue where enabled.
- **Promotion:** `lexicon_gate.py` and `readiness.py` refuse L1+ until lexicon gate and reviewer panel gates pass.

## Contributor credit, licences, and benefit-sharing

| Topic | Rule | Source |
| --- | --- | --- |
| **Credit** | Every archive item carries `contributor_ids`, `consent_record_id`, and `licence_register_id` in v2 schemas (`P4-100` envelope) | Studio + pipeline |
| **Licences** | Only commercially usable or PD/CC-BY sources per `licence_register.csv`; counsel sign-off on register (EXT-03) before scale publish | P4-106, EXT-03 |
| **Voice / training clips** | Separate model-training consent (P10-923); benefit-sharing per ADR-022 (Cowries table, no fiat micropayments for casual clips) | ADR-022 |
| **Paid studio contributors** | Written contract + IP (P4-128 when unblocked); not mixed with Living Archive volunteer L0 path | P4-128 |

## Proposed build cards (sizes — not started until RM-STOP-01)

| Card | Title | Size | Depends on |
| --- | --- | --- | --- |
| P13-005a | Living Archive admission CLI + admin queue for Wave 4 YAML files | M | P13-005, P13-001, P13-003 |
| P13-005b | Archive content schema (folktale / oríkì / song / proverb) + linter | M | P4-104, P13-005 |
| P13-005c | Learner Living Archive hub (browse L0 only, credit strip, licence badge) | L | F-028, P13-005b |
| P13-005d | Contributor upload + consent capture for archive media | L | P10-923, P4-128, P13-005b |
| P13-005e | Scale metrics dashboard (languages at L0, goal progress, no 95+ claim) | S | P13-005, P4-158 |

Card IDs `P13-005a`…`e` are **placeholders** for RTM split; register in plan when RM-STOP-01 clears.

## Risks

- Overlap with RM-P2-04 contributor marketplace (P13-011) — Living Archive stays **L0 cultural corpus**, not paid tutoring.
- Wave 4 breadth must not bypass P13-004 moonshot gate for implementation Ready.
