import 'package:lingafriq/services/env_config.dart';

/// Canonical API path contracts shared by mobile features.
/// Keep this file aligned with backend route mounts in `src/routes/index.route.ts`.
///
/// Usage:
///   ApiContract.url(ApiContract.auth.login)          // absolute URL
///   ApiContract.url(ApiContract.gamification.xpAward) // absolute URL
///   ApiContract.gamification.challenges(goalId)       // dynamic path builder
class ApiContract {
  ApiContract._();

  static String get baseUrl =>
      EnvConfig.backendBaseUrl.replaceAll(RegExp(r'/$'), '');

  /// Build an absolute URL from a contract path.
  static String url(String path) => '$baseUrl$path';

  // ---------------------------------------------------------------------------
  // Domain groups
  // ---------------------------------------------------------------------------

  static const auth = _Auth();
  static const accounts = _Accounts();
  static const gamification = _Gamification();
  static const chat = _Chat();
  static const social = _Social();
  static const socialAudio = _SocialAudio();
  static const content = _Content();
  static const grammar = _Grammar();
  static const ai = _Ai();
  static const games = _Games();
  static const lessonItems = _LessonItems();
  static const interactive = _Interactive();
  static const adaptiveLearning = _AdaptiveLearning();
  static const personalities = _Personalities();
  static const items = _Items();
  static const events = _Events();
  static const badges = _Badges();
  static const media = _Media();
  static const voice = _Voice();
  static const onboarding = _Onboarding();
  static const sync = _Sync();
  static const offline = _Offline();
  static const userContent = _UserContent();
  static const villages = _Villages();
  static const tribes = _Tribes();
  static const journey = _Journey();
  static const avatar = _Avatar();
  static const currency = _Currency();
  static const subscriptions = _Subscriptions();
  static const leaderboards = _Leaderboards();
  static const competitions = _Competitions();
  static const pronunciation = _Pronunciation();
  static const learning = _Learning();
  static const learningPath = _LearningPath();
  static const misc = _Misc();
}

// =============================================================================
// Auth
// =============================================================================
class _Auth {
  const _Auth();
  String get login => '/auth/jwt/create/';
  String get refresh => '/auth/jwt/refresh/';
  String get register => '/accounts/auth/users/';
  String get userInfo => '/accounts/auth/users/me/';
  String updateProfile(int id) => '/accounts/auth/users/$id/';
  String get resetPassword => '/accounts/auth/users/reset_password/';
  String get changePassword => '/accounts/auth/users/set_password/';
  String get sendVerification => '/auth/send-verification';
  String get verifyEmail => '/auth/verify-email';
  String get resendVerification => '/auth/resend-verification';
  String get registerFcmDevice => '/devices/';
  String unregisterFcmDevice(String token) => '/devices/$token/';
  String deleteUser(int id) => '/account/user_delete/$id';
  String get accountUpdate => '/account/update/';
  String get profiles => '/account/all_users/';
  String userProfile(int id) => '/account/my_user_profile/?id=$id';
}

// =============================================================================
// Accounts
// =============================================================================
class _Accounts {
  const _Accounts();
  String get usersSearch => '/accounts/auth/users/search';
  String get userPreferences => '/api/user/preferences';
}

// =============================================================================
// Gamification
// =============================================================================
class _Gamification {
  const _Gamification();
  String get sync => '/api/gamification/sync';
  String get progress => '/api/gamification/progress';
  String get progressSync => '/api/gamification/progress/sync';
  String get xpAward => '/api/gamification/xp/award';
  String get xpTotal => '/api/gamification/xp/total';
  String get badges => '/api/gamification/badges/';
  String userBadges(String userId) => '/api/gamification/badges/users/$userId';
  String userGamification(String userId) => '/api/gamification/users/$userId';
  String challenges(String goalId) =>
      '/api/gamification/advanced/challenges/$goalId';
  String get challengesBase => '/api/gamification/advanced/challenges';
  String get milestones => '/api/gamification/advanced/milestones';
  String get leagueXp => '/api/gamification/advanced/league/xp';
  String get leagueLeaderboard =>
      '/api/gamification/advanced/league/leaderboard';
  String get heartsUse => '/api/gamification/hearts/use';
  String get heartsRefill => '/api/gamification/hearts/refill';
  String get challengeMode => '/api/gamification/challenge-mode';
  String get launchEvents => '/api/gamification/launch-events/';
  String launchEventLeaderboard(String eventId) =>
      '/api/gamification/launch-events/$eventId/leaderboard';
  String get ubuntuDonate => '/api/gamification/ubuntu/donate';
  String get dailyChallenges => '/api/gamification/advanced/challenges';
  String get league => '/api/gamification/advanced/league';
}

