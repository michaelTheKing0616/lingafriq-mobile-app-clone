/// ML-based Adaptive Learning Service
/// World-class personalized learning paths
/// 
/// Features:
/// - ML-based difficulty adjustment
/// - Learning curve prediction
/// - Performance-based adaptation
/// - Personalized content recommendations
/// - Spaced repetition integration
/// 
/// Production-ready implementation (December 2025)

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/dio_provider.dart';
import '../../utils/api.dart';

/// Learning Difficulty Level
enum DifficultyLevel {
  beginner,    // A1
  elementary,  // A2
  intermediate, // B1
  upperIntermediate, // B2
  advanced,    // C1
  proficient,  // C2
}

/// User Performance Metrics
class UserPerformanceMetrics {
  final String userId;
  final String language;
  final double overallScore; // 0.0 - 1.0
  final double accuracy; // 0.0 - 1.0
  final double speed; // Words per minute
  final double retention; // 0.0 - 1.0
  final Map<String, double> skillScores; // Skill -> score
  final List<DateTime> studySessions;
  final int totalExercises;
  final int correctExercises;
  final DateTime lastUpdated;

  UserPerformanceMetrics({
    required this.userId,
    required this.language,
    required this.overallScore,
    required this.accuracy,
    required this.speed,
    required this.retention,
    required this.skillScores,
    required this.studySessions,
    required this.totalExercises,
    required this.correctExercises,
    required this.lastUpdated,
  });

