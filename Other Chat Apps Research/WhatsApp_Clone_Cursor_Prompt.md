# LINGAFRIQ — WhatsApp Clone Prompt (Flutter Edition)

Paste this entire prompt into Cursor AI as your first message.
Build fully end-to-end with NO stubs/placeholders/TODOs/dummy logic.

## Hard Constraints
- Frontend MUST be Flutter (existing app), not React.
- Use existing stack: `hooks_riverpod`, `dio`, `socket_io_client`, `record`, `audioplayers`, `better_player_plus`, `flutter_screenutil`, `flutter_animate`, `hive`, `flutter_secure_storage`.
- Navigation must use existing `onGenerateRoute` pattern in `lib/my_app.dart`.
- Backend must extend existing Node/Express/Mongoose/Socket.IO backend (no framework migration).
- Reuse existing auth middleware (`requireSignin`, `optionalAuth`) and push infra (`firebase-admin`, device tokens, workers).

## Target Outcome
Implement a WhatsApp-style module inside LingAfriq with:
1) 1:1 chat
2) Group chat (admin controls)
3) Delivery/read receipts
4) Typing indicators
5) Presence / last seen
6) Voice notes with waveform
7) Reactions, reply, forward, edit/delete
8) Status (24h stories)
9) Starred messages
10) Media/docs/links gallery
11) LingAfriq extras (translate/grammar/pronunciation scoring)

---

## 1) Backend Work (Node + Express + Mongoose)

### 1.1 Create models under `src/models/chat/`
Create and fully implement:
- `Conversation.model.ts`
- `Group.model.ts`
- `Status.model.ts`
- `StarredMessage.model.ts`

Extend existing `chatMessage.model.ts` with:
- `delivery_status`: `sending|sent|delivered|read|failed`
- `delivered_at`, `read_at`
- `reply_to`, `forwarded_from`, `is_forwarded`
- `reactions[]`
- `disappears_at`
- `voice_duration`, `voice_waveform`
- `translation`, `grammar_correction`
- `is_exercise`, `exercise_data`
- `location` payload

Indexes:
- room messages: `{ room_id: 1, created_at: -1 }`
- disappearing TTL index on `disappears_at`
- text index for search on message body

### 1.2 Add routes
Create routes and mount in `src/routes/index.route.ts`:
- `/api/wa/conversations`
- `/api/wa/messages`
- `/api/wa/groups`
- `/api/wa/status`
- `/api/wa/contacts`

Implement all CRUD and behavior:
- create/find direct conversation
- create/manage groups (add/remove/promote/demote members)
- paginated message history with cursor
- send/edit/delete/reply/forward/react/star
- mark delivered/read
- search messages
- status create/view/delete/viewers
- block/unblock contacts

### 1.3 Socket events
Add complete handlers in existing `src/services/socket.service.ts`:
- `wa:typing_start`, `wa:typing_stop`
- `wa:subscribe_presence`, `wa:unsubscribe_presence`
- `wa:new_message`, `wa:message_edited`, `wa:message_deleted`
- `wa:message_delivered`, `wa:messages_read`
- `wa:reaction_changed`
- `wa:status_posted`, `wa:status_viewed`, `wa:status_deleted`

Presence behavior:
- on connect: mark online in Redis + emit update
- on disconnect: set last seen + emit offline update

### 1.4 Workers
Add workers in `src/workers/chat/`:
- `disappearingMessages.worker.ts` (every 5m)
- `statusExpiry.worker.ts` (every 10m)
- `pushNotifications.worker.ts` (Bull queue: new msg, status replies, mentions)

### 1.5 LingAfriq-specific chat endpoints
Add to messages route:
- `POST /:id/translate`
- `POST /:id/grammar_check`
- `POST /:id/pronunciation_score` (voice note scoring via existing voice service)

---

## 2) Flutter Work (inside existing app)