// =============================================================================
// Chat
// =============================================================================
class _Chat {
  const _Chat();
  String get global => '/chat/global';
  String get private_ => '/chat/private';
  String get search => '/api/chat/search';
  String get report => '/chat/report';
}

// =============================================================================
// Social (connections)
// =============================================================================
class _Social {
  const _Social();
  String get connections => '/connections';
  String get connectionsSearch => '/connections/search';
  String get connectionRequest => '/connections/request';
  String connectionAccept(String id) => '/connections/$id/accept';
  String connectionReject(String id) => '/connections/$id';
  String get connectionBlock => '/connections/block';
  String get connectionUnblock => '/connections/unblock';
  String get connectionsPending => '/connections/pending';
  String get connectionsBlocked => '/connections/blocked';
  String get gift => '/api/social/gift';
  String get giftHistory => '/api/social/gifts/history';
  String get giftStats => '/api/social/gifts/stats';
  String get friendQuests => '/api/social/friend-quests';
  String friendQuest(String id) => '/api/social/friend-quests/$id';
  String friendQuestJoin(String id) => '/api/social/friend-quests/$id/join';
  String friendQuestProgress(String id) => '/api/social/friend-quests/$id/progress';
  String get feed => '/api/social/feed';
  String challenges(String? friendId) => '/api/social/challenges${friendId != null ? '?friendId=$friendId' : ''}';
}

// =============================================================================
// Social Audio
// =============================================================================
class _SocialAudio {
  const _SocialAudio();
  String get rooms => '/api/social-audio/rooms';
  String room(String roomId) => '/api/social-audio/rooms/$roomId';
  String roomJoin(String roomId) => '/api/social-audio/rooms/$roomId/join';
  String roomLeave(String roomId) => '/api/social-audio/rooms/$roomId/leave';
  String roomStatus(String roomId) => '/api/social-audio/rooms/$roomId/status';
  String roomParticipants(String roomId) =>
      '/api/social-audio/rooms/$roomId/participants';
  String roomModerate(String roomId) =>
      '/api/social-audio/rooms/$roomId/moderate';
  String roomSpeakers(String roomId) =>
      '/api/social-audio/rooms/$roomId/speakers';
  String roomHistory(String roomId) =>
      '/api/social-audio/rooms/$roomId/history';
  String followUser(String userId) => '/api/social-audio/following/$userId';
  String get following => '/api/social-audio/following';
  String get followingList => '/api/social-audio/following/list';
  String get followers => '/api/social-audio/followers';
  String get roomsScheduled => '/api/social-audio/rooms/scheduled';
  String get roomsUser => '/api/social-audio/rooms/user';
  String roomLearningSummary(String roomId) =>
      '/api/social-audio/rooms/$roomId/learning-summary';
  String get learningTrack => '/api/social-audio/learning/track';
  String get learningWords => '/api/social-audio/learning/words';
  String get learningPronunciation =>
      '/api/social-audio/learning/pronunciation';
  String get learningStats => '/api/social-audio/learning/stats';
  String get voiceContributions => '/api/voice/contributions';
}

// =============================================================================
// Content / Lessons
// =============================================================================
class _Content {
  const _Content();
  String get lessons => '/lessons/';
  String sectionLessons(int lessonId) => '/lessons/$lessonId/all';
  String completeLessonTutorial(dynamic lessonId, dynamic sectionId) =>
      '/lessons/$lessonId/lessons/$sectionId/lesson_lesson';
  String completeLessonQuiz(dynamic lessonId, dynamic sectionId) =>
      '/lessons/$lessonId/lessons/$sectionId/quiz_detail';
  String get language => '/language';
  String get mannerisms => '/mannerism/';
  String mannerismSections(int id) => '/mannerism/$id/all/';
  String completeMannerismLesson(int mannerismId, int lessonId) =>
      '/mannerism/$mannerismId/mannerism/$lessonId/lessons/';
  String get history => '/history/';
  String historySections(int id) => '/history/$id/all';
  String completeHistoryTutorial(dynamic historyId, dynamic sectionId) =>
      '/history/$historyId/lessons/$sectionId/history_lesson';
  String completeHistoryQuiz(dynamic historyId, dynamic sectionId) =>
      '/history/$historyId/quizes/$sectionId/quiz_detail';
  String get randomQuizBase => '/random_quiz/';
  String randomQuiz(int langId) => '/random_quiz/$langId/all';
  String completeRandomInstantQuiz(dynamic langId, dynamic qId) =>
      '/random_quiz/$langId/questions/$qId/inst_ques_detail';
  String completeRandomWordQuiz(dynamic langId, dynamic qId) =>
      '/random_quiz/$langId/questions/$qId/word_ques_detail';
  String get languageQuiz => '/language_quiz/';
  String languageQuizSections(int sectionId) =>
      '/language_quiz/$sectionId/all';
  String completeLanguageQuiz(dynamic sectionId, dynamic qId) =>
      '/language_quiz/$sectionId/quizes/$qId/quiz_detail';
  String get historyQuiz => '/history_quiz/';
  String historyQuizSections(int sectionId) =>
      '/history_quiz/$sectionId/all';
  String completeHistoryQuiz2(dynamic sectionId, dynamic qId) =>
      '/history_quiz/$sectionId/quizes/$qId/quiz_detail';
  String get cultureMagazine => '/culture-magazine/';
  String cultureArticles({bool? published}) =>
      '/culture-magazine/articles${published != null ? '?published=$published' : ''}';
  String cultureArticle(String id) => '/culture-magazine/articles/$id';
  String get scenarios => '/api/content/scenarios';
  String get cultural => '/api/content/cultural';
  String get wordOfDay => '/api/content/vocabulary/word-of-day';
  String get listening => '/api/content/listening';
}

