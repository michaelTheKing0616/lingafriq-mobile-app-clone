import 'package:lingafriq/services/env_config.dart';

class Api {
  // Use EnvConfig.backendBaseUrl; defaults to https://admin.lingafriq.com if BACKEND_URL not set.
  // Override via --dart-define=BACKEND_URL=... during build.
  static String get baseurl {
    final envUrl = EnvConfig.backendBaseUrl;
    // Ensure URL ends with slash
    return envUrl.endsWith('/') ? envUrl : '$envUrl/';
  }
  
  // Legacy commented URLs for reference
  // static const String baseurl = "http://34.121.156.251:8000/";
  // static const String baseurl = "http://34.67.162.25:8000/";
  // static const String baseurl = "http://64.227.113.179:8000/";
  // Auth endpoints
  //
  // IMPORTANT:
  // The backend provides Django-JWT compatible "legacy" endpoints at:
  // - POST /auth/jwt/create/   -> { access, refresh }
  // - POST /auth/jwt/refresh/  -> { access }
  //
  // These are mounted at both root and /accounts for backwards compatibility,
  // but we use the root paths here to avoid coupling auth to /accounts/*.
  static const String register = "accounts/auth/users/";
  static const String login = "auth/jwt/create/";
  static const String refreshToken = "auth/jwt/refresh/";
  static const String userInfo = "accounts/auth/users/me/";
  static const String userPreferences = "api/user/preferences";
  static const String registerFcmDevice = "devices/";
  static String unRegisterFcmDevice(String token) => "devices/$token/";
  static String userProfile(int id) => "account/my_user_profile/?id=$id";

  static String updateProfile(int id) => "accounts/auth/users/$id/";
  static const String accountUpdate = "account/update/";
  // static String deleteUser(int id) => "accounts/auth/users/$id/";
  static String deleteUser(int id) => "/account/user_delete/$id";
  static const String resetPassword = "accounts/auth/users/reset_password/";
  static const String changePassword = "accounts/auth/users/set_password/";
  static const String sendVerification = "auth/send-verification";
  static const String verifyEmail = "auth/verify-email";
  static const String resendVerification = "auth/resend-verification";
  // static const String profiles = "account/my_user_profile/";
  static const String profiles = "account/all_users/";
  static const String language = "language";

  //Lessons Start
  static const String lessons = "lessons/";
  static String sectionLessonsList(int lessonId) => "lessons/$lessonId/all";
  static String completeLessonTutorial(lessonId, sectionLessonId) =>
      "/lessons/$lessonId/lessons/$sectionLessonId/lesson_lesson";
  static String completeLessonQuiz(lessonId, sectionLessonId) =>
      "/lessons/$lessonId/lessons/$sectionLessonId/quiz_detail";
  //Lessons End

  //Mannerisms Start
  static const String mannerism = "mannerism/";
  static String mannerismTutorialsList(int mannerismId) => "mannerism/$mannerismId/all/";
  static String completeMannerismLessons(int mannerismId, int lessonId) =>
      "mannerism/$mannerismId/mannerism/$lessonId/lessons/";
  //Mannerisms End

  //History Start
  static const String history = "history/";
  static String sectionHistoryList(int historyId) => "history/$historyId/all";
  static String completeHistoryTutorial(historyId, sectionHistoryId) =>
      "/history/$historyId/lessons/$sectionHistoryId/history_lesson";
  static String completeHistoryQuiz(historyId, sectionHistoryId) =>
      "/history/$historyId/quizes/$sectionHistoryId/quiz_detail";
  //History End

  //Random Quiz Start
  static String randomQuiz(int languageId) => "/random_quiz/$languageId/all";
  static String completeRandomInstantQuiz(languageId, questionId) =>
      "/random_quiz/$languageId/questions/$questionId/inst_ques_detail";
  static String completeRandomWordQuiz(languageId, questionId) =>
      "/random_quiz/$languageId/questions/$questionId/word_ques_detail";
  //Random Quiz End

  //Language Quiz Start
  static const String languageQuiz = "/language_quiz/";
  static String sectionlanguageQuiz(int sectionId) => "/language_quiz/$sectionId/all";
  static String completelanguageInstantQuiz(sectionId, questionId) =>
      "/language_quiz/$sectionId/quizes/$questionId/quiz_detail";
  // static String completeRandomWordQuiz(languageId, questionId) =>
  //     "/random_quiz/$languageId/questions/$questionId/word_ques_detail";
  //Language Quiz End