### 2.1 Route wiring in `lib/my_app.dart`
Add named routes:
- `wa-chat-list`
- `wa-chat-thread`
- `wa-group-info`
- `wa-create-group`
- `wa-status-list`
- `wa-status-view`
- `wa-status-create`
- `wa-starred`
- `wa-media-gallery`
- `wa-contact-profile`
- `wa-search`

Ensure all route args are validated (show fallback error screen if missing args).

### 2.2 Create module structure
Create:
- `lib/screens/chat_whatsapp/`
  - `wa_chat_list_screen.dart`
  - `wa_chat_thread_screen.dart`
  - `wa_group_info_screen.dart`
  - `wa_create_group_screen.dart`
  - `wa_status_list_screen.dart`
  - `wa_status_view_screen.dart`
  - `wa_status_create_screen.dart`
  - `wa_starred_messages_screen.dart`
  - `wa_media_gallery_screen.dart`
  - `wa_contact_profile_screen.dart`
  - `wa_search_screen.dart`
- `lib/providers/chat_whatsapp/`
  - `wa_chat_provider.dart`
  - `wa_socket_provider.dart`
  - `wa_presence_provider.dart`
  - `wa_status_provider.dart`
- `lib/services/chat_whatsapp/`
  - `wa_chat_api_service.dart`
  - `wa_socket_service.dart`
  - `wa_voice_recorder_service.dart`
- `lib/models/chat_whatsapp/`
  - `wa_conversation.dart`
  - `wa_message.dart`
  - `wa_status.dart`
  - `wa_group.dart`

### 2.3 Provider rules
Use Riverpod (`StateNotifier`/`AsyncNotifier`) to manage:
- conversations list
- room messages with pagination cursor
- typing users by room
- presence map
- optimistic send queue and failure/retry
- unread counts

All async states must have:
- loading UI
- empty UI
- error UI with retry

### 2.4 Flutter widgets
Implement reusable widgets under `lib/widgets/chat_whatsapp/`:
- `wa_conversation_tile.dart`
- `wa_message_bubble.dart`
- `wa_message_input_bar.dart`
- `wa_typing_indicator.dart`
- `wa_voice_note_player.dart`
- `wa_voice_record_overlay.dart`
- `wa_reaction_bar.dart`
- `wa_reaction_picker_sheet.dart`
- `wa_attachment_sheet.dart`
- `wa_status_ring.dart`
- `wa_online_badge.dart`

### 2.5 UI behavior parity
Must include:
- chat list sorted by latest activity
- swipe to archive/pin
- long-press message context menu
- reply preview block in bubble
- ticks (sent/delivered/read)
- voice notes (record + playback + waveform rendering)
- message search
- status viewer with progress bars, tap left/right, hold-to-pause
- status privacy options

### 2.6 LingAfriq extras in Flutter UI
In thread screen:
- Translate action per message
- Grammar check action per own message
- Pronunciation score action for voice notes
- “Save word” bottom sheet when tapping detected target-language words

---

## 3) API Contracts

Use DTOs and strict parsing in Flutter models:
- `WAConversationDto`
- `WAMessageDto`
- `WAStatusDto`
- `WAPresenceDto`

All DTO parse errors must be caught and reported with structured logs.

---

## 4) Testing Requirements

### Backend tests
Add integration tests for:
- send/edit/delete/read flow
- group admin permission checks
- status expiry behavior
- presence transitions
- translation/grammar endpoints

### Flutter tests
Add tests for:
- provider state transitions
- message bubble rendering types
- chat input send/record switch logic
- route arg validation
- status progression logic

---

## 5) Done Criteria

Feature is done only when all are true:
1. End-to-end 1:1 chat works in Flutter with socket real-time updates
2. Group creation and member controls work
3. Status post/view lifecycle works with 24h expiry
4. Voice notes record/playback and waveform render correctly
5. Read receipts and presence are accurate across two devices
6. Translation + grammar + pronunciation integration works
7. All tests pass
8. No TODOs/placeholders/stub methods remain