// =============================================================================
// Grammar
// =============================================================================
class _Grammar {
  const _Grammar();
  String get explanations => '/api/grammar/explanations';
  String exercises(String topicId) => '/api/grammar/$topicId/exercises';
  String get progress => '/api/grammar/progress';
}

// =============================================================================
// AI / Polie
// =============================================================================
class _Ai {
  const _Ai();
  String get polieRiveState => '/api/v1/polie/rive-state';
  String get polieEvaluateGameTurn => '/api/v1/polie/evaluate-game-turn';
  String get polieGameContent => '/api/games/game-content';
  String get chatHistorySync => '/api/ai/chat/history/sync/';
  String chatHistory(String mode) => '/api/ai/chat/history/$mode';
  String get chatSrsSync => '/api/ai/chat/srs/sync/';
  String get chatCompletion => '/api/ai/chat/completion';
  String get loadingScreenContent => '/api/v1/loading-screen/content';
  String loadingScreenImage(String prompt) =>
      '/api/v1/loading-screen/image/${Uri.encodeComponent(prompt)}';
  String get hybridTranslate => '/hybrid-polie/translate';
  String get hybridCanonical => '/hybrid-polie/canonical';
  String get aiChat => '/api/ai-chat';
}

// =============================================================================
// Games
// =============================================================================
class _Games {
  const _Games();
  String get cards => '/api/games/cards';
  String get telemetry => '/api/games/telemetry/';
  String get sessionStart => '/api/games/session/start/';
  String srsUser(String userId) => '/api/games/srs/user/$userId';
  String get complete => '/games/complete';
  String get pronunciationQuick => '/pronunciation/quick';
}

// =============================================================================
// Lesson Items (v1)
// =============================================================================
class _LessonItems {
  const _LessonItems();
  String get list => '/v1/lesson-items';
  String item(String itemId) => '/v1/lesson-items/$itemId';
  String get stats => '/v1/lesson-items/stats';
}

// =============================================================================
// Interactive Exercises & Stories
// =============================================================================
class _Interactive {
  const _Interactive();
  String get exercises => '/api/v1/exercises';
  String exercise(String exerciseId) => '/api/v1/exercises/$exerciseId';
  String exerciseSubmit(String exerciseId) =>
      '/api/v1/exercises/$exerciseId/submit';
  String get exercisesAdaptive => '/api/v1/exercises/adaptive';
  String get stories => '/api/v1/stories';
  String story(String storyId) => '/api/v1/stories/$storyId';
  String storyChapter(String storyId, String chapterId) =>
      '/api/v1/stories/$storyId/chapters/$chapterId';
  String storyChapterChoice(String storyId, String chapterId) =>
      '/api/v1/stories/$storyId/chapters/$chapterId/choice';
  String storyProgress(String storyId, String userId) =>
      '/api/v1/stories/$storyId/progress/$userId';
}

// =============================================================================
// Adaptive Learning
// =============================================================================
class _AdaptiveLearning {
  const _AdaptiveLearning();
  String performance(String userId, String language) =>
      '/api/v1/adaptive-learning/performance/$userId/$language';
  String difficulty(String userId, String language) =>
      '/api/v1/adaptive-learning/difficulty/$userId/$language';
  String recommendations(String userId, String language) =>
      '/api/v1/adaptive-learning/recommendations/$userId/$language';
  String prediction(String userId, String language) =>
      '/api/v1/adaptive-learning/prediction/$userId/$language';
  String get adjustDifficulty => '/api/v1/adaptive-learning/adjust-difficulty';
  String get performanceSummary => '/api/v1/adaptive-learning/performance';
  String skillRecommendations(String skill) =>
      '/api/v1/adaptive-learning/skills/$skill/recommendations';
}

