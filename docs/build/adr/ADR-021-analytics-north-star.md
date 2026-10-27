charter: v2

# ADR-021 — North-star metric and analytics guardrails

Status: **Accepted** (Tope, 2026-10-27). Records EP-§15-01 and EP-§15-06; unblocks P10-934 and P10-935.

## North star

**Weekly learners who demonstrated at least one new can-do** (count of distinct pseudonymous learners).

### Definition

- **Demonstrated:** an analytics v1 event with `event_name` `exercise_answered` or `lesson_completed`, `metrics.new_can_do_demonstrated` = `true`, and `metrics.can_do_id` set to a stable integer id from the can-do map (not free text).
- **New (for that learner):** the learner had no prior `can_do_id` demonstration before the start of the counting window (UTC).
- **Counting window:** ISO week (Monday 00:00 UTC through Sunday 23:59:59 UTC) for dashboard tiles; rolling cohort windows for retention.
- **Exclusions:** `platform` = `admin`; events missing `pseudonymous_user_id`; learners with only `session_started` and no qualifying demonstration; duplicate demonstrations of the same `can_do_id` in the same week still count the learner once.

## Guardrail metrics (must hold when judging product or experiment success)

| Metric | Definition | Alert threshold (week close) |
| --- | --- | --- |
| D1 retention | Share of signup cohort active on calendar day 1 after first `session_started` | Below **35%** |
| D7 retention | Active on day 7 | Below **20%** |
| D30 retention | Active on day 30 | Below **12%** |
| Minutes practised | Sum of `session_ended.metrics.duration_ms` / 60_000 per learner per week (median reported) | Median below **15** minutes |
| Speaking minutes | Sum of `speech_attempt_scored` count × 30s cap per attempt / 60 per learner per week (median) | Median below **3** minutes |
| Crash-free sessions | `1 - (sessions_with_crash / sessions_started)` where `session_ended.metrics.crash` = true | Below **99.5%** (D17) |

## Optimisation constraint

**Streak length alone is never an optimisation target or the sole experiment success metric.** Any experiment must include at least one of: north-star weekly new can-do learners, D7 retention, minutes practised, speaking minutes, or crash-free sessions. Streak may appear only as a secondary diagnostic.

## Consequences

- P10-934 implements `admin_dashboard/metrics/northstar.ts` and `metrics.service.ts` using these definitions.
- P10-935 pre-registers experiments against the guardrail set above.
