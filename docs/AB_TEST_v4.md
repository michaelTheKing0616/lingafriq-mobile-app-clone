# A/B test plan — v4 elevation features

## Hypotheses

| Experiment | Control | Treatment | Primary metric |
|------------|---------|-----------|----------------|
| Polie streaming | JSON-only fallback path disabled | SSE streaming enabled (default) | `polie_conversation_success` rate |
| African TTS | Legacy flutter_tts path | `AfricanTtsService` Gold→Silver→Bronze | % sessions with `tier=gold` or `silver` |
| Games content v2 | Pre-v2 thin pools | Bundled v2 + traditional games | `game_session` completion rate |

## Assignment

Use remote config keys (Firebase or backend feature flags):

- `polie_streaming_enabled` (bool, default `true` in v4)
- `african_tts_v4` (bool, default `true`)
- `games_bundle_v2` (bool, default `true`)

50/50 split for two weeks per experiment; do not overlap all three in one cohort until week 2.

## Guardrails

- Roll back if `polie_conversation_error` > 8% of turns
- Roll back if `tts_resolution` with `tier=unavailable` > 15%
- Roll back if `game_load_failed` > 5%

## Analysis window

14 days after 1,000+ DAU per variant. Export events from telemetry ingest (`/api/telemetry`).