// =============================================================================
// Historical Personalities / AI Characters
// =============================================================================
class _Personalities {
  const _Personalities();
  String get list => '/api/v1/personalities';
  String details(String personalityId) =>
      '/api/v1/personalities/$personalityId';
  String chatStart(String personalityId) =>
      '/api/v1/personalities/$personalityId/chat/start';
  String chatMessage(String sessionId) =>
      '/api/v1/personalities/chat/$sessionId/message';
  String chatSession(String sessionId) =>
      '/api/v1/personalities/chat/$sessionId';
  String userChatSessions(String userId) =>
      '/api/v1/personalities/chat/user/$userId';
  String knowledge(String personalityId) =>
      '/api/v1/personalities/$personalityId/knowledge';
  String suggestions(String personalityId) =>
      '/api/v1/personalities/$personalityId/suggestions';
}

// =============================================================================
// Items / Inventory
// =============================================================================
class _Items {
  const _Items();
  String get list => '/api/items';
  String userInventory(String userId) => '/api/items/users/$userId/inventory';
  String userClaim(String userId) => '/api/items/users/$userId/items/claim';
  String userUse(String userId) => '/api/items/users/$userId/items/use';
}

// =============================================================================
// Events
// =============================================================================
class _Events {
  const _Events();
  String get list => '/api/events';
}

// =============================================================================
// Badges
// =============================================================================
class _Badges {
  const _Badges();
  String get list => '/api/badges';
  String userBadges(String userId) => '/api/badges/users/$userId';
}

// =============================================================================
// Media
// =============================================================================
class _Media {
  const _Media();
  String get upload => '/media/upload';
  String get base => '/media/';
  String details(String mediaId) => '/media/$mediaId';
  String transcribe(String mediaId) => '/media/$mediaId/transcribe';
  String generateLesson(String mediaId) => '/media/$mediaId/generate-lesson';
}

// =============================================================================
// Voice / Speech
// =============================================================================
class _Voice {
  const _Voice();
  String get sttTranscribeEnhanced => '/api/voice/stt/transcribe-enhanced';
  String get sttTranscribe => '/api/voice/stt/transcribe';
  String get detectLanguage => '/api/voice/stt/detect-language';
  String dialects(String languageCode) =>
      '/api/voice/stt/dialects/$languageCode';
  String get sttLanguages => '/api/voice/stt/languages';
  String get ttsSynthesize => '/api/voice/tts/synthesize';
  String get ttsLanguages => '/api/voice/tts/languages';
  String get lessons => '/api/voice/lessons';
  String lesson(String lessonId) => '/api/voice/lessons/$lessonId';
  String lessonsProgress(String userId, String language) =>
      '/api/voice/lessons/progress/$userId/$language';
  String get lessonsProgressUpdate => '/api/voice/lessons/progress';
  String get health => '/api/voice/health';
}

// =============================================================================
// Pronunciation
// =============================================================================
class _Pronunciation {
  const _Pronunciation();
  String get advancedAnalyze => '/api/pronunciation/advanced/analyze';
  String stats(String userId, String language) =>
      '/api/v1/pronunciation/stats/$userId/$language';
  String get languages => '/api/v1/pronunciation/languages';
  String get analyze => '/api/voice/pronunciation/analyze';
  String get history => '/api/voice/pronunciation/history';
  String get quick => '/api/voice/pronunciation/quick';
  String get tone => '/api/voice/pronunciation/tone';
  String difficulty(String userId, String language) =>
      '/api/voice/pronunciation/difficulty/$userId/$language';
  String profile(String userId, String language) =>
      '/api/voice/pronunciation/profile/$userId/$language';
}

// =============================================================================
// Learning Engine
// =============================================================================
class _Learning {
  const _Learning();
  String get syncState => '/api/learning/state/skill';
  String get syncFullState => '/api/learning/state/sync';
  String state(String languageCode) => '/api/learning/state/$languageCode';
  String metrics(String languageCode) => '/api/learning/metrics/$languageCode';
  String get corrections => '/api/learning/corrections';
  String correctionVote(String id) => '/api/learning/corrections/$id/vote';
  String get syncAchievement => '/api/learning/achievements/sync';
  String get achievements => '/api/learning/achievements';
  String get syncCorrection => '/api/learning/corrections';
}

