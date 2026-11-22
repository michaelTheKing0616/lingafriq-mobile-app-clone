# Consolidation harvest report

Card P3-072. Status stays Draft.

This report lists every harvest_list item on P3-065, P3-066, P3-067, P3-068, P3-069, and P3-070. A harvest_list line that the source card split into parts has one row per part. Status is Moved, Dropped, Kept, or Unresolved. Dropped rows copy the reason already written on the source card. Approver is Unrecorded. This repo has no human approver, so P3-072 is not marked Done.

P3-072 card file status read by this run: Draft.

P3-068 stays Draft. A seventh named template class is not in the repo. This report does not invent one. The old template shell is still imported. P3-068 says game_template_shell.dart stays because BaseGameScreen and test/games/game_template_shell_test.dart import it, and the six template files stay because that test still builds GameTemplateShell. Those references are Kept, not a scan failure. P3-068 also says the old files were not deleted, lib/screens/games/universal_game_screen.dart is not present, and lib/games/base_game_screen.dart is not present.

Counts: Moved 64, Dropped 54, Kept 14, Unresolved 11.

## Ledger

| Card | Harvest list item | Entry | Status | Card text | Approver |
| --- | --- | --- | --- | --- | --- |
| P3-065 | ai_chat_screen.dart | ai_chat_screen.dart | Dropped | Already deleted in 514e70e1 and had no route. | Unrecorded |
| P3-065 | ai_chat_screen_new.dart | ai_chat_screen_new.dart | Dropped | Already deleted in 514e70e1 and had no route. | Unrecorded |
| P3-065 | ai_chat_screen_with_tracking.dart | ai_chat_screen_with_tracking.dart | Dropped | Already deleted in 514e70e1 and had no route. | Unrecorded |
| P3-065 | conversation_enhanced_screen.dart | conversation_enhanced_screen.dart | Dropped | Already deleted in 514e70e1 and had no route. | Unrecorded |
| P3-065 | ai_mode_selection_screen.dart | ai_mode_selection_screen.dart | Moved | Moved to legacy/ai_chat/ after ai_chat_select started building the Polie workspace. | n/a |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | legacy mode-id map | Moved | legacy mode-id map | n/a |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | Surprise Me limited to modes that have a panel | Moved | Surprise Me limited to modes that have a panel | n/a |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | Conversation on the mode rail | Moved | Conversation on the mode rail | n/a |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | progress button for the tracking dashboards | Moved | progress button for the tracking dashboards | n/a |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | conversation turn counts and session record on leave | Moved | conversation turn counts and session record on leave | n/a |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | tutor keyword notes merged into the existing tutor session | Moved | tutor keyword notes merged into the existing tutor session | n/a |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | roleplay turn notes | Moved | roleplay turn notes | n/a |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | auto-correction toggle | Moved | auto-correction toggle | n/a |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | topic chips from conversation analytics with the enhanced-screen fallback | Moved | topic chips from conversation analytics with the enhanced-screen fallback | n/a |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | ai_chat_screen.dart tracking, mode selection, and enhanced controls are not present in the variant. Same route as Polie mode conversation. | Dropped | ai_chat_screen.dart tracking, mode selection, and enhanced controls are not present in the variant. Same route as Polie mode conversation. | Unrecorded |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | ai_chat_screen_new.dart per-mode HTTP bodies are the same route as the Polie mode surfaces, which already call the gateway. | Dropped | ai_chat_screen_new.dart per-mode HTTP bodies are the same route as the Polie mode surfaces, which already call the gateway. | Unrecorded |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | Grammar and pronunciation stay off the rail because the workspace panel for those modes is empty. | Dropped | Grammar and pronunciation stay off the rail because the workspace panel for those modes is empty. | Unrecorded |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | Assessment is the same route as Polie mode review. | Dropped | Assessment is the same route as Polie mode review. | Unrecorded |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | Empty-state starter chips in the tracking chat are the same route as the mode intro banners. | Dropped | Empty-state starter chips in the tracking chat are the same route as the mode intro banners. | Unrecorded |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | The tracking screen's corrections list was never appended to. | Dropped | The tracking screen's corrections list was never appended to. | Unrecorded |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | A second correction prompt was not copied, because it would add another user turn. | Dropped | A second correction prompt was not copied, because it would add another user turn. | Unrecorded |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | Roleplay completion navigation stays on the roleplay scenario flow. | Dropped | Roleplay completion navigation stays on the roleplay scenario flow. | Unrecorded |
| P3-065 | best parts of each: tracking hooks, mode selection, enhanced conversation controls | Vocab free-text addWord was not copied, because scoreSrs already stores the card. | Dropped | Vocab free-text addWord was not copied, because scoreSrs already stores the card. | Unrecorded |
| P3-066 | classroom_session_screen.dart | session list, active session, optional agenda, check-in, offline outbox queue, sync | Moved | session list, active session, optional agenda, check-in, offline outbox queue, sync | n/a |
| P3-066 | classroom_session_screen.dart | live phases, recording consent, recording banner, retention line, teacher start recording, leave | Moved | live phases, recording consent, recording banner, retention line, teacher start recording, leave | n/a |
| P3-066 | classroom_session_screen.dart | shouldPersistClassAv, classSessionPhaseLabel, consent and recording copy | Moved | shouldPersistClassAv, classSessionPhaseLabel, consent and recording copy | n/a |
| P3-066 | classroom_session_screen.dart | two em dashes in the queued check-in line and the recording indicator were replaced with periods. The card forbids an em dash. The meaning is unchanged. | Dropped | two em dashes in the queued check-in line and the recording indicator were replaced with periods. The card forbids an em dash. The meaning is unchanged. | Unrecorded |
| P3-066 | classroom_lobby_screen.dart | practice-room catalog from tribes with includeClassrooms | Moved | practice-room catalog from tribes with includeClassrooms | n/a |
| P3-066 | classroom_lobby_screen.dart | class code join | Moved | class code join | n/a |
| P3-066 | classroom_lobby_screen.dart | filter chips All, Starting Soon, My Languages. They change selection only. The source does not filter the list. | Moved | filter chips All, Starting Soon, My Languages. They change selection only. The source does not filter the list. | n/a |
| P3-066 | classroom_lobby_screen.dart | room card language, title, Community classroom, participant count, HOT when members_count is over 20 | Moved | room card language, title, Community classroom, participant count, HOT when members_count is over 20 | n/a |
| P3-066 | classroom_lobby_screen.dart | Notes opens /classroom-notes | Moved | Notes opens /classroom-notes | n/a |
| P3-066 | classroom_lobby_screen.dart | Queue opens /speaker-queue | Moved | Queue opens /speaker-queue | n/a |
| P3-066 | classroom_lobby_screen.dart | host and room open the live classroom room | Moved | host and room open the live classroom room | n/a |
| P3-066 | classroom_lobby_screen.dart | empty and error copy | Moved | empty and error copy | n/a |
| P3-066 | classroom_lobby_screen.dart | empty language_tag rendered an em dash. The chip is omitted when the tag is empty. | Dropped | empty language_tag rendered an em dash. The chip is omitted when the tag is empty. | Unrecorded |
| P3-066 | classroom_lobby_screen.dart | host and room tap opened LiveClassroomScreenMaterial3. That screen is not one of the four variants. The action now opens LiveClassroomScreen. | Dropped | host and room tap opened LiveClassroomScreenMaterial3. That screen is not one of the four variants. The action now opens LiveClassroomScreen. | Unrecorded |
| P3-066 | live_classroom_mobile_screen.dart | mute toggle | Moved | mute toggle | n/a |
| P3-066 | live_classroom_mobile_screen.dart | active lesson card | Moved | active lesson card | n/a |
| P3-066 | live_classroom_mobile_screen.dart | listener online dots and listener count | Moved | listener online dots and listener count | n/a |
| P3-066 | live_classroom_mobile_screen.dart | reactions with the party and clap marks | Moved | reactions with the party and clap marks | n/a |
| P3-066 | live_classroom_mobile_screen.dart | host speaking label | Moved | host speaking label | n/a |
| P3-066 | live_classroom_mobile_screen.dart | more_vert has no onPressed and builds no menu | Dropped | more_vert has no onPressed and builds no menu | Unrecorded |
| P3-066 | classroom_v2_route_args.dart | LiveClassroomScreen.fromRouteArguments uses ClassroomV2RouteArgs.parse for tribeId and tribeName | Moved | LiveClassroomScreen.fromRouteArguments uses ClassroomV2RouteArgs.parse for tribeId and tribeName | n/a |
| P3-066 | classroom_v2_route_args.dart | the file stays. classroom-roster-v2, classroom-assignments-v2, classroom-privacy-v2, and classroom-student-requests-v2 still call it, and classroom_v2_route_args_test.dart imports it. Those routes are outside this consolidation. | Kept | the file stays. classroom-roster-v2, classroom-assignments-v2, classroom-privacy-v2, and classroom-student-requests-v2 still call it, and classroom_v2_route_args_test.dart imports it. Those routes are outside this consolidation. | n/a |
| P3-066 | classroom_v2_route_args.dart | missingTribeIdScaffold is not applied on the live classroom. A missing tribe id opens the practice-room catalog. The scaffold stays on the routes that require a tribe id. | Dropped | missingTribeIdScaffold is not applied on the live classroom. A missing tribe id opens the practice-room catalog. The scaffold stays on the routes that require a tribe id. | Unrecorded |
| P3-066 | roster, notes, assignments, privacy and speaker queue ideas from the variants | roster | Unresolved | not present in the variant | n/a |
| P3-066 | roster, notes, assignments, privacy and speaker queue ideas from the variants | assignments | Unresolved | not present in the variant | n/a |
| P3-066 | roster, notes, assignments, privacy and speaker queue ideas from the variants | privacy | Unresolved | not present in the variant | n/a |
| P3-066 | roster, notes, assignments, privacy and speaker queue ideas from the variants | notes | Moved | classroom_lobby_screen.dart opens /classroom-notes with tribeId and roomName | n/a |
| P3-066 | roster, notes, assignments, privacy and speaker queue ideas from the variants | speaker queue | Moved | classroom_lobby_screen.dart opens /speaker-queue with tribeId and roomName | n/a |
| P3-067 | kijiji_onboarding_screen.dart village story | optional panel on the unified welcome step | Moved | optional panel on the unified welcome step | n/a |
| P3-067 | kijiji_onboarding_screen.dart village story | spoken lines in screen order: welcome, Pa LingAfriq, who you are, why you are learning, Adisa the Weaver, Nuru the Rhythm Master, Zawadi, choose your path, Amina the Griot, the Healer, build your clan, the naming line, let us see where you stand | Moved | spoken lines in screen order: welcome, Pa LingAfriq, who you are, why you are learning, Adisa the Weaver, Nuru the Rhythm Master, Zawadi, choose your path, Amina the Griot, the Healer, build your clan, the naming line, let us see where you stand | n/a |
| P3-067 | kijiji_onboarding_screen.dart village story | age, reason, language, level, duration, path, tone, and gamification controls. The unified steps already save those answers. | Dropped | age, reason, language, level, duration, path, tone, and gamification controls. The unified steps already save those answers. | Unrecorded |
| P3-067 | kijiji_onboarding_screen.dart village story | healer switches. Titles are camelCase keys split by a regex, not strings from the catalogue. | Dropped | healer switches. Titles are camelCase keys split by a regex, not strings from the catalogue. | Unrecorded |
| P3-067 | kijiji_onboarding_screen.dart village story | clan chips. Labels are the raw ids solo, buddies, community, and teacher_guided. | Dropped | clan chips. Labels are the raw ids solo, buddies, community, and teacher_guided. | Unrecorded |
| P3-067 | kijiji_onboarding_screen.dart village story | rhythm options. Labels are the raw ids audio, visual, stories, drills, and conversation. The unified learning-style step already saves those ids. | Dropped | rhythm options. Labels are the raw ids audio, visual, stories, drills, and conversation. The unified learning-style step already saves those ids. | Unrecorded |
| P3-067 | kijiji_onboarding_screen.dart village story | three self-report placement prompts inside _PlacementTestScreen. They assign fixed levels A0 through B2. The unified flow already opens PlacementTestScreen when self_reported_level is unsure. This card does not copy those prompts. | Dropped | three self-report placement prompts inside _PlacementTestScreen. They assign fixed levels A0 through B2. The unified flow already opens PlacementTestScreen when self_reported_level is unsure. This card does not copy those prompts. | Unrecorded |
| P3-067 | enhanced_onboarding_flow_screen.dart | proficiency language, learning language, age, reasons, daily time, primary goal, learning style, app tone, schedule, and profile. The unified steps already save those keys. | Dropped | proficiency language, learning language, age, reasons, daily time, primary goal, learning style, app tone, schedule, and profile. The unified steps already save those keys. | Unrecorded |
| P3-067 | enhanced_onboarding_flow_screen.dart | proficiency_level and pace_preference. Nothing else in lib reads those keys. Pace options render the raw ids slow, steady, fast, and surprise. | Dropped | proficiency_level and pace_preference. Nothing else in lib reads those keys. Pace options render the raw ids slow, steady, fast, and surprise. | Unrecorded |
| P3-067 | enhanced_onboarding_flow_screen.dart | the placement dialog. Unified already asks, then opens PlacementTestScreen. | Dropped | the placement dialog. Unified already asks, then opens PlacementTestScreen. | Unrecorded |
| P3-067 | enhanced_onboarding_flow_screen.dart | no generateAppRoute entry. The class was only constructed by its own file. | Dropped | no generateAppRoute entry. The class was only constructed by its own file. | Unrecorded |
| P3-067 | modern_onboarding_screen.dart | four marketing pages. Get started calls setOnboardingSeen, registerDevice, and TabsViewMaterial3. It does not read the path card. | Dropped | four marketing pages. Get started calls setOnboardingSeen, registerDevice, and TabsViewMaterial3. It does not read the path card. | Unrecorded |
| P3-067 | modern_onboarding_screen.dart | path cards call updatePath, including dialect, and then the next screen ignores selectedPath. | Dropped | path cards call updatePath, including dialect, and then the next screen ignores selectedPath. | Unrecorded |
| P3-067 | modern_onboarding_screen.dart | onboardingExplore54Countries2000LanguagesAnd is the frozen unverified language-count claim in MARKETING_CLAIMS_FREEZE.md. | Dropped | onboardingExplore54Countries2000LanguagesAnd is the frozen unverified language-count claim in MARKETING_CLAIMS_FREEZE.md. | Unrecorded |
| P3-067 | modern_onboarding_screen.dart | no generateAppRoute entry and no other file constructed the class. | Dropped | no generateAppRoute entry and no other file constructed the class. | Unrecorded |
| P3-067 | onboarding_screen.dart | page 4 calls navigateOffAll(TabsViewMaterial3) and saves no answers. | Dropped | page 4 calls navigateOffAll(TabsViewMaterial3) and saves no answers. | Unrecorded |
| P3-067 | onboarding_screen.dart | three descriptions are hard-coded English, including the frozen 2000-language claim. | Dropped | three descriptions are hard-coded English, including the frozen 2000-language claim. | Unrecorded |
| P3-067 | onboarding_screen.dart | no generateAppRoute entry and no other file constructed the class. | Dropped | no generateAppRoute entry and no other file constructed the class. | Unrecorded |
| P3-067 | onboarding_screen_material3.dart | its build method already returned UnifiedOnboardingScreen. auth_provider, sign_in_options, and passkey_service now construct UnifiedOnboardingScreen directly. | Moved | its build method already returned UnifiedOnboardingScreen. auth_provider, sign_in_options, and passkey_service now construct UnifiedOnboardingScreen directly. | n/a |
| P3-067 | onboarding_screen_material3.dart | the wrapper class. It had no other child. | Dropped | the wrapper class. It had no other child. | Unrecorded |
| P3-067 | placement_quiz_screen.dart | loads questions with PlacementTestService.loadQuestionsForLanguage and scores them with PlacementTestService.evaluate. The file contains no question text. | Dropped | loads questions with PlacementTestService.loadQuestionsForLanguage and scores them with PlacementTestService.evaluate. The file contains no question text. | Unrecorded |
| P3-067 | placement_quiz_screen.dart | updatePlacementTest and updateProficiency write onboardingProvider.placementTestResults. No reachable screen reads that field. | Dropped | updatePlacementTest and updateProficiency write onboardingProvider.placementTestResults. No reachable screen reads that field. | Unrecorded |
| P3-067 | placement_quiz_screen.dart | no generateAppRoute entry and no other file constructed the class. Unified opens PlacementTestScreen instead. | Dropped | no generateAppRoute entry and no other file constructed the class. Unified opens PlacementTestScreen instead. | Unrecorded |
| P3-067 | placement_test_screen.dart | the unified completion dialog already pushes this screen when self_reported_level is unsure. Questions come from the generate endpoint and PlacementTestService. This card does not copy a question into a new widget. Moving the file would leave that dialog with no screen. | Kept | the unified completion dialog already pushes this screen when self_reported_level is unsure. Questions come from the generate endpoint and PlacementTestService. This card does not copy a question into a new widget. Moving the file would leave that dialog with no screen. | n/a |
| P3-068 | 7 game templates | template_match_board.dart play slot board, action slot controls | Moved | template_match_board.dart play slot board, action slot controls | n/a |
| P3-068 | 7 game templates | template_narrative.dart play slot narrativeContent, action slot actions | Moved | template_narrative.dart play slot narrativeContent, action slot actions | n/a |
| P3-068 | 7 game templates | template_pronunciation.dart play slot content, action slot micControls | Moved | template_pronunciation.dart play slot content, action slot micControls | n/a |
| P3-068 | 7 game templates | template_rhythm.dart play slot rhythmArea, action slot controls | Moved | template_rhythm.dart play slot rhythmArea, action slot controls | n/a |
| P3-068 | 7 game templates | template_strategic.dart play slot board, action slot controls | Moved | template_strategic.dart play slot board, action slot controls | n/a |
| P3-068 | 7 game templates | template_timed_quiz.dart play slot questionArea, action slot actions | Moved | template_timed_quiz.dart play slot questionArea, action slot actions | n/a |
| P3-068 | 7 game templates | GameKitTemplateFrame places those slots on the shared game shell | Moved | GameKitTemplateFrame places those slots on the shared game shell | n/a |
| P3-068 | 7 game templates | seventh template | Unresolved | seventh: not present. A seventh named template class is not present. The card stays Draft. | n/a |
| P3-068 | 7 game templates | template_match_board.dart | Kept | The six template files stay. No route builds them. test/games/game_template_shell_test.dart still builds GameTemplateShell, and that test is outside this card. | n/a |
| P3-068 | 7 game templates | template_narrative.dart | Kept | The six template files stay. No route builds them. test/games/game_template_shell_test.dart still builds GameTemplateShell, and that test is outside this card. | n/a |
| P3-068 | 7 game templates | template_pronunciation.dart | Kept | The six template files stay. No route builds them. test/games/game_template_shell_test.dart still builds GameTemplateShell, and that test is outside this card. | n/a |
| P3-068 | 7 game templates | template_rhythm.dart | Kept | The six template files stay. No route builds them. test/games/game_template_shell_test.dart still builds GameTemplateShell, and that test is outside this card. | n/a |
| P3-068 | 7 game templates | template_strategic.dart | Kept | The six template files stay. No route builds them. test/games/game_template_shell_test.dart still builds GameTemplateShell, and that test is outside this card. | n/a |
| P3-068 | 7 game templates | template_timed_quiz.dart | Kept | The six template files stay. No route builds them. test/games/game_template_shell_test.dart still builds GameTemplateShell, and that test is outside this card. | n/a |
| P3-068 | 7 game templates | game_template_shell.dart | Kept | game_template_shell.dart stays. BaseGameScreen and that shell test import it. The live loader now also shows a harvested loading fact. | n/a |
| P3-068 | universal loading screen | Five loading facts, with the caller's fact winning even when it is empty | Moved | Five loading facts, with the caller's fact winning even when it is empty | n/a |
| P3-068 | universal loading screen | Skip only when a skip callback is set | Moved | Skip only when a skip callback is set | n/a |
| P3-068 | universal loading screen | Back only when the route can pop | Moved | Back only when the route can pop | n/a |
| P3-068 | universal loading screen | Dot index (value * 3).floor() clamped to 0, 1, or 2 | Moved | Dot index (value * 3).floor() clamped to 0, 1, or 2 | n/a |
| P3-068 | universal loading screen | Pulse 2400 ms, progress 8 s, dots 1800 ms | Moved | Pulse 2400 ms, progress 8 s, dots 1800 ms | n/a |
| P3-068 | universal loading screen | LingAfriq, Did You Know?, and Skip | Moved | LingAfriq, Did You Know?, and Skip | n/a |
| P3-068 | universal loading screen | BaseGameScreen and UniversalGameScreen show the fact while a game loads | Moved | BaseGameScreen and UniversalGameScreen show the fact while a game loads | n/a |
| P3-068 | universal loading screen | Three em dashes in the Yoruba, Ge'ez, and Wolof facts were replaced with periods. The card forbids an em dash. The meaning is unchanged. | Dropped | Three em dashes in the Yoruba, Ge'ez, and Wolof facts were replaced with periods. The card forbids an em dash. The meaning is unchanged. | Unrecorded |
| P3-068 | universal loading screen | Unseeded Random() on the live path was replaced with Random(language or game id hash) so the same language or game shows the same fact. The list and nextInt pick are unchanged. | Dropped | Unseeded Random() on the live path was replaced with Random(language or game id hash) so the same language or game shows the same fact. The list and nextInt pick are unchanged. | Unrecorded |
| P3-068 | universal loading screen | Full-page ModernGriot scaffold, pulse rings, and gradient bar stay on the old screen. A second scaffold inside the game shell would stack app bars. The old screen has no route. | Dropped | Full-page ModernGriot scaffold, pulse rings, and gradient bar stay on the old screen. A second scaffold inside the game shell would stack app bars. The old screen has no route. | Unrecorded |
| P3-068 | universal game screen | lib/screens/games/universal_game_screen.dart | Unresolved | screens_path: not present. lib/screens/games/universal_game_screen.dart is not present. | n/a |
| P3-068 | universal game screen | lib/games/gamekit/universal_game_screen.dart | Moved | The GameKit screen already plays a generic game. It now shows the harvested loader, and a start guide when the caller passes one. | n/a |
| P3-068 | universal game screen | GameMasteryResultsScreen | Kept | End of play still opens GameMasteryResultsScreen. Elevation revives that screen as the standard results view. Replacing it would drop skill deltas. | n/a |
| P3-068 | start guide | Character name and title, game title, mission objective, cultural tip | Moved | Character name and title, game title, mission objective, cultural tip | n/a |
| P3-068 | start guide | XP label +N XP | Moved | XP label +N XP | n/a |
| P3-068 | start guide | How to Play keeps the first three steps and drops the rest | Moved | How to Play keeps the first three steps and drops the rest | n/a |
| P3-068 | start guide | Start Mission and Review Vocabulary | Moved | Start Mission and Review Vocabulary | n/a |
| P3-068 | start guide | Hero art, bento grid, and pattern background | Dropped | Hero art, bento grid, and pattern background. They are decoration on an unrouted screen. The steps, labels, and actions are the behavior. | Unrecorded |
| P3-068 | victory results | Mission complete, XP as +N, vocabulary, score, idioms, griot rank, mastery percent | Moved | Mission complete, XP as +N, vocabulary, score, idioms, griot rank, mastery percent | n/a |
| P3-068 | victory results | Mastery bar value is mastery percent divided by 100 | Moved | Mastery bar value is mastery percent divided by 100 | n/a |
| P3-068 | victory results | Claim Rewards and Replay Mission | Moved | Claim Rewards and Replay Mission | n/a |
| P3-068 | victory results | Glow animation and glass stat cards. They are decoration on an unrouted screen. The totals and actions are the behavior. | Dropped | Glow animation and glass stat cards. They are decoration on an unrouted screen. The totals and actions are the behavior. | Unrecorded |
| P3-068 | victory results | UniversalGameScreen does not replace mastery results with this view. See universal_game_screen kept. | Dropped | UniversalGameScreen does not replace mastery results with this view. See universal_game_screen kept. | Unrecorded |
| P3-069 | games/proverb_unlocker GameKit rewrite | GameKit game, factory, scoring, feedback, and screen | Kept | GameKit game, factory, scoring, feedback, and screen | n/a |
| P3-069 | live random-logic version content and proverb data | Six live fallback proverbs, with id, language, original, translation, meaning, and cefr | Kept | Six live fallback proverbs, with id, language, original, translation, meaning, and cefr | n/a |
| P3-069 | live random-logic version content and proverb data | Meaning choice, seeded blank indexes, token order, and the fill-match check | Kept | Meaning choice, seeded blank indexes, token order, and the fill-match check | n/a |
| P3-069 | live random-logic version content and proverb data | Unseeded Random shuffle and blank picker | Dropped | Replaced by Random(seed) so the same seed returns the same proverb and outcome | Unrecorded |
| P3-069 | live random-logic version content and proverb data | Invented fallback proverb and meaning distractors | Dropped | Wisdom comes from experience, A common greeting, A traditional dance, A type of food, and A weather saying are not in the live proverb list | Unrecorded |
| P3-069 | live random-logic version content and proverb data | Polie proverb text on the played path | Dropped | Polie can return text that is not in the harvested list, including that invented fallback | Unrecorded |
| P3-069 | live random-logic version content and proverb data | Placeholder tokens such as word0 | Dropped | They are not proverb words. Token options use words from the harvested proverbs only | Unrecorded |
| P3-069 | live random-logic version content and proverb data | Ancestral tablet widgets | Dropped | The arcade route now builds the GameKit screen. No route builds the old tablet file, which was deleted after the catalog and seed test held the proverb text | Unrecorded |
| P3-070 | enhanced_translation_screen.dart | class now builds LiveTranslateScreen | Moved | The class now builds LiveTranslateScreen with the same source language, target language, and initial text. | n/a |
| P3-070 | enhanced_translation_screen.dart | primary, alternatives, grammar, and cultural notes parsed from the caption | Moved | primary, alternatives, grammar, and cultural notes parsed from the caption | n/a |
| P3-070 | enhanced_translation_screen.dart | the 5000 character guard | Moved | the 5000 character guard | n/a |
| P3-070 | enhanced_translation_screen.dart | a history entry and star toggle on mt.final | Moved | a history entry and star toggle on mt.final | n/a |
| P3-070 | enhanced_translation_screen.dart | the structured prompt text kept beside the parser | Moved | the structured prompt text kept beside the parser | n/a |
| P3-070 | enhanced_translation_screen.dart | client Groq sendMessage call, retry loop, and failure snackbars | Dropped | The live screen already translates on the session socket and already reconnects. | Unrecorded |
| P3-070 | enhanced_translation_screen.dart | fade and slide around the result cards, and the three hide chips | Dropped | A section is shown only when the parse found it. | Unrecorded |
| P3-070 | enhanced_translation_screen.dart | source-word grammar fallback rows | Kept | Source-word grammar fallback rows (part of speech word, no explanation) are still parsed and tested, and the live screen hides them so a plain caption does not list every word. | n/a |
| P3-070 | enhanced chat variant | enhanced chat variant | Unresolved | P3-065 already folded conversation_enhanced_screen.dart. That file is still absent. Polie files were not edited and the old chat screen was not recreated. | n/a |
| P3-070 | enhanced feed variant | enhanced feed variant | Unresolved | No file under lib/screens/feed has enhanced in the name. Survivor is XFeedHomeScreen (route x-feed-home). Nothing moved. | n/a |
| P3-070 | enhanced profile variant | enhanced profile variant | Unresolved | No file under lib/screens/profile has enhanced in the name. Survivor is ProfileScreenMaterial3. Nothing moved. | n/a |
| P3-070 | enhanced settings variant | enhanced settings variant | Unresolved | No file under lib/screens/settings has enhanced in the name. Survivor is SettingsScreenMaterial3 (route settings). Nothing moved. | n/a |
| P3-070 | enhanced curriculum variant | enhanced curriculum variant | Unresolved | No file under lib/screens/curriculum has enhanced in the name. Survivor is LessonsMapEntryScreen (route curriculum). Nothing moved. | n/a |
| P3-070 | enhanced practice variant | enhanced practice variant | Unresolved | No file under lib/screens/practice has enhanced in the name. Survivors are pronunciation_practice_screen.dart, conversation_practice_screen.dart, and tone_drill_screen.dart. Nothing moved. | n/a |
| P3-070 | enhanced UGC variant | lesson badge ids from grammar, cultural, and canonical checks | Moved | lesson badge ids from grammar, cultural, and canonical checks | n/a |
| P3-070 | enhanced UGC variant | validate POST /user-content/validate, the score line, and the validation details screen | Moved | validate POST /user-content/validate, the score line, and the validation details screen | n/a |
| P3-070 | enhanced UGC variant | quiz title, question, option, and answer checks plus badges | Moved | quiz title, question, option, and answer checks plus badges | n/a |
| P3-070 | enhanced UGC variant | story title and content checks plus badges | Moved | story title and content checks plus badges | n/a |
| P3-070 | enhanced UGC variant | CreateLessonScreenEnhanced extends CreateLessonScreen | Moved | That class now extends CreateLessonScreen, because the drawer files are outside this card. | n/a |
| P3-070 | enhanced UGC variant | enhanced lesson POST /user-content/lessons with qualityBadges | Dropped | The live service has no qualityBadges field and that service is outside this card. Badges are still shown. | Unrecorded |
| P3-070 | enhanced UGC variant | lesson loading overlay sentence | Dropped | The live create button already shows a spinner. | Unrecorded |
| P3-070 | enhanced UGC variant | enhanced quiz second question editor | Dropped | The live screen already edits four options and a correct answer. | Unrecorded |

