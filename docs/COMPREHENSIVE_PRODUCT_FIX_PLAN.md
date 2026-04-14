# LingAfriq mobile — comprehensive product fix plan

This document captures architecture notes, **completed work**, and a **phased backlog** for the feedback items (Lessons, Polie, AI Chat, Games, TTS, UI, Global/Private chat, Live Classroom, Practice room). The app’s canonical Flutter worktree is `mobile-app-safe-push-michael` (push via intermediary per project rules).

---

## A. Lessons & curriculum (Africa map hub)

### Intended UX (source of truth)

- **Hub screen:** `lib/screens/tabs_view/home/language_detail_screen.dart` — Africa map, taps: **Lessons** → `LearningPathScreen`, **Mannerisms** / **History** / **Take Quiz** as already wired.
- **Avoid** routing “lessons” to `CurriculumScreenMaterial3` alone; that screen is a secondary curriculum bundle UI, not the map hub.

### Implemented (this pass)

| Area | Change |
|------|--------|
| Dashboard — Continue Learning | Opens `LanguageDetailScreen(language)` (map hub). |
| Dashboard — Featured languages | Same. |
| Dashboard — “Start a lesson” | Opens `LessonsMapEntryScreen` → pick language → `LanguageDetailScreen`. |
| App drawer (Material3 + legacy) | “Curriculum” renamed to **Lessons**; pushes `LessonsMapEntryScreen`. “Learning Path” also opens the same entry so users are not stuck behind `learningLanguage` only. |
| `pan_african_drawer` | Label **Lessons**; route name `curriculum` unchanged for compatibility. |
| Named route `curriculum` in `my_app.dart` | Maps to `LessonsMapEntryScreen` instead of `CurriculumScreenMaterial3`. |
| New screen | `lib/screens/lessons/lessons_map_entry_screen.dart` — language list from `languagesProvider` → `LanguageDetailScreen`. |
| Learning path | `lib/screens/learning/learning_path_screen.dart` — loads real `Lesson` rows via `lessonsListProvider` (same API as `LessonsListScreen`), sequential unlock aligned with `lessons_list_screen.dart`; tap opens `LessonSectionsListScreen`. |

### Remaining / follow-ups

- **Courses tab:** Already navigates to `LanguageDetailScreen` via `LanguageDetailScreen` from `courses_tab_material3` → `LanguageDetailScreen` — no change required for map hub.
- **Curriculum chip on map:** Still opens `CurriculumScreenMaterial3` (intentional secondary entry).
- Optional: add analytics events on hub opens.

---

## B. Polie Tutor (translation / tutor / conversation / vocabulary)

**Scope:** `lib/screens/ai_chat/`, `lib/services/hybrid_polie/`, backend routes invoking Groq/OpenAI/etc.

| Item | Approach |
|------|------------|
| Translation: full source/target dropdowns | Extend Polie translation UI to use full `AppLanguage` or backend language catalog for **both** ends; validate pair before API call. |
| Tutor cards: accurate translations | Source tutor content from lexicon/backend or verified datasets; add QA pass on card generator prompts. |
| Conversation: world-class, long answers | Tune system prompts (length, bilingual explanations), ensure model ID env vars current, streaming UI optional. |
| Vocabulary: empty “New Word” | Trace `vocabulary` / flashcard providers; fix API empty responses and LLM fallback; verify no deprecated models in `.env` / config. |

---

## C. AI Chat (“Enter The Village”)

**Scope:** `AILanguageSelectionScreen`, village hub routes, any placeholder navigation in `my_app.dart` / stitch flows.

- Wire primary CTA to a real destination (e.g. language village + socket or Polie session).
- Remove dummy `onPressed: () {}` patterns under `grep` for `Enter` / `Village`.

---

## D. Games

**Scope:** `lib/screens/games/`, game catalog providers, backend game/lexicon endpoints.

- Align `GamesScreenMaterial3` data loading with backend availability per language.
- Map Stitch mockup components where files exist under design-import folders.

