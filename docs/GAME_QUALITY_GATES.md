# Game Quality Gates

Release is blocked unless all gates pass:

## Functional Gates
- 100% launch success for all catalog entries across one smoke pass.
- 0 dead-end loading states in game start and first turn.
- Deterministic correctness logic (no first-option random scoring).
- Completion modal emits exactly once per session.

## Reliability Gates
- Content load success rate >= 98%.
- Audio playback success rate >= 95% for audio-enabled games.
- Pronunciation scoring success rate >= 92%.
- Session completion rate >= 85% on stable network.

## Telemetry Gates
- Every session emits `game_start`, at least one `game_turn`, and `game_complete`.
- Failed content fetches are typed (`serviceUnavailable`, `noContent`, `parseFailure`, `authFailure`).

## Test Gates
- Unit tests for canonical catalog and registry alias contracts.
- Unit tests for key failure typing paths and fallback behavior.
- Widget tests for template shell loading and completion flow states.

Current coverage targets:
- `test/games/game_catalog_test.dart`
- `test/games/all_games_registry_alias_test.dart`
- `test/games/game_content_failure_typing_test.dart`
- `test/games/game_mode_certification_test.dart`
- `test/games/game_template_shell_test.dart`
- `test/games/completion_modal_test.dart`
