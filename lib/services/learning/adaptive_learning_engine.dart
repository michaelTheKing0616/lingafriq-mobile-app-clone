/// Adaptive Learning Engine
/// Adjusts learning path based on user performance
/// 
/// Features:
/// - Performance tracking
/// - Difficulty adjustment
/// - Personalized recommendations
/// - Learning curve analysis

import '../../models/lesson_item_model.dart';
import '../../utils/simple_cache.dart';
import 'dart:math' as math;

/// User performance metric
class PerformanceMetric {
  final String lessonItemId;
  final double accuracy;
  final int attemptCount;
  final DateTime lastAttempt;
  final Duration? timeSpent;
  final Map<String, dynamic>? details;

  PerformanceMetric({
    required this.lessonItemId,
    required this.accuracy,
    required this.attemptCount,
    required this.lastAttempt,
    this.timeSpent,
    this.details,
  });
}

/// Learning recommendation
class LearningRecommendation {
  final String type;
  final String lessonItemId;
  final String reason;
  final double priority;
  final Map<String, dynamic>? metadata;

  LearningRecommendation({
    required this.type,
    required this.lessonItemId,
    required this.reason,
    required this.priority,
    this.metadata,
  });
}

/// Adaptive Learning Engine
class AdaptiveLearningEngine {
  static final AdaptiveLearningEngine _instance = AdaptiveLearningEngine._internal();
  factory AdaptiveLearningEngine() => _instance;
  AdaptiveLearningEngine._internal();

  final SimpleCache _cache = SimpleCache();
  final Map<String, List<PerformanceMetric>> _performanceHistory = {};
  static const Duration _historyTTL = Duration(days: 90);

  /// Record user performance
  void recordPerformance({
    required String userId,
    required String lessonItemId,
    required double accuracy,
    int attemptCount = 1,
    Duration? timeSpent,
    Map<String, dynamic>? details,
  }) {
    final metric = PerformanceMetric(
      lessonItemId: lessonItemId,
      accuracy: accuracy,
      attemptCount: attemptCount,
      lastAttempt: DateTime.now(),
      timeSpent: timeSpent,
      details: details,
    );

    _performanceHistory.putIfAbsent(userId, () => []).add(metric);
    _cache.set('perf_$userId', _performanceHistory[userId]!, ttl: _historyTTL);
  }

  /// Get user performance for a lesson item
  PerformanceMetric? getUserPerformance(String userId, String lessonItemId) {
    final history = _performanceHistory[userId] ?? [];
    return history.where((m) => m.lessonItemId == lessonItemId).lastOrNull;
  }

  /// Calculate recommended difficulty
  double calculateRecommendedDifficulty(String userId, String languageCode, String currentLevel) {
    final history = _performanceHistory[userId] ?? [];
    if (history.isEmpty) {
      return _getBaseDifficulty(currentLevel);
    }

    final recentMetrics = history
        .where((m) => DateTime.now().difference(m.lastAttempt).inDays < 7)
        .toList();

    if (recentMetrics.isEmpty) {
      return _getBaseDifficulty(currentLevel);
    }

    final averageAccuracy = recentMetrics
        .map((m) => m.accuracy)
        .reduce((a, b) => a + b) / recentMetrics.length;

    final currentDifficulty = _getBaseDifficulty(currentLevel);

    if (averageAccuracy > 0.85) {
      return math.min(1.0, currentDifficulty + 0.1);
    } else if (averageAccuracy < 0.6) {
      return math.max(0.0, currentDifficulty - 0.1);
    }

    return currentDifficulty;
  }

