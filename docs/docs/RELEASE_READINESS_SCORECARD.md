# Release Readiness Scorecard

Use this for each release candidate (`RC`) and keep evidence links current.

## Release Metadata

- RC ID: `<rc-id>`
- App version/build: `<version+build>`
- Branch/commit: `<branch> @ <sha>`
- Date: `<yyyy-mm-dd>`
- Release owner: `<name>`
- QA owner: `<name>`

## Device Matrix Checklist

- [ ] Android low-end (2-4 GB RAM), latest supported app build
- [ ] Android mid-tier, latest supported app build
- [ ] Android high-tier, latest supported app build
- [ ] iOS baseline supported device
- [ ] iOS recent supported device
- [ ] Poor network profile (high latency, packet loss)
- [ ] Offline/airplane recovery profile

Evidence: `<link-to-device-matrix-results>`

## Critical Flow Checklist

- [ ] Chat: open chat, send/receive, retry, reconnect recovery
- [ ] Classroom: join room, live updates, reconnect after drop
- [ ] Media: play audio/video, pause/resume, recover from network hiccup
- [ ] Games: launch, complete loop, score/progress persisted
- [ ] Tribe: open tribe spaces, interact, refresh state without duplicates

Evidence: `<link-to-critical-flow-runbook-or-results>`

## Placeholder-Free Gate Checklist

- [ ] No lorem/placeholder text in production screens
- [ ] No placeholder media assets/icons in production paths
- [ ] No temporary/test-only banners, buttons, or debug labels
- [ ] Empty states are product-approved and localized

Evidence: `<link-to-ui-audit-screenshots-or-checklist>`

## Telemetry Gate Checklist

- [ ] Crash reporting enabled for RC build
- [ ] Error events include route/feature context
- [ ] Key flow events emitted (chat/classroom/media/games/tribe)
- [ ] Release dashboards updated with RC build/version tags
- [ ] Alert thresholds reviewed for launch window

Evidence: `<link-to-observability-dashboard>`

## Rollback Checklist

- [ ] Previous stable build identified and installable
- [ ] Rollback decision owner and incident commander assigned
- [ ] Rollback trigger thresholds documented (crash/error/latency)
- [ ] Communication template prepared (internal + user-facing)
- [ ] Rollback drill validated in staging/preprod

Evidence: `<link-to-rollback-runbook-or-drill-log>`

## Pass/Fail Rubric

| Gate | Rule | Status | Evidence |
|---|---|---|---|
| Device matrix | 100% of required matrix executed | `PASS/FAIL` | `<link>` |
| Critical flows | All critical flows pass with no Sev-1/Sev-2 defects | `PASS/FAIL` | `<link>` |
| Placeholder-free | Zero unresolved placeholder findings | `PASS/FAIL` | `<link>` |
| Telemetry | Required telemetry present and queryable | `PASS/FAIL` | `<link>` |
| Rollback | Rollback owner, trigger, and rehearsal confirmed | `PASS/FAIL` | `<link>` |

Release decision: `GO / NO-GO`  
Approvers: `<engineering>`, `<qa>`, `<product>`, `<ops>`
