# LingAfriq

Mobile client for **LingAfriq**, an African language learning app. Built with **Flutter**, **Riverpod**, and a **Node.js** backend (see the `node-backend-safe-push` directory in the repo root when present).

## Requirements

- **Flutter** SDK compatible with `environment.sdk` in [`pubspec.yaml`](pubspec.yaml) (currently Dart `>=3.8.0 <4.0.0`).
- **Android**: Android SDK / Gradle as configured under `android/` (see CI for pinned NDK / platform versions).
- **iOS**: Xcode toolchain on macOS for local iOS builds.

## Run locally

```bash
cd mobile-app-safe-push-michael   # if your clone uses this folder name
flutter pub get
flutter run
```

Configuration (API base URL, feature flags, optional certificate pinning hashes) is injected at build time via `--dart-define` / `EnvConfig`—see project docs under `docs/` and `lib/config/` for operational notes.

## Tests and analysis

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter test --coverage   # writes coverage/lcov.info (ignored by git)
```

CI (`.github/workflows/build-and-release.yml`) runs **analyze**, **`flutter test --coverage`**, prints an **lcov summary** on Linux, and uploads **coverage artifacts** for Android and iOS jobs.

## Project layout (high level)

| Area        | Location |
|------------|----------|
| App code   | `lib/` |
| Tests      | `test/` |
| Native     | `android/`, `ios/` |
| Tooling    | `tool/` |

## Documentation

- [`CODEBASE_ELEVATION_ROADMAP.md`](CODEBASE_ELEVATION_ROADMAP.md) — improvement backlog, product phases, staging checklist.
- [`../node-backend-safe-push/README_IMPLEMENTATION.md`](../node-backend-safe-push/README_IMPLEMENTATION.md) — backend test/contract commands (`npm run test:contracts`, etc.) when the server repo is checked out alongside this app.
- [`docs/`](docs/) — API contract notes, pinning ops, and other runbooks where present.

## License

See repository root or team policy for license terms.
