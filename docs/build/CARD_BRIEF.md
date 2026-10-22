charter: v2 — bound by `.cursor/rules/00-token-economy.mdc`. No narration; outputs are YAML files plus a ≤8-line report.

# Card drafting brief (engineering cards)

## Inputs you receive
- One RTM slice: `docs/build/rtm_slices/<slice>.csv` (columns `req_id, source_doc, anchor, type, verbatim_hook, …`). Read it once.
- A card id range and output directory `docs/build/cards/<phase>/`.
- Source text: only when a hook is not enough, read the anchored lines with `Read(offset, limit)` on `docs/source/ELEVATION.md` or `CURRICULUM.md` (anchor `§x.y:L120-L140` = lines 120–140). Never read beyond the slice's anchors.

## Goal
Every `req_id` in the slice appears in `req_ids` of ≥1 card you write (run `python3 scripts/plan/slice_coverage.py <slice.csv>` until it prints `OK`). Rows of type `informational` attach to the card that fixes the defect they describe. Rows of type `external` attach to the card that needs them and set `external_blockers: [EXT-nn]` (see `docs/build/EXTERNAL.md`). Rows of type `decision` attach to an `adr` card. Rows of type `metric` attach to the card whose AC carries the number.

## Card shape (copy exactly; validator: `python3 scripts/plan/validate_cards.py docs/build/cards/<phase>/*.yaml` must print OK)
```yaml
charter: v2
id: P1-004                 # == filename stem; use your assigned range
kind: build                # build | design | adr | verification | epic(not yours) | external(not yours)
title: <verb-first, ≤10 words>
phase: P1
epic: E-P1-CONTAINMENT     # the phase epic (exists); you may add E-<phase>-<SLUG> sub-epics as kind: epic cards
req_ids: [P0-4, EP-§9.5-02]           # must exist in RTM.csv
depends_on: [E-P0-INTAKE]             # card ids that exist (epics exist; your own cards too)
size: M                               # S|M|L; XL forbidden → split
difficulty: {score: 8, blast: 3, ambiguity: 1, coupling: 2, depth: 2, size: 0}   # parts sum == score; caps 3/2/2/2/1
tiers: {worker: T3, tester: T3, reviewer: T3, justification: "<one line from the score>"}
token_budget: 80000                   # S ≤30000, M ≤80000, L ≤200000
file_allowlist: [node-backend/src/services/socket.service.ts]   # ≤12 real repo paths (use paths cited in the source; new files allowed)
context_anchors: [ELEVATION.md#§1:L132-L141]                     # anchors only, never source text
acceptance_criteria:
  - {id: AC1, text: "Given <state>, when <action>, then <observable result with number where the source gives one>"}
test_plan: {unit: [...], integration: [...], security: [...], e2e: [], perf: [], a11y: [], content: []}   # fill the relevant layers; empty lists allowed
user_facing: false
ux_spec: null              # REQUIRED object when user_facing: true → {states: [...], copy_keys: [...], tokens: [...], motion_tier: product|rare, a11y: [...], goldens: [...]}
tags: []                   # hard-stop tags: consumers shows_score | issues_credential | under18_social | enables_persona | tts_tonal | uses_source ; providers scorer_real | content_real | guardian_moderation | ai_disclosure | tone_accuracy_gate | licence_register | placeholder_linter | native_verified_rule
p0_area: false             # true when the card touches auth, sockets, rewards, AI gateway, minors, moderation, payments, secrets
security_dsp_crypto: false # true allows tester T3
visual_evidence_required: false   # true only for design-gate cards
dod_evidence: [tester report, coverage on touched domain code, ledger row]
risks: []
gate: G1                   # G0..G13 or HUB
external_blockers: []
status: Draft
```

## Tier rules (04_ROUTING.md)
score 0–2 → worker T0/T1 · 3–4 → T1/T2 · 5–6 → T2 · 7–10 → T3. Tester ≤T2 unless `security_dsp_crypto`. Reviewer ≥ worker when blast ≥2; ≥T2 when `p0_area`. Prefer the cheapest tier that is correct.

## Content rules
- One card = one deliverable with ≤8 ACs. Split anything larger. Prefer S/M.
- ACs are Given/When/Then, testable, numeric where the source is numeric. No vague verbs ("improve", "enhance").
- No-Cut: never drop a requirement; consolidation cards list `harvest_list: [...]`.
- Fail loud: every error path in an AC is a typed error or visible state; no fake success.
- Honest by design: labels, "unsure" states, no fabricated numbers appear in ACs where relevant.
- Hard stops: a card that shows a pronunciation/tone score to a learner gets `tags: [shows_score]` and `depends_on` must include `E-P6-SCORER`; credentials → `issues_credential` + `E-P5-CONTENT-REAL`, `E-P6-SCORER`; under-18 social → `under18_social` + `E-P9-SAFETY`; enabling a persona → `enables_persona` + `E-P1-CONTAINMENT`; TTS for yo/ig/ha → `tts_tonal` + `E-P6-SCORER`; using a content source → `uses_source` + `E-P4-CONTENT-ENGINE`.
- Items tagged `[verify] [purchase] [quote] [Unverified] [estimate]` stay unverified: create `kind: verification` cards (S, T0/T1) whose AC is the verification itself.
- Never paste source sentences into cards; cite anchors.
- Keep YAML compact; no comments inside cards.

## Report (≤8 lines)
cards written (count, id range) · slice coverage line · validator line · splits or ambiguities (≤3, one line each).
