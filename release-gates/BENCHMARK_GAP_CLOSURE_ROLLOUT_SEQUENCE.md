# Benchmark Gap Closure Rollout Sequence

## Sequencing Model

Rule: `P0` must be green before `P1`; `P1` must be green before `P2`.

| Phase | Target Epics | Entry Criteria | Exit Gate (Must Be True) |
|---|---|---|---|
| P0 Foundation Reliability | E1, E2, E3 | Route + contract baselines available; telemetry schema frozen for phase | [ ] E1 KPIs hit for 7-day rolling window. [ ] E2 KPIs hit for 7-day rolling window. [ ] E3 KPI instrumentation complete with CI pass. |
| P1 Product Quality Lift | E4, E5, E6 | P0 exit gate green; QA regression suite expanded for AI/persona/content domains | [ ] E4 mode-identity and correction KPIs hit for 2 consecutive sprints. [ ] E5 completion + continuity KPIs hit. [ ] E6 freshness + placeholder-zero gate green. |
| P2 Scale And Governance Plus | E7, E8 | P1 exit gate green; experimentation and moderation pipelines operational | [ ] E7 retention/adaptive KPIs hit for one full cohort cycle. [ ] E8 security/moderation/release-readiness gates green for 2 release trains. |

## Epic Rollout Checklist (Machine-Actionable)

| Epic ID | Phase | Dependency Checklist | KPI Readiness Checklist | Owner Role Suggestion |
|---|---|---|---|---|
| E1 | P0 | [ ] Route contract map finalized. [ ] Progress API error envelope stable. [ ] Telemetry events for path/streak merged. | [ ] Continuity KPI query in dashboard. [ ] Streak-write success KPI alert configured. [ ] Broken-path session KPI report automated. | Mobile Tech Lead |
| E2 | P0 | [ ] Socket event schema versioned. [ ] Retry/idempotency middleware deployed. [ ] Message-state persistence contract tested. | [ ] Send success KPI tracked by network profile. [ ] Duplicate rate KPI tracked per event type. [ ] Delivery failure buckets visible in dashboard. | Realtime/Backend Lead |
| E3 | P0 | [ ] Scoring provider contract signed. [ ] Rubric fixtures curated. [ ] Speaking task IDs normalized. | [ ] Coverage KPI computed nightly. [ ] Retry completion KPI segmented by language. [ ] False-negative KPI backed by labeled sample set. | Speech/AI Engineer |
| E4 | P1 | [ ] Prompt contract registry live. [ ] Mode UX tokens implemented. [ ] Correction policy service integrated. | [ ] Mode confusion KPI from blind QA runs. [ ] Helpfulness CSAT event collection active. [ ] Correction acceptance KPI tracked weekly. | AI Product Engineer |
| E5 | P1 | [ ] Persona memory boundary rules merged. [ ] Scenario metadata complete. [ ] Roleplay rubric pipeline available. | [ ] Session completion KPI by scenario. [ ] Continuity break KPI from automated checks. [ ] Confidence uplift KPI linked to survey+telemetry. | Product Manager (Learning) |
| E6 | P1 | [ ] Backend-first ingestion path enforced. [ ] Cache invalidation strategy tested. [ ] Editorial checklist codified. | [ ] Freshness SLA KPI with alerting. [ ] Error-report KPI by content type. [ ] Placeholder-zero guard monitored at publish time. | Content Platform Lead |
| E7 | P2 | [ ] Mastery model API stable. [ ] Review scheduler integrated. [ ] Cohort experimentation guardrails defined. | [ ] D30 retention KPI by cohort. [ ] WAU uplift KPI by treatment. [ ] Adaptive-review completion KPI by segment. | Growth Product Manager |
| E8 | P2 | [ ] Moderation tooling integrated with policy engine. [ ] Release-gate automation enabled. [ ] Incident rollback runbook validated. | [ ] Moderation SLA KPI dashboarded. [ ] Security gate pass KPI from CI release lane. [ ] Rollback drill evidence attached each train. | Security/Platform Lead |

## Cross-Phase Owner Allocation

| Role | P0 Capacity Focus | P1 Capacity Focus | P2 Capacity Focus |
|---|---|---|---|
| Mobile Tech Lead | E1 integration and KPI instrumentation | E4 UX signature parity checks | E7 experiment client hooks |
| Realtime/Backend Lead | E2 event reliability and idempotency | E6 content pipeline hardening | E8 policy and gate enforcement |
| Speech/AI Engineer | E3 pronunciation scoring reliability | E4 correction quality + E5 persona logic support | E7 adaptive policy tuning |
| QA Automation Engineer | P0 reliability regression suite | AI/persona/content regression suite | Release-gate compliance automation |
| Product Manager | KPI target finalization and baseline lock | Experience quality acceptance sign-offs | Retention/cohort and governance sign-offs |
| SRE/DevOps | Observability and alert thresholds | Cache + publish pipeline reliability | Security gate + rollback drill program |

## Governance Cadence

- Weekly: KPI scorecard update per epic owner.
- Sprint-end: Phase gate review with QA Lead + Product Manager + Platform/Security owner.
- Release candidate: Enforce exit-gate checklist; no override without incident commander approval.
