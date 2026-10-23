# LingAfriq

Flutter client for LingAfriq, an African language learning app. The API is the sibling `node-backend` repository. This file describes the client that is in this tree.

## Requirements

- Dart SDK `>=3.8.0 <4.0.0`, from `pubspec.yaml`.
- Flutter, for `flutter pub get`, `flutter test`, and `flutter run`.
- Android SDK for an Android build. Xcode on macOS for an iOS build.

## Run

From this repository:

```bash
flutter pub get
flutter run
```

The app version in `pubspec.yaml` is `1.6.2+330`.

## Tests

```bash
flutter test
```

Domain coverage for `lib/learning` is gated at 70 percent by `scripts/ci/coverage_gate.py`. That gate does not lower the threshold.

Release automation is `.github/workflows/build-and-release.yml`. It runs on pushes and pull requests to `main`, and on `workflow_dispatch`.

## Layout

| Area | Location |
| --- | --- |
| App | `lib/` |
| Local database | `lib/db/` |
| Tests | `test/` |
| Android and iOS | `android/`, `ios/` |
| Current build record | `docs/build/STATE.md`, `HANDOFF.md` |

Older root notes are in `docs/archive/status/`. They are not a status report. `STATUS.md` is generated from test results and feature flags.

## License

No license file is in this repository.
