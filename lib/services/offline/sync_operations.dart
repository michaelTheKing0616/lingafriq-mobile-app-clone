// Background Sync Operations
// Implements specific sync operations for different data types
// 
// Features:
// - User progress sync
// - Lesson completion sync
// - Vocabulary progress sync
// - Gamification data sync
// - Conflict resolution
// 
// Production-ready implementation (December 2025)

import 'dart:convert';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sync operation types
enum SyncOperationType {
  userProgress,
  lessonCompletion,
  vocabularyProgress,
  gamificationData,
  roleplayProgress,
  tutorProgress,
  reviewProgress,
  learnerState,
  competenceAchievements,
  peerCorrections,
}

/// Sync operation result
class SyncOperationResult {
  final bool success;
  final int itemsSynced;
  final List<String> errors;
  final DateTime completedAt;

  SyncOperationResult({
    required this.success,
    required this.itemsSynced,
    required this.errors,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'itemsSynced': itemsSynced,
    'errors': errors,
    'completedAt': completedAt.toIso8601String(),
  };
}

/// Background Sync Operations Manager
class SyncOperations {
  static final SyncOperations _instance = SyncOperations._internal();
  factory SyncOperations() => _instance;
  SyncOperations._internal();

  /// Sync user progress
  Future<SyncOperationResult> syncUserProgress() async {
    try {
      logger.info('Starting user progress sync');
      
      final prefs = await SharedPreferences.getInstance();
      final pendingProgress = prefs.getStringList('pending_progress') ?? [];
      
      if (pendingProgress.isEmpty) {
        logger.debug('No pending progress to sync');
        return SyncOperationResult(
          success: true,
          itemsSynced: 0,
          errors: [],
          completedAt: DateTime.now(),
        );
      }

      int synced = 0;
      final errors = <String>[];

      // Sync each pending progress item
      await ApiService.initialize(); // Ensure API service is initialized
      
      for (final progressJson in pendingProgress) {
        try {
          // Parse progress item
          final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
          
          // Sync progress metrics to backend using ApiService
          final response = await ApiService.post('/api/gamification/progress/sync', data: progressData);
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            synced++;
            logger.debug('Synced progress item: $synced/${pendingProgress.length}');
          } else {
            errors.add('Failed to sync progress item: API returned ${response.statusCode}');
            logger.warn('Progress sync failed', context: {'item': progressData, 'statusCode': response.statusCode});
          }
        } catch (e) {
          errors.add('Failed to sync progress item: $e');
          logger.error('Error syncing progress item', error: e);
        }
      }

      // Remove synced items
      if (synced > 0) {
        final remaining = pendingProgress.skip(synced).toList();
        await prefs.setStringList('pending_progress', remaining);
      }

      logger.info('User progress sync completed: $synced items synced');
      
      return SyncOperationResult(
        success: errors.isEmpty,
        itemsSynced: synced,
        errors: errors,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error('User progress sync failed', error: e);
      return SyncOperationResult(
        success: false,
        itemsSynced: 0,
        errors: [e.toString()],
        completedAt: DateTime.now(),
      );
    }
  }

  /// Sync lesson completions
  Future<SyncOperationResult> syncLessonCompletions() async {
    try {
      logger.info('Starting lesson completion sync');
      
      final prefs = await SharedPreferences.getInstance();
      final pendingCompletions = prefs.getStringList('pending_lesson_completions') ?? [];
      
      if (pendingCompletions.isEmpty) {
        logger.debug('No pending lesson completions to sync');
        return SyncOperationResult(
          success: true,
          itemsSynced: 0,
          errors: [],
          completedAt: DateTime.now(),
        );
      }

      int synced = 0;
      final errors = <String>[];

      await ApiService.initialize();
      
      for (final completionJson in pendingCompletions) {
        try {
          // Parse lesson completion data
          final completionData = jsonDecode(completionJson) as Map<String, dynamic>;
          
          // Sync lesson completion to backend
          final response = await ApiService.post('/api/learner-activity', data: {
            'user_id': completionData['userId'],
            'language': completionData['language'] ?? 'unknown',
            'activity_type': 'lesson_completion',
            'metadata': completionData,
            'timestamp': DateTime.now().toIso8601String(),
          });
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            synced++;
          } else {
            errors.add('Failed to sync lesson completion: API returned ${response.statusCode}');
          }
        } catch (e) {
          errors.add('Failed to sync lesson completion: $e');
          logger.error('Error syncing lesson completion', error: e);
        }
      }

      if (synced > 0) {
        final remaining = pendingCompletions.skip(synced).toList();
        await prefs.setStringList('pending_lesson_completions', remaining);
      }

      logger.info('Lesson completion sync completed: $synced items synced');
      
      return SyncOperationResult(
        success: errors.isEmpty,
        itemsSynced: synced,
        errors: errors,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error('Lesson completion sync failed', error: e);
      return SyncOperationResult(
        success: false,
        itemsSynced: 0,
        errors: [e.toString()],
        completedAt: DateTime.now(),
      );
    }
  }

