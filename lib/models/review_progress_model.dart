/// Review Progress Model
/// Tracks review sessions, SRS performance, and review statistics
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Review Session Result
class ReviewSessionResult {
  final String sessionId;
  final String language;
  final List<ReviewItem> itemsReviewed;
  final int totalItems;
  final int correctCount;
  final int incorrectCount;
  final double accuracy;
  final int timeSpent; // in seconds
  final DateTime completedAt;
  final Map<String, dynamic> metadata;

  ReviewSessionResult({
    required this.sessionId,
    required this.language,
    this.itemsReviewed = const [],
    required this.totalItems,
    required this.correctCount,
    required this.incorrectCount,
    required this.accuracy,
    required this.timeSpent,
    required this.completedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'language': language,
        'items_reviewed': itemsReviewed.map((i) => i.toJson()).toList(),
        'total_items': totalItems,
        'correct_count': correctCount,
        'incorrect_count': incorrectCount,
        'accuracy': accuracy,
        'time_spent': timeSpent,
        'completed_at': completedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory ReviewSessionResult.fromJson(Map<String, dynamic> json) {
    return ReviewSessionResult(
      sessionId: json['session_id'] ?? '',
      language: json['language'] ?? '',
      itemsReviewed: (json['items_reviewed'] as List?)
              ?.map((i) => ReviewItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      totalItems: json['total_items'] ?? 0,
      correctCount: json['correct_count'] ?? 0,
      incorrectCount: json['incorrect_count'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      timeSpent: json['time_spent'] ?? 0,
      completedAt: DateTime.parse(json['completed_at']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Review Item
class ReviewItem {
  final String itemId;
  final String type; // 'word', 'phrase', 'grammar'
  final String question;
  final String? correctAnswer;
  final String? userAnswer;
  final bool isCorrect;
  final double confidence; // 0.0 to 1.0
  final int timeSpent; // in seconds
  final DateTime reviewedAt;

  ReviewItem({
    required this.itemId,
    required this.type,
    required this.question,
    this.correctAnswer,
    this.userAnswer,
    required this.isCorrect,
    this.confidence = 0.0,
    this.timeSpent = 0,
    required this.reviewedAt,
  });

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'type': type,
        'question': question,
        if (correctAnswer != null) 'correct_answer': correctAnswer,
        if (userAnswer != null) 'user_answer': userAnswer,
        'is_correct': isCorrect,
        'confidence': confidence,
        'time_spent': timeSpent,
        'reviewed_at': reviewedAt.toIso8601String(),
      };

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      itemId: json['item_id'] ?? '',
      type: json['type'] ?? '',
      question: json['question'] ?? '',
      correctAnswer: json['correct_answer'],
      userAnswer: json['user_answer'],
      isCorrect: json['is_correct'] ?? false,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      timeSpent: json['time_spent'] ?? 0,
      reviewedAt: DateTime.parse(json['reviewed_at']),
    );
  }
}

/// Review Statistics
class ReviewStatistics {
  final String language;
  final int totalReviews;
  final int totalItemsReviewed;
  final double averageAccuracy;
  final double averageTimePerItem; // in seconds
  final Map<String, int> accuracyByType; // type -> correct count
  final Map<String, double> averageTimeByType; // type -> average time
  final List<ReviewSessionResult> recentSessions;
  final DateTime? lastReview;
  final int currentStreak;
  final Map<DateTime, int> dailyReviewCounts; // date -> count

  ReviewStatistics({
    required this.language,
    this.totalReviews = 0,
    this.totalItemsReviewed = 0,
    this.averageAccuracy = 0.0,
    this.averageTimePerItem = 0.0,
    this.accuracyByType = const {},
    this.averageTimeByType = const {},
    this.recentSessions = const [],
    this.lastReview,
    this.currentStreak = 0,
    this.dailyReviewCounts = const {},
  });

  ReviewStatistics copyWith({
    String? language,
    int? totalReviews,
    int? totalItemsReviewed,
    double? averageAccuracy,
    double? averageTimePerItem,
    Map<String, int>? accuracyByType,
    Map<String, double>? averageTimeByType,
    List<ReviewSessionResult>? recentSessions,
    DateTime? lastReview,
    int? currentStreak,
    Map<DateTime, int>? dailyReviewCounts,
  }) {
    return ReviewStatistics(
      language: language ?? this.language,
      totalReviews: totalReviews ?? this.totalReviews,
      totalItemsReviewed: totalItemsReviewed ?? this.totalItemsReviewed,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      averageTimePerItem: averageTimePerItem ?? this.averageTimePerItem,
      accuracyByType: accuracyByType ?? this.accuracyByType,
      averageTimeByType: averageTimeByType ?? this.averageTimeByType,
      recentSessions: recentSessions ?? this.recentSessions,
      lastReview: lastReview ?? this.lastReview,
      currentStreak: currentStreak ?? this.currentStreak,
      dailyReviewCounts: dailyReviewCounts ?? this.dailyReviewCounts,
    );
  }

  /// Get accuracy trend (last 7 days)
  List<double> getAccuracyTrend({int days = 7}) {
    final now = DateTime.now();
    final trend = <double>[];
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final sessions = recentSessions.where((s) {
        final sessionDate = DateTime(s.completedAt.year, s.completedAt.month, s.completedAt.day);
        final targetDate = DateTime(date.year, date.month, date.day);
        return sessionDate == targetDate;
      }).toList();
      
      if (sessions.isEmpty) {
        trend.add(0.0);
      } else {
        final avg = sessions.fold<double>(0.0, (sum, s) => sum + s.accuracy) / sessions.length;
        trend.add(avg);
      }
    }
    
    return trend;
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'total_reviews': totalReviews,
        'total_items_reviewed': totalItemsReviewed,
        'average_accuracy': averageAccuracy,
        'average_time_per_item': averageTimePerItem,
        'accuracy_by_type': accuracyByType,
        'average_time_by_type': averageTimeByType.map((k, v) => MapEntry(k, v)),
        'recent_sessions': recentSessions.map((s) => s.toJson()).toList(),
        if (lastReview != null) 'last_review': lastReview!.toIso8601String(),
        'current_streak': currentStreak,
        'daily_review_counts': dailyReviewCounts.map(
          (k, v) => MapEntry(k.toIso8601String(), v),
        ),
      };

  factory ReviewStatistics.fromJson(Map<String, dynamic> json) {
    final dailyCounts = <DateTime, int>{};
    if (json['daily_review_counts'] != null) {
      (json['daily_review_counts'] as Map).forEach((k, v) {
        dailyCounts[DateTime.parse(k)] = v as int;
      });
    }

    return ReviewStatistics(
      language: json['language'] ?? '',
      totalReviews: json['total_reviews'] ?? 0,
      totalItemsReviewed: json['total_items_reviewed'] ?? 0,
      averageAccuracy: (json['average_accuracy'] ?? 0.0).toDouble(),
      averageTimePerItem: (json['average_time_per_item'] ?? 0.0).toDouble(),
      accuracyByType: Map<String, int>.from(
        (json['accuracy_by_type'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {},
      ),
      averageTimeByType: Map<String, double>.from(
        (json['average_time_by_type'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
      ),
      recentSessions: (json['recent_sessions'] as List?)
              ?.map((s) => ReviewSessionResult.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      lastReview: json['last_review'] != null
          ? DateTime.parse(json['last_review'])
          : null,
      currentStreak: json['current_streak'] ?? 0,
      dailyReviewCounts: dailyCounts,
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory ReviewStatistics.fromJsonString(String jsonString) {
    return ReviewStatistics.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

