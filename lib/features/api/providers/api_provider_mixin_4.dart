import 'package:lingafriq/features/api/providers/api_provider_helpers.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, visibleForTesting;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/history/models/history_response.dart';
import 'package:lingafriq/history/models/section_history_model.dart';
import 'package:lingafriq/history_quiz/models/history_quiz_lesson_model.dart';
import 'package:lingafriq/mannerisms/models/mannerism_response.dart';
import 'package:lingafriq/mannerisms/models/mannerism_tutorial_model.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/models/profiles_response.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/providers/firebase_messaging_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/random_quiz/models/random_quiz_lesson_model.dart';
import 'package:lingafriq/services/auth_token_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/history_quiz/models/history_quiz_response.dart';
import 'package:lingafriq/language_quiz/models/language_quiz_lesson_model.dart';
import 'package:lingafriq/language_quiz/models/language_quiz_response.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/lessons/models/section_lesson_model.dart';
import 'package:lingafriq/models/user.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/utils/structured_logger.dart';

import 'package:lingafriq/features/api/providers/api_provider_mixin_3.dart';

mixin ApiProviderMixin4 on ApiProviderMixin3 {
  Future<Map<String, dynamic>> getLoadingScreenContent({
    String? country,
    String? language,
    String? lastContentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (country != null) queryParams['country'] = country;
      if (language != null) queryParams['language'] = language;
      if (lastContentId != null) queryParams['lastContentId'] = lastContentId;

      final res = await ref.read(client).get(
        ApiContract.url(ApiContract.ai.loadingScreenContent),
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (res.statusCode != 200) throw res.data;
      return res.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Search users by handle (global_id)
  Future<List<Map<String, dynamic>>> searchUsersByHandle(String handle) async {
    try {
      final res = await ref.read(client).get(
        Api.searchUsersByHandle(handle),
      );
      if (res.statusCode != 200) throw res.data;
      final data = res.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('result')) {
        final result = data['result'];
        if (result is List) {
          return List<Map<String, dynamic>>.from(result);
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Award XP to a user (server-authoritative)
  /// Returns true if successful, false otherwise
  Future<bool> awardXP({
    required String userId,
    required String source,
    required String sourceId,
    required int amount,
    double difficultyMultiplier = 1.0,
  }) async {
    try {
      final res = await ref.read(client).post(
        Api.xpAward,
        data: {
          'source': source,
          'sourceId': sourceId,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error awarding XP', error: e);
      return false;
    }
  }

  /// Get user XP and level information
  /// Returns Map with totalXP, level, levelTitle, or null on error
  Future<Map<String, dynamic>?> getUserXP(String userId) async {
    try {
      final res = await ref.read(client).get('${Api.xpTotal}?user_id=$userId');
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return null;
    } catch (e) {
      logger.error('Error getting user XP', error: e);
      return null;
    }
  }

  /// Record learner activity for analytics and progress tracking
  Future<bool> recordLearnerActivity({
    required String userId,
    required String language,
    String? activityType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.sync.learnerActivity),
        data: {
          'user_id': userId,
          'language': language,
          if (activityType != null) 'activity_type': activityType,
          if (metadata != null) 'metadata': metadata,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error recording learner activity', error: e);
      return false;
    }
  }

  /// Get experiments configuration (feature flags and variants)
  Future<Map<String, dynamic>> getExperimentsConfig() async {
    try {
      final res = await ref.read(client).get(
        ApiContract.url(ApiContract.sync.experimentsConfig),
      );
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return {'flags': {}, 'variants': {}};
    } catch (e) {
      logger.error('Error getting experiments config', error: e);
      // Return default empty config on error
      return {'flags': {}, 'variants': {}};
    }
  }

  /// Get daily goals for the current user
  Future<Map<String, dynamic>> getDailyGoals() async {
    try {
      final res = await ref.read(client).get(Api.dailyChallenges);
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return {};
    } catch (e) {
      logger.error('Error getting daily goals', error: e);
      return {};
    }
  }

  /// Sync gamification data with backend
  Future<bool> syncGamification(Map<String, dynamic> data) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.gamification.sync),
        data: data,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error syncing gamification', error: e);
      return false;
    }
  }

  /// Save AI chat history
  Future<bool> saveAiChatHistory(Map<String, dynamic> chatData) async {
    try {
      // Canonical backend route: POST /api/ai/chat/history/sync/
      //
      // Backward compatible input: older callers may include `language_code`.
      // Sync controller expects `{ mode, messages, timestamp }`.
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.ai.chatHistorySync),
        data: {
          'mode': chatData['mode'],
          'messages': chatData['messages'],
          if (chatData['languageCode'] != null) 'languageCode': chatData['languageCode'],
          if (chatData['language_code'] != null) 'language_code': chatData['language_code'],
          if (chatData['timestamp'] != null) 'timestamp': chatData['timestamp'],
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error saving AI chat history', error: e);
      return false;
    }
  }

  /// Get AI chat history from backend
  /// Returns list of message maps, or null if not found/error
  Future<List<Map<String, dynamic>>?> getAiChatHistory({
    required String mode,
    required String languageCode,
  }) async {
    try {
      // Canonical backend route: GET /api/ai/chat/history/:mode
      final res = await ref.read(client).get(
        ApiContract.url(ApiContract.ai.chatHistory(mode)),
        queryParameters: {
          'languageCode': languageCode,
        },
      );

      if (res.statusCode != 200 || res.data == null) return null;

      // Expected: { success: true, data: { messages: [...] } }
      final root = res.data;
      if (root is Map) {
        final data = root['data'];
        if (data is Map && data['messages'] is List) {
          return (data['messages'] as List).map((m) => Map<String, dynamic>.from(m as Map)).toList();
        }
        // Backward-compatible fallbacks
        if (root['messages'] is List) {
          return (root['messages'] as List).map((m) => Map<String, dynamic>.from(m as Map)).toList();
        }
      }

      return null;
    } catch (e) {
      logger.error('Error getting AI chat history', error: e);
      return null;
    }
  }

  /// Get user gamification data from backend
  /// Returns gamification data map, or null if not found/error
  Future<Map<String, dynamic>?> getGamification(String userId) async {
    try {
      final res = await ref.read(client).get(
        Api.userGamification(userId),
      );
      
      if (res.statusCode == 200 && res.data != null) {
        if (res.data is Map) {
          return res.data as Map<String, dynamic>;
        } else if (res.data is List && (res.data as List).isNotEmpty) {
          // Backend might return a list with single item
          return (res.data as List).first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      logger.error('Error getting gamification', error: e);
      return null;
    }
  }

  /// Update daily goal progress
  Future<bool> updateDailyGoal(String goalId, Map<String, dynamic> progress) async {
    try {
      final res = await ref.read(client).patch(
        ApiContract.url(ApiContract.gamification.challenges(goalId)),
        data: progress,
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      logger.error('Error updating daily goal', error: e);
      return false;
    }
  }

  /// Update user points (legacy method - prefer awardXP)
  Future<bool> updateUserPoints(int points) async {
    try {
      final res = await ref.read(client).post(
        Api.currencyAward,
        data: {'amount': points},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error updating user points', error: e);
      return false;
    }
  }

  /// Get progress metrics for the current user
  Future<Map<String, dynamic>> getProgressMetrics() async {
    try {
      final res = await ref.read(client).get(
        ApiContract.url(ApiContract.gamification.progress),
      );
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return {};
    } catch (e) {
      logger.error('Error getting progress metrics', error: e);
      return {};
    }
  }

  /// Update progress metrics
  Future<bool> updateProgressMetrics(Map<String, dynamic> metrics) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.gamification.progress),
        data: metrics,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error updating progress metrics', error: e);
      return false;
    }
  }

  /// Get all achievements
  Future<List<Map<String, dynamic>>> getAchievements() async {
    try {
      final res = await ref.read(client).get(Api.badges);
      if (res.statusCode == 200) {
        if (res.data is List) {
          return List<Map<String, dynamic>>.from(res.data);
        } else if (res.data is Map && res.data['results'] is List) {
          return List<Map<String, dynamic>>.from(res.data['results']);
        }
      }
      return [];
    } catch (e) {
      logger.error('Error getting achievements', error: e);
      return [];
    }
  }

  /// Unlock an achievement
  Future<bool> unlockAchievement(String achievementId) async {
    try {
      final res = await ref.read(client).post(
        '${Api.badges}$achievementId/unlock',
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error unlocking achievement', error: e);
      return false;
    }
  }

  /// Update XP (legacy method - prefer awardXP)
  Future<bool> updateXP(int xp) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return false;
      return await awardXP(
        userId: user.id.toString(),
        source: 'manual_update',
        sourceId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        amount: xp,
      );
    } catch (e) {
      logger.error('Error updating XP', error: e);
      return false;
    }
  }

  /// Update challenge progress
  Future<bool> updateChallengeProgress(String challengeId, Map<String, dynamic> progress) async {
    try {
      final res = await ref.read(client).patch(
        ApiContract.url(ApiContract.gamification.challenges(challengeId)),
        data: progress,
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      logger.error('Error updating challenge progress', error: e);
      return false;
    }
  }

  /// Update milestone stats
  Future<bool> updateMilestoneStats(String milestoneId, int value) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.gamification.milestones),
        data: {
          'milestoneId': milestoneId,
          'value': value,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error updating milestone stats', error: e);
      return false;
    }
  }

  /// Add XP to league (for tribe competitions)
  Future<bool> addLeagueXP(int xp) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.gamification.leagueXp),
        data: {'xp': xp},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error adding league XP', error: e);
      return false;
    }
  }

  /// Use a heart (lives system)
  Future<bool> useHeart() async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.gamification.heartsUse),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error using heart', error: e);
      return false;
    }
  }

  /// Refill hearts (buy or wait)
  Future<bool> refillHearts() async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.gamification.heartsRefill),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error refilling hearts', error: e);
      return false;
    }
  }

  /// Toggle challenge mode
  Future<bool> toggleChallengeMode(bool enabled) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.gamification.challengeMode),
        data: {'enabled': enabled},
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      logger.error('Error toggling challenge mode', error: e);
      return false;
    }
  }

  /// Get leaderboard
}