// =============================================================================
// Learning Path
// =============================================================================
class _LearningPath {
  const _LearningPath();

  String byContext({
    required String language,
    required String type,
  }) =>
      '/api/learning-path?language=$language&type=$type';

  String get create => '/api/learning-path';

  String updateByContext({
    required String language,
    required String type,
  }) =>
      '/api/learning-path?language=$language&type=$type';

  String get completeModule => '/api/learning-path/complete-module';
}

// =============================================================================
// Onboarding
// =============================================================================
class _Onboarding {
  const _Onboarding();
  String get save => '/api/onboarding/save/';
  String get checkUsername => '/onboarding/check-username';
  String get placementTestGenerate => '/onboarding/placement-test/generate';
}

// =============================================================================
// Sync / Offline / Telemetry
// =============================================================================
class _Sync {
  const _Sync();
  String get learnerActivity => '/api/learner-activity';
  String get experimentsConfig => '/api/experiments/config';
}

// =============================================================================
// Offline Content
// =============================================================================
class _Offline {
  const _Offline();
  String contentManifest(String language) =>
      '/api/v1/offline/content/$language/manifest';
  String gameManifest(String gameId) =>
      '/api/v1/offline/games/$gameId/manifest';
}

// =============================================================================
// User-Generated Content
// =============================================================================
class _UserContent {
  const _UserContent();
  String get lessons => '/api/user-content/lessons';
  String get quizzes => '/api/user-content/quizzes';
  String get stories => '/api/user-content/stories';
  String get share => '/api/user-content/share';
  String get content => '/api/user-content/content';
  String get rate => '/api/user-content/rate';
  String get base => '/api/user-content/';
}

// =============================================================================
// Villages
// =============================================================================
class _Villages {
  const _Villages();
  String get list => '/api/villages';
  String byLanguage(String lang) => '/api/villages/$lang';
  String livekitToken(String lang) => '/api/villages/$lang/livekit-token';
}

// =============================================================================
// Tribes
// =============================================================================
class _Tribes {
  const _Tribes();
  String get list => '/api/tribes';
  String get classrooms => '/api/tribes/classrooms';
  String details(String id) => '/api/tribes/$id';
  String join(String id) => '/api/tribes/$id/join';
  String leave(String id) => '/api/tribes/$id/leave';
  String activity(String id) => '/api/tribes/$id/activity';
  String depositXp(String id) => '/api/tribes/$id/deposit-xp';
  String get eventsCurrent => '/api/tribes/events/current';
  String get me => '/api/tribes/me';
  String classroomProgress(String id) =>
      '/api/tribes/$id/classroom/progress';
}

// =============================================================================
// Journey / Quests
// =============================================================================
class _Journey {
  const _Journey();
  String nodes(String campaign) => '/api/journey/$campaign/nodes';
  String node(String campaign, String nodeId) =>
      '/api/journey/$campaign/node/$nodeId';
  String nodeStart(String campaign, String nodeId) =>
      '/api/journey/$campaign/node/$nodeId/start';
  String nodeComplete(String campaign, String nodeId) =>
      '/api/journey/$campaign/node/$nodeId/complete';
  String userProgress(String userId) => '/api/journey/$userId/progress';
}

// =============================================================================
// Avatar
// =============================================================================
class _Avatar {
  const _Avatar();
  String get config => '/api/avatar/config';
  String get unlock => '/api/avatar/unlock';
}

// =============================================================================
// Currency
// =============================================================================
class _Currency {
  const _Currency();
  String get balance => '/api/gamification/currency/balance';
  String get award => '/api/gamification/currency/award';
  String get spend => '/api/gamification/currency/spend';
  String get transfer => '/api/gamification/currency/transfer';
  String get tribeDeposit => '/api/gamification/currency/tribe/deposit';
}

// =============================================================================
// Subscriptions
// =============================================================================
class _Subscriptions {
  const _Subscriptions();
  String get status => '/api/subscriptions/status';
  String get cancel => '/api/subscriptions/cancel';
}

// =============================================================================
// Leaderboards
// =============================================================================
class _Leaderboards {
  const _Leaderboards();
  String get base => '/api/leaderboards';
  String byType(String type) => '/api/leaderboards/$type';
  String userRanks(String userId) => '/api/leaderboards/user/$userId/ranks';
}

// =============================================================================
// Competitions
// =============================================================================
class _Competitions {
  const _Competitions();
  String get list => '/api/competitions';
  String details(String id) => '/api/competitions/$id';
  String results(String id) => '/api/competitions/$id/results';
}

// =============================================================================
// Misc
// =============================================================================
class _Misc {
  const _Misc();
  String get healthcheck => '/healthcheck';
}
