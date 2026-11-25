import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/lens_word_card.dart';
import 'package:lingafriq/services/lens/lens_collection_service.dart';
import 'package:lingafriq/services/learning/living_dictionary_service.dart';
import 'package:lingafriq/services/learning/spaced_repetition_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

LensWordCard _sampleCard({String lexemeId = 'yo.lex.book'}) {
  return LensWordCard(
    lexemeId: lexemeId,
    language: 'yo',
    word: 'ìwé',
    objectSetId: 'afr.book',
    audio: const LensWordCardAudio(kind: LensWordCardAudioKind.noRecordingYet),
  );
}

void main() {
  group('lensCollectionFsrsItemId', () {
    test('prefixes verified lexeme id', () {
      expect(lensCollectionFsrsItemId('yo.lex.a'), 'lens:yo.lex.a');
    });
  });

  group('LensCollectionService', () {
    const userId = 'user_lens_909';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      SpacedRepetitionService().clearUserCards(userId);
    });

    test('dedupes on second save', () async {
      final svc = LensCollectionService();
      final first = await svc.saveWordCard(
        userId: userId,
        card: _sampleCard(),
        attemptServerSync: false,
      );
      expect(first.created, isTrue);

      final second = await svc.saveWordCard(
        userId: userId,
        card: _sampleCard(),
        attemptServerSync: false,
      );
      expect(second.created, isFalse);
      expect(second.item.verifiedLexemeId, first.item.verifiedLexemeId);

      final list = await svc.listForUser(userId);
      expect(list.length, 1);
    });

    test('enrols FSRS with initial due date', () async {
      final svc = LensCollectionService();
      final before = DateTime.now();
      final result = await svc.saveWordCard(
        userId: userId,
        card: _sampleCard(lexemeId: 'yo.lex.fsrs'),
        attemptServerSync: false,
      );
      expect(result.item.fsrsDueAt.isBefore(before.add(const Duration(days: 1))), isTrue);

      final sr = SpacedRepetitionService();
      await sr.initializeUser(userId);
      final card = sr.getOrCreateCard(userId, lensCollectionFsrsItemId('yo.lex.fsrs'));
      expect(card.nextReview, result.item.fsrsDueAt.toLocal());
    });

    test('offline save stays pending then flushes via stub living dictionary', () async {
      final calls = <Map<String, String>>[];
      final living = _StubLivingDictionary(onAdd: (lang, lemma) {
        calls.add({'language': lang, 'lemma': lemma});
        return {'_id': 'living-1', 'verified_lexeme_id': 'yo.lex.book'};
      });

      final svc = LensCollectionService(livingDictionary: living);
      final offline = await svc.saveWordCard(
        userId: userId,
        card: _sampleCard(),
        attemptServerSync: false,
      );
      expect(offline.item.syncState, LensCollectionSyncState.pending);

      final flushed = await svc.flushPendingSync(userId: userId);
      expect(flushed, 1);
      expect(calls.length, 1);

      final list = await svc.listForUser(userId);
      expect(list.single.syncState, LensCollectionSyncState.synced);
      expect(list.single.livingEntryId, 'living-1');
    });
  });
}

class _StubLivingDictionary extends LivingDictionaryService {
  _StubLivingDictionary({
    required this.onAdd,
  });

  final Map<String, dynamic> Function(String language, String lemma) onAdd;

  @override
  Future<Map<String, dynamic>> addEntry({
    required String language,
    required String lemma,
    String? translation,
    String? sourceMediaId,
    int? startMs,
    int? endMs,
    String? context,
    bool idiom = false,
    bool consentAcknowledged = true,
  }) async {
    return onAdd(language, lemma);
  }

  @override
  Future<void> clearListCaches() async {}
}
