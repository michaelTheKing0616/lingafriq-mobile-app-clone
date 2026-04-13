# Stitch mockup → Flutter traceability

Canonical HTML mockups live under `mobile-app-main/Elite Features to implement/` (three Stitch export roots). This table maps each **`code.html`** folder to the **primary Flutter surface** and **named route** (when registered in `lib/my_app.dart`). Update rows when screens split or routes are added.

**Counts:** 88 mockups — 20 FLB studio, 42 private chat / village / social, 26 speed-round games.

## Cluster A — `stitch_f_l_b_studio_media_import`

| Mockup folder | Canonical screen | Route / entry |
|---------------|------------------|---------------|
| `archive_submission_flow` | `screens/ugc/ugc_hub_screen.dart` | `ugc` |
| `audio_archive_player_mode` | `screens/heritage/flb_heritage_detail_screen.dart` (audio-capable content) | `flb-heritage-detail` (args) |
| `collection_overview_the_griot_s_tongue` | `screens/magazine/culture_magazine_screen_enhanced.dart` | `magazine` |
| `f_l_b_home_discovery_feed` | `screens/magazine/culture_magazine_screen_enhanced.dart` | `magazine` |
| `f_l_b_home_mode_selector` | `screens/magazine/culture_magazine_screen_enhanced.dart` | `magazine` |
| `f_l_b_learn_interactive_transcript` | `screens/magazine/culture_magazine_screen_enhanced.dart` | `magazine` |
| `f_l_b_profile_vocabulary_progress` | `screens/progress/progress_dashboard_screen.dart` / vocabulary flows | `progress`, `my-vocabulary` |
| `f_l_b_studio_media_import` | `screens/media/import_media_screen.dart` | `import_media` |
| `glossary_lexicon_explorer` | `screens/content/vocabulary_builder_screen.dart` | `vocabulary-builder` |
| `language_map_geospatial_exploration` | `screens/heritage/flb_heritage_archive_screen.dart` | `flb-heritage-archive` |
| `magazine_article_deep_dive` | `screens/magazine/culture_magazine_screen_enhanced.dart` | `magazine` |
| `photo_essay_visual_narratives` | `screens/magazine/culture_magazine_screen_enhanced.dart` | `magazine` |
| `profile_the_curator_s_dashboard` | `screens/tabs_view/profile/` flows / `settings` | `settings` |
| `studio_ai_processing_review` | `screens/media/import_media_screen.dart` (enhanced pipeline) | `import_media` |
| `studio_batch_processing_view` | `screens/media/import_media_screen.dart` | `import_media` |
| `studio_lesson_workspace` | `screens/lesson/lesson_flow_screen.dart` | `lesson-flow` |
| `studio_my_media_dashboard` | `screens/media/import_media_screen.dart` | `import_media` |
| `studio_transcription_translation_editor` | `screens/media/import_media_screen.dart` | `import_media` |
| `tribe_community_feed` | `screens/feed/x_feed_home_screen.dart` | `x-feed-home` |
| `tribe_social_drill_challenge` | `screens/games/games_screen_material3.dart` + `game_router` | `games` |
| `tribe_the_enhanced_square` | `screens/social/social_hub_screen.dart` | `social-hub` |

## Cluster B — `stitch_private_chat`