---

## E. TTS

**Scope:** `flutter_tts`, backend TTS proxy env (`TTS_*`), Android/iOS permissions.

- Verify backend activation; client: ensure `FlutterTts` init, language codes, and error surfacing (no silent failure).

---

## F. UI — global navigation

**Pattern:** Prefer `PanAfricanAppBar` / back + drawer affordance on inner screens; audit screens pushed from drawer without `Scaffold` app bars.

---

## G. Global chat — Polie empty + persistence

**Scope:** `global_chat_screen_material3.dart`, Polie message pipeline, local store for thread history.

- Fix empty Polie payload (parser + API error handling).
- Persist messages via `shared_preferences` / SQLite / existing chat store; reload on app start.

---

## H. Private chat

- **Search by global handle:** Confirm API `user_search` / global ID endpoints match UI; add explicit “Search” action button next to field for keyboards without search action.
- **Status media:** Extend status composer to pick image/video/audio (permissions + upload API).

---

## I. Live Classroom

**Scope:** `live_classroom_screen_material3.dart`, feature flags, Stitch assets.

- Replace “locked” with real LiveKit/session flow when credentials exist; apply Stitch mockup widgets where present.

---

## J. Practice room — “server unavailable”

**Scope:** `practice_room_*`, `ConnectivityService`, API health checks.

- Distinguish HTTP 5xx vs auth vs wrong base URL; stop showing offline banner when `ping` succeeds.

### J.1 Collaborative practice (LiveKit) — implemented

**Files:** `lib/screens/village/practice_room_collaborative_screen.dart`, `lib/widgets/livekit/livekit_video_widgets.dart`, route in `lib/my_app.dart`.

| Behavior | Detail |
|----------|--------|
| **No room id/name** | Lobby: user names room, optional language tag; creates tribe classroom via `POST` `Api.tribesClassrooms`, then `pushReplacementNamed` `/practice-room-collaborative` with `roomId`, `roomName`, `language`. |
| **Session** | `Room.connect` with token from `AppConfig.chatClassroomToken(roomId)` (or passed-in token/url); `LiveKitParticipantGrid` + mic/camera toggles; scratchpad via LiveKit **data** topic `practice_chat`; timer; leave disconnects. |
| **Route args** | `my_app.dart` passes `roomId`, `roomName`, `livekitToken`, `livekitUrl`, `language` / `languageTag` — same pattern as `live-classroom`. |
| **Entry** | `PracticeRoomSetupScreen`: **“Practice live with others”** (after connectivity check) → collaborative route with `languageTag` from `VillageNavigation.isoCodeForLanguageLabel`. |

---

## K. App-wide navigation — registry and audit (named vs imperative)

**Canonical registry:** `lib/my_app.dart` → `_onGenerateRoute` → `routes` map. Names are normalized **without** a leading `/`. Unknown names get the fallback “Feature Unavailable” scaffold.

### K.1 Named routes (complete list)

