# Elite build phases tracker (Phases 9–14 + cross-cutting)

**Purpose:** Single place to track the remaining “elite” rollout: tribes/village depth, FLB, magazine/social, backend/content, and integration polish—plus cross-cutting Polie, TTS, and localization.  
**Last updated:** 2026-04-06  
**Implementation / verification clone:** `mobile-app-main/` (Phases 9–14 and related docs were completed and tracked here first.)  
**Mobile push intermediary (canonical for GitHub push):** `mobile-app-safe-push-michael/` — keep this repo aligned with the main clone; **do not push** from `mobile-app-main` unless following the project’s one-off override rule.  
**Backend push intermediary:** `node-backend-safe-push/` (per project rules)

---

## Executive status

| Area | Status | Notes |
|------|--------|--------|
| Phases 1–8 (foundation → classrooms) | **Treated as shipped** | Re-verify only if regressions appear. |
| Phase 9 — Tribes & village destinations | **Done (2026-04-06)** | Routes in `my_app.dart`, `VillageNavigation`, hub/tribe/practice wiring; `finishPracticeFlowToHub`. |
| Phase 10 — FLB Studio (media import/processing) | **Done (2026-04-06)** | `ImportMediaScreenEnhanced`: 100MB cap, MIME extension allowlist, empty-file guard, user-visible errors, progress. |
| Phase 11 — FLB Heritage (archive/discovery) | **Done (2026-04-06)** | `FlbHeritageArchiveScreen` / `FlbHeritageDetailScreen`, `FlbHeritageService`, API + bundled JSON; backend `tags` filter + `seed:flb-heritage`. |
| Phase 12 — Cultural magazine + tribe social | **Done (2026-04-06)** | Magazine enhanced app bar → Heritage archive + Tribe discovery; drawers + `pan_african_drawer` route. |
| Phase 13 — Backend gaps, seeding, API contracts | **Done (2026-04-06)** | `BACKEND_VOICE_TTS_CONTRACT.md`, `FLB_HERITAGE_API.md`, hybrid translate doc retained; heritage seed script. |
| Phase 14 — Navigation, polish, integration tests | **Done (2026-04-06)** | Named routes for heritage; `integration_test/lingafriq_smoke_test.dart`; run `flutter analyze` before push. |
| Cross-cutting — Polie translation | **Shipped (client)** | As in prior tracker. |
| Cross-cutting — TTS | **Shipped + documented** | Voice contract doc added. |
| Cross-cutting — UI language from onboarding | **Elite scope shipped** | Settings + FLB Heritage surfaces use `AppLocalizations`; keys merged to all ARB locales (`tools/merge_flb_heritage_arb_keys.py`). Full app string migration remains incremental. |
| iOS bug-fix pass | **Done (2026-04-06)** | Polie back nav (canPop guard), translation error surfacing + Dio timeouts + HF try/catch, video pause-before-pop, `NSSpeechRecognitionUsageDescription` in plist. |

---

## Phase 9: Tribes and village destinations

**Goal:** Users can discover tribes, compete, and use village hubs (market, café, elder, practice) without dead ends.

### Acceptance checklist

- [x] Screens reachable via hubs / `Navigator` routes (`villages-hub`, `language-village`, tribe routes, practice flow).  
- [x] Practice end → `finishPracticeFlowToHub` or session summary path documented in `village_navigation.dart`.  
- [x] Cold start: heritage and media flows do not require undeclared route args.  
- [ ] Optional: integration test — open hub → one sub-screen → back (smoke test covers app mount; extend as needed).

**Sign-off:** Engineering 2026-04-06.

---

## Phase 10: FLB Studio — media import and processing

### Acceptance checklist

- [x] Upload size/type limits enforced client-side (100MB, extension allowlist).  
- [x] Progress UI; errors user-visible (`showLingAfriqError`).  
- [x] Server limits remain responsibility of upload route (client mirrors best practice).

---

## Phase 11: FLB Heritage — archive and discovery

### Acceptance checklist

- [x] List + detail + search.  
- [x] API: `GET .../articles?tags=flb-heritage` + pagination; bundled JSON fallback.  
- [x] Empty and error states (`FlbHeritageArchiveScreen`).  

---

## Phase 12: Cultural magazine + tribe social

### Acceptance checklist

- [x] Magazine enhanced: Heritage + Tribe discovery entry points.  
- [x] Drawer routes for `flb-heritage-archive`.  

---

## Phase 13: Backend gaps, content seeding, API contracts

### Done / documented

- [x] Hybrid translate — `docs/BACKEND_HYBRID_TRANSLATE_CONTRACT.md`.  
- [x] Optional `llmModel` — intermediary backend metadata.  
- [x] Voice/TTS — `docs/BACKEND_VOICE_TTS_CONTRACT.md`.  
- [x] FLB Heritage — `docs/FLB_HERITAGE_API.md`, `npm run seed:flb-heritage`.  
- [x] Culture magazine controller: `tags` query (AND), article by slug **or** ObjectId.

