// Review Progress Service
// Manages review sessions, SRS scheduling, and review statistics
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review_progress_model.dart';
import '../providers/user_provider.dart';
import '../providers/backend_sync_provider.dart';
import 'vocabulary_progress_service.dart';

final reviewProgressServiceProvider = Provider<ReviewProgressService>((ref) {
  return ReviewProgressService(ref);
});

class ReviewProgressService {
  final Ref _ref;
  ReviewStatistics? _cachedStatistics;

  ReviewProgressService(this._ref);

  /// Load review statistics from local storage
  Future<ReviewStatistics> loadStatistics(String language) async {
    if (_cachedStatistics != null && _cachedStatistics!.language == language) {
      return _cachedStatistics!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString('review_statistics_$language');
      
      if (statsJson != null && statsJson.isNotEmpty) {
        _cachedStatistics = ReviewStatistics.fromJsonString(statsJson);
        if (_cachedStatistics!.language == language) {
          return _cachedStatistics!;
        }
      }
    } catch (e) {
      debugPrint('Error loading review statistics: $e');
    }

    _cachedStatistics = ReviewStatistics(language: language);
    return _cachedStatistics!;
  }

  /// Save review statistics to local storage
  Future<void> saveStatistics(ReviewStatistics statistics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('review_statistics_${statistics.language}', statistics.toJsonString());
      _cachedStatistics = statistics;
      
      // Sync to backend
      await _syncToBackend(statistics);
    } catch (e) {
      debugPrint('Error saving review statistics: $e');
    }
  }

  /// Record a review session
  Future<void> recordSession(ReviewSessionResult result) async {
    final stats = await loadStatistics(result.language);
    
    // Update statistics
    final newTotalReviews = stats.totalReviews + 1;
    final newTotalItems = stats.totalItemsReviewed + result.totalItems;
    
    // Calculate new average accuracy
    final newAvgAccuracy = stats.totalReviews == 0
        ? result.accuracy
        : ((stats.averageAccuracy * stats.totalReviews) + result.accuracy) / newTotalReviews;
    
    // Calculate new average time per item
    final avgTimeThisSession = result.totalItems > 0
        ? result.timeSpent / result.totalItems
        : 0.0;
    final newAvgTime = stats.totalItemsReviewed == 0
        ? avgTimeThisSession
        : ((stats.averageTimePerItem * stats.totalItemsReviewed) + (avgTimeThisSession * result.totalItems)) / newTotalItems;

    // Update accuracy by type
    final updatedAccuracyByType = Map<String, int>.from(stats.accuracyByType);
    final updatedTimeByType = Map<String, double>.from(stats.averageTimeByType);
    
    for (final item in result.itemsReviewed) {
      final type = item.type;
      if (item.isCorrect) {
        updatedAccuracyByType[type] = (updatedAccuracyByType[type] ?? 0) + 1;
      }
      
      // Update average time for this type
      final currentAvgTime = updatedTimeByType[type] ?? 0.0;
      final typeCount = result.itemsReviewed.where((i) => i.type == type).length;
      if (typeCount > 0) {
        final typeTime = result.itemsReviewed
            .where((i) => i.type == type)
            .fold<int>(0, (sum, i) => sum + i.timeSpent) /
            typeCount;
        updatedTimeByType[type] = currentAvgTime == 0.0
            ? typeTime
            : (currentAvgTime + typeTime) / 2.0;
      }
    }

    // Update recent sessions (keep last 30)
    final updatedSessions = [result, ...stats.recentSessions].take(30).toList();

    // Update streak
    final now = DateTime.now();
    final lastReview = stats.lastReview;
    final newStreak = lastReview != null &&
            now.difference(lastReview).inDays == 1
        ? stats.currentStreak + 1
        : (lastReview != null && now.difference(lastReview).inDays == 0
            ? stats.currentStreak
            : 1);

    // Update daily review counts
    final today = DateTime(now.year, now.month, now.day);
    final updatedDailyCounts = Map<DateTime, int>.from(stats.dailyReviewCounts);
    updatedDailyCounts[today] = (updatedDailyCounts[today] ?? 0) + 1;
    
    // Keep only last 30 days
    final cutoff = now.subtract(Duration(days: 30));
    updatedDailyCounts.removeWhere((date, _) => date.isBefore(cutoff));

    final updatedStats = stats.copyWith(
      totalReviews: newTotalReviews,
      totalItemsReviewed: newTotalItems,
      averageAccuracy: newAvgAccuracy,
      averageTimePerItem: newAvgTime,
      accuracyByType: updatedAccuracyByType,
      averageTimeByType: updatedTimeByType,
      recentSessions: updatedSessions,
      lastReview: now,
      currentStreak: newStreak,
      dailyReviewCounts: updatedDailyCounts,
    );

    await saveStatistics(updatedStats);
  }

  /// Get review heatmap data (for visualization)
  Future<Map<DateTime, int>> getReviewHeatmap(String language, {int days = 30}) async {
    final stats = await loadStatistics(language);
    final now = DateTime.now();
    final heatmap = <DateTime, int>{};

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      heatmap[dayStart] = stats.dailyReviewCounts[dayStart] ?? 0;
    }

    return heatmap;
  }

  /// Get items due for review (from vocabulary service)
  Future<int> getItemsDueForReview(String language) async {
    try {
      // Integrate with vocabulary service to get actual due items
      final vocabService = _ref.read(vocabularyProgressServiceProvider);
      final vocabProgress = await vocabService.loadProgress(language);
      
      // Count words due for review
      final dueWords = vocabProgress.getDueWords();
      
      // Also count review items from recent sessions that need re-review
      final stats = await loadStatistics(language);
      final recentItemsNeedingReview = stats.recentSessions
          .expand((session) => session.itemsReviewed)
          .where((item) => 
              !item.isCorrect && 
              item.reviewedAt.isBefore(DateTime.now().subtract(Duration(days: 1))))
          .length;
      
      return dueWords.length + recentItemsNeedingReview;
    } catch (e) {
      debugPrint('Error getting items due for review: $e');
      // Fallback: calculate from statistics
      final stats = await loadStatistics(language);
      if (stats.recentSessions.isEmpty) return 0;
      
      // Estimate based on recent activity
      final avgItemsPerSession = stats.totalItemsReviewed / stats.totalReviews.clamp(1, 100);
      final daysSinceLastReview = stats.lastReview != null
          ? DateTime.now().difference(stats.lastReview!).inDays
          : 7;
      
      // Estimate items due based on SRS schedule (typically 20-30% of learned items)
      return (avgItemsPerSession * 0.25 * (daysSinceLastReview / 7.0).clamp(0.0, 1.0)).round();
    }
  }

  /// Sync statistics to backend
  Future<void> _syncToBackend(ReviewStatistics statistics) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) return;

      final syncProvider = _ref.read(backendSyncProvider.notifier);
      await syncProvider.queueSync(SyncTask(
        type: SyncType.progress,
        data: {
          'user_id': user.id.toString(),
          'type': 'review_statistics',
          'language': statistics.language,
          'statistics': statistics.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      debugPrint('Error syncing review statistics: $e');
    }
  }

  /// Clear cached statistics
  void clearCache() {
    _cachedStatistics = null;
  }
}

