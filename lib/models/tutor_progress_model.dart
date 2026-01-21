/// Tutor Progress Model
/// Tracks tutor mode learning progress, CEFR advancement, and adaptive difficulty
import 'dart:convert';

/// Tutor Session Result
class TutorSessionResult {
  final String sessionId;
  final String language;
  final String cefrLevel;
  final List<TutorInteraction> interactions;
  final double overallScore;
  final Map<String, double> skillScores; // grammar, pronunciation, vocabulary, comprehension
  final List<String> topicsCovered;
  final List<String> vocabularyLearned;
  final List<String> grammarPoints;
  final int timeSpent; // in seconds
  final DateTime completedAt;
  final Map<String, dynamic> metadata;

  TutorSessionResult({
    required this.sessionId,
    required this.language,
    required this.cefrLevel,
    this.interactions = const [],
    required this.overallScore,
    this.skillScores = const {},
    this.topicsCovered = const [],
    this.vocabularyLearned = const [],
    this.grammarPoints = const [],
    required this.timeSpent,
    required this.completedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'language': language,
        'cefr_level': cefrLevel,
        'interactions': interactions.map((i) => i.toJson()).toList(),
        'overall_score': overallScore,
        'skill_scores': skillScores,
        'topics_covered': topicsCovered,
        'vocabulary_learned': vocabularyLearned,
        'grammar_points': grammarPoints,
        'time_spent': timeSpent,
        'completed_at': completedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory TutorSessionResult.fromJson(Map<String, dynamic> json) {
    return TutorSessionResult(
      sessionId: json['session_id'] ?? '',
      language: json['language'] ?? '',
      cefrLevel: json['cefr_level'] ?? 'A1',
      interactions: (json['interactions'] as List?)
              ?.map((i) => TutorInteraction.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      overallScore: (json['overall_score'] ?? 0.0).toDouble(),
      skillScores: Map<String, double>.from(
        (json['skill_scores'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
      ),
      topicsCovered: List<String>.from(json['topics_covered'] ?? []),
      vocabularyLearned: List<String>.from(json['vocabulary_learned'] ?? []),
      grammarPoints: List<String>.from(json['grammar_points'] ?? []),
      timeSpent: json['time_spent'] ?? 0,
      completedAt: DateTime.parse(json['completed_at']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Tutor Interaction
class TutorInteraction {
  final String type; // 'question', 'explanation', 'exercise', 'correction'
  final String content;
  final String? userResponse;
  final double? score;
  final String? feedback;
  final DateTime timestamp;

  TutorInteraction({
    required this.type,
    required this.content,
    this.userResponse,
    this.score,
    this.feedback,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'content': content,
        if (userResponse != null) 'user_response': userResponse,
        if (score != null) 'score': score,
        if (feedback != null) 'feedback': feedback,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TutorInteraction.fromJson(Map<String, dynamic> json) {
    return TutorInteraction(
      type: json['type'] ?? '',
      content: json['content'] ?? '',
      userResponse: json['user_response'],
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      feedback: json['feedback'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Tutor Progress
class TutorProgress {
  final String language;
  final String currentCefrLevel;
  final double cefrScore; // 0.0 to 100.0
  final Map<String, double> skillLevels; // grammar, pronunciation, vocabulary, comprehension
  final Map<String, int> topicsMastered; // topic -> mastery count
  final Map<String, int> vocabularyMastered; // word -> mastery count
  final Map<String, int> grammarPointsMastered; // grammar point -> mastery count
  final List<TutorSessionResult> recentSessions;
  final int totalSessions;
  final double averageScore;
  final int totalTimeSpent; // in seconds
  final DateTime? lastActivity;
  final Map<String, dynamic> adaptiveSettings;

  TutorProgress({
    required this.language,
    this.currentCefrLevel = 'A1',
    this.cefrScore = 0.0,
    this.skillLevels = const {},
    this.topicsMastered = const {},
    this.vocabularyMastered = const {},
    this.grammarPointsMastered = const {},
    this.recentSessions = const [],
    this.totalSessions = 0,
    this.averageScore = 0.0,
    this.totalTimeSpent = 0,
    this.lastActivity,
    this.adaptiveSettings = const {},
  });

  TutorProgress copyWith({
    String? language,
    String? currentCefrLevel,
    double? cefrScore,
    Map<String, double>? skillLevels,
    Map<String, int>? topicsMastered,
    Map<String, int>? vocabularyMastered,
    Map<String, int>? grammarPointsMastered,
    List<TutorSessionResult>? recentSessions,
    int? totalSessions,
    double? averageScore,
    int? totalTimeSpent,
    DateTime? lastActivity,
    Map<String, dynamic>? adaptiveSettings,
  }) {
    return TutorProgress(
      language: language ?? this.language,
      currentCefrLevel: currentCefrLevel ?? this.currentCefrLevel,
      cefrScore: cefrScore ?? this.cefrScore,
      skillLevels: skillLevels ?? this.skillLevels,
      topicsMastered: topicsMastered ?? this.topicsMastered,
      vocabularyMastered: vocabularyMastered ?? this.vocabularyMastered,
      grammarPointsMastered: grammarPointsMastered ?? this.grammarPointsMastered,
      recentSessions: recentSessions ?? this.recentSessions,
      totalSessions: totalSessions ?? this.totalSessions,
      averageScore: averageScore ?? this.averageScore,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      lastActivity: lastActivity ?? this.lastActivity,
      adaptiveSettings: adaptiveSettings ?? this.adaptiveSettings,
    );
  }

  /// Get recommended next CEFR level
  String getRecommendedNextLevel() {
    const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final currentIndex = levels.indexOf(currentCefrLevel);
    if (currentIndex >= 0 && currentIndex < levels.length - 1) {
      // Check if ready to advance (score > 80% and all skills > 70%)
      if (cefrScore >= 80.0) {
        final allSkillsGood = skillLevels.values.every((score) => score >= 70.0);
        if (allSkillsGood) {
          return levels[currentIndex + 1];
        }
      }
    }
    return currentCefrLevel;
  }

  /// Get weak areas that need practice
  List<String> getWeakAreas() {
    final weak = <String>[];
    skillLevels.forEach((skill, score) {
      if (score < 60.0) {
        weak.add(skill);
      }
    });
    return weak;
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'current_cefr_level': currentCefrLevel,
        'cefr_score': cefrScore,
        'skill_levels': skillLevels,
        'topics_mastered': topicsMastered,
        'vocabulary_mastered': vocabularyMastered,
        'grammar_points_mastered': grammarPointsMastered,
        'recent_sessions': recentSessions.map((s) => s.toJson()).toList(),
        'total_sessions': totalSessions,
        'average_score': averageScore,
        'total_time_spent': totalTimeSpent,
        if (lastActivity != null) 'last_activity': lastActivity!.toIso8601String(),
        'adaptive_settings': adaptiveSettings,
      };

  factory TutorProgress.fromJson(Map<String, dynamic> json) {
    return TutorProgress(
      language: json['language'] ?? '',
      currentCefrLevel: json['current_cefr_level'] ?? 'A1',
      cefrScore: (json['cefr_score'] ?? 0.0).toDouble(),
      skillLevels: Map<String, double>.from(
        (json['skill_levels'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
      ),
      topicsMastered: Map<String, int>.from(
        (json['topics_mastered'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {},
      ),
      vocabularyMastered: Map<String, int>.from(
        (json['vocabulary_mastered'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {},
      ),
      grammarPointsMastered: Map<String, int>.from(
        (json['grammar_points_mastered'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {},
      ),
      recentSessions: (json['recent_sessions'] as List?)
              ?.map((s) => TutorSessionResult.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      totalSessions: json['total_sessions'] ?? 0,
      averageScore: (json['average_score'] ?? 0.0).toDouble(),
      totalTimeSpent: json['total_time_spent'] ?? 0,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
      adaptiveSettings: Map<String, dynamic>.from(json['adaptive_settings'] ?? {}),
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory TutorProgress.fromJsonString(String jsonString) {
    return TutorProgress.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

