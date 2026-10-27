import 'dart:convert';

import 'package:lingafriq/models/lens_word_card.dart';
import 'package:lingafriq/services/learning/living_dictionary_service.dart';
import 'package:lingafriq/services/learning/spaced_repetition_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Visible sync state for a saved Lens word (P7-909).
enum LensCollectionSyncState {
  synced,
  pending,
  failed,
}

LensCollectionSyncState lensCollectionSyncStateFromName(String? raw) {
  switch (raw) {
    case 'synced':
      return LensCollectionSyncState.synced;
    case 'failed':
      return LensCollectionSyncState.failed;
    default:
      return LensCollectionSyncState.pending;
  }
}

/// FSRS deck id for a verified lexeme saved from Lens.
String lensCollectionFsrsItemId(String verifiedLexemeId) => 'lens:$verifiedLexemeId';

class LensCollectionItem {
  const LensCollectionItem({
    required this.verifiedLexemeId,
    required this.language,
    required this.word,
    required this.objectSetId,
    required this.savedAt,
    required this.syncState,
    required this.fsrsDueAt,
    this.livingEntryId,
  });

  final String verifiedLexemeId;
  final String language;
  final String word;
  final String objectSetId;
  final DateTime savedAt;
  final LensCollectionSyncState syncState;
  final DateTime fsrsDueAt;
  final String? livingEntryId;

  Map<String, dynamic> toJson() => {
        'verified_lexeme_id': verifiedLexemeId,
        'language': language,
        'word': word,
        'object_set_id': objectSetId,
        'saved_at': savedAt.toUtc().toIso8601String(),
        'sync_state': syncState.name,
        'fsrs_due_at': fsrsDueAt.toUtc().toIso8601String(),
        if (livingEntryId != null) 'living_entry_id': livingEntryId,
      };

  factory LensCollectionItem.fromJson(Map<String, dynamic> json) {
    return LensCollectionItem(
      verifiedLexemeId: (json['verified_lexeme_id'] ?? '').toString(),
      language: (json['language'] ?? '').toString(),
      word: (json['word'] ?? '').toString(),
      objectSetId: (json['object_set_id'] ?? '').toString(),
      savedAt: DateTime.parse(json['saved_at'] as String),
      syncState: lensCollectionSyncStateFromName(json['sync_state']?.toString()),
      fsrsDueAt: DateTime.parse(json['fsrs_due_at'] as String),
      livingEntryId: json['living_entry_id']?.toString(),
    );
  }
}

class LensCollectionSaveResult {
  const LensCollectionSaveResult({
    required this.item,
    required this.created,
  });

  final LensCollectionItem item;
  final bool created;
}

/// Offline-first Lens personal collection + FSRS enrolment (P7-909).
class LensCollectionService {
  LensCollectionService({
    SpacedRepetitionService? spacedRepetition,
    LivingDictionaryService? livingDictionary,
    Future<SharedPreferences> Function()? prefsLoader,
  })  : _sr = spacedRepetition ?? SpacedRepetitionService(),
        _livingDictionary = livingDictionary ?? LivingDictionaryService(),
        _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  static const storageKeyPrefix = 'lens_collection_v1_';

  final SpacedRepetitionService _sr;
  final LivingDictionaryService _livingDictionary;
  final Future<SharedPreferences> Function() _prefsLoader;

  String _storageKey(String userId) => '$storageKeyPrefix$userId';

  Future<List<LensCollectionItem>> listForUser(String userId) async {
    final prefs = await _prefsLoader();
    final raw = prefs.getString(_storageKey(userId));
    if (raw == null || raw.trim().isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => LensCollectionItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.verifiedLexemeId.isNotEmpty)
        .toList();
  }

  Future<void> _persist(String userId, List<LensCollectionItem> items) async {
    final prefs = await _prefsLoader();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey(userId), encoded);
  }

  Future<LensCollectionSaveResult> saveWordCard({
    required String userId,
    required LensWordCard card,
    bool attemptServerSync = true,
  }) async {
    final verifiedId = card.lexemeId.trim();
    if (verifiedId.isEmpty) {
      throw ArgumentError('Lens word card must carry a verified lexeme id');
    }

    final existing = await listForUser(userId);
    final match = existing.where((e) => e.verifiedLexemeId == verifiedId).toList();
    if (match.isNotEmpty) {
      return LensCollectionSaveResult(item: match.first, created: false);
    }

    await _sr.initializeUser(userId);
    final srCard = _sr.getOrCreateCard(userId, lensCollectionFsrsItemId(verifiedId));

    var syncState = LensCollectionSyncState.pending;
    String? livingEntryId;

    if (attemptServerSync) {
      try {
        final entry = await _livingDictionary.addEntry(
          language: card.language,
          lemma: card.word,
          translation: card.exampleSentence,
          context: 'lens:${card.objectSetId}',
          consentAcknowledged: true,
        );
        livingEntryId = entry['_id']?.toString() ?? entry['id']?.toString();
        syncState = LensCollectionSyncState.synced;
        await _livingDictionary.clearListCaches();
      } catch (_) {
        syncState = LensCollectionSyncState.pending;
      }
    }

    final item = LensCollectionItem(
      verifiedLexemeId: verifiedId,
      language: card.language,
      word: card.word,
      objectSetId: card.objectSetId,
      savedAt: DateTime.now().toUtc(),
      syncState: syncState,
      fsrsDueAt: srCard.nextReview.toUtc(),
      livingEntryId: livingEntryId,
    );

    final next = [...existing, item];
    await _persist(userId, next);
    return LensCollectionSaveResult(item: item, created: true);
  }

  int pendingSyncCount(String userId, List<LensCollectionItem> items) {
    return items
        .where((e) =>
            e.syncState == LensCollectionSyncState.pending ||
            e.syncState == LensCollectionSyncState.failed)
        .length;
  }

  /// Flushes rows that still need a living-dictionary row on the server.
  Future<int> flushPendingSync({required String userId}) async {
    final items = await listForUser(userId);
    var flushed = 0;
    final updated = <LensCollectionItem>[];

    for (final item in items) {
      if (item.syncState == LensCollectionSyncState.synced) {
        updated.add(item);
        continue;
      }
      try {
        final entry = await _livingDictionary.addEntry(
          language: item.language,
          lemma: item.word,
          context: 'lens:${item.objectSetId}',
          consentAcknowledged: true,
        );
        final livingEntryId = entry['_id']?.toString() ?? entry['id']?.toString();
        updated.add(
          LensCollectionItem(
            verifiedLexemeId: item.verifiedLexemeId,
            language: item.language,
            word: item.word,
            objectSetId: item.objectSetId,
            savedAt: item.savedAt,
            syncState: LensCollectionSyncState.synced,
            fsrsDueAt: item.fsrsDueAt,
            livingEntryId: livingEntryId,
          ),
        );
        flushed++;
      } catch (_) {
        updated.add(
          LensCollectionItem(
            verifiedLexemeId: item.verifiedLexemeId,
            language: item.language,
            word: item.word,
            objectSetId: item.objectSetId,
            savedAt: item.savedAt,
            syncState: LensCollectionSyncState.failed,
            fsrsDueAt: item.fsrsDueAt,
            livingEntryId: item.livingEntryId,
          ),
        );
      }
    }

    await _persist(userId, updated);
    if (flushed > 0) {
      await _livingDictionary.clearListCaches();
    }
    return flushed;
  }
}