  //History Quiz Start
  static const String historyQuiz = "/history_quiz/";
  static String sectionHistoryQuiz(int sectionId) => "/history_quiz/$sectionId/all";
  static String completeHistoryInstantQuiz(sectionId, questionId) =>
      "/history_quiz/$sectionId/quizes/$questionId/quiz_detail";
  // static String completeRandomWordQuiz(languageId, questionId) =>
  //     "/random_quiz/$languageId/questions/$questionId/word_ques_detail";
  //History Quiz End

  // Gamification API endpoints
  static const String gamificationBase = 'api/gamification/';
  static const String xpAward = '${gamificationBase}xp/award';
  static const String xpTotal = '${gamificationBase}xp/total';
  static const String badges = '${gamificationBase}badges/';
  static String userBadges(String userId) => '${gamificationBase}badges/users/$userId';
  static String userGamification(String userId) => '${gamificationBase}users/$userId';
  static const String launchEvents = '${gamificationBase}launch-events/';
  static String launchEventJoin(String eventId) => '${gamificationBase}launch-events/join';
  static String launchEventLeaderboard(String eventId) => '${gamificationBase}launch-events/$eventId/leaderboard';
  static const String ubuntuDonate = '${gamificationBase}ubuntu/donate';
  static const String dailyChallenges = '${gamificationBase}advanced/challenges';
  static const String league = '${gamificationBase}advanced/league';
  static const String leagueLeaderboard = '${gamificationBase}advanced/league/leaderboard';
  static const String milestones = '${gamificationBase}advanced/milestones';
  
  // Tribes API endpoints
  static const String tribes = 'api/tribes';
  static const String tribesClassrooms = 'api/tribes/classrooms';
  static String tribeDetails(String id) => 'api/tribes/$id';
  static String tribeJoin(String id) => 'api/tribes/$id/join';
  static String tribeLeave(String id) => 'api/tribes/$id/leave';
  static String tribeActivity(String id) => 'api/tribes/$id/activity';
  static String tribeDepositXP(String id) => 'api/tribes/$id/deposit-xp';
  
  // Avatar API endpoints
  static const String avatarBase = 'api/avatar/';
  static const String avatarConfig = '${avatarBase}config';
  static const String avatarUnlock = '${avatarBase}unlock';
  
  // Currency API endpoints
  static const String currencyBalance = '${gamificationBase}currency/balance';
  static const String currencyAward = '${gamificationBase}currency/award';
  static const String currencySpend = '${gamificationBase}currency/spend';
  static const String currencyTransfer = '${gamificationBase}currency/transfer';
  static const String currencyTribeDeposit = '${gamificationBase}currency/tribe/deposit';
  
  // Culture Magazine API endpoints
  static const String cultureMagazine = 'culture-magazine/';
  static String cultureArticles({bool? published}) => 'culture-magazine/articles${published != null ? '?published=$published' : ''}';
  static String cultureArticle(String id) => 'culture-magazine/articles/$id';
  
  // Media API endpoints
  static const String media = 'media/';
  static String mediaGenerateLesson(String mediaId) => 'media/$mediaId/generate-lesson';
  static String mediaLinkLesson(String mediaId) => 'media/$mediaId/link-lesson';
  
  // Chat API endpoints
  static const String chatGlobal = 'chat/global';
  static const String chatPrivate = 'chat/private';
  static const String chatConversations = 'chat/conversations';
  /// Private DM thread with another user (numeric id or handle-resolved id).
  static String chatPrivateMessages(String otherUserId) => 'chat/private/$otherUserId';
  /// WhatsApp-style REST surface (auth required).
  static const String waConversations = 'api/wa/conversations';
  static const String waMessages = 'api/wa/messages';
  
  // Media API endpoints  
  static String mediaUpload() => 'media/upload';
  static String mediaTranscribe(String mediaId) => 'media/$mediaId/transcribe';
  static String mediaDetails(String mediaId) => 'media/$mediaId';
  
  // User Content API endpoints
  static const String userContent = 'api/user-content/';
  
  // Marketplace API endpoints
  static const String marketplace = 'api/marketplace/';
  static String marketplaceItems({String? category}) => 'api/marketplace/items${category != null ? '?category=$category' : ''}';
  