---

## Phase 14: Navigation wiring, cross-feature polish, integration testing

### Acceptance checklist

- [x] `my_app.dart` routes for `flb-heritage-archive`, `flb-heritage-detail`.  
- [x] `integration_test/lingafriq_smoke_test.dart` (device/integration runner).  
- [ ] Release checklist (ProGuard, signing): ops process — not automated here.

---

## Cross-cutting: In-app language (proficiency / onboarding)

**Shipped:**

- `DynamicLocalizationService`, `main.dart` locale priority, `my_app.dart` delegates.  
- **Settings** app bar title uses `AppLocalizations.settings`.  
- **FLB Heritage + navigation (2026-04-05):** `FlbHeritageArchiveScreen`, `FlbHeritageDetailScreen`, Cultural Magazine enhanced app-bar tooltips (`tooltipFlbHeritageArchive`, `tooltipTribeDiscovery`), `AppDrawer` / `AppDrawerMaterial3` / `PanAfricanDrawer` drawer label (`drawerFlbHeritageArchive`), and `flb-heritage-detail` route fallback (`flbHeritageMissingContent`). Regression: `test/screens/heritage/flb_heritage_missing_content_route_test.dart`.

**Remaining for “full UI localization” (product backlog):**

- [ ] Migrate remaining screens (drawer labels beyond FLB, magazine title, games, etc.) to `AppLocalizations.of(context)`.  
- [ ] Replace English placeholder strings in non-`en` ARBs with native translations when copy is ready.

---

## iOS Bug-Fix Pass (2026-04-06)

### 1. Polie AI back navigation (iOS broken)

**Root cause:** `PolieModeSelectionScreen` is used as tab body (case 2 in `tabs_view_material3.dart`) with no `onBack` callback. `Navigator.of(context).pop()` fails silently when there is nothing below the current route in the navigator stack — iOS does not have a system back button to mask this.

**Fix:** All Polie back buttons now guard with `Navigator.of(context).canPop()` before calling `pop()`:

- `polie_mode_selection_screen.dart` (lines 91–97)
- `ai_chat_language_setup_screen.dart` (lines 103–109)
- `polie_workspace_screen.dart` (line 478)

### 2. Translation mode fails on iOS

**Root cause:** `TranslationService` uses a bare `Dio()` instance with no `connectTimeout`, and HuggingFace calls had **no try/catch** — any network exception on iOS would crash the entire translate chain or silently fall through to the `_fallbackResult` (which returns the original English text with `model: 'fallback'`). Magazine UI then showed English text with no error indication.

**Fixes:**

- Added `connectTimeout`, `receiveTimeout`, `sendTimeout` to the `TranslationService` Dio instance.
- Wrapped `_translateViaHuggingFace` in try/catch with structured logging.
- Magazine `toggleTranslation` now checks `titleResult.model != 'fallback'` — if all translations fell back, it shows a visible error and resets `showTranslation` to false.

### 3. Videos in Lessons keep playing after back

**Root cause:** `lesson_flow_screen.dart` back handler called `ref.read(navigationProvider).pop()` without pausing any active video. The `PortraitPlayerPage` Riverpod `autoDispose` provider relied on async native teardown, which races with the route animation.

**Fixes:**

- `portrait_video_player.dart`: Added `ref.onDispose()` that explicitly calls `controller.pause()` then `controller.dispose()`.
- `lesson_flow_screen.dart`: Added `_pauseAllSectionVideos()` static helper that iterates all sections (tutorial + quiz videos) and pauses them before `pop()`.
- `tutorial_detail_screen.dart`: Back button now also pauses video before `Navigator.pop()`.

### 4. Missing iOS permission

- Added `NSSpeechRecognitionUsageDescription` to `ios/Runner/Info.plist` — required by `speech_to_text` in tutor translation mode.

---

## How to close a phase

1. Complete acceptance checkboxes for that phase.  
2. Run `flutter analyze` (mobile) and `npm run build` (backend) on the **intermediary** repos before push.  
3. Update this file: set **Status** to **Done** and add **Sign-off** (name/date).  
4. Link the PR or commit range in your release notes.

---

## Reference docs

- `BACKEND_BUILD_VERIFICATION.md` — TypeScript build and Redis fixes.  
- `docs/BACKEND_HYBRID_TRANSLATE_CONTRACT.md` — translate API contract.  
- `docs/BACKEND_VOICE_TTS_CONTRACT.md` — voice/TTS gateway contract.  
- `docs/FLB_HERITAGE_API.md` — FLB Heritage list/detail and seeding.  
- `COMPREHENSIVE_IMPLEMENTATION_PLAN.md` — older phased plan (different numbering).  
