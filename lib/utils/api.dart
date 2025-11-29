class Api {
  // static const String baseurl = "http://34.121.156.251:8000/";
  // static const String baseurl = "http://34.67.162.25:8000/";
  // static const String baseurl = "http://64.227.113.179:8000/";
  static const String baseurl = "http://admin.lingafriq.com/";
  static const String register = "accounts/auth/users/";
  static const String login = "accounts/auth/jwt/create/";
  static const String userInfo = "accounts/auth/users/me/";
  static const String registerFcmDevice = "devices/";
  static String unRegisterFcmDevice(String token) => "devices/$token/";
  static String userProfile(int id) => "account/my_user_profile/?id=$id";

  static String updateProfile(int id) => "accounts/auth/users/$id/";
  static const String accountUpdate = "account/update/";
  // static String deleteUser(int id) => "accounts/auth/users/$id/";
  static String deleteUser(int id) => "/account/user_delete/$id";
  static const String resetPassword = "accounts/auth/users/reset_password/";
  static const String changePassword = "accounts/auth/users/set_password/";
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

  // Progress Tracking & Daily Goals Start
  static const String dailyGoals = "progress/daily_goals/";
  static const String updateDailyGoal = "progress/daily_goals/update/";
  static const String progressMetrics = "progress/metrics/";
  static const String updateProgressMetrics = "progress/metrics/update/";
  static const String achievements = "progress/achievements/";
  static const String unlockAchievement = "progress/achievements/unlock/";
  // Progress Tracking & Daily Goals End

  // Global Rankings & Statistics Start
  static const String globalStats = "global/stats/";
  static const String globalLeaderboard = "global/leaderboard/";
  static const String topLanguages = "global/top_languages/";
  // Global Rankings & Statistics End

  // Culture Content Start
  static const String cultureContent = "culture/content/";
  static String cultureContentByType(String type) => "culture/content/?type=$type";
  static String cultureContentById(String id) => "culture/content/$id/";
  // Culture Content End

  // Chat & Social Start
  static const String chatRooms = "chat/rooms/";
  static String chatMessages(String room) => "chat/rooms/$room/messages/";
  static const String onlineUsers = "chat/online_users/";
  // Chat & Social End

  // Loading Screen Start
  static const String loadingScreen = "api/loading-screen";
  static String loadingScreenByCountry(String country) => "api/loading-screen/country/$country";
  static String loadingScreenByLanguage(String language) => "api/loading-screen/language/$language";
  // Loading Screen End
}
