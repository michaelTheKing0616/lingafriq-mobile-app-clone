# Offline outbox + sync v2 design (v1)

This doc is the mobile-side companion to backend `node-backend-safe-push/docs/OFFLINE_OUTBOX_DESIGN_V1.md`.

## Source of truth

- **Backend** accepts only `ALLOWED_TYPES` in `src/controllers/syncV2.controller.ts`.
- **Mobile** mirrors allowed types in `lib/config/sync_outbox_operation_types.dart`.

## Where the outbox lives

- Implementation: `lib/services/offline/persisted_outbox_service.dart`
- Storage: Hive `Box<String>` named `lingafriq_sync_outbox_v1`
  - key = `clientOperationId` (UUID v4)
  - value = JSON string of the operation record

## Operation record schema (stored JSON)

```json
{
  "clientOperationId": "uuid",
  "idempotencyKey": "sha256(type|json(payload))",
  "type": "phrase_dna_attempt_submit",
  "payload": { "..." : "..." },
  "clientCreatedAt": "2026-04-16T00:00:00.000Z",
  "clientInstallId": "uuid",
  "clientAppVersion": "x.y.z+build",
  "schemaVersion": 1,
  "createdAt": "2026-04-16T00:00:00.000Z",
  "attempts": 0,
  "lastError": null
}
```

## Flush behavior

- Triggered by:
  - app resume (`WidgetsBindingObserver` in `my_app.dart`)
  - periodic background task (`lib/services/offline/background_sync_service.dart`)
  - connectivity transition in `OfflineService`
- Network gating:
  - `ConnectivityService.hasInternet()` is used to skip flush when offline
- Retry behavior:
  - transient failures (network, 5xx, 429) retried with bounded backoff
  - successful ops are removed individually based on server per-op result

## Legacy sync (non-outbox)

There are older sync mechanisms that still exist in code:

- `lib/services/offline/sync_operations.dart` (SharedPreferences-backed queues)
- `lib/providers/backend_sync_provider.dart` (task queue calling older sync endpoints)

Current safety stance:

- Periodic background sync flushes the persisted outbox (sync v2) only.
- `BackendSyncProvider.syncAll()` now flushes the persisted outbox before processing legacy queued tasks so outbox ops are not skipped.