  /// Get learning recommendations
  List<LearningRecommendation> getRecommendations({
    required String userId,
    required String languageCode,
    required String currentLevel,
    required List<LessonItem> availableItems,
    int limit = 10,
  }) {
    final recommendations = <LearningRecommendation>[];
    final history = _performanceHistory[userId] ?? [];
    final completedItems = history.map((m) => m.lessonItemId).toSet();

    for (final item in availableItems) {
      if (completedItems.contains(item.id)) {
        final perf = history.firstWhere((m) => m.lessonItemId == item.id);
        if (perf.accuracy < 0.7) {
          recommendations.add(LearningRecommendation(
            type: 'review',
            lessonItemId: item.id,
            reason: 'Low accuracy: ${(perf.accuracy * 100).toStringAsFixed(0)}%',
            priority: 1.0 - perf.accuracy,
            metadata: {'accuracy': perf.accuracy},
          ));
        }
      } else {
        final itemDifficulty = item.difficulty;
        final recommendedDifficulty = calculateRecommendedDifficulty(
          userId,
          languageCode,
          currentLevel,
        );

        if ((itemDifficulty - recommendedDifficulty).abs() < 0.15) {
          recommendations.add(LearningRecommendation(
            type: 'new',
            lessonItemId: item.id,
            reason: 'Matches your learning level',
            priority: 0.8,
            metadata: {'difficulty': itemDifficulty},
          ));
        }
      }
    }

    recommendations.sort((a, b) => b.priority.compareTo(a.priority));
    return recommendations.take(limit).toList();
  }

  /// Analyze learning curve
  Map<String, dynamic> analyzeLearningCurve(String userId, {Duration? period}) {
    final history = _performanceHistory[userId] ?? [];
    if (history.isEmpty) {
      return {
        'trend': 'stable',
        'improvement_rate': 0.0,
        'average_accuracy': 0.0,
        'items_completed': 0,
      };
    }

    final cutoffDate = period != null
        ? DateTime.now().subtract(period)
        : DateTime.fromMillisecondsSinceEpoch(0);

    final filteredHistory = history
        .where((m) => m.lastAttempt.isAfter(cutoffDate))
        .toList();

    if (filteredHistory.length < 2) {
      final avgAccuracy = filteredHistory.isEmpty
          ? 0.0
          : filteredHistory.map((m) => m.accuracy).reduce((a, b) => a + b) /
              filteredHistory.length;

      return {
        'trend': 'stable',
        'improvement_rate': 0.0,
        'average_accuracy': avgAccuracy,
        'items_completed': filteredHistory.length,
      };
    }

    filteredHistory.sort((a, b) => a.lastAttempt.compareTo(b.lastAttempt));

    final earlyAccuracy = filteredHistory
        .take(filteredHistory.length ~/ 2)
        .map((m) => m.accuracy)
        .reduce((a, b) => a + b) / (filteredHistory.length ~/ 2);

    final lateAccuracy = filteredHistory
        .skip(filteredHistory.length ~/ 2)
        .map((m) => m.accuracy)
        .reduce((a, b) => a + b) / (filteredHistory.length - filteredHistory.length ~/ 2);

    final improvementRate = lateAccuracy - earlyAccuracy;
    final averageAccuracy = filteredHistory
        .map((m) => m.accuracy)
        .reduce((a, b) => a + b) / filteredHistory.length;

    String trend;
    if (improvementRate > 0.05) {
      trend = 'improving';
    } else if (improvementRate < -0.05) {
      trend = 'declining';
    } else {
      trend = 'stable';
    }

    return {
      'trend': trend,
      'improvement_rate': improvementRate,
      'average_accuracy': averageAccuracy,
      'items_completed': filteredHistory.length,
      'early_accuracy': earlyAccuracy,
      'late_accuracy': lateAccuracy,
    };
  }

  double _getBaseDifficulty(String level) {
    const difficultyMap = {
      'A0': 0.1,
      'A1': 0.2,
      'A2': 0.4,
      'B1': 0.6,
      'B2': 0.8,
      'C1': 0.95,
    };

    return difficultyMap[level] ?? 0.5;
  }

  void clearHistory(String userId) {
    _performanceHistory.remove(userId);
    _cache.remove('perf_$userId');
  }

  Map<String, dynamic> getUserStats(String userId) {
    final history = _performanceHistory[userId] ?? [];
    if (history.isEmpty) {
      return {
        'total_items': 0,
        'average_accuracy': 0.0,
        'items_mastered': 0,
        'items_needing_review': 0,
      };
    }

    final averageAccuracy = history
        .map((m) => m.accuracy)
        .reduce((a, b) => a + b) / history.length;

    final mastered = history.where((m) => m.accuracy >= 0.9).length;
    final needsReview = history.where((m) => m.accuracy < 0.7).length;

    return {
      'total_items': history.length,
      'average_accuracy': averageAccuracy,
      'items_mastered': mastered,
      'items_needing_review': needsReview,
    };
  }
}