  /// Sync vocabulary progress
  Future<SyncOperationResult> syncVocabularyProgress() async {
    try {
      logger.info('Starting vocabulary progress sync');
      
      final prefs = await SharedPreferences.getInstance();
      final pendingVocabulary = prefs.getStringList('pending_vocabulary_progress') ?? [];
      
      if (pendingVocabulary.isEmpty) {
        logger.debug('No pending vocabulary progress to sync');
        return SyncOperationResult(
          success: true,
          itemsSynced: 0,
          errors: [],
          completedAt: DateTime.now(),
        );
      }

      int synced = 0;
      final errors = <String>[];
      await ApiService.initialize();

      for (final vocabJson in pendingVocabulary) {
        try {
          final vocabData = jsonDecode(vocabJson) as Map<String, dynamic>;
          
          // Sync vocabulary progress
          final response = await ApiService.post('/api/learner-activity', data: {
            'user_id': vocabData['userId'],
            'language': vocabData['language'] ?? 'unknown',
            'activity_type': 'vocabulary_review',
            'metadata': vocabData,
            'timestamp': DateTime.now().toIso8601String(),
          });
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            synced++;
          } else {
            errors.add('Failed to sync vocabulary item: API returned ${response.statusCode}');
          }
        } catch (e) {
          errors.add('Failed to sync vocabulary item: $e');
          logger.error('Error syncing vocabulary item', error: e);
        }
      }

      if (synced > 0) {
        final remaining = pendingVocabulary.skip(synced).toList();
        await prefs.setStringList('pending_vocabulary_progress', remaining);
      }
      logger.info('Vocabulary progress sync completed: $synced items synced');
      
      return SyncOperationResult(
        success: errors.isEmpty,
        itemsSynced: synced,
        errors: errors,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error('Vocabulary progress sync failed', error: e);
      return SyncOperationResult(
        success: false,
        itemsSynced: 0,
        errors: [e.toString()],
        completedAt: DateTime.now(),
      );
    }
  }

  /// Sync gamification data
  Future<SyncOperationResult> syncGamificationData() async {
    try {
      logger.info('Starting gamification data sync');
      
      final prefs = await SharedPreferences.getInstance();
      final pendingGamification = prefs.getStringList('pending_gamification') ?? [];
      
      if (pendingGamification.isEmpty) {
        logger.debug('No pending gamification data to sync');
        return SyncOperationResult(
          success: true,
          itemsSynced: 0,
          errors: [],
          completedAt: DateTime.now(),
        );
      }

      int synced = 0;
      final errors = <String>[];

      await ApiService.initialize();

      for (final gamificationJson in pendingGamification) {
        try {
          final gamificationData = jsonDecode(gamificationJson) as Map<String, dynamic>;
          
          // Sync gamification data (XP, badges, achievements, etc.)
          final response = await ApiService.post('/api/gamification/sync', data: gamificationData);
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            synced++;
          } else {
            errors.add('Failed to sync gamification data: API returned ${response.statusCode}');
            logger.warn('Gamification sync failed', context: {'data': gamificationData, 'statusCode': response.statusCode});
          }
        } catch (e) {
          errors.add('Failed to sync gamification data: $e');
          logger.error('Error syncing gamification data', error: e);
        }
      }

      if (synced > 0) {
        final remaining = pendingGamification.skip(synced).toList();
        await prefs.setStringList('pending_gamification', remaining);
      }

      logger.info('Gamification data sync completed: $synced items synced');
      
      return SyncOperationResult(
        success: errors.isEmpty,
        itemsSynced: synced,
        errors: errors,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error('Gamification data sync failed', error: e);
      return SyncOperationResult(
        success: false,
        itemsSynced: 0,
        errors: [e.toString()],
        completedAt: DateTime.now(),
      );
    }
  }

