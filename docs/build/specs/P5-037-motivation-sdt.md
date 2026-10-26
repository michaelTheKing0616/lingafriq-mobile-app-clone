charter: v2

# P5-037 — Autonomy, competence, relatedness (no streak pressure)

ELEVATION §6.2 maps motivation to self-determination theory. Streak length is informational only and is not the primary home driver (EP-§6.2-26, ADR-021 guardrail).

## Autonomy (AC1)

The learner chooses session themes from the published catalog. Only `theme_id` values present in the catalog may be selected. Blocked themes are omitted. An empty selection falls back to the curriculum default theme for the active unit.

```text
resolveSessionTheme(catalogThemeIds, learnerThemeIds, blockedThemeIds, curriculumDefaultThemeId) -> themeId
```

## Competence (AC2)

Progress surfaces show demonstrated skill growth: new can-dos this week, units mastered via can-do evidence (P5-015), and BKT mastery deltas. Streak counters do not replace these metrics on the hero slot.

```text
competenceHeroCopy(snapshot) -> headline + detail
```

`CompetenceGrowthSnapshot` carries `newCanDosThisWeek`, `unitsMasteredCount`, and optional `masteryDelta`.

## Relatedness (AC3)

Social encouragement (squad activity, shared goals) may appear as a supporting module. Relatedness never outranks competence on the home hero. Streak reminders and loss-aversion copy are never the hero CTA.

```text
rankHomeModules(...) -> ordered slots with prominence hero | supporting | hidden
```

Streak prominence is at most `supporting` and is `hidden` when competence data exists and streak would otherwise be hero.

## Streak guardrail

`streakMayBeHero` is always false. Product experiments must not use streak length as the sole success metric.
