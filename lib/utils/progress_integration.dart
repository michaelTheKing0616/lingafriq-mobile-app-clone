import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/providers/progress_tracking_provider.dart';
import 'package:lingafriq/providers/achievements_provider.dart';

/// Helper class to integrate progress tracking into activities
class ProgressIntegration {
  /// Call this when a lesson is completed
  static Future<void> onLessonCompleted(WidgetRef ref, {String? language}) async {
    // Update daily goals
    ref.read(dailyGoalsProvider.notifier).updateGoalProgress('lessons', 1);
    
    // Track progress (estimate 5 words learned per lesson)
    ref.read(progressTrackingProvider.notifier).recordWordsLearned(5, language: language);
    ref.read(progressTrackingProvider.notifier).recordActivityTime('lessons', 5.0); // 5 minutes
    
    // Check achievements
    final metrics = ref.read(progressTrackingProvider.notifier).metrics;
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements(
      wordsLearned: metrics.wordsLearned,
      lessonsCompleted: (metrics.timeByActivity['lessons'] ?? 0.0).toInt(),
    );
  }

  /// Call this when a quiz is completed
  static Future<void> onQuizCompleted(WidgetRef ref, {int? wordsLearned}) async {
    // Update daily goals
    ref.read(dailyGoalsProvider.notifier).updateGoalProgress('quizzes', 1);
    
    // Track progress
    ref.read(progressTrackingProvider.notifier).recordWordsLearned(wordsLearned ?? 3);
    ref.read(progressTrackingProvider.notifier).recordActivityTime('quizzes', 3.0); // 3 minutes
    
    // Check achievements
    final metrics = ref.read(progressTrackingProvider.notifier).metrics;
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements(
      wordsLearned: metrics.wordsLearned,
      quizzesCompleted: (metrics.timeByActivity['quizzes'] ?? 0.0).toInt(),
    );
  }

  /// Call this when a game is completed
  static Future<void> onGameCompleted(WidgetRef ref, {int? wordsLearned}) async {
    // Update daily goals
    ref.read(dailyGoalsProvider.notifier).updateGoalProgress('games', 1);
    
    // Track progress
    ref.read(progressTrackingProvider.notifier).recordWordsLearned(wordsLearned ?? 2);
    ref.read(progressTrackingProvider.notifier).recordActivityTime('games', 2.0); // 2 minutes
    
    // Check achievements
    final metrics = ref.read(progressTrackingProvider.notifier).metrics;
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements(
      wordsLearned: metrics.wordsLearned,
    );
  }

  /// Call this when chatting with Polie (AI chat)
  static Future<void> onChatActivity(WidgetRef ref, {double minutes = 0.0, int? wordsLearned}) async {
    // Update daily goals (chat minutes)
    if (minutes > 0) {
      ref.read(dailyGoalsProvider.notifier).updateGoalProgress('chat_minutes', minutes.toInt());
    }
    
    // Track progress
    if (wordsLearned != null && wordsLearned > 0) {
      ref.read(progressTrackingProvider.notifier).recordWordsLearned(wordsLearned);
    }
    ref.read(progressTrackingProvider.notifier).recordActivityTime('chat', minutes);
    
    // Check achievements
    final metrics = ref.read(progressTrackingProvider.notifier).metrics;
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements(
      wordsLearned: metrics.wordsLearned,
    );
  }

  /// Call this when listening activity occurs
  static Future<void> onListeningActivity(WidgetRef ref, {double minutes = 0.0}) async {
    ref.read(progressTrackingProvider.notifier).recordListeningTime(minutes);
  }

  /// Call this when speaking activity occurs
  static Future<void> onSpeakingActivity(WidgetRef ref, {double minutes = 0.0}) async {
    ref.read(progressTrackingProvider.notifier).recordSpeakingTime(minutes);
  }

  /// Call this when reading activity occurs
  static Future<void> onReadingActivity(WidgetRef ref, {int wordsRead = 0}) async {
    ref.read(progressTrackingProvider.notifier).recordReadingWords(wordsRead);
  }

  /// Call this when writing activity occurs
  static Future<void> onWritingActivity(WidgetRef ref, {int wordsWritten = 0}) async {
    ref.read(progressTrackingProvider.notifier).recordWrittenWords(wordsWritten);
  }

  /// Check streak-based achievements
  static Future<void> checkStreakAchievements(WidgetRef ref) async {
    final streak = ref.read(dailyGoalsProvider.notifier).currentStreak;
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements(
      streak: streak,
    );
  }

  /// Check time-based achievements
  static Future<void> checkTimeAchievements(WidgetRef ref) async {
    final metrics = ref.read(progressTrackingProvider.notifier).metrics;
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements(
      hoursSpent: metrics.timeSpentHours,
    );
  }
}

