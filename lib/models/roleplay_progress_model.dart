/// Roleplay Progress Model
/// Tracks user progress through roleplay scenarios
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Scenario Progress
class ScenarioProgress {
  final String scenarioId;
  final String scenarioName;
  final String language;
  final String category;
  final String difficulty; // A1, A2, B1, B2, C1, C2
  final int timesCompleted;
  final double averageAccuracy;
  final double averageFluency;
  final int bestScore;
  final DateTime? firstCompleted;
  final DateTime? lastCompleted;
  final List<String> branchesExplored;
  final Map<String, int> vocabularyUsed; // word -> count
  final Map<String, int> grammarPoints; // grammar point -> count
  final int totalTimeSpent; // in seconds
  final bool isMastered;
  final int streak;

  ScenarioProgress({
    required this.scenarioId,
    required this.scenarioName,
    required this.language,
    required this.category,
    required this.difficulty,
    this.timesCompleted = 0,
    this.averageAccuracy = 0.0,
    this.averageFluency = 0.0,
    this.bestScore = 0,
    this.firstCompleted,
    this.lastCompleted,
    this.branchesExplored = const [],
    this.vocabularyUsed = const {},
    this.grammarPoints = const {},
    this.totalTimeSpent = 0,
    this.isMastered = false,
    this.streak = 0,
  });

  ScenarioProgress copyWith({
    String? scenarioId,
    String? scenarioName,
    String? language,
    String? category,
    String? difficulty,
    int? timesCompleted,
    double? averageAccuracy,
    double? averageFluency,
    int? bestScore,
    DateTime? firstCompleted,
    DateTime? lastCompleted,
    List<String>? branchesExplored,
    Map<String, int>? vocabularyUsed,
    Map<String, int>? grammarPoints,
    int? totalTimeSpent,
    bool? isMastered,
    int? streak,
  }) {
    return ScenarioProgress(
      scenarioId: scenarioId ?? this.scenarioId,
      scenarioName: scenarioName ?? this.scenarioName,
      language: language ?? this.language,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      timesCompleted: timesCompleted ?? this.timesCompleted,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      averageFluency: averageFluency ?? this.averageFluency,
      bestScore: bestScore ?? this.bestScore,
      firstCompleted: firstCompleted ?? this.firstCompleted,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      branchesExplored: branchesExplored ?? this.branchesExplored,
      vocabularyUsed: vocabularyUsed ?? this.vocabularyUsed,
      grammarPoints: grammarPoints ?? this.grammarPoints,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      isMastered: isMastered ?? this.isMastered,
      streak: streak ?? this.streak,
    );
  }

  Map<String, dynamic> toJson() => {
        'scenario_id': scenarioId,
        'scenario_name': scenarioName,
        'language': language,
        'category': category,
        'difficulty': difficulty,
        'times_completed': timesCompleted,
        'average_accuracy': averageAccuracy,
        'average_fluency': averageFluency,
        'best_score': bestScore,
        'first_completed': firstCompleted?.toIso8601String(),
        'last_completed': lastCompleted?.toIso8601String(),
        'branches_explored': branchesExplored,
        'vocabulary_used': vocabularyUsed,
        'grammar_points': grammarPoints,
        'total_time_spent': totalTimeSpent,
        'is_mastered': isMastered,
        'streak': streak,
      };

  factory ScenarioProgress.fromJson(Map<String, dynamic> json) {
    return ScenarioProgress(
      scenarioId: json['scenario_id'] ?? '',
      scenarioName: json['scenario_name'] ?? '',
      language: json['language'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'A1',
      timesCompleted: json['times_completed'] ?? 0,
      averageAccuracy: (json['average_accuracy'] ?? 0.0).toDouble(),
      averageFluency: (json['average_fluency'] ?? 0.0).toDouble(),
      bestScore: json['best_score'] ?? 0,
      firstCompleted: json['first_completed'] != null
          ? DateTime.parse(json['first_completed'])
          : null,
      lastCompleted: json['last_completed'] != null
          ? DateTime.parse(json['last_completed'])
          : null,
      branchesExplored: List<String>.from(json['branches_explored'] ?? []),
      vocabularyUsed: Map<String, int>.from(json['vocabulary_used'] ?? {}),
      grammarPoints: Map<String, int>.from(json['grammar_points'] ?? {}),
      totalTimeSpent: json['total_time_spent'] ?? 0,
      isMastered: json['is_mastered'] ?? false,
      streak: json['streak'] ?? 0,
    );
  }
}

/// Roleplay Session Result
class RoleplaySessionResult {
  final String scenarioId;
  final String language;
  final int turnCount;
  final double accuracy;
  final double fluency;
  final int score;
  final List<String> branchesTaken;
  final List<String> vocabularyLearned;
  final List<String> grammarPoints;
  final List<String> corrections;
  final int timeSpent; // in seconds
  final DateTime completedAt;
  final Map<String, dynamic> metadata;