`ai_chat_select`, `polie_mode_selection`, `curriculum`, `games`, `games_api_languages`, `games_enhanced_catalog`, `daily_goals`, `progress`, `achievements`, `badges`, `leaderboard`, `tribe`, `tribe_vs_tribe`, `tribe-selection`, `tribe_selection`, `villages`, `villages-hub`, `language-village`, `swahili-village-map`, `village-market`, `village-cafe`, `elder-hut`, `practice-room-setup`, `practice-session`, **`practice-room-collaborative`**, `session-summary`, `flashcard-focus`, `matching-pairs`, `tonal-lesson`, `tribe-hub`, `tribe-discovery`, `my-tribe`, `tribal-duel`, `inter-tribe-leaderboard`, `global_chat`, `connections`, `quest`, `events`, `magic_items`, `ancestral_tree`, `magazine`, `flb-heritage-archive`, `flb-heritage-detail`, `ugc`, `contribute_voice`, `import_media`, `settings`, `stitch-hub`, `private-chat-inbox`, `call-history`, `live-classroom`, `classroom-lobby`, `classroom-notes`, `speaker-queue`, `features_guide`, `policy`, `lesson-flow`, `grammar-hub`, `grammar-lesson`, `grammar-exercise`, `social-hub`, `friend-profile`, `challenge-friend`, `share-progress`, `conversation-scenarios`, `cultural-hub`, `vocabulary-builder`, `listening-practice`, `writing-practice`, `learning-path`, `friend-quests`, `create-friend-quest`, `email-verification`, `my-vocabulary`, `flashcard-review`, `wa-status`, `wa-status-create`, `wa-status-view`, `wa-starred`, `wa-media-gallery`, `snap-inbox`, `snap-story-feed`, `snap-camera`, `snap-streaks`, `snap-viewer`, `x-feed-home`, `x-compose`, `x-post-detail`, `x-notifications`, `x-explore`, `x-lists`, `x-profile`, `explore-community`, `search-community`, `community-profile`, `historical-personas`.

### K.2 Routes that require `arguments` (guardrails in code)

Pass a `Map` (and required keys) for: `live-classroom`, **`practice-room-collaborative`** (optional fields except when joining an existing room), `classroom-notes`, `speaker-queue`, `features_guide`, `lesson-flow`, `grammar-lesson`, `grammar-exercise`, `friend-profile`, `challenge-friend`, `share-progress`, `learning-path`, `email-verification`, `flashcard-review`, `wa-status-view`, `snap-viewer`, `x-post-detail`, `flb-heritage-detail`. Several return a centered error `Scaffold` if args are missing.

### K.3 Files using `Navigator.pushNamed` (string routes)

Direct alignment with §K.1: `practice_room_setup_screen.dart`, `practice_room_collaborative_screen.dart`, `private_chat_list_screen.dart`, `ai_language_selection_screen.dart`, `app_drawer.dart`, `social_hub_screen.dart`, `stitch_navigation_hub_screen.dart`, `classroom_lobby_screen.dart`, `explore_community_screen.dart`, `x_feed_home_screen.dart`, `culture_magazine_screen_enhanced.dart`, `flb_heritage_archive_screen.dart`, `village_navigation.dart`, `tribe_hub_screen.dart`, `swahili_village_map_screen.dart`, `wa_status_list_screen.dart`, `tribe_vs_tribe_screen.dart`, `snap_*` screens.

### K.4 Imperative inner routes (not in `_onGenerateRoute`)

Many flows use `Navigator.push` + `MaterialPageRoute` / `SmoothPageRoute` to a **widget constructor** (e.g. large sections of `app_drawer.dart`, `app_drawer_material3.dart`, `dashboard_screen_material3.dart`, games hub → per-game screens). Those bypass the string registry; refactors should grep for `SmoothPageRoute` / `MaterialPageRoute` when auditing behavior or deep links.

---

## Execution order (recommended)

1. **Lessons hub + learning path** — done in repo as above.  
2. **Global chat Polie + persistence** — user-visible, high impact.  
3. **Games content pipeline** — depends on backend lexicon/game APIs.  
4. **Polie modes** — prompt + model config.  
5. **Live classroom / practice room** — infra-dependent; collaborative practice LiveKit path in §J.1.  
6. **Full UI nav audit** — §K documents the named-route registry; imperative routes in §K.4.

---

## Verification

After pulling these changes:

- **Static analysis:** rely on **GitHub CI** (`flutter analyze` / project checks) — do not block local work on a full-project analyze unless debugging CI.
- Manually: Dashboard → Start a lesson → pick language → map → Lessons → path node → section content opens.
- Named route: open drawer (legacy) → navigate to `curriculum` → should show `LessonsMapEntryScreen`.
- Collaborative practice: Practice setup → **Practice live with others** → lobby → create room → LiveKit session (requires backend + token endpoint).
