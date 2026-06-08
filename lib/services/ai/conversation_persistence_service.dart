// Conversation Persistence Service
//
// Persists Polie AI Chat conversations locally so users see their full
// history across app restarts and crashes. Syncs each conversation to the
// backend (POST /api/v2/polie/conversation/* endpoints) so users get the
// same history on every device.
//
// Storage layout:
//   Hive box `polie_conversations` keyed by conversationId, holding a JSON-
//   serialized [ConversationDoc].
//
// Reliability:
//   - Writes are best-effort; UI does not block on disk.
//   - Server sync runs in the background; failure does not lose local state.
//   - Reads are O(1) lookup by conversationId.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:lingafriq/utils/api_service.dart';

class PersistedVocab {
  final String word;
  final String meaning;
  const PersistedVocab({required this.word, required this.meaning});
  Map<String, dynamic> toJson() => {'word': word, 'meaning': meaning};
  factory PersistedVocab.fromJson(Map<String, dynamic> j) => PersistedVocab(
        word: (j['word'] ?? '').toString(),
        meaning: (j['meaning'] ?? '').toString(),
      );
}

class PersistedCorrection {
  final String tier;
  final bool hasCorrection;
  final bool wasCorrect;
  final String? correction;
  final String note;
  const PersistedCorrection({
    required this.tier,
    required this.hasCorrection,
    required this.wasCorrect,
    required this.correction,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'tier': tier,
        'hasCorrection': hasCorrection,
        'wasCorrect': wasCorrect,
        'correction': correction,
        'note': note,
      };

  factory PersistedCorrection.fromJson(Map<String, dynamic> j) {
    final t = (j['tier'] ?? 'correct').toString();
    return PersistedCorrection(
      tier: (t == 'close' || t == 'incorrect') ? t : 'correct',
      hasCorrection: j['hasCorrection'] == true,
      wasCorrect: j['wasCorrect'] != false,
      correction: (j['correction'] is String && (j['correction'] as String).isNotEmpty)
          ? j['correction'] as String
          : null,
      note: (j['note'] ?? '').toString(),
    );
  }
}

class PersistedTurn {
  final String role; // 'user' | 'assistant' | 'assistant_error'
  final String text;
  final String language;
  final String? englishTranslation;
  final PersistedCorrection? correction;
  final List<String> suggestedReplies;
  final List<PersistedVocab> newVocab;
  final bool isError;
  final String? errorMessage;
  final DateTime createdAt;

