# Mobile ↔ Backend API contract audit

This document maps the **Flutter app** (`mobile-app-safe-push-michael`) to the **Node backend** (`node-backend-safe-push`) so feature work stays aligned with real routes, versioning, and sync semantics.

Last updated: 2026-04-16.

---

## 1. Canonical entry points

| Layer | Location |
|--------|----------|
| Mobile URL building | `lib/config/api_contract.dart` — `ApiContract.url(...)` prepends `EnvConfig.backendBaseUrl` |
| Backend mirror (keep in sync) | `node-backend-safe-push/src/contracts/mobileApiContract.ts` — `MobileApiContract` |
| Mobile HTTP (legacy singleton) | `lib/utils/api_service.dart` — used by sync outbox, some services |
| Mobile HTTP (Riverpod) | `lib/providers/dio_provider.dart` — `ApiProvider` / `ref.read(client)` |
| Backend route mount order | `node-backend-safe-push/src/routes/index.route.ts` |

**Important:** Some features use **Dio + ApiContract**; others use **ApiService**. New code should prefer **one** path per domain over time (future-forward roadmap Phase 0). **Do not maintain a third list of paths** — update `api_contract.dart` + `mobileApiContract.ts` together.

---

## 2. Auth & identity

| Mobile | Backend |
|--------|---------|
| `ApiContract.auth.*`, `ApiContract.accounts.*` | Legacy JWT under `/auth`, `/accounts` (see `v1/auth.routes.ts` + `auth.route.ts`) |

Mobile stores tokens via secure storage; refresh is handled in Dio interceptors (`dio_provider.dart`).

---

## 3. Sync v2 (offline-first outbox) — **preferred for typed deltas**

Canonical paths: `MobileApiContract.syncV2` and `ApiContract.syncV2` (same strings).

**Legacy v1** `/api/v1/offline/sync/preferences` **reuses** `getSyncPreferencesHandler` / `putSyncPreferencesHandler` from `syncV2.controller.ts` (see `offline.route.ts`) — no duplicate preference logic in `offline.controller.ts`.

**Progress metrics:** op type `progress_metrics_merge` → `applyProgressMetricsMerge` in `syncV2.controller.ts`; mobile enqueue via `PersistedOutboxService`.

---

## 4. Legacy gamification progress (full document replace)

| Mobile | Backend |
|--------|---------|
| `ApiProvider.syncProgress` → `ApiContract.gamification.progressSync` | `sync.route.ts` — `POST /api/gamification/progress/sync` → `updateGamificationProgress` → `syncProgress` in `sync.controller.ts` |

**Semantics:** `syncProgress` uses `findOneAndUpdate` with the **full metrics object** from the client body. Field names in Mongo are **snake_case** (`words_learned`, …). Sending camelCase-only objects can mis-align with the schema; incremental **sync v2** merge is safer for long-term consistency.

**Current product direction (implemented):** `ProgressTrackingProvider` enqueues **`progress_metrics_merge`** via `PersistedOutboxService` (debounced/coalesced) instead of `SyncType.progress`. Other feature services may still queue `SyncType.progress` for bespoke payloads; consider migrating those incrementally.

---

## 5. Content packs (offline packs v1)

| Mobile | Backend |
|--------|---------|
| `ApiContract.contentPacks.manifest(language)` | `GET /api/v2/content-packs/:language/manifest` — `contentPack.controller.ts`, static JSON under `data/content-packs/` when present |

Related: `LessonDownloadService`, `OfflineDownloadProvider`.

---

## 6. Learning v2 (dialect, heritage, living dictionary, …)

Use `ApiContract.learningV2` + `MobileApiContract.learningV2`. Thin mobile wrappers (no duplicate HTTP stacks): `DialectPreferenceService`, `LivingDictionaryService`, `HeritageMilestoneService`. Routes: `learningV2.route.ts` → `learningV2.controller.ts`.

**Named routes (deep links / Stitch hub):** `heritage-milestones`, `living-dictionary`, `dialect-preference` (optional args: `dialect-preference` → `{ "umbrellaLanguage": "yo" }`).

---

## 7. Micro-mentors v2

| Mobile | Backend |
|--------|---------|
| `ApiContract.microMentorsV2.*` | `src/routes/microMentorsV2.route.ts` |

Outbox ops `micro_mentor_session_request` and `micro_mentor_rubric_submit` align with `MicroMentorSessionModel` and AI summary flows in `syncV2.controller.ts`.

---

## 8. Deprecated v1 offline routes

`GET/POST /api/v1/offline/*` (`offline.route.ts`) — several handlers are **stubs** or thin wrappers; responses include `deprecated` + `successor` links to **sync v2**. New features must not depend on v1 offline queue endpoints.

---

## 9. Verification checklist for new endpoints

1. Add path to `ApiContract` and `node-backend-safe-push/src/contracts/mobileApiContract.ts` (if used).
2. If the operation must survive offline: add type to `ALLOWED_TYPES` + mobile `kSyncOutboxOperationTypes`, implement handler in `syncV2.controller.ts`, enqueue from mobile via `PersistedOutboxService`.
3. Integration test or manual: enqueue → flush → receipt in `SyncOperationReceipt` collection.

---

## 10. References (future-forward roadmap alignment)

- `C:\Users\HP\.cursor\plans\lingafriq_future-forward_roadmap_041e2020.plan.md` — Phase 0 networking unification + outbox protocol.
- `CODEBASE_ELEVATION_ROADMAP.md` — quality gates and architecture notes.
