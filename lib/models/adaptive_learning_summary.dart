/// High-level snapshot of a learner's current state for powering
/// adaptive home/dashboard experiences.
class AdaptiveLearningSummary {
  final String cefrLevel;
  final double cefrScore; // 0-100
  final int dueSrsItems;
  final int totalSrsItems;
  final int dailyStreak;
  final int totalXp;
  final int heartsRemaining;
  final List<AdaptiveRecommendation> recommendations;

  const AdaptiveLearningSummary({
    required this.cefrLevel,
    required this.cefrScore,
    required this.dueSrsItems,
    required this.totalSrsItems,
    required this.dailyStreak,
    required this.totalXp,
    required this.heartsRemaining,
    required this.recommendations,
  });
}

class AdaptiveRecommendation {
  final String id;
  final String title;
  final String description;
  final AdaptiveActionType actionType;

  const AdaptiveRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.actionType,
  });
}

enum AdaptiveActionType {
  reviewWords,
  continuePolieTutor,
  playGame,
  completeLesson,
  joinChat,
  readMagazine,
}


