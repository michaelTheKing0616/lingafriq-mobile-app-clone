import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PolieTutorSavedCard {
  final String targetLanguage;
  final String difficulty;
  final String conceptKey;
  final String concept;
  final String explanation;
  final String exampleTarget;
  final String exampleTransliteration;
  final String exampleEnglish;
  final String memoryTip;
  final String? watchOut;
  final String? practiceQuestion;
  final String? practiceHint;
  final DateTime savedAt;

  PolieTutorSavedCard({
    required this.targetLanguage,
    required this.difficulty,
    required this.conceptKey,
    required this.concept,
    required this.explanation,
    required this.exampleTarget,
    required this.exampleTransliteration,
    required this.exampleEnglish,
    required this.memoryTip,
    required this.watchOut,
    required this.practiceQuestion,
    required this.practiceHint,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'targetLanguage': targetLanguage,
        'difficulty': difficulty,
        'conceptKey': conceptKey,
        'concept': concept,
        'explanation': explanation,
        'exampleTarget': exampleTarget,
        'exampleTransliteration': exampleTransliteration,
        'exampleEnglish': exampleEnglish,
        'memoryTip': memoryTip,
        'watchOut': watchOut,
        'practiceQuestion': practiceQuestion,
        'practiceHint': practiceHint,
        'savedAt': savedAt.toIso8601String(),
      };

  static PolieTutorSavedCard? fromJson(Map<String, dynamic> json) {
    try {
      return PolieTutorSavedCard(
        targetLanguage: (json['targetLanguage'] ?? '').toString(),
        difficulty: (json['difficulty'] ?? '').toString(),
        conceptKey: (json['conceptKey'] ?? '').toString(),
        concept: (json['concept'] ?? '').toString(),
        explanation: (json['explanation'] ?? '').toString(),
        exampleTarget: (json['exampleTarget'] ?? '').toString(),
        exampleTransliteration: (json['exampleTransliteration'] ?? '').toString(),
        exampleEnglish: (json['exampleEnglish'] ?? '').toString(),
        memoryTip: (json['memoryTip'] ?? '').toString(),
        watchOut: (json['watchOut'] as Object?)?.toString(),
        practiceQuestion: (json['practiceQuestion'] as Object?)?.toString(),
        practiceHint: (json['practiceHint'] as Object?)?.toString(),
        savedAt: DateTime.tryParse((json['savedAt'] ?? '').toString()) ??
            DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

class PolieTutorSavedCardsService {
  PolieTutorSavedCardsService._();

  static const String _cardsKey = 'polie_tutor_saved_cards_v1';

  static String _seenKey(String targetLanguage, String difficulty) =>
      'polie_tutor_seen_concepts_v1:${targetLanguage.trim().toLowerCase()}:${difficulty.trim().toLowerCase()}';

  static Future<List<String>> loadSeenConceptKeys({
    required String targetLanguage,
    required String difficulty,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_seenKey(targetLanguage, difficulty));
    return list ?? const <String>[];
  }

  static Future<void> addSeenConceptKey({
    required String targetLanguage,
    required String difficulty,
    required String conceptKey,
    int maxItems = 200,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _seenKey(targetLanguage, difficulty);
    final existing = prefs.getStringList(key) ?? <String>[];
    final normalized = conceptKey.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final next = <String>{normalized, ...existing}.toList();
    if (next.length > maxItems) next.removeRange(maxItems, next.length);
    await prefs.setStringList(key, next);
  }

  static Future<List<PolieTutorSavedCard>> loadSavedCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cardsKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <PolieTutorSavedCard>[];
      for (final item in decoded) {
        if (item is Map) {
          final card = PolieTutorSavedCard.fromJson(item.cast<String, dynamic>());
          if (card != null) out.add(card);
        }
      }
      // Most recent first
      out.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return out;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveCard(PolieTutorSavedCard card) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadSavedCards();
    final deduped = <PolieTutorSavedCard>[
      card,
      ...existing.where((c) => c.conceptKey != card.conceptKey),
    ];
    await prefs.setString(
      _cardsKey,
      jsonEncode(deduped.map((c) => c.toJson()).toList()),
    );
  }

  static Future<void> removeCard(String conceptKey) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadSavedCards();
    final next = existing.where((c) => c.conceptKey != conceptKey).toList();
    await prefs.setString(
      _cardsKey,
      jsonEncode(next.map((c) => c.toJson()).toList()),
    );
  }

  static Future<bool> isSaved(String conceptKey) async {
    final existing = await loadSavedCards();
    return existing.any((c) => c.conceptKey == conceptKey);
  }
}

