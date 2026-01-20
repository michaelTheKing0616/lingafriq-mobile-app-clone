import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/adaptive_learning_summary.dart';
import '../providers/gamification_provider.dart';
import '../providers/hearts_provider.dart';
import '../providers/user_provider.dart';
import '../services/vocabulary/vocabulary_service.dart';

/// Provides a high-level adaptive summary for powering the dashboard and recommendations.
///
/// This implementation is intentionally **local-first**:
/// - It works offline.
/// - It derives signals from gamification, hearts, and SRS/vocabulary.
/// - Backend/ML services can enrich this later, but the UI stays functional.
final adaptiveLearningProvider = Provider<AdaptiveLearningSummary>((ref) {
  // Trigger rebuilds when gamification or hearts change.
  ref.watch(gamificationProvider);
  final heartsState = ref.watch(heartsProvider);

  final gamification = ref.read(gamificationProvider.notifier).gamification;
  final user = ref.read(userProvider);
  final vocab = ref.read(vocabularyServiceProvider);

  final language = gamification.currentLanguage ?? user?.learningLanguage;
  final due = vocab.getDueForReview(language: language).length;
  final total = vocab.allWords.length;

  final xp = gamification.xp;
  final cefr = _estimateCefrFromXp(xp);
  final cefrScore = _estimateCefrScoreFromXp(xp);

  final recs = _buildRecommendations(
    dueSrsItems: due,
    totalSrsItems: total,
    heartsRemaining: heartsState.currentHearts,
    dailyStreak: gamification.dailyStreak,
  );

  return AdaptiveLearningSummary(
    cefrLevel: cefr,
    cefrScore: cefrScore,
    dueSrsItems: due,
    totalSrsItems: total,
    dailyStreak: gamification.dailyStreak,
    totalXp: xp,
    heartsRemaining: heartsState.currentHearts,
    recommendations: recs,
  );
});

String _estimateCefrFromXp(int xp) {
  if (xp < 500) return 'A0';
  if (xp < 1500) return 'A1';
  if (xp < 3000) return 'A2';
  if (xp < 6000) return 'B1';
  if (xp < 10000) return 'B2';
  if (xp < 15000) return 'C1';
  return 'C2';
}

double _estimateCefrScoreFromXp(int xp) {
  // Map XP to a 0–100 score for UI progress bars.
  // This is heuristic but consistent and monotonic.
  const bands = <int>[0, 500, 1500, 3000, 6000, 10000, 15000, 25000];
  int bandIndex = 0;
  while (bandIndex < bands.length - 1 && xp >= bands[bandIndex + 1]) {
    bandIndex++;
  }
  final low = bands[bandIndex];
  final high = bands[(bandIndex + 1).clamp(0, bands.length - 1)];
  if (high == low) return 100.0;
  final t = ((xp - low) / (high - low)).clamp(0.0, 1.0);
  return ((bandIndex / (bands.length - 2)) * 100.0 + t * (100.0 / (bands.length - 2)))
      .clamp(0.0, 100.0);
}

List<AdaptiveRecommendation> _buildRecommendations({
  required int dueSrsItems,
  required int totalSrsItems,
  required int heartsRemaining,
  required int dailyStreak,
}) {
  final recs = <AdaptiveRecommendation>[];

  if (dueSrsItems > 0) {
    recs.add(const AdaptiveRecommendation(
      id: 'review_due_srs',
      title: 'Review due words',
      description: 'You have words ready for review. A quick 5–10 minute review boosts retention.',
      actionType: AdaptiveActionType.reviewWords,
    ));
  }

  if (heartsRemaining <= 1) {
    recs.add(const AdaptiveRecommendation(
      id: 'hearts_low',
      title: 'Switch to low-stress practice',
      description: 'Try a short Polie tutor session or reading to keep momentum while hearts recharge.',
      actionType: AdaptiveActionType.continuePolieTutor,
    ));
  }

  if (dailyStreak == 0) {
    recs.add(const AdaptiveRecommendation(
      id: 'start_streak',
      title: 'Start your streak today',
      description: 'A tiny daily session beats a long session once a week. Do 3 minutes now.',
      actionType: AdaptiveActionType.completeLesson,
    ));
  }

  if (recs.isEmpty) {
    recs.add(const AdaptiveRecommendation(
      id: 'play_game',
      title: 'Play a quick game',
      description: 'Keep it fun—short games reinforce vocabulary and listening skills.',
      actionType: AdaptiveActionType.playGame,
    ));
  }

  // Always keep a social hook.
  recs.add(const AdaptiveRecommendation(
    id: 'join_chat',
    title: 'Join a chat',
    description: 'Practice with others to improve confidence and consistency.',
    actionType: AdaptiveActionType.joinChat,
  ));

  // If SRS is empty, encourage content discovery.
  if (totalSrsItems == 0) {
    recs.add(const AdaptiveRecommendation(
      id: 'read_magazine',
      title: 'Read a culture article',
      description: 'Reading builds intuition—pick one article and save 3 new words.',
      actionType: AdaptiveActionType.readMagazine,
    ));
  }

  return recs;
}