  RoleplaySessionResult({
    required this.scenarioId,
    required this.language,
    required this.turnCount,
    required this.accuracy,
    required this.fluency,
    required this.score,
    this.branchesTaken = const [],
    this.vocabularyLearned = const [],
    this.grammarPoints = const [],
    this.corrections = const [],
    required this.timeSpent,
    required this.completedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'scenario_id': scenarioId,
        'language': language,
        'turn_count': turnCount,
        'accuracy': accuracy,
        'fluency': fluency,
        'score': score,
        'branches_taken': branchesTaken,
        'vocabulary_learned': vocabularyLearned,
        'grammar_points': grammarPoints,
        'corrections': corrections,
        'time_spent': timeSpent,
        'completed_at': completedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory RoleplaySessionResult.fromJson(Map<String, dynamic> json) {
    return RoleplaySessionResult(
      scenarioId: json['scenario_id'] ?? '',
      language: json['language'] ?? '',
      turnCount: json['turn_count'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      fluency: (json['fluency'] ?? 0.0).toDouble(),
      score: json['score'] ?? 0,
      branchesTaken: List<String>.from(json['branches_taken'] ?? []),
      vocabularyLearned: List<String>.from(json['vocabulary_learned'] ?? []),
      grammarPoints: List<String>.from(json['grammar_points'] ?? []),
      corrections: List<String>.from(json['corrections'] ?? []),
      timeSpent: json['time_spent'] ?? 0,
      completedAt: DateTime.parse(json['completed_at']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Roleplay Progress Summary
class RoleplayProgress {
  final Map<String, ScenarioProgress> scenarios; // scenarioId -> progress
  final String currentDifficulty;
  final int totalScenariosCompleted;
  final double averageAccuracy;
  final double averageFluency;
  final List<String> masteredScenarios;
  final Map<String, int> categoryProgress; // category -> count completed
  final Map<String, int> difficultyProgress; // difficulty -> count completed
  final int totalTimeSpent; // in seconds
  final int currentStreak;
  final DateTime? lastActivity;

  RoleplayProgress({
    this.scenarios = const {},
    this.currentDifficulty = 'A1',
    this.totalScenariosCompleted = 0,
    this.averageAccuracy = 0.0,
    this.averageFluency = 0.0,
    this.masteredScenarios = const [],
    this.categoryProgress = const {},
    this.difficultyProgress = const {},
    this.totalTimeSpent = 0,
    this.currentStreak = 0,
    this.lastActivity,
  });

  RoleplayProgress copyWith({
    Map<String, ScenarioProgress>? scenarios,
    String? currentDifficulty,
    int? totalScenariosCompleted,
    double? averageAccuracy,
    double? averageFluency,
    List<String>? masteredScenarios,
    Map<String, int>? categoryProgress,
    Map<String, int>? difficultyProgress,
    int? totalTimeSpent,
    int? currentStreak,
    DateTime? lastActivity,
  }) {
    return RoleplayProgress(
      scenarios: scenarios ?? this.scenarios,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      totalScenariosCompleted: totalScenariosCompleted ?? this.totalScenariosCompleted,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      averageFluency: averageFluency ?? this.averageFluency,
      masteredScenarios: masteredScenarios ?? this.masteredScenarios,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      difficultyProgress: difficultyProgress ?? this.difficultyProgress,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      currentStreak: currentStreak ?? this.currentStreak,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  Map<String, dynamic> toJson() => {
        'scenarios': scenarios.map((k, v) => MapEntry(k, v.toJson())),
        'current_difficulty': currentDifficulty,
        'total_scenarios_completed': totalScenariosCompleted,
        'average_accuracy': averageAccuracy,
        'average_fluency': averageFluency,
        'mastered_scenarios': masteredScenarios,
        'category_progress': categoryProgress,
        'difficulty_progress': difficultyProgress,
        'total_time_spent': totalTimeSpent,
        'current_streak': currentStreak,
        'last_activity': lastActivity?.toIso8601String(),
      };

  factory RoleplayProgress.fromJson(Map<String, dynamic> json) {
    final scenariosMap = json['scenarios'] as Map<String, dynamic>? ?? {};
    return RoleplayProgress(
      scenarios: scenariosMap.map(
        (k, v) => MapEntry(k, ScenarioProgress.fromJson(v as Map<String, dynamic>)),
      ),
      currentDifficulty: json['current_difficulty'] ?? 'A1',
      totalScenariosCompleted: json['total_scenarios_completed'] ?? 0,
      averageAccuracy: (json['average_accuracy'] ?? 0.0).toDouble(),
      averageFluency: (json['average_fluency'] ?? 0.0).toDouble(),
      masteredScenarios: List<String>.from(json['mastered_scenarios'] ?? []),
      categoryProgress: Map<String, int>.from(json['category_progress'] ?? {}),
      difficultyProgress: Map<String, int>.from(json['difficulty_progress'] ?? {}),
      totalTimeSpent: json['total_time_spent'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory RoleplayProgress.fromJsonString(String jsonString) {
    return RoleplayProgress.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

