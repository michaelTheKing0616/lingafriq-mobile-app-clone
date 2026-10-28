charter: v2

# Grandma Mode — family dialect recordings (P13-007)

Status: **Design complete** (builder, 2026-10-28). Implements ELEVATION §16.4 RM-MS-03 / RM-MS-12: family members record phrases in their own dialect; diaspora learners practise with honest labels and consent. **Implementation** remains blocked by ADR-037 (RM-STOP-01) until F-001…F-151 are Done and connected.

## Product boundary

Grandma Mode is **heritage-family UGC audio**, not the Living Archive L0 corpus (P13-005) and not the paid teacher marketplace (P13-011). Lessons generated from a recording stay **private to the inviting learner circle** until native review clears wider sharing.

## Recording consent and licence (before storage)

| Gate | Requirement | Implementation hook |
| --- | --- | --- |
| **Recorded consent** | Contributor hears a plain-language script, taps record, then confirms retention scope (family circle only vs request wider publish) | New `family_recording_consent` capture UI; audio of consent optional where counsel requires (EXT-18) |
| **Licence choice** | Contributor picks one of: *family-private* (default), *CC-BY family share*, or *decline model-training*; choice stored before blob upload | `licence_register.csv` row + `consent_record_id` on v2 envelope (`P4-100`) |
| **Voice storage** | Separate from practice scoring retention; must use `voice-consent.service.ts` opt-in copy and guardian rules | P10-922 |
| **Model training** | Off by default; optional second opt-in via `training-consent.service.ts` — never bundled with Grandma upload | P10-923 |

No object storage write until `consent_record_id`, `licence_register_id`, and `contributor_ids` are persisted server-side.

## Family-sourced label and native review before wider sharing

| Stage | Label / readiness | Learner copy |
| --- | --- | --- |
| **Draft lesson (circle only)** | `ai_assisted` or `expert_reviewed` max; `provenance: family_sourced` | “Recorded by your family — not verified for all speakers of this dialect.” |
| **After native panel** | May promote per `native_validation.py` + `readiness.py` | Standard `content_label_*` keys; never `native_verified` without two-native evidence |
| **Wider than circle** | Blocked until `review_assignment.py` queues linguist + native reviewers (`P4-132`) | Village / public surfaces stay off until review passes |

Generated items (TTS, exercise text) inherit **family_sourced** and must pass `drafting_policy.py` / `grounded_prompt.py` — no free-form LLM phrases without lexicon anchor.

## Minors, guardians, and moderation (E-P9-SAFETY)

| Case | Rule | Source |
| --- | --- | --- |
| **Contributor under 18** | Guardian consent required before record; same pattern as voice-storage minor block | `voice-consent.service.ts`, guardian hub |
| **Subject in recording is a minor** | Face/voice treat as minor UGC: blur on share (`face_blur.dart`), no public Village post without guardian approval | P7-911, moderation queue |
| **Abuse / CSAM** | Standard report → escalation (`P4-161`); family recordings are in scope for CSAM matching when uploaded | E-P9-MODERATION |

Family circles use **existing** circle/guardian policies; Grandma Mode does not add under-13 social discovery.

## Consent withdrawal and deletion

| Asset | On withdraw | SLA |
| --- | --- | --- |
| **Raw family recording** | Delete blob + alignment sidecar; revoke derived lesson publish | **30 calendar days** after withdraw request (align with `VOICE_STORAGE_WITHDRAW_PURGE_DAYS` in P10-922) |
| **Derived exercises / TTS** | Version-bump pack removal; strip from learner devices on next sync | Same purge job batch as recording |
| **Training queue** | If training opt-in was ever granted, `withdrawTrainingContribution` queues clip removal | P10-923 |

`purge_due_at` is set at withdraw time; nightly retention job (`P10-921`) logs per-user completion.

## Proposed build cards (sizes — not started until RM-STOP-01)

| Card | Title | Size | Depends on |
| --- | --- | --- | --- |
| P13-007a | Family circle invite + Grandma record flow (consent script, licence picker, upload gate) | L | P10-922, P10-923, P13-007 |
| P13-007b | `family_sourced` provenance on v2 items + studio review queue | M | P4-100, P4-132, P13-007 |
| P13-007c | Lesson generator from aligned family clip (phrase cards, listen-repeat, scorer) | L | P4-123, P6-031, P13-007b |
| P13-007d | Heritage milestones + “phrase of the week” teach-back (circle goals) | M | P10-909, F-027.E, P13-007c |
| P13-007e | Withdraw + purge orchestration for family blobs and derived packs | S | P10-921, P13-007a |

Placeholder IDs register in plan when RM-STOP-01 clears.

## Risks

- DPIA threshold for multi-party family voice (EXT-18) — counsel review before public beta.
- Dialect lessons must not bypass `anglicisation.py` / kit linters when PCM-adjacent.
- Paid contributor terms (P4-128) are separate; family path stays voluntary.