## Harvest list coverage

Every harvest_list item on the six cards has at least one row above.

Items read from the cards:

- P3-065: 6 harvest_list items
- P3-066: 5 harvest_list items
- P3-067: 7 harvest_list items
- P3-068: 5 harvest_list items
- P3-069: 2 harvest_list items
- P3-070: 8 harvest_list items

## Import scan

Scanned `lib` for import, export, and part directives.
Comments are not imports. The GameKit proverb file is not the deleted tablet. A path must contain cultural/proverb_unlocker_game.dart to match the old tablet.

Scan set the cards named as deleted or moved to legacy:

- ai_chat_screen.dart, ai_chat_screen_new.dart, ai_chat_screen_with_tracking.dart, conversation_enhanced_screen.dart. P3-065 says they were already deleted in 514e70e1 and had no route.
- ai_mode_selection_screen.dart. P3-065 says it moved to legacy/ai_chat/.
- cultural/proverb_unlocker_game.dart. P3-069 says the old tablet file was deleted. The surviving catalog names that path. lib/games/proverb_unlocker/proverb_unlocker_game.dart is the survivor.
- create_quiz_screen_enhanced.dart and create_story_screen_enhanced.dart. P3-070 says the quiz and story enhanced files are deleted.

Also scanned, because the files are under legacy/onboarding/. P3-067's harvest_audit does not say moved to legacy. An import from lib/ would still be a remaining variant import:

