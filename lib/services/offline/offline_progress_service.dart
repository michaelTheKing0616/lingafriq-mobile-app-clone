import 'package:uuid/uuid.dart';
import '../../models/offline/local_progress.dart';
import '../../utils/api_service.dart';
import '../../utils/structured_logger.dart';
import 'local_database_service.dart';

const _uuid = Uuid();

/// Offline Progress Service
/// Stores all progress events locally and syncs with backend when online
class OfflineProgressService {
  static final OfflineProgressService _instance = OfflineProgressService._internal();
  factory OfflineProgressService() => _instance;
  OfflineProgressService._internal();

  final LocalDatabaseService _db = LocalDatabaseService();

  /// Record progress event
  /// Immediately stores in local database
  Future<String> recordProgress({
    required String type,
    required String language,
    int xp = 0,
    int score = 0,
    double completionPercentage = 0.0,
    int timeSpentSeconds = 0,
    Map<String, dynamic> details = const {},
    String? sessionId,
  }) async {
    final progressId = _uuid.v4();
    final now = DateTime.now();

    final progress = LocalProgress(
      id: progressId,
      type: type,
      language: language,
      xpEarned: xp,
      completionPercentage: completionPercentage,
      score: score,
      timeSpentSeconds: timeSpentSeconds,
      completedAt: now,
      isSynced: false,
      details: details,
      sessionId: sessionId,
    );

    await _db.saveProgress(progress);
    
    logger.debug('Progress recorded', context: {
      'id': progressId,
      'type': type,
      'language': language,
      'xp': xp,
    });

    return progressId;
  }

  /// Get progress for a specific language
  List<LocalProgress> getProgressForLanguage(String language) {
    return _db.getProgressByLanguage(language);
  }

  /// Get total XP earned across all languages
  int getTotalXP() {
    final allProgress = _db.getAllProgress();
    return allProgress.fold<int>(
      0,
      (sum, progress) => sum + progress.xpEarned,
    );
  }

  /// Get total XP for a specific language
  int getTotalXPForLanguage(String language) {
    final progress = _db.getProgressByLanguage(language);
    return progress.fold<int>(
      0,
      (sum, p) => sum + p.xpEarned,
    );
  }

  /// Get unsynced progress
  List<LocalProgress> getUnsyncedProgress() {
    return _db.getUnsyncedProgress();
  }

  /// Mark progress as synced
  Future<void> markAsSynced(List<String> ids) async {
    for (final id in ids) {
      await _db.markProgressAsSynced(id);
    }
  }

  /// Get progress dashboard data
  Map<String, dynamic> getProgressDashboardData({String? language}) {
    final progressList = language != null
        ? _db.getProgressByLanguage(language)
        : _db.getAllProgress();

    if (progressList.isEmpty) {
      return {
        'totalXP': 0,
        'totalLessons': 0,
        'totalTimeSpent': 0,
        'averageScore': 0.0,
        'completionRate': 0.0,
        'byType': <String, Map<String, dynamic>>{},
        'byLanguage': <String, Map<String, dynamic>>{},
      };
    }

    final totalXP = progressList.fold<int>(
      0,
      (sum, p) => sum + p.xpEarned,
    );

    final totalTimeSpent = progressList.fold<int>(
      0,
      (sum, p) => sum + p.timeSpentSeconds,
    );

    final totalScore = progressList.fold<int>(
      0,
      (sum, p) => sum + p.score,
    );

    final averageScore = progressList.isNotEmpty
        ? totalScore / progressList.length
        : 0.0;

    final totalCompletion = progressList.fold<double>(
      0.0,
      (sum, p) => sum + p.completionPercentage,
    );

    final completionRate = progressList.isNotEmpty
        ? totalCompletion / progressList.length
        : 0.0;

    final byType = <String, Map<String, dynamic>>{};
    final byLanguage = <String, Map<String, dynamic>>{};

    for (final progress in progressList) {
      byType.putIfAbsent(progress.type, () => {
        'count': 0,
        'totalXP': 0,
        'totalTime': 0,
        'averageScore': 0.0,
      });

      final typeData = byType[progress.type]!;
      byType[progress.type] = {
        'count': (typeData['count'] as int) + 1,
        'totalXP': (typeData['totalXP'] as int) + progress.xpEarned,
        'totalTime': (typeData['totalTime'] as int) + progress.timeSpentSeconds,
        'averageScore': ((typeData['averageScore'] as double) * (typeData['count'] as int) + progress.score) /
            ((typeData['count'] as int) + 1),
      };

      byLanguage.putIfAbsent(progress.language, () => {
        'count': 0,
        'totalXP': 0,
        'totalTime': 0,
        'averageScore': 0.0,
      });

      final langData = byLanguage[progress.language]!;
      byLanguage[progress.language] = {
        'count': (langData['count'] as int) + 1,
        'totalXP': (langData['totalXP'] as int) + progress.xpEarned,
        'totalTime': (langData['totalTime'] as int) + progress.timeSpentSeconds,
        'averageScore': ((langData['averageScore'] as double) * (langData['count'] as int) + progress.score) /
            ((langData['count'] as int) + 1),
      };
    }

    return {
      'totalXP': totalXP,
      'totalLessons': progressList.length,
      'totalTimeSpent': totalTimeSpent,
      'averageScore': averageScore,
      'completionRate': completionRate,
      'byType': byType,
      'byLanguage': byLanguage,
    };
  }

