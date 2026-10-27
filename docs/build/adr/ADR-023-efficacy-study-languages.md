charter: v2

# ADR-023 — Efficacy-study language pair (Stage 1)

Status: **Accepted** (Tope, 2026-10-27). Records EP-§15-21 and EP-§15-22; unblocks P10-936.

## Decision

The external learning-outcome efficacy study (pre/post oral proficiency interview with blinded raters, per ELEVATION §15) will use **two Stage-1 languages**:

| Role | Language | `language_id` | Rationale |
| --- | --- | --- | --- |
| Tonal West African | **Yoruba** | `yo` | Flagship tonal track in Wave 1 (D28 Stage-1 set); largest documented diaspora demand in the seven-language roster; exercises the tone scorer, diacritic keyboard, and three-way tone-agreement pipeline that are central product differentiators. |
| Bantu | **isiZulu** | `zu` | Wave 1 Bantu representative with noun-class concord distinct from Swahili agglutination; Tier B content and Azure voice path already gated in release artefacts; click and depressor phenomena stress-test speaking feedback beyond Niger-Congo tone alone. |

### Alternatives considered (not selected)

- **Igbo (`ig`)** instead of Yoruba: equally tonal and Stage-1, but Yoruba is named in ELEVATION §15 as the exemplar tonal West African language and has the earlier A1 publish wave in the content plan.
- **Swahili (`sw`)** instead of isiZulu: Tier A and wider L2 demand, but efficacy should sample a Bantu morphology lane the product treats separately (P4-044 vs P4-045); isiZulu matches the ELEVATION §15 exemplar.

### Scope limits

- No efficacy statistics exist yet. Marketing and product copy must not cite study outcomes until a completed study is recorded with citations (P10-936 AC3).
- Study execution still depends on **EXT-20** (external partner). This ADR only fixes the language pair.

## Consequences

- P10-936 writes `docs/analytics/EFFICACY_STUDY_BRIEF.md` using `yo` and `zu` as the two arms.
- Analytics and experiment docs must reference this ADR when naming study languages.