  // Villages API endpoints
  static const String villages = 'api/villages';
  static String villageByLanguage(String lang) => 'api/villages/$lang';
  static String villageLivekitToken(String lang) => 'api/villages/$lang/livekit-token';
  
  // Journey API endpoints
  static String journeyNodes(String campaign) => 'api/journey/$campaign/nodes';
  static String journeyNode(String campaign, String nodeId) => 'api/journey/$campaign/node/$nodeId';
  static String journeyNodeStart(String campaign, String nodeId) => 'api/journey/$campaign/node/$nodeId/start';
  static String journeyNodeComplete(String campaign, String nodeId) => 'api/journey/$campaign/node/$nodeId/complete';
  static String journeyUserProgress(String userId) => 'api/journey/$userId/progress';
  
  // Games API endpoints
  static const String games = 'games';
  static const String gameSessionStart = 'api/games/session/start';
  static String gameSessionTurn(String sessionId) => 'api/games/session/$sessionId/turn';
  static String gameSessionComplete(String sessionId) => 'api/games/session/$sessionId/complete';
  
  // Leaderboard API endpoints
  static const String leaderboards = 'api/leaderboards';
  static String leaderboardByType(String type) => 'api/leaderboards/$type';
  static String userLeaderboardRanks(String userId) => 'api/leaderboards/user/$userId/ranks';
  
  // Competitions API endpoints
  static const String competitions = 'api/competitions';
  static String competitionDetails(String id) => 'api/competitions/$id';
  
  // User Search API endpoints
  static String searchUsersByHandle(String handle) => 'accounts/auth/users/search?handle=$handle';
  
  // Connections API endpoints
  static const String connections = 'connections';
  static const String connectionsSearch = 'connections/search';
  static String connectionRequest() => 'connections/request';
  static String connectionAccept(String connectionId) => 'connections/$connectionId/accept';
  static String connectionReject(String connectionId) => 'connections/$connectionId';
  static String connectionBlock() => 'connections/block';
  static String connectionUnblock() => 'connections/unblock';
  static const String connectionsPending = 'connections/pending';
  static const String connectionsBlocked = 'connections/blocked';
  
  // Social Audio API endpoints
  static const String socialAudioBase = 'api/social-audio/';
  static const String socialAudioRooms = '${socialAudioBase}rooms';
  static String socialAudioRoom(String roomId) => '${socialAudioBase}rooms/$roomId';
  static String socialAudioRoomJoin(String roomId) => '${socialAudioBase}rooms/$roomId/join';
  static String socialAudioRoomLeave(String roomId) => '${socialAudioBase}rooms/$roomId/leave';
  static String socialAudioRoomStatus(String roomId) => '${socialAudioBase}rooms/$roomId/status';
  static String socialAudioRoomSpeakers(String roomId) => '${socialAudioBase}rooms/$roomId/speakers';
  static String socialAudioRoomModerate(String roomId) => '${socialAudioBase}rooms/$roomId/moderate';
  static const String socialAudioRoomsUser = '${socialAudioBase}rooms/user';
  static const String socialAudioRoomsScheduled = '${socialAudioBase}rooms/scheduled';
  static String socialAudioRoomParticipants(String roomId) => '${socialAudioBase}rooms/$roomId/participants';
  static String socialAudioRoomHistory(String roomId) => '${socialAudioBase}rooms/$roomId/history';
  static String socialAudioRoomLearningSummary(String roomId) => '${socialAudioBase}rooms/$roomId/learning-summary';
  static const String socialAudioFollowing = '${socialAudioBase}following';
  static String socialAudioFollowUser(String userId) => '${socialAudioBase}following/$userId';
  static String socialAudioUnfollowUser(String userId) => '${socialAudioBase}following/$userId';
  static const String socialAudioFollowers = '${socialAudioBase}followers';
  static const String socialAudioFollowingList = '${socialAudioBase}following/list';
  static const String socialAudioLearningTrack = '${socialAudioBase}learning/track';
  static const String socialAudioLearningWords = '${socialAudioBase}learning/words';
  static const String socialAudioLearningPronunciation = '${socialAudioBase}learning/pronunciation';
  static const String socialAudioLearningStats = '${socialAudioBase}learning/stats';
}
