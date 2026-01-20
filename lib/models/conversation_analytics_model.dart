/// Conversation Analytics Model
/// Tracks conversation mode metrics, fluency, and topic coverage
import 'dart:convert';

/// Conversation Session
class ConversationSession {
  final String sessionId;
  final String language;
  final DateTime startTime;
  final DateTime? endTime;
  final int messageCount;
  final int wordCount;
  final List<String> topics;
  final double fluencyScore;
  final int errorCount;
  final List<String> corrections;
  final Map<String, int> vocabularyUsed;
  final Map<String, dynamic> metadata;

  ConversationSession({
    required this.sessionId,
    required this.language,
    required this.startTime,
    this.endTime,
    this.messageCount = 0,
    this.wordCount = 0,
    this.topics = const [],
    this.fluencyScore = 0.0,
    this.errorCount = 0,
    this.corrections = const [],
    this.vocabularyUsed = const {},
    this.metadata = const {},
  });

  int get durationMinutes {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inMinutes;
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'language': language,
        'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime!.toIso8601String(),
        'message_count': messageCount,
        'word_count': wordCount,
        'topics': topics,
        'fluency_score': fluencyScore,
        'error_count': errorCount,
        'corrections': corrections,
        'vocabulary_used': vocabularyUsed,
        'metadata': metadata,
      };

  factory ConversationSession.fromJson(Map<String, dynamic> json) {
    return ConversationSession(
      sessionId: json['session_id'] ?? '',
      language: json['language'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      messageCount: json['message_count'] ?? 0,
      wordCount: json['word_count'] ?? 0,
      topics: List<String>.from(json['topics'] ?? []),
      fluencyScore: (json['fluency_score'] ?? 0.0).toDouble(),
      errorCount: json['error_count'] ?? 0,
      corrections: List<String>.from(json['corrections'] ?? []),
      vocabularyUsed: Map<String, int>.from(
        (json['vocabulary_used'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {},
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Conversation Analytics
class ConversationAnalytics {
  final String language;
  final List<ConversationSession> sessions;
  final double averageFluency;
  final int totalMessages;
  final int totalWords;
  final Set<String> allTopics;
  final Map<String, int> topicFrequency;
  final Map<String, int> vocabularyFrequency;
  final double averageSessionLength; // in minutes
  final DateTime? lastActivity;

  ConversationAnalytics({
    required this.language,
    this.sessions = const [],
    this.averageFluency = 0.0,
    this.totalMessages = 0,
    this.totalWords = 0,
    this.allTopics = const {},
    this.topicFrequency = const {},
    this.vocabularyFrequency = const {},
    this.averageSessionLength = 0.0,
    this.lastActivity,
  });

  ConversationAnalytics copyWith({
    String? language,
    List<ConversationSession>? sessions,
    double? averageFluency,
    int? totalMessages,
    int? totalWords,
    Set<String>? allTopics,
    Map<String, int>? topicFrequency,
    Map<String, int>? vocabularyFrequency,
    double? averageSessionLength,
    DateTime? lastActivity,
  }) {
    return ConversationAnalytics(
      language: language ?? this.language,
      sessions: sessions ?? this.sessions,
      averageFluency: averageFluency ?? this.averageFluency,
      totalMessages: totalMessages ?? this.totalMessages,
      totalWords: totalWords ?? this.totalWords,
      allTopics: allTopics ?? this.allTopics,
      topicFrequency: topicFrequency ?? this.topicFrequency,
      vocabularyFrequency: vocabularyFrequency ?? this.vocabularyFrequency,
      averageSessionLength: averageSessionLength ?? this.averageSessionLength,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  /// Get most common topics
  List<MapEntry<String, int>> getTopTopics({int limit = 5}) {
    final sorted = topicFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Get most used vocabulary
  List<MapEntry<String, int>> getTopVocabulary({int limit = 10}) {
    final sorted = vocabularyFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'average_fluency': averageFluency,
        'total_messages': totalMessages,
        'total_words': totalWords,
        'all_topics': allTopics.toList(),
        'topic_frequency': topicFrequency,
        'vocabulary_frequency': vocabularyFrequency,
        'average_session_length': averageSessionLength,
        if (lastActivity != null) 'last_activity': lastActivity!.toIso8601String(),
      };

  factory ConversationAnalytics.fromJson(Map<String, dynamic> json) {
    final sessions = (json['sessions'] as List?)
            ?.map((s) => ConversationSession.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    // Calculate derived metrics
    final avgFluency = sessions.isEmpty
        ? 0.0
        : sessions.fold<double>(0.0, (sum, s) => sum + s.fluencyScore) / sessions.length;
    final totalMsgs = sessions.fold<int>(0, (sum, s) => sum + s.messageCount);
    final totalWrds = sessions.fold<int>(0, (sum, s) => sum + s.wordCount);
    final allTopicsSet = sessions
        .expand((s) => s.topics)
        .toSet();
    final topicFreq = <String, int>{};
    final vocabFreq = <String, int>{};

    for (final session in sessions) {
      for (final topic in session.topics) {
        topicFreq[topic] = (topicFreq[topic] ?? 0) + 1;
      }
      session.vocabularyUsed.forEach((word, count) {
        vocabFreq[word] = (vocabFreq[word] ?? 0) + count;
      });
    }

    final avgSessionLength = sessions.isEmpty
        ? 0.0
        : sessions.fold<double>(0.0, (sum, s) => sum + s.durationMinutes) / sessions.length;

    return ConversationAnalytics(
      language: json['language'] ?? '',
      sessions: sessions,
      averageFluency: avgFluency,
      totalMessages: totalMsgs,
      totalWords: totalWrds,
      allTopics: allTopicsSet,
      topicFrequency: topicFreq,
      vocabularyFrequency: vocabFreq,
      averageSessionLength: avgSessionLength,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory ConversationAnalytics.fromJsonString(String jsonString) {
    return ConversationAnalytics.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