  /// Sync roleplay progress
  Future<SyncOperationResult> syncRoleplayProgress() async {
    try {
      logger.info('Starting roleplay progress sync');
      
      final prefs = await SharedPreferences.getInstance();
      final pendingRoleplay = prefs.getStringList('pending_roleplay_progress') ?? [];
      
      if (pendingRoleplay.isEmpty) {
        logger.debug('No pending roleplay progress to sync');
        return SyncOperationResult(
          success: true,
          itemsSynced: 0,
          errors: [],
          completedAt: DateTime.now(),
        );
      }

      int synced = 0;
      final errors = <String>[];

      for (final roleplayJson in pendingRoleplay) {
        try {
          final roleplayData = jsonDecode(roleplayJson) as Map<String, dynamic>;
          
          // Sync roleplay session data
          await ApiService.initialize();
          // Canonical backend route: POST /api/ai/chat/history/sync/
          final response = await ApiService.post('/api/ai/chat/history/sync/', data: roleplayData);
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            synced++;
          } else {
            errors.add('Failed to sync roleplay progress: API returned ${response.statusCode}');
          }
        } catch (e) {
          errors.add('Failed to sync roleplay progress: $e');
          logger.error('Error syncing roleplay progress', error: e);
        }
      }

      if (synced > 0) {
        final remaining = pendingRoleplay.skip(synced).toList();
        await prefs.setStringList('pending_roleplay_progress', remaining);
      }

      logger.info('Roleplay progress sync completed: $synced items synced');
      
      return SyncOperationResult(
        success: errors.isEmpty,
        itemsSynced: synced,
        errors: errors,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error('Roleplay progress sync failed', error: e);
      return SyncOperationResult(
        success: false,
        itemsSynced: 0,
        errors: [e.toString()],
        completedAt: DateTime.now(),
      );
    }
  }

  /// Sync tutor progress
  Future<SyncOperationResult> syncTutorProgress() async {
    try {
      logger.info('Starting tutor progress sync');
      
      final prefs = await SharedPreferences.getInstance();
      final pendingTutor = prefs.getStringList('pending_tutor_progress') ?? [];
      
      if (pendingTutor.isEmpty) {
        logger.debug('No pending tutor progress to sync');
        return SyncOperationResult(
          success: true,
          itemsSynced: 0,
          errors: [],
          completedAt: DateTime.now(),
        );
      }

      int synced = 0;
      final errors = <String>[];

      for (final tutorJson in pendingTutor) {
        try {
          final tutorData = jsonDecode(tutorJson) as Map<String, dynamic>;
          
          // Sync tutor session data
          await ApiService.initialize();
          // Canonical backend route: POST /api/ai/chat/history/sync/
          final response = await ApiService.post('/api/ai/chat/history/sync/', data: tutorData);
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            synced++;
          } else {
            errors.add('Failed to sync tutor progress: API returned ${response.statusCode}');
          }
        } catch (e) {
          errors.add('Failed to sync tutor progress: $e');
          logger.error('Error syncing tutor progress', error: e);
        }
      }

      if (synced > 0) {
        final remaining = pendingTutor.skip(synced).toList();
        await prefs.setStringList('pending_tutor_progress', remaining);
      }

      logger.info('Tutor progress sync completed: $synced items synced');
      
      return SyncOperationResult(
        success: errors.isEmpty,
        itemsSynced: synced,
        errors: errors,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error('Tutor progress sync failed', error: e);
      return SyncOperationResult(
        success: false,
        itemsSynced: 0,
        errors: [e.toString()],
        completedAt: DateTime.now(),
      );
    }
  }

  /// Sync review progress
  Future<SyncOperationResult> syncReviewProgress() async {
    try {
      logger.info('Starting review progress sync');
      
      final prefs = await SharedPreferences.getInstance();
      final pendingReviews = prefs.getStringList('pending_review_progress') ?? [];
      
      if (pendingReviews.isEmpty) {
        logger.debug('No pending review progress to sync');
        return SyncOperationResult(
          success: true,
          itemsSynced: 0,
          errors: [],
          completedAt: DateTime.now(),
        );
      }

      int synced = 0;
      final errors = <String>[];

      for (final reviewJson in pendingReviews) {
        try {
          final reviewData = jsonDecode(reviewJson) as Map<String, dynamic>;
          
          // Sync review data (spaced repetition reviews, flashcard reviews, etc.)
          await ApiService.initialize();
          final response = await ApiService.post('/api/learner-activity', data: {
            'user_id': reviewData['userId'],
            'language': reviewData['language'] ?? 'unknown',
            'activity_type': 'review',
            'metadata': reviewData,
            'timestamp': DateTime.now().toIso8601String(),
          });
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            synced++;
          } else {
            errors.add('Failed to sync review progress: API returned ${response.statusCode}');
          }
        } catch (e) {
          errors.add('Failed to sync review progress: $e');
          logger.error('Error syncing review progress', error: e);
        }
      }

      if (synced > 0) {
        final remaining = pendingReviews.skip(synced).toList();
        await prefs.setStringList('pending_review_progress', remaining);
      }

      logger.info('Review progress sync completed: $synced items synced');
      
      return SyncOperationResult(
        success: errors.isEmpty,
        itemsSynced: synced,
        errors: errors,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error('Review progress sync failed', error: e);
      return SyncOperationResult(
        success: false,
        itemsSynced: 0,
        errors: [e.toString()],
        completedAt: DateTime.now(),
      );
    }
  }

