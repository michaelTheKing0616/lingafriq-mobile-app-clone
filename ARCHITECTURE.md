# Architecture

This repository is the Flutter client. The API is the sibling `node-backend` repository. This file states behaviour that is in the client code.

## Client

The package name is `lingafriq`. State uses Riverpod. The Dart SDK constraint is `>=3.8.0 <4.0.0`.

## Local database

`LingAfriqDatabase` in `lib/db/app_database.dart` uses Drift (`drift` 2.35.2). The schema version is 4. A failed migration rolls the transaction back and leaves the previous `user_version`. An upgrade does not clear the signed-in session (`clearsSessionOnUpgrade` is false).

The SQL in `lib/db/migrations/local_sql.dart` creates `lessons`, `vocabulary`, `progress`, `media_cache`, `point_and_say`, and `outbox`.

## Startup

`lib/services/monitoring/startup_schedule.dart` starts crash reporting before the database, preferences, Firebase, and Rive work, which run together. Offline sync and recommendations wait until after the first frame. The cold-start budget in that file is 2 seconds. Ten profile runs on a device are not recorded in this repository.

## Feature flags

`FeatureFlagService` in `lib/services/feature_flag_service.dart` keeps a 60 second cache. A failed evaluation, a missing flag, or a stale cache uses the safe default, which is off. The client does not fetch flags from the API.

## What this file does not claim

Store crash-free and ANR rates are not measured here. A generated `STATUS.md` says unknown when a test report or a flag snapshot was not passed to `scripts/docs/gen_status.py`.
