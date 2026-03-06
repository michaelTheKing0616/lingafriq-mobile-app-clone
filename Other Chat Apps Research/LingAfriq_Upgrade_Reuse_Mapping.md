# LingAfriq Upgrade/Reuse Mapping (Current -> WhatsApp/Snap/X)

## Current Assets Identified

### Flutter
- `lib/screens/chat/private_chat_screen_material3.dart`
- `lib/screens/chat/private_chat_list_screen.dart`
- `lib/screens/chat/global_chat_screen_material3.dart`
- `lib/providers/chat_socket_provider.dart`
- `lib/screens/chat/live_classroom_screen_material3.dart`
- `lib/screens/chat/classroom_chat_livekit_screen.dart`
- `lib/screens/chat/community_chat_screen_material3.dart`
- `lib/screens/chat/tribe_chat_screen_material3.dart`

### Backend
- `src/routes/chat.route.ts` (global/private, conversations, message moderation, classroom token + hand raise/promote/demote)
- `src/routes/index.route.ts` mounts `/api/chat` and `/api/social-audio`

---

## Mapping: Keep / Upgrade / New

## 1) WhatsApp-Inspired Features

### 1.1 Direct Chat
- **Current:** private chat already exists (screen + list + route + socket provider).
- **Action:** **Upgrade in place**.
- **Upgrade targets:**
  - read receipts/ticks
  - typing indicator
  - reactions
  - reply/forward/star
  - disappearing messages
  - richer media bubbles
  - better optimistic send states wired to existing socket ack logic

### 1.2 Conversation List
- **Current:** `private_chat_list_screen.dart` has search + online + unread estimation.
- **Action:** **Upgrade in place**.
- **Upgrade targets:** pin/archive/mute, better unread counting, last message types, status strip.

### 1.3 Global/Community/Tribe Chat
- **Current:** global + community + tribe screens and backend support exist.
- **Action:** **Keep + refine**, not replace.
- **Upgrade targets:** moderation UX, richer message types, mentions/hashtags, media presentation parity.

### 1.4 Group Chat Admin Features
- **Current:** group-like contexts exist (community/tribe), but WA-style group controls not complete.
- **Action:** **Add on existing model**, avoid parallel group system.
- **Upgrade targets:** member roles, invite links, admin-only send/edit options.

### 1.5 Status (24h)
- **Current:** no dedicated WA status subsystem found.
- **Action:** **New module**, integrated with existing users/connections and push.

### 1.6 Voice Notes
- **Current:** chat stack exists, media infra exists.
- **Action:** **Upgrade existing message pipeline**, not new transport.

---

## 2) Snapchat-Inspired Features

### 2.1 View-Once Snaps
- **Current:** private media messaging exists.
- **Action:** **Add as message mode extension** (`view_mode`) in chat domain.

### 2.2 Stories + Viewer Lists
- **Current:** no full snap-style stories lifecycle in chat module.
- **Action:** **New module** (`snap stories`) but integrated with existing contacts and push.

### 2.3 Streaks
- **Current:** gamification systems exist broadly, but snap exchange streaks not present.
- **Action:** **New model + worker**, tie into existing notification and gamification layers.

### 2.4 Story Replies
- **Current:** DM pathway exists.
- **Action:** **Reuse current private chat route** for story replies (do not invent new DM backend).

---

## 3) X-Inspired Features

### 3.1 Feed + Timeline
- **Current:** no dedicated X-like post feed module found in Flutter chat screens.
- **Action:** **New feed module** (`/api/feed/*` + new Flutter feed screens).

### 3.2 Social Graph
- **Current:** user connections and social features already exist.
- **Action:** **Reuse** these as base follow/follower graph for feed ranking and notifications.

### 3.3 Audio Spaces
- **Current:** LiveKit classroom + social audio already exist.
- **Action:** **Reuse and skin as “Spaces”**, do not re-platform.

### 3.4 Notifications
- **Current:** push infrastructure already exists.
- **Action:** **Extend existing notification infra** to include feed events.

---

## Anti-Duplication Rules

1. Do not create a second socket framework. Extend `chat_socket_provider.dart` and backend Socket.IO handlers.
2. Do not create duplicate private chat APIs if `/chat/private` already covers them; extend payload/features.
3. Do not replace LiveKit classroom with another RTC stack.
4. Do not build parallel social graph tables/models if connections already exist.
5. New modules should be only:
   - WA status subsystem
   - Snap lifecycle/streak subsystem
   - Feed/post/timeline subsystem

---

## Recommended Build Sequence

1. Upgrade existing private/global chat and socket payloads.
2. Add WA status + starred/media gallery.
3. Add snap stories/view-once/streaks reusing DM + push.
4. Add X feed module reusing social graph + audio rooms.
5. Final consolidation: remove dead paths, ensure one source of truth per concern.

