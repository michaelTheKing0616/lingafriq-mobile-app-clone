# LINGAFRIQ — X (Twitter) Clone Prompt (Flutter Edition)

Paste this whole prompt into Cursor AI as first message.
Build everything end-to-end with NO placeholders/TODOs/stubs.

## Mandatory Stack Alignment
- Frontend must be Flutter in existing app (`hooks_riverpod`, `dio`, `socket_io_client`, `flutter_animate`, `flutter_screenutil`, `hive`).
- Use named routes via `onGenerateRoute` in `lib/my_app.dart`.
- Backend remains Node/Express/Mongoose/Socket.IO (existing architecture).

## Product Scope
Build an X-style social layer for LingAfriq with:
1) Home timeline (For You + Following)
2) Compose post + media + language post types
3) Replies/threads
4) Repost + quote post
5) Likes/bookmarks
6) Notifications
7) Explore/trending hashtags
8) Profiles and follow graph
9) Lists
10) Audio spaces (reuse existing LiveKit social audio)
11) LingAfriq language-learning feed features

---

## 1) Backend

### 1.1 Models under `src/models/feed/`
Create fully:
- `Post.model.ts`
- `PostLike.model.ts`
- `PostRepost.model.ts`
- `PostBookmark.model.ts`
- `FeedNotification.model.ts`
- `Hashtag.model.ts`
- `UserList.model.ts`

`Post.model.ts` must support:
- type: `text|image|video|audio|poll|quiz|phrase|word_of_day|lesson_snippet`
- content/media
- language fields: `language_code`, `native_text`, `translation`, `pronunciation`, `audio_url`
- social graph fields: `reply_to_id`, `quote_of_id`, `thread_id`, `thread_depth`
- counters: like/repost/reply/bookmark/view/quote
- visibility and moderation flags
- indexes for timeline queries + text search + hashtags

### 1.2 Routes under `src/routes/feed/`
Create and mount:
- `/api/feed/posts`
- `/api/feed/timeline`
- `/api/feed/explore`
- `/api/feed/notifications`
- `/api/feed/lists`
- `/api/feed/profile`

Implement fully:

#### `/api/feed/posts`
- `GET /` timeline modes: following | foryou | language
- `POST /` create post (multipart)
- `GET /:postId`
- `DELETE /:postId`
- `GET /:postId/replies`
- `GET /:postId/thread`
- `POST /:postId/like` toggle
- `POST /:postId/repost` toggle + quote support
- `POST /:postId/bookmark` toggle
- `POST /:postId/view`
- `POST /:postId/poll/vote`
- `POST /:postId/quiz/answer`
- `POST /:postId/translate`
- `POST /:postId/flag`

#### `/api/feed/timeline`
- `GET /home?tab=for_you|following`
- `GET /user/:username?tab=posts|replies|media|likes`
- `GET /language/:code`

#### `/api/feed/explore`
- `GET /trending`
- `GET /search?q=&type=posts|users|hashtags`
- `GET /suggested-users`
- `GET /language-rooms` (reuse existing social audio rooms)

#### `/api/feed/notifications`
- `GET /`
- `POST /read-all`
- `POST /:id/read`
- `GET /unread-count`

#### `/api/feed/lists`
- full CRUD for lists
- add/remove members
- follow/unfollow lists
- list feed endpoint

#### `/api/feed/profile`
- profile details
- followers/following lists
- follow/unfollow
- update self profile
- pin/unpin own post

### 1.3 Feed algorithm details
Implement in service layer (`src/services/feed/feed.service.ts`):

For You score:
- base = `like_count*3 + repost_count*4 + reply_count*2 + bookmark_count*2`
- recency bonus: `<1h +50`, `<6h +30`, `<24h +10`
- language bonus: `+20` if in user learning languages
- social bonus: `+15` if author followed by user
- remove blocked/muted content

Following feed:
- posts from followed users + own posts
- strict chronological order

### 1.4 Socket events in existing `socket.service.ts`
Add:
- `feed:new_post`
- `feed:post_liked`
- `feed:post_unliked`
- `feed:post_reposted`
- `feed:post_deleted`
- `feed:new_reply`
- `feed:new_notification`
- `feed:new_follower`
- `feed:trending_updated`
- `feed:poll_updated`

Join rooms:
- `feed:user:{userId}`
- `feed:timeline:{userId}`

### 1.5 Workers under `src/workers/feed/`
Create:
- `viewCountFlush.worker.ts` (every 1m; flush Redis view counters)
- `trendingHashtags.worker.ts` (hourly)
- `pollCloser.worker.ts` (every 5m)
- `pushNotifications.worker.ts` (Bull queue)
- `wordOfDayScheduler.worker.ts` (daily language word-of-day posts)

---

## 2) Flutter Implementation

