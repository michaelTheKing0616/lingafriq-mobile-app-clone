import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/adaptive_learning_summary.dart';
import '../providers/ai_chat_provider_groq.dart';
import '../providers/gamification_provider.dart';

/// Computes an adaptive learning summary from existing providers:
/// - Polie SRS & CEFR info
/// - Gamification (XP, streak, hearts)
///
/// This is intentionally lightweight and synchronous so it can be
/// consumed easily from home/dashboard widgets.
final adaptiveLearningProvider = Provider<AdaptiveLearningSummary>((ref) {
  final polie = ref.read(groqChatProvider.notifier);
  final gamification = ref.read(gamificationProvider.notifier).gamification;

  final cefrInfo = polie.cefrInfo;
  final due = polie.dueSRSItems;
  final total = polie.totalSRSItems;

  final streak = gamification.dailyStreak;
  final xp = gamification.xp;
  final hearts = gamification.hearts;

  final recommendations = <AdaptiveRecommendation>[];

  if (due > 0) {
    recommendations.add(
      const AdaptiveRecommendation(
        id: 'review_words',
        title: 'Review words with Polie',
        description: 'You have words ready for spaced repetition review. Strengthen them now for faster progress.',
        actionType: AdaptiveActionType.reviewWords,
      ),
    );
  }

  // If CEFR score is low, recommend tutor mode
  if (cefrInfo.score < 40) {
    recommendations.add(
      const AdaptiveRecommendation(
        id: 'tutor_mode',
        title: 'Guided session with Polie',
        description: 'Let Polie walk you through short, targeted exercises to build core skills.',
        actionType: AdaptiveActionType.continuePolieTutor,
      ),
    );
  }

  // If streak is active, keep user on track
  if (streak > 0) {
    recommendations.add(
      AdaptiveRecommendation(
        id: 'maintain_streak',
        title: 'Keep your ${streak}-day streak alive',
        description: 'Complete a quick lesson or game to protect your streak and earn bonus XP.',
        actionType: AdaptiveActionType.completeLesson,
      ),
    );
  }

  // Always offer a game suggestion as a fun entry point
  recommendations.add(
    const AdaptiveRecommendation(
      id: 'play_game',
      title: 'Play a cultural game',
      description: 'Jump into a short, fun game to reinforce what you\'ve learned with African culture at the center.',
      actionType: AdaptiveActionType.playGame,
    ),
  );

  return AdaptiveLearningSummary(
    cefrLevel: cefrInfo.level,
    cefrScore: cefrInfo.score,
    dueSrsItems: due,
    totalSrsItems: total,
    dailyStreak: streak,
    totalXp: xp,
    heartsRemaining: hearts,
    recommendations: recommendations,
  );
});


