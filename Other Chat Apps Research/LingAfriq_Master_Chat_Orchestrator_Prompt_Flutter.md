# LingAfriq Master Chat Orchestrator Prompt (Flutter + Upgrade-First)

Paste this entire prompt into Cursor AI as your first message.
Build end-to-end with no stubs/placeholders/TODOs.

## Non-Negotiable Constraints
- Frontend is Flutter only (existing app), not React.
- Reuse existing app architecture:
  - `hooks_riverpod`, `flutter_hooks`, `dio`, `socket_io_client`, `flutter_animate`, `flutter_screenutil`, `hive`.
  - Existing route system in `lib/my_app.dart` with `onGenerateRoute`.
  - Existing backend stack: Express + Mongoose + Socket.IO + Redis + Bull + Firebase Admin.
- Upgrade existing features before creating net-new systems.

## Ground Truth in Current Codebase (Do not ignore)
- Existing private chat UI: `lib/screens/chat/private_chat_screen_material3.dart`
- Existing private chat list: `lib/screens/chat/private_chat_list_screen.dart`
- Existing global chat UI: `lib/screens/chat/global_chat_screen_material3.dart`
- Existing socket provider with retries/acks/edit/react/delete: `lib/providers/chat_socket_provider.dart`
- Existing LiveKit classroom UIs:
  - `lib/screens/chat/live_classroom_screen_material3.dart`
  - `lib/screens/chat/classroom_chat_livekit_screen.dart`
- Existing backend chat routes: `src/routes/chat.route.ts`
- Existing backend mounts:
  - `/api/chat` and `/chat` in `src/routes/index.route.ts`
  - `/api/social-audio` already mounted

---

## 1) Upgrade Matrix (Replace/Upgrade/New)

### 1.1 WhatsApp-inspired
- **Upgrade existing (do not replace from scratch):**
  - Upgrade `private_chat_screen_material3.dart` into full WA thread behavior.
  - Upgrade `private_chat_list_screen.dart` into WA-style conversation inbox (pin/archive/unread/status row).
  - Extend `chat_socket_provider.dart` with typing, read receipts, presence subscriptions.
  - Extend `chat.route.ts` with reactions/forward/star/search/disappearing/status endpoints where missing.
- **Keep existing and enrich:**
  - Keep existing `/chat/private` and `/chat/conversations`, add feature-complete fields and events.
- **Add net-new where truly missing:**
  - Status (24h) model/routes/UI.
  - Starred messages screen and media gallery screen.

### 1.2 Snapchat-inspired
- **Reuse existing chat/media primitives:**
  - Reuse existing media upload path and chat auth middleware.
  - Reuse push infra and socket infra.
- **Add net-new module:**
  - Snap message lifecycle (view-once/replay), stories viewer list, streak model/worker.
- **Integrate, don’t fork:**
  - Story reply should create DM through existing private chat path.
  - Language challenge spotlight should feed into existing gamification/progress endpoints.

### 1.3 X-inspired
- **Upgrade existing social graph/community surfaces first:**
  - Reuse connection/follow data from existing social/user-connections domain.
  - Reuse social audio rooms as “Spaces”.
- **Add net-new feed module:**
  - Posts, timeline ranking, notifications, lists, trending hashtags.
- **Integrate with existing language systems:**
  - Word-of-day, phrase posts, quiz posts awarding XP.

---

## 2) Delivery Strategy (Phased, Upgrade-First)

Build in this order to avoid duplicate systems:

1. **Foundation hardening**
   - Normalize chat DTOs and socket payload contracts.
   - Add shared chat/feed model classes in Flutter.
   - Add migration-safe backend schema extensions.

2. **WhatsApp upgrade pass**
   - Upgrade existing private/global chat stack to production-grade messaging.
   - Add status and starred/media modules.
   - Keep route compatibility for old clients.

3. **Snapchat module pass**
   - Add snaps/stories/streaks on top of upgraded messaging primitives.
   - Reuse notification and socket channels.

4. **X/feed module pass**
   - Add feed service/routes/models.
   - Integrate with existing social graph and language learning entities.