- enhanced_onboarding_flow_screen.dart
- kijiji_onboarding_screen.dart
- modern_onboarding_screen.dart
- onboarding_screen.dart
- onboarding_screen_material3.dart
- placement_quiz_screen.dart

Not in the failure set:

- placement_test_screen.dart. P3-067 says the file stays.
- classroom_v2_route_args.dart. P3-066 says the file stays. P3-066 does not say the other classroom variant files were deleted or moved to legacy, so those names are not a failure set.
- game_template_shell.dart and the six template files. P3-068 says they stay.
- enhanced_translation_screen.dart and create_lesson_screen_enhanced.dart. P3-070 says the navigation helper still constructs the translation screen and the drawer still opens the lesson class. Those files were not described as deleted.

No lib/ import of a deleted or legacy variant. Exit 0.

Kept template references in lib/. These are not failures.

- lib/games/gamekit/harvested_frame.dart:5 references `../../screens/games/templates/game_template_shell.dart`
- lib/screens/games/base_game_screen.dart:30 references `templates/game_template_shell.dart`
- lib/screens/games/templates/index.dart:1 references `game_template_shell.dart`
- lib/screens/games/templates/index.dart:2 references `template_match_board.dart`
- lib/screens/games/templates/index.dart:3 references `template_narrative.dart`
- lib/screens/games/templates/index.dart:4 references `template_pronunciation.dart`
- lib/screens/games/templates/index.dart:5 references `template_rhythm.dart`
- lib/screens/games/templates/index.dart:6 references `template_strategic.dart`
- lib/screens/games/templates/index.dart:7 references `template_timed_quiz.dart`
- lib/screens/games/templates/template_match_board.dart:2 references `game_template_shell.dart`
- lib/screens/games/templates/template_narrative.dart:2 references `game_template_shell.dart`
- lib/screens/games/templates/template_pronunciation.dart:2 references `game_template_shell.dart`
- lib/screens/games/templates/template_rhythm.dart:2 references `game_template_shell.dart`
- lib/screens/games/templates/template_strategic.dart:2 references `game_template_shell.dart`
- lib/screens/games/templates/template_timed_quiz.dart:2 references `game_template_shell.dart`

P3-068 kept game_template_shell.dart because BaseGameScreen and the shell test import it. The shell test lives under test/ and is outside this lib scan. harvested_frame.dart also imports the shell. That is the same kept file, so it is listed here and does not fail the scan.