  factory UserPerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return UserPerformanceMetrics(
      userId: json['user_id'] ?? '',
      language: json['language'] ?? '',
      overallScore: (json['overall_score'] ?? 0.0).toDouble(),
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      speed: (json['speed'] ?? 0.0).toDouble(),
      retention: (json['retention'] ?? 0.0).toDouble(),
      skillScores: Map<String, double>.from(
        json['skill_scores'] ?? {},
      ),
      studySessions: (json['study_sessions'] as List?)
          ?.map((s) => DateTime.parse(s))
          .toList() ?? [],
      totalExercises: json['total_exercises'] ?? 0,
      correctExercises: json['correct_exercises'] ?? 0,
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

/// Learning Recommendation
class LearningRecommendation {
  final String type; // 'exercise', 'story', 'vocabulary', 'grammar'
  final String id;
  final String title;
  final String? description;
  final DifficultyLevel recommendedDifficulty;
  final double confidence; // 0.0 - 1.0
  final String reasoning;
  final List<String> focusAreas;
  final Map<String, dynamic>? metadata;

  LearningRecommendation({
    required this.type,
    required this.id,
    required this.title,
    this.description,
    required this.recommendedDifficulty,
    required this.confidence,
    required this.reasoning,
    required this.focusAreas,
    this.metadata,
  });

  factory LearningRecommendation.fromJson(Map<String, dynamic> json) {
    return LearningRecommendation(
      type: json['type'] ?? '',
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      recommendedDifficulty: DifficultyLevel.values.firstWhere(
        (d) => d.name == json['recommended_difficulty'],
        orElse: () => DifficultyLevel.beginner,
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] ?? '',
      focusAreas: List<String>.from(json['focus_areas'] ?? []),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }
}

/// Learning Curve Prediction
class LearningCurvePrediction {
  final String userId;
  final String language;
  final List<DateTime> predictedDates;
  final List<double> predictedScores;
  final double currentScore;
  final double predictedScore30Days;
  final double predictedScore90Days;
  final List<String> recommendations;
  final DateTime generatedAt;

  LearningCurvePrediction({
    required this.userId,
    required this.language,
    required this.predictedDates,
    required this.predictedScores,
    required this.currentScore,
    required this.predictedScore30Days,
    required this.predictedScore90Days,
    required this.recommendations,
    required this.generatedAt,
  });

  factory LearningCurvePrediction.fromJson(Map<String, dynamic> json) {
    return LearningCurvePrediction(
      userId: json['user_id'] ?? '',
      language: json['language'] ?? '',
      predictedDates: (json['predicted_dates'] as List?)
          ?.map((d) => DateTime.parse(d))
          .toList() ?? [],
      predictedScores: (json['predicted_scores'] as List?)
          ?.map((s) => (s as num).toDouble())
          .toList() ?? [],
      currentScore: (json['current_score'] ?? 0.0).toDouble(),
      predictedScore30Days: (json['predicted_score_30_days'] ?? 0.0).toDouble(),
      predictedScore90Days: (json['predicted_score_90_days'] ?? 0.0).toDouble(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      generatedAt: DateTime.parse(json['generated_at']),
    );
  }
}

/// Adaptive Learning Service Provider
final adaptiveLearningServiceProvider = Provider<AdaptiveLearningService>((ref) {
  return AdaptiveLearningService(ref);
});

/// Adaptive Learning Service
/// 
/// Provides ML-based adaptive learning with:
/// - Difficulty adjustment
/// - Learning curve prediction
/// - Personalized recommendations
/// - Performance analysis
class AdaptiveLearningService {
  final Ref _ref;
  final Dio _dio;

  AdaptiveLearningService(this._ref) : _dio = _ref.read(client);

  /// Get user performance metrics
  Future<UserPerformanceMetrics?> getPerformanceMetrics({
    required String userId,
    required String language,
  }) async {
    try {
      final response = await _dio.get(
        '${Api.baseurl}api/v1/adaptive-learning/performance/$userId/$language',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return UserPerformanceMetrics.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('Get performance metrics error: $e');
      return null;
    }
  }

  /// Get adaptive difficulty recommendation
  Future<DifficultyLevel> getRecommendedDifficulty({
    required String userId,
    required String language,
    String? skill,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (skill != null) 'skill': skill,
      };

      final response = await _dio.get(
        '${Api.baseurl}api/v1/adaptive-learning/difficulty/$userId/$language',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final levelStr = data['recommended_difficulty'] ?? 'beginner';
        return DifficultyLevel.values.firstWhere(
          (d) => d.name == levelStr,
          orElse: () => DifficultyLevel.beginner,
        );
      }

      return DifficultyLevel.beginner;
    } catch (e) {
      debugPrint('Get recommended difficulty error: $e');
      return DifficultyLevel.beginner;
    }
  }

  /// Get personalized learning recommendations
  Future<List<LearningRecommendation>> getRecommendations({
    required String userId,
    required String language,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (limit != null) 'limit': limit,
      };

      final response = await _dio.get(
        '${Api.baseurl}api/v1/adaptive-learning/recommendations/$userId/$language',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final recommendations = data['recommendations'] as List?;
        if (recommendations != null) {
          return recommendations
              .map((r) => LearningRecommendation.fromJson(r as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('Get recommendations error: $e');
      return [];
    }
  }

  /// Predict learning curve
  Future<LearningCurvePrediction?> predictLearningCurve({
    required String userId,
    required String language,
  }) async {
    try {
      final response = await _dio.get(
        '${Api.baseurl}api/v1/adaptive-learning/prediction/$userId/$language',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return LearningCurvePrediction.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('Predict learning curve error: $e');
      return null;
    }
  }

  /// Adjust difficulty based on performance
  Future<DifficultyLevel> adjustDifficulty({
    required String userId,
    required String language,
    required double performanceScore, // 0.0 - 1.0
    required DifficultyLevel currentDifficulty,
  }) async {
    try {
      final response = await _dio.post(
        '${Api.baseurl}api/v1/adaptive-learning/adjust-difficulty',
        data: {
          'user_id': userId,
          'language': language,
          'performance_score': performanceScore,
          'current_difficulty': currentDifficulty.name,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final levelStr = data['new_difficulty'] ?? currentDifficulty.name;
        return DifficultyLevel.values.firstWhere(
          (d) => d.name == levelStr,
          orElse: () => currentDifficulty,
        );
      }

      return currentDifficulty;
    } catch (e) {
      debugPrint('Adjust difficulty error: $e');
      return currentDifficulty;
    }
  }

  /// Update performance after exercise
  Future<void> updatePerformance({
    required String userId,
    required String language,
    required String exerciseId,
    required bool correct,
    required double score,
    required Duration timeTaken,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _dio.post(
        '${Api.baseurl}api/v1/adaptive-learning/performance',
        data: {
          'user_id': userId,
          'language': language,
          'exercise_id': exerciseId,
          'correct': correct,
          'score': score,
          'time_taken_ms': timeTaken.inMilliseconds,
          if (details != null) 'details': details,
        },
      );
    } catch (e) {
      debugPrint('Update performance error: $e');
      // Don't throw - performance update failure shouldn't break the app
    }
  }

  /// Get skill-specific recommendations
  Future<List<LearningRecommendation>> getSkillRecommendations({
    required String userId,
    required String language,
    required String skill, // 'vocabulary', 'grammar', 'pronunciation', etc.
  }) async {
    try {
      final response = await _dio.get(
        '${Api.baseurl}api/v1/adaptive-learning/skills/$skill/recommendations',
        queryParameters: {
          'user_id': userId,
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final recommendations = data['recommendations'] as List?;
        if (recommendations != null) {
          return recommendations
              .map((r) => LearningRecommendation.fromJson(r as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('Get skill recommendations error: $e');
      return [];
    }
  }
}

