# Games — release gates (mobile)

Automated checks (see `.github/workflows/build-and-release.yml`):

1. **`flutter pub get`**
2. **`flutter analyze`** — zero analyzer errors on `lib/` (fix warnings that block CI if configured).
3. **`flutter test`** — full suite including `test/games/*`.

### Game-specific quality bar

| Area | Gate |
|------|------|
| **Routing** | `test/games/all_games_registry_test.dart`, `game_catalog_coverage_test.dart`, `game_router_switch_coverage_test.dart` |
| **Shell UI** | `test/games/game_template_shell_test.dart`, `test/games/shell_labels_test.dart` |
| **Telemetry** | `TelemetryService.trackGameLoadFailed` on failed `BaseGameScreen` session start; existing `game_start` / `game_turn` / `game_session` via `GameProvider` |

### Manual smoke (before store submission)

- Open **3–5 representative games** (cultural + GameKit + template inline): back button, loading, error retry, completion flow.
- Verify **top bar** shows language + progress/score where implemented (`shellProgressLabel` / `shellScoreLabel`).

### Privacy

- Telemetry events must not include secrets or raw auth tokens; reasons are truncated in `trackGameLoadFailed`.
