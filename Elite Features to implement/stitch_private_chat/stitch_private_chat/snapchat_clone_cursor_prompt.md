# LINGAFRIQ — Snapchat Clone Prompt (Flutter Edition)

Paste this whole prompt into Cursor AI as first message.
Build everything fully end-to-end with NO placeholders/TODOs/stubs.

## Required Stack Alignment
- Frontend: Flutter + Riverpod (`hooks_riverpod`) in existing app.
- Use `dio`, `socket_io_client`, `image_picker`, `better_player_plus`, `record`, `audioplayers`, `hive`, `flutter_secure_storage`, `flutter_animate`.
- Keep backend on existing Node/Express/Mongoose/Socket.IO architecture.
- Reuse existing push infra (Firebase admin + device tokens).

## Product Scope (Snapchat-style for LingAfriq)
1) Camera-first snap creation
2) View-once media messages
3) Stories (24h)
4) Story viewer list
5) Screenshot detection + notifications
6) Streak system
7) Daily challenge spotlight
8) Cultural sticker packs
9) Story reply to DM
10) LingAfriq language overlays on snaps

---

## 1) Backend (Node/Express/Mongoose)

### 1.1 Models under `src/models/snap/`
Create fully:
- `SnapMessage.model.ts`
- `SnapStory.model.ts`
- `SnapStoryView.model.ts`
- `SnapStreak.model.ts`
- `SnapScreenshotEvent.model.ts`
- `SnapStickerPack.model.ts`

#### `SnapMessage` fields
- sender_id, recipient_id
- media_url, media_type (`image|video`)
- caption
- view_mode (`once|replayable`)
- viewed_at
- expires_at
- replay_used
- is_deleted
- created_at
Indexes:
- `{ recipient_id: 1, created_at: -1 }`
- TTL on `expires_at`

#### `SnapStory` fields
- user_id
- media_url, media_type
- caption
- language_code
- phrase_overlay (native_text, pronunciation, translation)
- stickers[]
- visibility (`contacts|custom`)
- visibility_list[]
- created_at
- expires_at (24h)
TTL index on `expires_at`.

#### `SnapStreak` fields
- user_a, user_b (normalized pair)
- streak_count
- last_exchange_date
- hourglass_sent_at
- created_at, updated_at
Unique index on pair.

### 1.2 Routes
Mount in `src/routes/index.route.ts`:
- `/api/snap/messages`
- `/api/snap/stories`
- `/api/snap/streaks`
- `/api/snap/stickers`

Implement fully:

#### `/api/snap/messages`
- `POST /` send snap (multipart)
- `GET /inbox` list incoming snaps
- `GET /:id` open snap (marks viewed, starts expiry countdown)
- `POST /:id/replay` one replay allowed if `view_mode=replayable`
- `POST /:id/screenshot` report screenshot event
- `DELETE /:id` sender delete (before viewed)

Rules:
- if viewed and `view_mode=once`, auto delete media reference
- screenshot creates notification to sender
- on open/replay events emit socket updates

#### `/api/snap/stories`
- `POST /` create story
- `GET /feed` stories from contacts (unseen first)
- `GET /mine` own active stories
- `POST /:storyId/view` record view
- `GET /:storyId/viewers` owner only
- `DELETE /:storyId`
- `POST /:storyId/reply` converts to DM in existing chat route

#### `/api/snap/streaks`
- `GET /` list my streaks
- `POST /sync` recalc streak from recent snap exchanges

#### `/api/snap/stickers`
- `GET /packs`
- `GET /packs/:id`
- `GET /search?q=`

### 1.3 Socket events in existing `socket.service.ts`
Add:
- `snap:new_message`
- `snap:opened`
- `snap:replayed`
- `snap:screenshot`
- `snap:story_posted`
- `snap:story_viewed`
- `snap:streak_updated`
- `snap:hourglass_warning`

Join user room `snap:user:{userId}` and deliver all relevant events there.

### 1.4 Workers under `src/workers/snap/`
Create:
- `snapExpiry.worker.ts` (every 5 min): purge expired snaps/stories and emit updates
- `streak.worker.ts` (hourly): send hourglass notifications if 20h+ no exchange
- `dailySpotlight.worker.ts` (daily): publish daily language challenge story

---

