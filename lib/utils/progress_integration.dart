import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/providers/progress_tracking_provider.dart';
import 'package:lingafriq/providers/achievements_provider.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/utils/gamification_integration.dart';

/// Helper class to integrate progress tracking into activities
class ProgressIntegration {
  /// Call this when a lesson is completed
  static Future<void> onLessonCompleted(WidgetRef ref, {String? language, int? pointsEarned, bool perfect = false}) async {
    debugPrint('[ProgressIntegration] Lesson completed');
    
    // Calculate XP
    const baseXP = 25;
    final perfectBonus = perfect ? 15 : 0;
    final xpEarned = baseXP + perfectBonus + (pointsEarned ?? 0);
    
    // Use new gamification integration (handles everything: XP, challenges, milestones, leagues, backend sync)
    await GamificationIntegration.of(ref).onLessonComplete(
      xpEarned: xpEarned,
      wordsLearned: 5, // estimate 5 words per lesson
      timeSpentMinutes: 5, // estimate 5 minutes
    );
    
    // Update daily goals (local)
    ref.read(dailyGoalsProvider.notifier).updateGoalProgress('lessons', 1);
    
    // Sync with backend
    try {
      await ref.read(apiProvider.notifier).updateDailyGoal('lessons', 1);
    } catch (e) {
      // Silently fail - local state is updated
    }
    
    // Track progress (estimate 5 words learned per lesson)
    ref.read(progressTrackingProvider.notifier).recordWordsLearned(5, language: language);
    ref.read(progressTrackingProvider.notifier).recordActivityTime('lessons', 5.0); // 5 minutes
    
    // Update points if earned
    if (pointsEarned != null && pointsEarned > 0) {
      try {
        await ref.read(apiProvider.notifier).updateUserPoints(pointsEarned);
      } catch (e) {
        // Silently fail
      }
    }
    
    // Sync progress metrics with backend
    try {
      final metrics = ref.read(progressTrackingProvider.notifier).metrics;
      await ref.read(apiProvider.notifier).updateProgressMetrics(metrics.toMap());
    } catch (e) {
      // Silently fail - local state is updated
    }
    
    // Check achievements
    final metrics = ref.read(progressTrackingProvider.notifier).metrics;
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements(
      wordsLearned: metrics.wordsLearned,
      lessonsCompleted: (metrics.timeByActivity['lessons'] ?? 0.0).toInt(),
    );
  }

  /// Call this when a quiz is completed
  static Future<void> onQuizCompleted(WidgetRef ref, {int? wordsLearned, int? pointsEarned, bool perfect = false}) async {
    debugPrint('[ProgressIntegration] Quiz completed');
    
    // Calculate XP
    const baseXP = 20;
    final perfectBonus = perfect ? 25 : 0;
    final xpEarned = baseXP + perfectBonus + (pointsEarned ?? 0);
    
    // Use new gamification integration (handles everything: XP, challenges, milestones, leagues, backend sync)
    await GamificationIntegration.of(ref).onQuizComplete(
      score: perfect ? 100 : 80, // estimate
      xpEarned: xpEarned,
      isPerfect: perfect,
      wordsLearned: wordsLearned ?? 3,
    );
    
    // Update daily goals (local)
    ref.read(dailyGoalsProvider.notifier).updateGoalProgress('quizzes', 1);
    
    // Sync with backend
    try {
      await ref.read(apiProvider.notifier).updateDailyGoal('quizzes', 1);
    } catch (e) {
      // Silently fail
    }
    
    // Track progress
    ref.read(progressTrackingProvider.notifier).recordWordsLearned(wordsLearned ?? 3);
    ref.read(progressTrackingProvider.notifier).recordActivityTime('quizzes', 3.0); // 3 minutes
    
    // Update points if earned
    if (pointsEarned != null && pointsEarned > 0) {
      try {
        await ref.read(apiProvider.notifier).updateUserPoints(pointsEarned);
      } catch (e) {
        // Silently fail
      }
    }
    
    // Sync with backend
    try {
      final metrics = ref.read(progressTrackingProvider.notifier).metrics;
      await ref.read(apiProvider.notifier).updateProgressMetrics(metrics.toMap());
    } catch (e) {
      // Silently fail
    }
    
    // Check achievements
    final metrics = ref.read(progressTrackingProvider.notifier).metrics;
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements(
      wordsLearned: metrics.wordsLearned,
      quizzesCompleted: (metrics.timeByActivity['quizzes'] ?? 0.0).toInt(),
    );
  }

