# Screen / route / API matrix (living document)

**Purpose:** Auditable mapping from UI entry points to widgets and backend contracts. Every inventoried screen file must end as **Pass** or **Won’t fix (documented)** with an owner.

## Where to look first

| Doc | Use |
|-----|-----|
| **[SCREEN_BACKEND_REGISTRY.md](./SCREEN_BACKEND_REGISTRY.md)** | Full **245-file** strategy, tier meanings, prior upgrade baseline, production definition. |
| **[SCREEN_WIRING_SCAN.csv](./SCREEN_WIRING_SCAN.csv)** | Automated **Tier A/B/C** + integration signals per file. |
| **[TIER_C_REVIEW_QUEUE.txt](./TIER_C_REVIEW_QUEUE.txt)** | Paths with **Tier C** (manual review required). |
| **[NAMED_ROUTES_REGISTRY.txt](./NAMED_ROUTES_REGISTRY.txt)** | **~84** names from `lib/my_app.dart` (regenerate after route edits). |
| **[LIVE_READINESS_CHECKLIST.md](./LIVE_READINESS_CHECKLIST.md)** | Per-screen **Pass** criteria. |

Regenerate tooling (from `mobile-app-main`):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/generate_screen_inventory.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/scan_screen_backend_wiring.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/extract_named_routes.ps1
```

## Inventory

- **245** paths: `lib/**/*screen*.dart` — see [`SCREEN_FILE_INVENTORY.txt`](./SCREEN_FILE_INVENTORY.txt).

## Named routes

Defined in [`lib/my_app.dart`](../lib/my_app.dart). Unknown names hit **Feature Unavailable** (see `_onGenerateRoute`). Full extracted list: [`NAMED_ROUTES_REGISTRY.txt`](./NAMED_ROUTES_REGISTRY.txt).

Examples:

| Route name | Widget / notes |
|------------|----------------|
| `games` | `GamesScreenMaterial3` — canonical hub; languages, bundled words, lexicon sample |
| `curriculum` | `CurriculumScreenMaterial3` |
| `lesson-flow` | `LessonFlowScreen` (requires `lessonId`, `sectionLessons`, `lessonTitle`) |
| `learning-path` | `LessonHubNavigation.learningPath(language)` |
| `settings` | `SettingsScreenMaterial3` |
| `global_chat`, `x-feed-home`, … | See registry file |

## API alignment

- Mobile paths: [`lib/config/api_contract.dart`](../lib/config/api_contract.dart).
- Node: `node-backend-safe-push/src/routes/index.route.ts` (+ `mobileApiContract.ts`).

## Status column (template)

| Screen file (under `lib/`) | Entry route / caller | Primary APIs | Tier (scan) | Status | Owner epic |
|----------------------------|----------------------|--------------|-------------|--------|------------|
| `screens/games/games_screen_material3.dart` | `games`, drawer, goals | languages, game content, lexicon search | A | Pass (baseline) | Games |
| _add rows as domains close_ | | | | Pending | |

_Fill rows incrementally; prefer one vertical slice per PR._