  /// Sync learner model state (skill mastery, half-life, error distributions)
  Future<SyncOperationResult> syncLearnerState() async {
    try {
      logger.info('Starting learner state sync');
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('learner_state_'));
      int synced = 0;
      final errors = <String>[];

      for (final key in keys) {
        try {
          final data = prefs.getString(key);
          if (data == null) continue;

          await ApiService.initialize();
          final response = await ApiService.post(
            '/api/learning/state/skill',
            data: jsonDecode(data),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            synced++;
          }
        } catch (e) {
          errors.add('Failed to sync learner state $key: $e');
        }
      }

      logger.info('Learner state sync completed: $synced items synced');
      return SyncOperationResult(
        success: errors.isEmpty,
        itemsSynced: synced,
        errors: errors,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error('Learner state sync failed', error: e);
      return SyncOperationResult(
        success: false, itemsSynced: 0,
        errors: [e.toString()], completedAt: DateTime.now(),
      );
    }
  }

  /// Sync competence achievements to backend
  Future<SyncOperationResult> syncCompetenceAchievements() async {
    try {
      logger.info('Starting competence achievements sync');
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_achievements') ?? [];
      int synced = 0;
      final errors = <String>[];

      for (final item in pending) {
        try {
          await ApiService.initialize();
          final response = await ApiService.post(
            '/api/learning/achievements/sync',
            data: jsonDecode(item),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            synced++;
          }
        } catch (e) {
          errors.add('Failed to sync achievement: $e');
        }
      }

      if (synced > 0) {
        final remaining = pending.skip(synced).toList();
        await prefs.setStringList('pending_achievements', remaining);
      }

      logger.info('Achievements sync completed: $synced items synced');
      return SyncOperationResult(
        success: errors.isEmpty,
        itemsSynced: synced,
        errors: errors,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error('Achievements sync failed', error: e);
      return SyncOperationResult(
        success: false, itemsSynced: 0,
        errors: [e.toString()], completedAt: DateTime.now(),
      );
    }
  }

  /// Sync peer corrections to backend
  Future<SyncOperationResult> syncPeerCorrections() async {
    try {
      logger.info('Starting peer corrections sync');
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_peer_corrections') ?? [];
      int synced = 0;
      final errors = <String>[];

      for (final item in pending) {
        try {
          await ApiService.initialize();
          final response = await ApiService.post(
            '/api/learning/corrections',
            data: jsonDecode(item),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            synced++;
          }
        } catch (e) {
          errors.add('Failed to sync peer correction: $e');
        }
      }

      if (synced > 0) {
        final remaining = pending.skip(synced).toList();
        await prefs.setStringList('pending_peer_corrections', remaining);
      }

      logger.info('Peer corrections sync completed: $synced items synced');
      return SyncOperationResult(
        success: errors.isEmpty,
        itemsSynced: synced,
        errors: errors,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      logger.error('Peer corrections sync failed', error: e);
      return SyncOperationResult(
        success: false, itemsSynced: 0,
        errors: [e.toString()], completedAt: DateTime.now(),
      );
    }
  }

  /// Sync all operations
  Future<Map<SyncOperationType, SyncOperationResult>> syncAll() async {
    logger.info('Starting full background sync');
    
    final results = <SyncOperationType, SyncOperationResult>{};

    // Sync all operation types
    results[SyncOperationType.userProgress] = await syncUserProgress();
    results[SyncOperationType.lessonCompletion] = await syncLessonCompletions();
    results[SyncOperationType.vocabularyProgress] = await syncVocabularyProgress();
    results[SyncOperationType.gamificationData] = await syncGamificationData();
    results[SyncOperationType.roleplayProgress] = await syncRoleplayProgress();
    results[SyncOperationType.tutorProgress] = await syncTutorProgress();
    results[SyncOperationType.reviewProgress] = await syncReviewProgress();
    results[SyncOperationType.learnerState] = await syncLearnerState();
    results[SyncOperationType.competenceAchievements] = await syncCompetenceAchievements();
    results[SyncOperationType.peerCorrections] = await syncPeerCorrections();

    // Update last sync time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync', DateTime.now().toIso8601String());

    final totalSynced = results.values.fold<int>(
      0,
      (sum, result) => sum + result.itemsSynced,
    );

    logger.info('Full background sync completed: $totalSynced total items synced');
    
    return results;
  }
}