  /// Sync progress with backend
  /// Server wins for XP/levels, client wins for timestamps
  Future<void> syncWithBackend() async {
    final unsynced = getUnsyncedProgress();
    
    if (unsynced.isEmpty) {
      logger.debug('No unsynced progress to sync');
      return;
    }

    try {
      await ApiService.initialize();

      final syncedIds = <String>[];

      for (final progress in unsynced) {
        try {
          final response = await ApiService.post(
            '/api/gamification/progress/sync',
            data: {
              'id': progress.id,
              'type': progress.type,
              'language': progress.language,
              'xp_earned': progress.xpEarned,
              'completion_percentage': progress.completionPercentage,
              'score': progress.score,
              'time_spent_seconds': progress.timeSpentSeconds,
              'completed_at': progress.completedAt.toIso8601String(),
              'details': progress.details,
              'session_id': progress.sessionId,
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final responseData = response.data as Map<String, dynamic>?;
            
            if (responseData != null) {
              final serverXP = responseData['xp_earned'] as int?;
              final serverLevel = responseData['level'] as int?;
              
              if (serverXP != null || serverLevel != null) {
                await _db.updateProgress(
                  progress.copyWith(
                    xpEarned: serverXP ?? progress.xpEarned,
                    isSynced: true,
                    syncedAt: DateTime.now(),
                  ),
                );
              } else {
                await markAsSynced([progress.id]);
              }
            } else {
              await markAsSynced([progress.id]);
            }
            
            syncedIds.add(progress.id);
            logger.debug('Synced progress: ${progress.id}');
          }
        } catch (e) {
          logger.error('Failed to sync progress: ${progress.id}', error: e);
        }
      }

      logger.info('Progress sync completed: ${syncedIds.length}/${unsynced.length} synced');
    } catch (e) {
      logger.error('Failed to sync progress with backend', error: e);
      rethrow;
    }
  }

  /// Get progress by type
  List<LocalProgress> getProgressByType(String type) {
    return _db.getProgressByType(type);
  }

  /// Get progress statistics for a specific type
  Map<String, dynamic> getProgressStatsByType(String type) {
    final progressList = _db.getProgressByType(type);
    
    if (progressList.isEmpty) {
      return {
        'count': 0,
        'totalXP': 0,
        'totalTime': 0,
        'averageScore': 0.0,
        'averageCompletion': 0.0,
      };
    }

    final totalXP = progressList.fold<int>(
      0,
      (sum, p) => sum + p.xpEarned,
    );

    final totalTime = progressList.fold<int>(
      0,
      (sum, p) => sum + p.timeSpentSeconds,
    );

    final totalScore = progressList.fold<int>(
      0,
      (sum, p) => sum + p.score,
    );

    final totalCompletion = progressList.fold<double>(
      0.0,
      (sum, p) => sum + p.completionPercentage,
    );

    return {
      'count': progressList.length,
      'totalXP': totalXP,
      'totalTime': totalTime,
      'averageScore': totalScore / progressList.length,
      'averageCompletion': totalCompletion / progressList.length,
    };
  }

  /// Delete progress
  Future<void> deleteProgress(String id) async {
    await _db.deleteProgress(id);
  }

  /// Get progress by session ID
  List<LocalProgress> getProgressBySession(String sessionId) {
    final allProgress = _db.getAllProgress();
    return allProgress.where((p) => p.sessionId == sessionId).toList();
  }

  /// Get recent progress (last N items)
  List<LocalProgress> getRecentProgress({int limit = 50}) {
    final allProgress = _db.getAllProgress();
    allProgress.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return allProgress.take(limit).toList();
  }
}
