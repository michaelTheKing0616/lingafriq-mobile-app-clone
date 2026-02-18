import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A single memory entry for cross-class persona context (learner + topic + summary).
class PersonaMemoryEntry {
  final String personaId;
  final String learnerId;
  final String topic;
  final String summary;
  final DateTime timestamp;
  final double relevance;

  const PersonaMemoryEntry({
    required this.personaId,
    required this.learnerId,
    required this.topic,
    required this.summary,
    required this.timestamp,
    this.relevance = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'personaId': personaId,
        'learnerId': learnerId,
        'topic': topic,
        'summary': summary,
        'timestamp': timestamp.toIso8601String(),
        'relevance': relevance,
      };

  factory PersonaMemoryEntry.fromJson(Map<String, dynamic> json) {
    return PersonaMemoryEntry(
      personaId: json['personaId'] as String? ?? '',
      learnerId: json['learnerId'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      relevance: (json['relevance'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Persistent memory across classroom sessions for persona context injection.
class CrossClassPersonaMemory {
  static CrossClassPersonaMemory? _instance;
  static CrossClassPersonaMemory get instance =>
      _instance ??= CrossClassPersonaMemory._();

  CrossClassPersonaMemory._();

  static const String _prefsKeyPrefix = 'cross_class_persona_memory_';

  final Map<String, List<PersonaMemoryEntry>> _memories = {};

  /// Store a memory from a session.
  void remember({
    required String personaId,
    required String learnerId,
    required String topic,
    required String summary,
    double relevance = 1.0,
  }) {
    final entry = PersonaMemoryEntry(
      personaId: personaId,
      learnerId: learnerId,
      topic: topic,
      summary: summary,
      timestamp: DateTime.now(),
      relevance: relevance,
    );
    _memories.putIfAbsent(personaId, () => []).add(entry);
  }

  /// Recall relevant memories for context injection.
  List<PersonaMemoryEntry> recall({
    required String personaId,
    String? learnerId,
    String? topic,
    int maxResults = 5,
  }) {
    var list = _memories[personaId] ?? [];
    if (learnerId != null) {
      list = list.where((e) => e.learnerId == learnerId).toList();
    }
    if (topic != null && topic.isNotEmpty) {
      final lower = topic.toLowerCase();
      list = list
          .where((e) =>
              e.topic.toLowerCase().contains(lower) ||
              e.summary.toLowerCase().contains(lower))
          .toList();
    }
    list = List.from(list)
      ..sort((a, b) {
        final scoreA = a.relevance * _recencyFactor(a.timestamp);
        final scoreB = b.relevance * _recencyFactor(b.timestamp);
        return scoreB.compareTo(scoreA);
      });
    return list.take(maxResults).toList();
  }

  double _recencyFactor(DateTime timestamp) {
    final days = DateTime.now().difference(timestamp).inDays;
    if (days <= 1) return 1.0;
    if (days <= 7) return 0.9;
    if (days <= 30) return 0.7;
    return 0.5;
  }

  /// Build context string for prompt injection.
  String getContextForPrompt(String personaId, {String? learnerId}) {
    final memories =
        recall(personaId: personaId, learnerId: learnerId, maxResults: 5);
    if (memories.isEmpty) return '';
    return 'Previous interactions:\n${memories.map((m) => '- ${m.summary}').join('\n')}';
  }

  /// Persist to SharedPreferences (one key per persona).
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _memories.entries) {
      final key = '$_prefsKeyPrefix${entry.key}';
      final list = entry.value.map((e) => e.toJson()).toList();
      await prefs.setString(key, jsonEncode(list));
    }
  }

  /// Load from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefsKeyPrefix));
    for (final key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) continue;
      try {
        final list = (jsonDecode(jsonStr) as List<dynamic>)
            .map((e) => PersonaMemoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        final personaId = key.substring(_prefsKeyPrefix.length);
        _memories[personaId] = list;
      } catch (_) {
        // Skip malformed entry
      }
    }
  }

  /// Keep only the last [maxEntries] per persona.
  void prune(String personaId, {int maxEntries = 50}) {
    final list = _memories[personaId];
    if (list == null || list.length <= maxEntries) return;
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _memories[personaId] = list.take(maxEntries).toList();
  }
}