### 2.1 Routes in `lib/my_app.dart`
Add:
- `feed-home`
- `feed-compose`
- `feed-post-detail`
- `feed-user-profile`
- `feed-explore`
- `feed-notifications`
- `feed-bookmarks`
- `feed-lists`
- `feed-list-detail`
- `feed-hashtag`
- `feed-search`
- `feed-language-rooms`
- `feed-language-room`

### 2.2 Folder structure
Create:
- `lib/screens/feed/`
  - `feed_home_screen.dart`
  - `feed_compose_screen.dart`
  - `feed_post_detail_screen.dart`
  - `feed_user_profile_screen.dart`
  - `feed_explore_screen.dart`
  - `feed_notifications_screen.dart`
  - `feed_bookmarks_screen.dart`
  - `feed_lists_screen.dart`
  - `feed_list_detail_screen.dart`
  - `feed_hashtag_screen.dart`
  - `feed_search_screen.dart`
  - `feed_language_rooms_screen.dart`
  - `feed_language_room_screen.dart`
- `lib/providers/feed/`
  - `feed_timeline_provider.dart`
  - `feed_compose_provider.dart`
  - `feed_post_provider.dart`
  - `feed_notifications_provider.dart`
  - `feed_explore_provider.dart`
  - `feed_socket_provider.dart`
- `lib/services/feed/`
  - `feed_api_service.dart`
  - `feed_socket_service.dart`
- `lib/models/feed/`
  - `feed_post.dart`
  - `feed_notification.dart`
  - `feed_trend.dart`
  - `feed_user_list.dart`

### 2.3 Key screens behavior

#### `feed_home_screen.dart`
- top app bar with tabs: For You / Following
- infinite scroll pagination
- pull-to-refresh
- floating compose button
- show “new posts” chip when socket posts arrive while scrolled down

#### `feed_compose_screen.dart`
- text composer with 2000-char limit
- media picker (image/video)
- post type selector: text, phrase, word_of_day, poll, quiz
- poll builder (2-4 options)
- quiz builder (question, options, correct answer, explanation, XP reward)
- hashtag and mention parsing preview

#### `feed_post_detail_screen.dart`
- focal post
- ancestor + reply thread view
- reply composer
- action bar (reply/repost/like/bookmark/share)

#### `feed_user_profile_screen.dart`
- profile header + follow button
- tabs: posts/replies/media/likes
- pinned post support

#### `feed_explore_screen.dart`
- trending hashtags
- suggested users
- language communities
- language audio rooms
- word-of-day block

#### `feed_notifications_screen.dart`
- unread badge
- grouped notifications
- mark one / mark all read

#### `feed_language_room_screen.dart`
- reuse existing LiveKit social audio flow
- speaker stage + audience list
- raise hand / mute / leave
- phrase board panel for language practice

### 2.4 Widgets under `lib/widgets/feed/`
Create reusable widgets:
- `feed_post_card.dart`
- `feed_post_skeleton.dart`
- `feed_phrase_card.dart`
- `feed_word_of_day_card.dart`
- `feed_poll_card.dart`
- `feed_quiz_card.dart`
- `feed_repost_sheet.dart`
- `feed_reply_composer.dart`
- `feed_verified_badge.dart`
- `feed_hashtag_text.dart`
- `feed_notification_tile.dart`
- `feed_trend_tile.dart`
- `feed_user_suggestion_tile.dart`

### 2.5 Provider rules
Riverpod state must include:
- home timelines per tab with cursor/hasMore
- optimistic mutation handling for like/repost/bookmark/reply
- notification unread count
- real-time socket merge logic
- robust error and retry state

### 2.6 LingAfriq-specific feed features
Implement:
1. `Translate post` action for non-native language content
2. `Phrase` post type with pronunciation + translation reveal
3. `Word of Day` cards with save-to-vocabulary action
4. Quiz posts award XP via existing gamification endpoint
5. For You ranking boosts posts in user learning languages
6. Daily automated Word-of-Day posts from worker

---

## 3) Tests

### Backend integration tests
- create post + fetch timeline
- like/repost/bookmark toggle correctness
- reply/thread retrieval
- poll voting rules
- quiz XP award rules
- notification creation and read states
- trending computation and view flush

### Flutter tests
- provider state transitions for timeline + compose + notifications
- post card rendering by post type
- compose form validation
- route arg validation in `onGenerateRoute`
- optimistic updates rollback on API failure

---

## 4) Done Criteria
Done only when:
1. Flutter home feed works with for_you and following tabs
2. Compose supports all required post types
3. Threads/replies/quote posts function end-to-end
4. Likes/reposts/bookmarks sync in real-time
5. Explore and trending are live
6. Notifications and unread counters are accurate
7. Audio language rooms open/join/leave correctly
8. Language-learning feed features are operational
9. Tests pass
10. No TODOs/placeholders/stubs remain
