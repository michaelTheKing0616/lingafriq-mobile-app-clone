charter: v2

# ADR-022 — Contributor payment and benefit-sharing for voice and training data (P10-924)

Status: **Accepted** (Tope, 2026-10-27). Records EP-§13.2-15 and unblocks P10-923 (training consent copy and scope).

## Context

Elevation §13.2 requires separate consent before learner recordings enter model-training datasets, and expects **payment or benefit-sharing** for contributors. LingAfriq also runs contracted native linguists (D4), optional voice contributions, Cowries (ADR-020), and a community language-preservation fund (P10-904). Cash payroll for every casual learner clip is neither scalable nor appropriate for minors.

## Decision

| Contributor class | Compensation | Notes |
| --- | --- | --- |
| **Default learners** (practice, scoring, no training opt-in) | **Neither** | No payment or benefit-sharing; recordings follow P10-922 storage consent and delete-after-scoring defaults. |
| **Learners who opt in to model-training contribution** (P10-923) | **Benefit-sharing** | Approved clips earn **Cowries** on a published per-language table with diminishing returns (same family as XP rules). Optional **public attribution** on profile or content credits only with a second, explicit consent. A configurable share of Heritage Fund inflows (`contributor_benefit_pool_percent`, default **0** until EXT-03 and counsel set a non-zero value) is earmarked for periodic Cowries grants to opted-in contributors proportional to approved minutes. **No fiat micropayments** in-app for training clips; cross-border cash rails require separate contracts and counsel review. |
| **Contracted linguists, reviewers, and studio contributors** (D4, EXT-11, P4-128 when unblocked) | **Payment** | Fees under written contract with consent and IP assignment; outside the in-app Cowries benefit-sharing table. |

**Legal basis (for counsel review, not legal advice):** training contributions rely on **explicit consent** under Nigeria NDPA 2023 and parallel GDPR/POPIA lawful-basis mapping; benefit-sharing Cowries are **contractual counter-performance** documented in the training-consent record (scope, version, timestamp). Contracted work uses **contract** as the lawful basis. Heritage Fund pool percentages and any future marketplace revenue share stay **config-only** until EXT-03 and jurisdiction review.

**Alignment:** `language_kit.py` and the language registry continue to record `benefit_sharing_terms` (e.g. `standard benefit-sharing v1` referencing this ADR). Intron and other non-commercial training sources remain off product flags.

## Consequences

- P10-923 implements distinct training consent, withdrawal, and minor exclusion; benefit copy cites this ADR.
- P10-904 Heritage Fund reporting may surface contributor-pool allocations when `contributor_benefit_pool_percent` is non-zero.
- P4-128 (Blocked-External) still needs executed contributor licence and payment terms for paid studio work; this ADR does not replace counsel or EXT-03.