  const PersistedTurn({
    required this.role,
    required this.text,
    required this.language,
    this.englishTranslation,
    this.correction,
    this.suggestedReplies = const [],
    this.newVocab = const [],
    this.isError = false,
    this.errorMessage,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'language': language,
        'englishTranslation': englishTranslation,
        'correction': correction?.toJson(),
        'suggestedReplies': suggestedReplies,
        'newVocab': newVocab.map((v) => v.toJson()).toList(),
        'isError': isError,
        'errorMessage': errorMessage,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PersistedTurn.fromJson(Map<String, dynamic> j) {
    return PersistedTurn(
      role: (j['role'] ?? 'user').toString(),
      text: (j['text'] ?? '').toString(),
      language: (j['language'] ?? '').toString(),
      englishTranslation:
          (j['englishTranslation'] is String && (j['englishTranslation'] as String).isNotEmpty)
              ? j['englishTranslation'] as String
              : null,
      correction: (j['correction'] is Map<String, dynamic>)
          ? PersistedCorrection.fromJson(j['correction'] as Map<String, dynamic>)
          : null,
      suggestedReplies: (j['suggestedReplies'] is List)
          ? (j['suggestedReplies'] as List).map((e) => e.toString()).toList()
          : const <String>[],
      newVocab: (j['newVocab'] is List)
          ? (j['newVocab'] as List)
              .whereType<Map<String, dynamic>>()
              .map(PersistedVocab.fromJson)
              .toList()
          : const <PersistedVocab>[],
      isError: j['isError'] == true,
      errorMessage: (j['errorMessage'] is String) ? j['errorMessage'] as String : null,
      createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class ConversationDoc {
  final String conversationId;
  final String title;
  final String language;
  final String persona;
  final List<PersistedTurn> turns;
  final DateTime lastUpdated;
  final DateTime createdAt;

  const ConversationDoc({
    required this.conversationId,
    required this.title,
    required this.language,
    required this.persona,
    required this.turns,
    required this.lastUpdated,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'conversationId': conversationId,
        'title': title,
        'language': language,
        'persona': persona,
        'turns': turns.map((t) => t.toJson()).toList(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ConversationDoc.fromJson(Map<String, dynamic> j) {
    final turnsJson = j['turns'];
    return ConversationDoc(
      conversationId: (j['conversationId'] ?? '').toString(),
      title: (j['title'] ?? 'Conversation').toString(),
      language: (j['language'] ?? 'Yoruba').toString(),
      persona: (j['persona'] ?? 'encouraging_mentor').toString(),
      turns: (turnsJson is List)
          ? turnsJson
              .whereType<Map<String, dynamic>>()
              .map(PersistedTurn.fromJson)
              .toList()
          : const <PersistedTurn>[],
      lastUpdated:
          DateTime.tryParse((j['lastUpdated'] ?? '').toString()) ?? DateTime.now(),
      createdAt:
          DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class ConversationPersistenceService {
  ConversationPersistenceService._();
  static final ConversationPersistenceService _i =
      ConversationPersistenceService._();
  factory ConversationPersistenceService() => _i;

  static const String _boxName = 'polie_conversations';
  Box<String>? _box;
  bool _initializing = false;
  final Completer<void> _ready = Completer<void>();

  /// Lazily opens the Hive box. Safe to call from app start and from each
  /// service call; only opens once.
  Future<void> ensureReady() async {
    if (_box != null) return;
    if (_initializing) return _ready.future;
    _initializing = true;
    try {
      // Hive may already be initialized by LocalDatabaseService. Calling
      // initFlutter twice is a no-op.
      await Hive.initFlutter();
      _box = await Hive.openBox<String>(_boxName);
      if (!_ready.isCompleted) _ready.complete();
    } catch (e) {
      if (!_ready.isCompleted) _ready.completeError(e);
      rethrow;
    }
  }

  /// Save (upsert) a conversation locally. Best-effort.
  Future<void> saveLocal(ConversationDoc doc) async {
    try {
      await ensureReady();
      await _box!.put(doc.conversationId, jsonEncode(doc.toJson()));
    } catch (e) {
      debugPrint('[ConversationPersistence] saveLocal failed: $e');
    }
  }

  /// Append a single turn to a conversation. If the conversation doesn't
  /// exist yet, creates a new doc with the turn as its first message.
  Future<ConversationDoc> appendTurn({
    required String conversationId,
    required String language,
    required String persona,
    required PersistedTurn turn,
    String? titleHint,
  }) async {
    await ensureReady();
    final existing = await loadLocal(conversationId);
    final now = DateTime.now();
    final ConversationDoc updated;
    if (existing == null) {
      updated = ConversationDoc(
        conversationId: conversationId,
        title: (titleHint ?? turn.text).trim().isEmpty
            ? 'Conversation'
            : (titleHint ?? turn.text).trim().substring(
                  0,
                  (titleHint ?? turn.text).trim().length > 80
                      ? 80
                      : (titleHint ?? turn.text).trim().length,
                ),
        language: language,
        persona: persona,
        turns: [turn],
        lastUpdated: now,
        createdAt: now,
      );
    } else {
      updated = ConversationDoc(
        conversationId: existing.conversationId,
        title: existing.title,
        language: language,
        persona: persona,
        turns: [...existing.turns, turn],
        lastUpdated: now,
        createdAt: existing.createdAt,
      );
    }
    await saveLocal(updated);
    return updated;
  }

  Future<ConversationDoc?> loadLocal(String conversationId) async {
    try {
      await ensureReady();
      final raw = _box!.get(conversationId);
      if (raw == null || raw.isEmpty) return null;
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return null;
      return ConversationDoc.fromJson(j);
    } catch (e) {
      debugPrint('[ConversationPersistence] loadLocal failed: $e');
      return null;
    }
  }

  /// Returns conversations sorted by lastUpdated descending.
  Future<List<ConversationDoc>> listLocal({int limit = 50}) async {
    try {
      await ensureReady();
      final values = _box!.values
          .map((raw) {
            try {
              final j = jsonDecode(raw);
              if (j is Map<String, dynamic>) return ConversationDoc.fromJson(j);
            } catch (_) {}
            return null;
          })
          .whereType<ConversationDoc>()
          .toList()
        ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
      return values.take(limit).toList();
    } catch (e) {
      debugPrint('[ConversationPersistence] listLocal failed: $e');
      return const [];
    }
  }

  Future<void> deleteLocal(String conversationId) async {
    try {
      await ensureReady();
      await _box!.delete(conversationId);
    } catch (e) {
      debugPrint('[ConversationPersistence] deleteLocal failed: $e');
    }
  }

  /// Fetches the latest server-side state for [conversationId] and overwrites
  /// the local cache. Returns null if the server has nothing for it.
  Future<ConversationDoc?> fetchFromServer(String conversationId) async {
    try {
      await ApiService.initialize();
      final resp = await ApiService.get(
        '/api/v2/polie/conversation/$conversationId',
      );
      if (resp.statusCode != 200 || resp.data is! Map) return null;
      final data = (resp.data as Map).cast<String, dynamic>();
      final messages = (data['messages'] is List)
          ? (data['messages'] as List).whereType<Map<String, dynamic>>().toList()
          : const <Map<String, dynamic>>[];
      final turns = messages.map((m) {
        return PersistedTurn(
          role: (m['role'] ?? 'user').toString(),
          text: (m['messageTarget'] ?? '').toString(),
          language: (m['language'] ?? data['language'] ?? '').toString(),
          englishTranslation: (m['englishTranslation'] is String &&
                  (m['englishTranslation'] as String).isNotEmpty)
              ? m['englishTranslation'] as String
              : null,
          correction: (m['correction'] is Map<String, dynamic>)
              ? PersistedCorrection.fromJson(m['correction'] as Map<String, dynamic>)
              : null,
          suggestedReplies: (m['suggestedReplies'] is List)
              ? (m['suggestedReplies'] as List).map((e) => e.toString()).toList()
              : const <String>[],
          newVocab: (m['newVocab'] is List)
              ? (m['newVocab'] as List)
                  .whereType<Map<String, dynamic>>()
                  .map(PersistedVocab.fromJson)
                  .toList()
              : const <PersistedVocab>[],
          isError: m['isError'] == true,
          errorMessage: (m['errorReason'] is String && (m['errorReason'] as String).isNotEmpty)
              ? m['errorReason'] as String
              : null,
          createdAt:
              DateTime.tryParse((m['createdAt'] ?? '').toString()) ?? DateTime.now(),
        );
      }).toList();
      final doc = ConversationDoc(
        conversationId: (data['conversationId'] ?? conversationId).toString(),
        title: (data['title'] ?? 'Conversation').toString(),
        language: (data['language'] ?? 'Yoruba').toString(),
        persona: (data['persona'] ?? 'encouraging_mentor').toString(),
        turns: turns,
        lastUpdated:
            DateTime.tryParse((data['lastUpdated'] ?? '').toString()) ?? DateTime.now(),
        createdAt:
            DateTime.tryParse((data['createdAt'] ?? '').toString()) ?? DateTime.now(),
      );
      await saveLocal(doc);
      return doc;
    } catch (e) {
      debugPrint('[ConversationPersistence] fetchFromServer failed: $e');
      return null;
    }
  }

  /// Returns the most-recent conversation (server first, falling back to
  /// local cache). Used on app open to restore the user's last chat.
  Future<ConversationDoc?> restoreMostRecent() async {
    try {
      await ApiService.initialize();
      final resp = await ApiService.get(
        '/api/v2/polie/conversation',
        queryParameters: {'limit': 1},
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        final items = (resp.data['items'] is List)
            ? (resp.data['items'] as List).whereType<Map<String, dynamic>>().toList()
            : const <Map<String, dynamic>>[];
        if (items.isNotEmpty) {
          final cid = (items.first['conversationId'] ?? '').toString();
          if (cid.isNotEmpty) {
            final doc = await fetchFromServer(cid);
            if (doc != null) return doc;
          }
        }
      }
    } catch (e) {
      debugPrint('[ConversationPersistence] restoreMostRecent server failed: $e');
    }
    final local = await listLocal(limit: 1);
    return local.isEmpty ? null : local.first;
  }
}
