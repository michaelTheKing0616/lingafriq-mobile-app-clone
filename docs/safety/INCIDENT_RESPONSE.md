---
card_id: P9-934
version: "1.0.0"
effective_date: "2026-10-28"
safety_lead:
  name: Temitope Olaitan
  role: Chief Safety Lead
  contact_email: safety@lingafriq.com
deputy_safety_lead:
  name: LingAfriq Trust & Safety Deputy
  role: Deputy Safety Lead (on-call rotation)
  contact_email: safety-deputy@lingafriq.com
owner_signature:
  signed_by: Tope
  signed_date: "2026-10-28"
tabletop_exercise:
  last_completed: "2026-10-25"
  scenario: "CSAM hash match + grooming case parallel containment"
  participants:
    - safety lead
    - moderation ops
    - backend on-call
    - legal counsel (observer)
incident_response_sections:
  - detection
  - containment
  - notification
  - regulator_and_hotline_reporting
  - post_incident_review
---

# Incident response (Trust & Safety)

This plan covers child-safety and high-severity moderation incidents for LingAfriq Village, chat, classroom, and media surfaces. It complements automated detectors (P9-922–P9-927) and human moderation queues (P9-931).

## Detection

- Automated: CSAM hash matches, grooming heuristics (P9-925), image classifiers, toxicity eval gates, and SLA breaches on child-safety queues.
- Human: moderator console triage, user reports linked to community guidelines clauses, guardian escalations (P9-161), and staff on-call alerts from `GET /admin/analytics/northstar` week-close safety metrics when configured.

On detection, open or attach a `ModerationCase`, seal evidence per P9-161, and page the safety lead and deputy using the contacts in front matter.

## Containment

1. Suspend or restrict accounts involved per `userSafety.service.ts` and minor capability gates (P9-918).
2. Stop further distribution: hold media, revoke LiveKit/realtime tokens, disable persona and AI modes via kill switches (P6-007, P11-009).
3. Preserve append-only audit trails (`audit.service.ts`, moderation verdict records) before mutating user-visible state.
4. Document every action with timestamps, actor id, and case id in the moderation case ledger.

## Notification

- Affected users and guardians receive plain-language notices through in-app status and email where policy allows (no details that re-traumatize minors).
- Internal: safety lead notifies engineering, support, and legal within 60 minutes for child-safety severity.
- External comms drafts require safety lead + counsel approval before any public statement.

## Regulator and hotline reporting

- US-linked CSAM: file NCMEC CyberTipline when criteria are met; retain submission receipt in sealed evidence (law-enforcement hotline account provisioning tracked under EXT-25 / P9-928).
- Nigeria and other operating regions: follow local hotline and regulator contacts maintained in the safety lead runbook vault (Doppler); never store hotline credentials in this repo.
- Cross-border cases: legal counsel selects applicable reporting path; safety lead owns the timeline log.

## Post-incident review

Within five business days of closure:

- Root cause, detector gaps, and policy updates are recorded.
- Action items are assigned with owners and due dates.
- Moderator training or rule updates (see `MODERATOR_TRAINING.md`) are scheduled when human error or novel grooming patterns appeared.

## Tabletop exercise record

The latest tabletop is recorded in YAML front matter (`tabletop_exercise.last_completed`). Re-run at least quarterly or after any P0 child-safety incident.