5. **Consolidation pass**
   - Ensure one source of truth for conversation, presence, notifications.
   - Remove duplicate code paths and route dead-ends.

---

## 3) Backend Tasks (Implementation-Ready)

### 3.1 Chat upgrade (existing route family)
Extend `src/routes/chat.route.ts` and related controllers/services/models to include:
- Message lifecycle: `sent|delivered|read|failed`
- Typing indicators
- Reactions
- Reply-to and forward
- Edit/delete windows
- Star/unstar
- Search filters
- Disappearing timers
- Presence + last seen
- Group admin controls

Socket events to add/standardize:
- `wa:new_message`
- `wa:message_delivered`
- `wa:messages_read`
- `wa:typing_indicator`
- `wa:reaction_changed`
- `wa:presence_update`

### 3.2 Status module (WhatsApp)
Add:
- Models: status item + viewers
- Routes:
  - create/list/mine/view/delete/viewers
- Worker for 24h expiry

### 3.3 Snap module
Add route family `/api/snap/*`:
- messages (view-once/replay/screenshot event)
- stories
- streaks
- stickers

Add workers:
- snap expiry
- streak warning/hourglass
- daily spotlight

### 3.4 Feed module
Add route family `/api/feed/*`:
- posts/timeline/explore/notifications/lists/profile

Add workers:
- view counter flush
- trending hashtags
- poll closing
- word-of-day scheduler

---

## 4) Flutter Tasks (Upgrade Existing Screens)

### 4.1 Upgrade existing chat screens in place
- Upgrade `private_chat_screen_material3.dart`:
  - message bubble types
  - read receipts
  - typing indicator
  - reactions
  - reply/forward
  - voice note waveform + playback
  - translation/grammar/pronunciation actions
- Upgrade `private_chat_list_screen.dart`:
  - pinned chats
  - archive
  - unread badges with reliable counts
  - status row integration
- Upgrade `global_chat_screen_material3.dart`:
  - improve channel UX
  - moderation/report indicators
  - richer message types

### 4.2 Keep and enhance LiveKit classroom
- Keep `live_classroom_screen_material3.dart` and `classroom_chat_livekit_screen.dart`.
- Add:
  - phrase board
  - reaction controls
  - stronger participant role controls
  - classroom-linked discussion thread hooks

### 4.3 Add new Flutter modules
Add only missing flows:
- WhatsApp status screens
- Snapchat camera/preview/story/streak screens
- X feed screens (home/compose/post detail/profile/explore/notifications/lists)

All new routes must be added to `lib/my_app.dart` and follow existing argument validation patterns.

---

## 5) Route and Compatibility Policy

- Do not break existing endpoints currently used by app screens.
- Add new endpoints under additive namespaces (`/api/snap/*`, `/api/feed/*`, optional `/api/wa/*` for enhanced chat features).
- Where possible, enrich existing `/chat/*` payloads rather than replacing format.
- Maintain backward compatibility for older Flutter screens until migration is complete.

---

## 6) Data/State Policy

- Single chat socket provider remains source of truth; refactor/extend rather than parallel providers.
- Use Riverpod notifiers for module state:
  - chat enhancements
  - snap state
  - feed timelines
  - notifications
- Persist offline-critical queues via Hive (outbound message queue, unsent snaps, draft posts).

---

## 7) Quality Gates (Must Pass)

### Backend integration tests
- private message lifecycle (send/deliver/read/edit/delete/reaction)
- group role permissions
- status expiry and viewer privacy
- snap open/replay/screenshot flow
- feed create/like/repost/reply/bookmark/timeline ranking

### Flutter tests
- provider state transitions for chat/snap/feed
- route argument validation
- optimistic updates + rollback
- story viewer progression logic
- message rendering by type

---

## 8) Final Acceptance Criteria

Release is complete only if:
1. Existing private/global/classroom flows still work.
2. WhatsApp-level messaging is upgraded in-place (not duplicated).
3. Snapchat flows run end-to-end and integrate with DM/push/streaks.
4. X-style feed works end-to-end with language-learning overlays.
5. No duplicate competing chat systems in codebase.
6. No stubs/placeholders/TODOs remain.

