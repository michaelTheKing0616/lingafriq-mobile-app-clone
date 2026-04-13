# Screen ↔ backend registry (245 inventoried `*screen*.dart` files)

This document ties together **inventory**, **named routes**, **automated wiring signals**, and **prior upgrade work**. It is the single place to answer: *which surfaces are production-backed, which need review, and what “done” means.*

## Definitions

- **Production-ready (backend complete)** for a screen means:
  - All **mutations** that should persist go through **real Node APIs** (or an explicitly documented offline contract), and
  - **Reads** surface **loading / empty / error** (per [`LIVE_READINESS_CHECKLIST.md`](./LIVE_READINESS_CHECKLIST.md)), and
  - **401/403** are handled for authed features, and
  - The row in [`SCREEN_API_MATRIX.md`](./SCREEN_API_MATRIX.md) is **Pass** (or **Won’t fix** with owner + reason).

- **Automated tier** (from [`SCREEN_WIRING_SCAN.csv`](./SCREEN_WIRING_SCAN.csv)) is a **heuristic**, not proof:
  - **Tier A** — Strong signals: `ApiContract`, `ApiService`, `Dio`, `Repository`, `package:lingafriq/providers/`, `package:lingafriq/services/`, realtime, or game loader hooks.
  - **Tier B** — Partial (often delegates to providers/widgets without importing `ApiContract` in-file).
  - **Tier C** — No matched pattern; **must be manually reviewed** (many are pure UI, game shells loaded by `LazyGameLoader` from parents, or routes that push children that own the API).

Regenerate the scan after substantive refactors:

`powershell -NoProfile -ExecutionPolicy Bypass -File tools/scan_screen_backend_wiring.ps1`

## Artifacts

| Artifact | Purpose |
|----------|---------|
| [`SCREEN_FILE_INVENTORY.txt`](./SCREEN_FILE_INVENTORY.txt) | Flat list of all `lib/**/*screen*.dart` paths (245). |
| [`SCREEN_WIRING_SCAN.csv`](./SCREEN_WIRING_SCAN.csv) | Per-file tier + boolean signals for integration review. |
| [`NAMED_ROUTES_REGISTRY.txt`](./NAMED_ROUTES_REGISTRY.txt) | Route names from `lib/my_app.dart` (heuristic extract). |
| [`SCREEN_API_MATRIX.md`](./SCREEN_API_MATRIX.md) | Human **Pass / Won’t fix** tracking with APIs and owners. |

Route extract:

`powershell -NoProfile -ExecutionPolicy Bypass -File tools/extract_named_routes.ps1`

## Prior sessions — already upgraded or hardened (non-exhaustive)

These were explicitly implemented or wired in earlier work; **treat as baseline “done” unless product reopens**:

| Area | Files / behavior | Backend / contract notes |
|------|------------------|---------------------------|
| Games hub | `screens/games/games_screen_material3.dart` | Route `games`; languages + bundled content + **lexicon sample** via `gamesHubLexiconSampleProvider` + `LexiconRepository.sampleForLanguageResult` (errors surfaced). |
| Daily goals → games | `screens/goals/daily_goals_screen.dart` | Navigates to **GamesScreenMaterial3** (canonical hub). |
| Lesson quiz completion | `screens/lesson/widgets/quiz_section_widget.dart`, `lesson_flow_screen.dart` | **`onFinish`** on last question triggers section completion (no dead Finish button). |
| Lesson flow logic tests | `test/screens/lesson/lesson_flow_section_completion_logic_test.dart` | Pure `lessonFlowStateAfterSectionMarkedComplete` / notifier behavior. |
| Lexicon (mobile) | `services/lexicon/lexicon_repository.dart` | Search + **lemma lookup** via `entryForLemmaResult` (transport errors not conflated with “missing word”). |
| Lexicon (Node) | `node-backend-safe-push` — `/api/lexicon`, `/admin/lexicon/*` | Staging/import/promote; align with `ApiContract` / `mobileApiContract.ts`. |
| Hybrid Polie metadata | `services/hybrid_polie/hybrid_polie_orchestrator.dart` + test | `translation_style` in metadata; unit test with stub Groq provider. |
| Offline minigame lexicon (hub languages) | `data/language_words.dart`, `screens/games/quiz_chef_screen.dart` | Word lists + Quiz Chef rounds for **all** `kGamesHubLanguageSlugs` (yoruba through afrikaans); aligns with slug-based `BaseGameScreen.language` and API `Language.name` via `_hubSlugOrAliasToListKey` + partial match. |

Add new rows here whenever a domain PR closes.

## Coverage strategy for the remaining ~245 files

1. **Sort `SCREEN_WIRING_SCAN.csv` by `Tier` then folder** — clear **Tier C** first where the screen is on a **named route** or primary navigation path (cross-check `NAMED_ROUTES_REGISTRY.txt` + `my_app.dart` builders).
2. **Do not** assume Tier C is broken: open the file and trace **providers**, **repositories**, and **child routes**.
3. **Game type screens** under `lib/games/**` often rely on **`LazyGameLoader`** / **`game_router`** from `GamesScreenMaterial3` — backend for content may be **game JSON + Polie APIs**; document in the matrix row.
4. **Batch PRs by domain** (see [`EPIC_DOMAIN_TRACKING.md`](./EPIC_DOMAIN_TRACKING.md)): onboarding → settings → lessons → games → village → feed → chat → classroom → AI → content.

## When a screen is “uncreated”

If product adds a **new** `*screen*.dart` file:

1. Run `tools/generate_screen_inventory.ps1`.
2. Add a matrix row and run `tools/scan_screen_backend_wiring.ps1`.
3. Register the **route** in `lib/my_app.dart` if user-facing, or document **internal-only** (no route).

---

*Last scan counts are printed when you run `scan_screen_backend_wiring.ps1`; see console output for current Tier A/B/C totals.*
