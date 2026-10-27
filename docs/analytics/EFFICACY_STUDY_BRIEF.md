---
card: P10-936
status: open
partner_blocker: EXT-20
adr: ADR-023
language_arms:
  - language_id: yo
    label: Yoruba
    role: tonal West African (Stage 1)
  - language_id: zu
    label: isiZulu
    role: Bantu (Stage 1)
study_results: none
efficacy_required_sections:
  - "Study status"
  - "Language arms"
  - "Primary outcome measure"
  - "Rater blinding and training"
  - "Timeline"
  - "Sample size and power"
  - "Partner role (EXT-20)"
  - "Handoff"
---

# LingAfriq external learning-outcome efficacy study — design brief

This brief satisfies EP-§15-18 through EP-§15-20 and EP-§15-23–24. It implements ADR-023 (`docs/build/adr/ADR-023-efficacy-study-languages.md`). **No study has been run. No efficacy statistics exist yet.** Product, marketing, and analytics copy must not cite learning gains, effect sizes, or significance until a completed study is recorded with citations.

## Study status

| Field | Value |
| --- | --- |
| Results | **None** (design only) |
| Partner | **Not contracted** — blocked on **EXT-20** (external research partner) |
| Owner for partner outreach | Tope |
| Languages fixed | `yo`, `zu` per ADR-023 |

## Language arms

Each arm uses the same protocol; outcomes are reported **per language** and in aggregate only after pre-registration allows it.

| Arm | `language_id` | Rationale (ADR-023) |
| --- | --- | --- |
| Tonal West African | `yo` | Flagship tonal track; tone scorer, diacritic keyboard, three-way tone agreement |
| Bantu | `zu` | Noun-class concord distinct from Swahili; click and depressor speaking feedback |

Learners are assigned to one arm by stratified randomisation (L1 English vs other, prior exposure self-report, child account excluded). Minors are out of scope for this study protocol.

## Primary outcome measure

**Pre/post oral proficiency interview (OPI-style)** with **blinded independent raters** for each language arm.

1. **Baseline** OPI within 14 days of enrolment (before regular app use beyond onboarding).
2. **Intervention**: documented minimum exposure (hours in app, speaking attempts logged via `speech_attempt_scored`, can-do demonstrations via `cando_demonstrated`) — thresholds set in the partner protocol addendum once EXT-20 signs; not fixed here.
3. **Post** OPI within 14 days after the intervention window closes.
4. **Scoring**: rubric aligned to ACTFL-style functional ratings (novice/low–mid bands for Stage-1 A1 learners). Raters score from audio only; they do not see app UI, usernames, or pre scores during post scoring.

Secondary outcomes (exploratory, pre-registered separately): tone accuracy aggregates from server scorer, can-do badge attainment, session retention. None of these substitute for the primary OPI outcome in marketing claims.

## Rater blinding and training

- Raters are **native speakers** of the target language, contracted via the EXT-20 partner, with no LingAfriq employment conflict.
- **Blinding**: post-hoc clips are identified by study IDs only; raters never see learner identity or treatment assignment labels.
- **Training**: calibration on a shared anchor set (partner-supplied or co-created); inter-rater agreement monitored before live scoring; adjudication process for disagreements documented in the partner SOP.
- LingAfriq engineering provides **de-identified audio exports** only under the data-processing terms in the partner agreement (see P10-919 DPIA and voice-consent flows).

## Timeline

Target: **complete enrolment, intervention, and post-OPI within twelve months** of the EXT-20 contract start date (ELEVATION §15). Milestones:

| Phase | Duration (relative) | Deliverable |
| --- | --- | --- |
| Partner contracting | Months 0–1 | Signed EXT-20 SOW, IRB or local ethics if required |
| Instrument & rubric lock | Months 1–2 | Pre-registered protocol, rater manual |
| Recruitment | Months 2–4 | Per-language enrolment per approved sample plan |
| Intervention | Months 4–9 | Monitored app use per protocol |
| Post OPI & analysis | Months 9–12 | Blinded scoring complete; analysis report to LingAfriq |

Dates slip if EXT-20 is not signed; this brief remains **open** until results exist.

## Sample size and power

**No target N is set in this document** (no invented statistics). After EXT-20 onboarding:

1. Partner biostatistician runs a **pre-registered power analysis** using the chosen minimum detectable effect on the OPI rubric, α, and power (conventional 0.05 / 0.80 unless ethics board requires otherwise).
2. Assumptions (baseline variance, attrition) come from **pilot data or published OPI studies** cited in the protocol addendum — not from LingAfriq marketing.
3. Enrolment stops when the approved N per arm is met or the ethics-approved cap is reached.

## Partner role (EXT-20)

The external partner (EXT-20) is expected to:

- Lead ethics/IRB or equivalent where required
- Recruit and compensate participants per local law
- Train and manage blinded raters
- Hold the authoritative analysis plan and release a citable report
- Allow LingAfriq to verify de-identification and retention limits against the DPIA

Until EXT-20 is signed, LingAfriq does not run recruitment or collect study-labelled OPI audio.

## Handoff

**Tope**: initiate or continue EXT-20 partner search; attach this brief to vendor conversations. When a partner is selected, update front matter `status` to `protocol_locked` and file the signed protocol reference in the licence register.

**Engineering**: no feature flags for “efficacy mode”; use standard analytics (`events.v1.json`) with study IDs only after partner SOP exists.

## References

- ADR-023 — efficacy language pair (`yo`, `zu`)
- ELEVATION §15 — learning-outcome research requirement
- `../node-backend/docs/analytics/EXPERIMENT_RULES.md` — pre-registration discipline for in-product experiments (separate from this external study)
