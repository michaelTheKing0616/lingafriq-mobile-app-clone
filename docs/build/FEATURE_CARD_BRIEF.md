charter: v2 — bound by `.cursor/rules/00-token-economy.mdc`. No narration; outputs are YAML files plus a ≤6-line report.

# Feature card brief (F-001…F-151)

Each feature gets exactly one card `docs/build/cards/<phase>/F-<nnn>.yaml` holding only its **delta**. The shared bar is inherited from `docs/build/templates/feature_card_base.yaml` (do not copy it).

## Inputs
- RTM slice `docs/build/rtm_slices/<slice>.csv`: rows `F-nnn` (anchor = the feature's deep-dive line range) and facet rows `F-nnn.D` (Defects), `.E` (Elevation), `.U` (UX and render), `.L` (Lives in).
- For each feature read **only** its anchored line range from `docs/source/ELEVATION.md` with `Read(offset, limit)`; it holds `What it is. / Code. / Current state. / Defects. / Elevation. / UX and render. / Lives in.`

## Card shape (validator: `python3 scripts/plan/validate_cards.py docs/build/cards/<phase>/F-*.yaml` must print OK)
```yaml
charter: v2
id: F-012
kind: feature
inherits: FEATURE_BASE
title: Elevate <feature name>
phase: P7                      # Today/Learn/Speak → P7 · Play → P8 · Village → P9 · Me → P10
epic: <hub epic given in your task>
hub: Learn
req_ids: [F-012, F-012.D, F-012.E, F-012.U, F-012.L]   # plus any P0-n / REV-nn / CON-nn ids the text names, if they exist in RTM.csv
depends_on: [E-P3-DESIGN-SYSTEM, E-P2-PLATFORM]          # add E-P6-SCORER if a score is shown; E-P9-SAFETY if social for under-18s; E-P5-CONTENT-REAL if it shows curriculum content; E-P1-CONTAINMENT if it calls AI
size: M
difficulty: {score: 5, blast: 1, ambiguity: 1, coupling: 2, depth: 1, size: 0}   # parts sum == score
tiers: {worker: T2, tester: T2, reviewer: T2, justification: "<one line>"}
token_budget: 80000
file_allowlist: [<paths from the 'Code.' line, ≤12>]
context_anchors: [ELEVATION.md#§18.3:L3700-L3720]
delta:
  current_state: <one line from 'Current state.'>
  defects_to_fix: [<one line each, from 'Defects.'>]
  elevation_to_build: [<one line each, from 'Elevation.'>]
  ux_and_render: [<one line each, from 'UX and render.' beyond the shared bar>]
  hub_placement: <from 'Lives in.'>
  unlock_stage: <from the text if stated, else "per §17.4">
  harvest_list: [<only when the text consolidates an older/parallel implementation: what moves over>]
acceptance_criteria:           # 3–6, Given/When/Then, derived from Defects + Elevation + UX; numeric where the text is numeric
  - {id: AC1, text: "Given …, when …, then …"}
test_plan: {unit: [...], integration: [...], e2e: [...], a11y: [goldens at 100%/200% text, semantics], content: []}
user_facing: true
ux_spec: {states: [skeleton, empty, error, offline, ai_unavailable, under_review], copy_keys: [<feature>.*], tokens: [design-system only], motion_tier: product, a11y: [semantics, reduced_motion, 200% text], goldens: [light, dark]}
tags: []                       # shows_score | issues_credential | under18_social | enables_persona | tts_tonal as applicable
p0_area: false                 # true if the text cites a P0-n
dod_evidence: [tester report, goldens diff, coverage on touched domain code, ledger row]
risks: []
gate: HUB
external_blockers: []          # EXT-16 for features needing Rive/illustration art; EXT-13 for native audio
status: Draft
```

## Rules
- Tier: default worker T2 (score 5–6). Use T1 only for scores ≤4 (thin screens with no logic). Use T3 for scores ≥7 (real-time audio, scoring, E2EE, moderation). Reviewer ≥T2 when `p0_area`.
- Size: S if only wiring/revive; M default; L only for flagship games or multi-screen flows. Never XL.
- Honest by design: a feature that today fakes a score, participant, or stat gets an AC that removes the fake and shows the honest state until the real dependency lands.
- Mandatory ACs per tag: `shows_score` ⇒ an AC that the UI shows the 'unsure' state and stores no number when the scorer is unavailable or below threshold; `under18_social` ⇒ an AC that the surface is hidden or guardian-gated for under-18 / age-unknown accounts, enforced server-side; `issues_credential` ⇒ an AC that nothing is signed without verified evidence.
- No-Cut: `harvest_list` is mandatory when `Current state.` or `Elevation.` mentions a duplicate/older/unrouted variant being consolidated.
- Do not paste source sentences; paraphrase into ≤1 line per bullet. Keep YAML compact, no comments.
- After writing, run `python3 scripts/plan/slice_coverage.py <slice.csv>` → must print `OK`.

## Report (≤6 lines)
cards written (ids) · coverage line · validator line · ≤2 ambiguities.