  /// Call this when a game is completed
  static Future<void> onGameCompleted(Ref ref, {int? wordsLearned, int? pointsEarned, bool perfect = false}) async {
    // Update daily goals (local)
    ref.read(dailyGoalsProvider.notifier).updateGoalProgress('games', 1);
    
    // Sync with backend
    try {
      await ref.read(apiProvider.notifier).updateDailyGoal('games', 1);
    } catch (e) {
      // Silently fail
    }
    
    // Track progress
    ref.read(progressTrackingProvider.notifier).recordWordsLearned(wordsLearned ?? 2);
    ref.read(progressTrackingProvider.notifier).recordActivityTime('games', 2.0); // 2 minutes
    
    // Award XP for gamification
    try {
      await ref.read(gamificationProvider.notifier).awardXP('game_complete');
    } catch (e) {
      // Silently fail
    }
    
    // Update points if earned
    if (pointsEarned != null && pointsEarned > 0) {
      try {
        await ref.read(apiProvider.notifier).updateUserPoints(pointsEarned);
      } catch (e) {
        // Silently fail
      }
    }
    
    // Sync with backend
    try {
      final metrics = ref.read(progressTrackingProvider.notifier).metrics;
      await ref.read(apiProvider.notifier).updateProgressMetrics(metrics.toMap());
    } catch (e) {
      // Silently fail
    }
    
    // Check achievements
    final metrics = ref.read(progressTrackingProvider.notifier).metrics;
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements(
      wordsLearned: metrics.wordsLearned,
    );
  }

  /// Call this when chatting with Polie (AI chat)
  static Future<void> onChatActivity(WidgetRef ref, {double minutes = 0.0, int? wordsLearned, double? pronunciationScore}) async {
    // Update daily goals (chat minutes)
    if (minutes > 0) {
      ref.read(dailyGoalsProvider.notifier).updateGoalProgress('chat_minutes', minutes.toInt());
    }
    
    // Track progress
    if (wordsLearned != null && wordsLearned > 0) {
      ref.read(progressTrackingProvider.notifier).recordWordsLearned(wordsLearned);
    }
    ref.read(progressTrackingProvider.notifier).recordActivityTime('chat', minutes);
    
    // Award XP for gamification
    try {
      if (minutes >= 5.0) {
        await ref.read(gamificationProvider.notifier).awardXP('ai_chat_5min');
      }
      
      // Award XP for perfect pronunciation (95%+)
      if (pronunciationScore != null && pronunciationScore >= 0.95) {
        await ref.read(gamificationProvider.notifier).awardXP('pronunciation_95plus');
      }
    } catch (e) {
      // Silently fail
    }
    
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

  /// Call this when a story/chapter is completed
  /// XP is only awarded AFTER the user has fully consumed the content (read story, completed lessons)
  static Future<void> onStoryCompleted(
    Ref ref, {
    required String chapterId,
    required String chapterTitle,
    int? wordsLearned,
    int? xpReward,
    bool allLessonsCompleted = false,
  }) async {
    // Only award XP if all lessons are completed (content fully consumed)
    if (!allLessonsCompleted) {
      debugPrint('Story not fully completed - lessons remaining. XP not awarded.');
      return;
    }

    // Update daily goals (local)
    ref.read(dailyGoalsProvider.notifier).updateGoalProgress('stories', 1);

    // Sync with backend
    try {
      await ref.read(apiProvider.notifier).updateDailyGoal('stories', 1);
    } catch (e) {
      // Silently fail
    }

    // Track progress
    ref.read(progressTrackingProvider.notifier).recordWordsLearned(wordsLearned ?? 10);
    ref.read(progressTrackingProvider.notifier).recordActivityTime('stories', 15.0); // 15 minutes for story

    // Award XP for gamification (server-authoritative)
    try {
      await ref.read(gamificationProvider.notifier).awardXP(
        'complete_quest_chapter',
        multiplier: (xpReward ?? 100) / 50.0,
        sourceId: chapterId, // Unique source ID to prevent duplicate XP
      );
    } catch (e) {
      debugPrint('Error awarding story XP: $e');
    }

    // Update points if earned (legacy support)
    if (xpReward != null && xpReward > 0) {
      try {
        await ref.read(apiProvider.notifier).updateUserPoints(xpReward);
      } catch (e) {
        // Silently fail
      }
    }

    // Sync with backend
    try {
      final metrics = ref.read(progressTrackingProvider.notifier).metrics;
      await ref.read(apiProvider.notifier).updateProgressMetrics(metrics.toMap());
    } catch (e) {
      // Silently fail
    }

    // Check achievements
    final metrics = ref.read(progressTrackingProvider.notifier).metrics;
    ref.read(achievementsProvider.notifier).checkAndUnlockAchievements(
      wordsLearned: metrics.wordsLearned,
    );
  }

  /// Call this when a lesson within a story is completed
  /// This does NOT award XP - XP is only awarded when the entire story/chapter is completed
  static Future<void> onStoryLessonCompleted(Ref ref, {String? language}) async {
    // Track progress but don't award XP yet
    ref.read(progressTrackingProvider.notifier).recordWordsLearned(3, language: language);
    ref.read(progressTrackingProvider.notifier).recordActivityTime('stories', 3.0); // 3 minutes per lesson

    // Sync with backend
    try {
      final metrics = ref.read(progressTrackingProvider.notifier).metrics;
      await ref.read(apiProvider.notifier).updateProgressMetrics(metrics.toMap());
    } catch (e) {
      // Silently fail
    }
  }
}

