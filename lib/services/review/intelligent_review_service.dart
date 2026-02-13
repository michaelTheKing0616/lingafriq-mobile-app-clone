// Intelligent Review Service
// Determines optimal timing for review prompts based on user engagement
// Inspired by best practices from Duolingo, Babbel, and other top apps

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class IntelligentReviewService {
  static const String _keyLastReviewPrompt = 'last_review_prompt_date';
  static const String _keyReviewDeclined = 'review_declined';
  static const String _keyReviewCompleted = 'review_completed';
  static const String _keySessionCount = 'review_session_count';
  static const String _keyStreakDays = 'review_streak_days';
  static const String _keyLessonsCompleted = 'review_lessons_completed';
  static const String _keyGamesPlayed = 'review_games_played';
  static const String _keyLastDeclineReason = 'review_last_decline_reason';

  /// Check if review prompt should be shown
  static Future<bool> shouldShowReviewPrompt({
    required int sessionCount,
    required int streakDays,
    required int lessonsCompleted,
    required int gamesPlayed,
    required DateTime lastActiveDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Never show if already completed
      if (prefs.getBool(_keyReviewCompleted) == true) {
        return false;
      }

      // Check if declined recently (wait 30 days)
      if (prefs.getBool(_keyReviewDeclined) == true) {
        final lastPrompt = prefs.getString(_keyLastReviewPrompt);
        if (lastPrompt != null) {
          final lastPromptDate = DateTime.parse(lastPrompt);
          if (DateTime.now().difference(lastPromptDate).inDays < 30) {
            return false;
          }
        }
      }

      // Check last prompt date (don't show too frequently)
      final lastPrompt = prefs.getString(_keyLastReviewPrompt);
      if (lastPrompt != null) {
        final lastPromptDate = DateTime.parse(lastPrompt);
        if (DateTime.now().difference(lastPromptDate).inDays < 7) {
          return false;
        }
      }

      // Intelligent triggers (based on engagement milestones)
      final triggers = [
        // Milestone 1: Active user (5+ sessions, 3+ day streak)
        sessionCount >= 5 && streakDays >= 3,
        
        // Milestone 2: Engaged learner (10+ lessons completed)
        lessonsCompleted >= 10,
        
        // Milestone 3: Game enthusiast (5+ games played)
        gamesPlayed >= 5,
        
        // Milestone 4: Dedicated user (7+ day streak)
        streakDays >= 7,
        
        // Milestone 5: Power user (20+ sessions, 10+ lessons)
        sessionCount >= 20 && lessonsCompleted >= 10,
        
        // Milestone 6: Consistent user (active in last 3 days, 10+ sessions)
        DateTime.now().difference(lastActiveDate).inDays <= 3 && sessionCount >= 10,
      ];

      // Show if any trigger is met
      return triggers.any((trigger) => trigger);
    } catch (e) {
      debugPrint('Error checking review prompt: $e');
      return false;
    }
  }

  /// Record review prompt shown
  static Future<void> recordReviewPromptShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastReviewPrompt, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error recording review prompt: $e');
    }
  }

  /// Record review declined
  static Future<void> recordReviewDeclined({String? reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyReviewDeclined, true);
      if (reason != null) {
        await prefs.setString(_keyLastDeclineReason, reason);
      }
    } catch (e) {
      debugPrint('Error recording review decline: $e');
    }
  }

  /// Record review completed
  static Future<void> recordReviewCompleted({required int rating}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyReviewCompleted, true);
      await prefs.setInt('review_rating', rating);
    } catch (e) {
      debugPrint('Error recording review completion: $e');
    }
  }

  /// Get review statistics
  static Future<Map<String, dynamic>> getReviewStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'sessionCount': prefs.getInt(_keySessionCount) ?? 0,
        'streakDays': prefs.getInt(_keyStreakDays) ?? 0,
        'lessonsCompleted': prefs.getInt(_keyLessonsCompleted) ?? 0,
        'gamesPlayed': prefs.getInt(_keyGamesPlayed) ?? 0,
        'lastReviewPrompt': prefs.getString(_keyLastReviewPrompt),
        'reviewCompleted': prefs.getBool(_keyReviewCompleted) ?? false,
        'reviewDeclined': prefs.getBool(_keyReviewDeclined) ?? false,
      };
    } catch (e) {
      return {};
    }
  }

  /// Update engagement metrics
  static Future<void> updateEngagementMetrics({
    int? sessionCount,
    int? streakDays,
    int? lessonsCompleted,
    int? gamesPlayed,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (sessionCount != null) {
        await prefs.setInt(_keySessionCount, sessionCount);
      }
      if (streakDays != null) {
        await prefs.setInt(_keyStreakDays, streakDays);
      }
      if (lessonsCompleted != null) {
        await prefs.setInt(_keyLessonsCompleted, lessonsCompleted);
      }
      if (gamesPlayed != null) {
        await prefs.setInt(_keyGamesPlayed, gamesPlayed);
      }
    } catch (e) {
      debugPrint('Error updating engagement metrics: $e');
    }
  }
}

