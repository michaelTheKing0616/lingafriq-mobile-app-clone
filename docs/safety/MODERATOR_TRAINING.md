---
card_id: P9-934
version: "1.0.0"
effective_date: "2026-10-28"
training_modules:
  - id: mod-101
    title: Community guidelines enforcement
    source: docs/safety/community_guidelines.md
  - id: mod-102
    title: Grooming-pattern recognition
    source: node-backend/src/services/moderation/groomingRules.json
    companion_code: node-backend/src/services/moderation/grooming.heuristics.ts
  - id: mod-103
    title: Evidence handling and appeals
    source: P9-931 moderation console + P9-932 appeals flow
  - id: mod-104
    title: Incident response handoff
    source: docs/safety/INCIDENT_RESPONSE.md
grooming_training_required: true
active_moderators:
  - moderator_id: mod-trust-001
    display_name: Trust & Safety Moderator (primary panel)
    completed_at: "2026-10-22"
    modules_completed: [mod-101, mod-102, mod-103, mod-104]
  - moderator_id: mod-trust-002
    display_name: Trust & Safety Moderator (backup panel)
    completed_at: "2026-10-24"
    modules_completed: [mod-101, mod-102, mod-103, mod-104]
---

# Moderator training (Trust & Safety)

All moderators with queue access must complete the modules listed in front matter before handling live cases. Training content is English-only for v1; localized briefs follow community guidelines ARBs.

## Module mod-101 · Community guidelines

- Read `community_guidelines.md` and map report reasons to clause ids.
- Practice: classify three fixture reports without opening sealed media (use admin e2e fixtures).

## Module mod-102 · Grooming-pattern recognition

**Required for every active moderator.**

- Study `groomingRules.json`: weighted signals, adult→minor context, and the disclosure that heuristics never auto-accuse learners.
- Review `grooming.heuristics.ts` escalation path: high-priority case creation, evidence audit fields, precision ledger updates after human review.
- Practice drills (fixture transcripts only):
  - Secret-keeping requests and platform migration (“delete this app and use …”).
  - Gift or money offers tied to private contact off-platform.
  - Age probing combined with flattery or isolation from guardians.

Moderators must not change grooming rules without safety lead approval and eval harness re-run (P9-923).

## Module mod-103 · Evidence and appeals

- Blurred evidence UI, SLA tiers, and party notices (P9-931).
- Appeals assigned to a different moderator than the original action (P9-932).

## Module mod-104 · Incident handoff

- When to page the safety lead, how to seal evidence, and hotline reporting prerequisites (see `INCIDENT_RESPONSE.md`).

## Completion records

Front matter `active_moderators` lists every moderator with live queue access and their `modules_completed` dates. Adding a moderator requires updating this file and re-running `scripts/safety/safety_ops_check.py` in CI.