## 2) Flutter Implementation

### 2.1 Routes in `lib/my_app.dart`
Add:
- `snap-camera`
- `snap-preview`
- `snap-inbox`
- `snap-view`
- `snap-story-feed`
- `snap-story-viewer`
- `snap-story-create`
- `snap-story-viewers`
- `snap-streaks`
- `snap-stickers`

### 2.2 Folder structure
Create:
- `lib/screens/snap/`
  - `snap_camera_screen.dart`
  - `snap_preview_screen.dart`
  - `snap_inbox_screen.dart`
  - `snap_view_screen.dart`
  - `snap_story_feed_screen.dart`
  - `snap_story_viewer_screen.dart`
  - `snap_story_create_screen.dart`
  - `snap_story_viewers_screen.dart`
  - `snap_streaks_screen.dart`
  - `snap_sticker_picker_screen.dart`
- `lib/providers/snap/`
  - `snap_camera_provider.dart`
  - `snap_messages_provider.dart`
  - `snap_stories_provider.dart`
  - `snap_streaks_provider.dart`
  - `snap_socket_provider.dart`
- `lib/services/snap/`
  - `snap_api_service.dart`
  - `snap_socket_service.dart`
  - `snap_media_service.dart`
- `lib/models/snap/`
  - `snap_message.dart`
  - `snap_story.dart`
  - `snap_streak.dart`
  - `snap_sticker.dart`

### 2.3 Camera-first UX details
`snap_camera_screen.dart`:
- Use `image_picker` camera flow for MVP capture
- Top actions: flash toggle, switch camera, close
- Hold record for video, tap for photo
- Bottom actions: memories/gallery, shutter, friends
- On capture -> `snap_preview_screen.dart`

`snap_preview_screen.dart`:
- caption text field
- sticker button opens sticker picker
- language overlay mode (native text + pronunciation + translation)
- draw tool (basic color stroke overlay)
- send-to selector (friends + story)

### 2.4 Story viewer behavior
`snap_story_viewer_screen.dart`:
- progress bars at top
- tap left/right prev-next
- hold to pause
- swipe down to close
- swipe up to reply
- auto-advance per media duration
- call `POST /api/snap/stories/:id/view` exactly once per viewer

### 2.5 Snap viewing rules
`snap_view_screen.dart`:
- open snap full-screen
- prevent replay if replay already used
- after close: remove snap from inbox if once-view
- screenshot detection attempt:
  - on Android/iOS where direct detection is unavailable, detect app lifecycle + secure flag state and add manual “I took screenshot” fallback event
  - always call backend screenshot event when detected/fallback used

### 2.6 Streak UI
`snap_streaks_screen.dart`:
- list each friend streak with count and emoji state:
  - normal: 🔥
  - warning: ⏳
- show “last exchanged” time
- quick send button opens camera targeting that friend

### 2.7 LingAfriq-specific overlays
- On snap preview, user can choose a learning language and add:
  - native phrase
  - pronunciation
  - translation
- Story card includes “Did you know this?” mini poll
- Story reply can include pronunciation practice challenge link

---

## 3) Reusable Flutter widgets
Create under `lib/widgets/snap/`:
- `snap_capture_button.dart`
- `snap_preview_toolbar.dart`
- `snap_story_ring.dart`
- `snap_story_progress.dart`
- `snap_reply_sheet.dart`
- `snap_streak_tile.dart`
- `snap_sticker_grid.dart`
- `snap_language_overlay.dart`

Animations via `flutter_animate`:
- story ring pulse
- progress fill linear
- viewer transitions slide/fade
- streak fire subtle scale animation

---

## 4) Tests

### Backend
- snap send/open/replay lifecycle
- story view recording and viewer visibility permissions
- streak calculation and warning thresholds
- screenshot event notification

### Flutter
- providers for inbox/story/streak state transitions
- viewer progression logic
- replay lock behavior
- route argument validation

---

## 5) Done Criteria
Feature done only when:
1. End-to-end snap send/open/delete works
2. Story feed + viewer + viewer list works
3. Streak updates correctly on snap exchange
4. Screenshot notifications reach sender
5. Daily challenge spotlight is auto-published
6. All screens are Flutter-native and route-integrated
7. Tests pass
8. No TODOs/placeholders/stubs remain