| Mockup folder | Canonical screen | Route / entry |
|---------------|------------------|---------------|
| `achievements` | `screens/achievements/achievements_screen.dart` | `achievements` |
| `alerts` | `screens/feed/x_feed_home_screen.dart` (`XNotificationsScreen` in same library) | `x-notifications` |
| `call_history` | Voice/call history surfaces (see `ApiContract.calls`) | *(push from chat/settings as wired)* |
| `chat_inbox` | Private chat list / WA upgrade inbox patterns | *(SmoothPageRoute / chat navigator)* |
| `classroom_lobby` | `screens/classroom/classroom_lobby_screen.dart` | `classroom-lobby` |
| `classroom_notes` | `screens/classroom/classroom_notes_screen.dart` | `classroom-notes` (args: `tribeId`) |
| `community_profile` | `screens/feed/community_profile_screen.dart` → `XProfileScreen` | `community-profile`, `x-profile` |
| `contact_info` | Profile / connections | `connections` |
| `dashboard` | `screens/progress/progress_dashboard_screen.dart` | `progress` |
| `elder_s_hut` | `screens/village/elder_hut_screen.dart` | `elder-hut` |
| `explore_community` | `screens/feed/explore_community_screen.dart` → `XExploreScreen` | `explore-community`, `x-explore` |
| `flashcard_focus` | `screens/village/flashcard_focus_screen.dart` | `flashcard-focus` |
| `global_chat` | `screens/chat/global_chat_screen_material3.dart` | `global_chat` |
| `inter_tribe_leaderboard` | `screens/village/inter_tribe_leaderboard_screen.dart` | `inter-tribe-leaderboard` |
| `language_selection` | `screens/gamification/tribe_selection_screen.dart` / onboarding | `tribe-selection` |
| `language_village` | `screens/social/language_villages_screen.dart` | `language-village` |
| `learning_path` | `screens/learning/learning_path_screen.dart` | `learning-path` |
| `lesson_recap` | Lesson recap within `lesson_flow_screen` | `lesson-flow` |
| `live_classroom` | `screens/chat/live_classroom_screen_material3.dart` | `live-classroom` (args) |
| `live_classroom_repaired` | Same implementation as `live_classroom` | `live-classroom` |
| `matching_pairs` | `screens/village/matching_pairs_screen.dart` | `matching-pairs` |
| `my_tribe` | `screens/village/my_tribe_screen.dart` | `my-tribe` |
| `post_detail` | `screens/feed/x_post_detail_screen.dart` (legacy `post_detail_screen.dart` delegates here) | `x-post-detail` |
| `post_detail_repaired` | Same | `x-post-detail` |
| `practice_room` | `screens/village/practice_room_collaborative_screen.dart` | `practice-room-collaborative` |
| `practice_room_setup` | `screens/village/practice_room_setup_screen.dart` | `practice-room-setup` |
| `practice_session` | `screens/village/practice_session_screen.dart` | `practice-session` |
| `private_chat` | Private chat thread | *(chat module)* |
| `search_community` | `screens/feed/search_community_screen.dart` | `search-community` |
| `session_summary` | `screens/village/session_summary_screen.dart` | `session-summary` |
| `speaker_queue` | `screens/classroom/speaker_queue_screen.dart` | `speaker-queue` (args: `tribeId`) |
| `starred_messages` | `screens/wa/wa_starred_messages_screen.dart` | `wa-starred` |
| `status_viewer` | `screens/wa/wa_status_view_screen.dart` | `wa-status-view` |
| `swahili_village_map` | `screens/village/swahili_village_map_screen.dart` | `swahili-village-map` |
| `tonal_lesson` | `screens/village/tonal_lesson_screen.dart` | `tonal-lesson` |
| `tribal_duel` | `screens/village/tribal_duel_screen.dart` | `tribal-duel` |
| `tribe_discovery` | `screens/village/tribe_discovery_screen.dart` | `tribe-discovery` |
| `tribe_hub` | `screens/village/tribe_hub_screen.dart` | `tribe-hub` |
| `villages_hub` | `screens/village/villages_hub_screen.dart` | `villages-hub` |
| `village_caf` | `screens/village/village_cafe_screen.dart` | `village-cafe` |
| `village_market` | `screens/village/village_market_screen.dart` | `village-market` |
| `welcome` | `screens/splash/splash_screen.dart` / onboarding | *(initial route)* |

## Cluster C — `stitch_speed_round_remix`

| Mockup folder | Canonical screen | Route / entry |
|---------------|------------------|---------------|
| `clan_lineage_story_builder` | `screens/games/game_router.dart` / `game_catalog.dart` | `games` |
| `elders_blessings_challenge` | Games hub + `GameType` mapping | `games` |
| `emoji_translator_pidgin` | Games hub + `GameType` mapping | `games` |
| `folktale_reconstruction` | Games hub + `GameType` mapping | `games` |
| `game_mastery_results` | Game results (embedded in game flows) | `games` |
| `game_start_guide_igbo` | Game intro / loader | `games` |
| `grammar_detective` | Games hub + `GameType` mapping | `games` |
| `grammar_jam` | Games hub + `GameType` mapping | `games` |
| `greeting_diplomacy_challenge` | Games hub + `GameType` mapping | `games` |
| `listen_sketch_swahili` | Games hub + `GameType` mapping | `games` |
| `market_bargaining_simulator` | Games hub + `GameType` mapping | `games` |
| `memory_map_hausa` | Games hub + `GameType` mapping | `games` |
| `picture_word_association` | Games hub + `GameType` mapping | `games` |
| `pronunciation_duel_yoruba` | Games hub + `GameType` mapping | `games` |
| `pronunciation_karaoke_swahili` | Games hub + `GameType` mapping | `games` |
| `proverb_unlocker` | Games hub + `GameType` mapping | `games` |
| `quiz_chef` | Games hub + `GameType` mapping | `games` |
| `roleplay_adventure` | Games hub + `GameType` mapping | `games` |
| `speed_round_remix` | `screens/games/games_screen_material3.dart` | `games` |
| `story_builder` | Games hub + `GameType` mapping | `games` |
| `taxi_bus_stop_survival` | Games hub + `GameType` mapping | `games` |
| `tone_trainer_igbo` | Games hub + `GameType` mapping | `games` |
| `universal_loading_screen` | `LazyGameLoader` / game shell | `games` |
| `victory_results_yoruba` | Game results | `games` |
| `word_match_audio` | Games hub + `GameType` mapping | `games` |

## API touchpoints (community / feed)

- Trending: `GET /api/feed/explore/trending` — `XExploreScreen`, `loadTrending()`.
- Search: `GET /api/feed/explore/search?q=&type=posts|users|hashtags` — `SearchCommunityScreen`, `loadFeedSearch()`.
- Profile: `GET /api/feed/profile` — `XProfileScreen` / `community-profile`.

Contracts: `lib/config/api_contract.dart` ↔ `node-backend-safe-push/src/contracts/mobileApiContract.ts`.

---

*Generated for the full-build Stitch program; amend when new mockups land or routes are registered.*
