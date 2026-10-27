import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/lexicon_search_service.dart';
import 'package:lingafriq/services/offline/lexicon_pack_service.dart';

VerifiedLexeme _lexeme({
  required String id,
  required String lemma,
  required String standard,
}) {
  return VerifiedLexeme(
    lexemeId: id,
    language: 'yo',
    verificationStatus: 'expert_reviewed',
    lemma: lemma,
    standardOrthography: standard,
    exampleSentence: null,
    audioUris: const [],
    raw: {
      'id': id,
      'lemma': lemma,
      'orthography': {'standard': standard},
    },
  );
}

List<LexiconPackEntry> _packEntries() => [
      LexiconPackEntry(
        lexemeId: 'yo.lex.aa',
        lemma: 'báwo',
        standard: 'báwo',
        adjustedRank: 1,
        audioUris: const [],
      ),
      LexiconPackEntry(
        lexemeId: 'yo.lex.bb',
        lemma: 'ọkọ',
        standard: 'ọkọ̀',
        adjustedRank: 2,
        audioUris: const [],
      ),
    ];

void main() {
  group('lexiconSearchFieldMatches', () {
    test('matches tone-marked forms when query omits diacritics', () {
      expect(lexiconSearchFieldMatches('ọkọ̀', 'oko'), isTrue);
      expect(lexiconSearchFieldMatches('báwo', 'baw'), isTrue);
      expect(lexiconSearchFieldMatches('báwo', 'xyz'), isFalse);
    });
  });

  group('orderGlobalSearchHits', () {
    test('lists lexicon words before lesson hits', () {
      final lexicon = [_lexeme(id: 'yo.lex.1', lemma: 'a', standard: 'a')];
      final ancillary = [
        GlobalSearchHit.lessonPlaceholder('Greetings unit'),
      ];
      final ordered = orderGlobalSearchHits(
        lexicon: lexicon,
        ancillary: ancillary,
      );
      expect(ordered.first.kind, GlobalSearchResultKind.lexiconWord);
      expect(ordered.last.kind, GlobalSearchResultKind.lesson);
    });
  });

  group('LexiconSearchService offline', () {
    late LexiconPackService pack;

    setUp(() async {
      pack = LexiconPackService();
      pack.resetForTests();
      final entries = _packEntries();
      await pack.installVerifiedPack(
        manifest: LexiconPackManifest(
          language: 'yo',
          version: '1.0.0',
          entryCount: entries.length,
          entriesSha256: lexiconPackEntriesDigest(entries),
          audioBytesEstimate: 1024,
        ),
        entries: entries,
      );
    });

    test('returns pack hits when offline', () async {
      final service = LexiconSearchService(
        languageCode: 'yo',
        packService: pack,
        assumeOffline: true,
      );
      final result = await service.search('oko');
      expect(result.offlineOnly, isTrue);
      expect(result.usedOfflinePack, isTrue);
      expect(result.hits, isNotEmpty);
      expect(result.hits.first.kind, GlobalSearchResultKind.lexiconWord);
      expect(result.hits.first.title, 'ọkọ̀');
    });

    test('diacritic-insensitive offline prefix finds ọkọ̀', () async {
      final hits = lexiconHitsFromPack(
        entries: _packEntries(),
        languageCode: 'yo',
        query: 'oko',
      );
      expect(hits.single.lexemeId, 'yo.lex.bb');
    });
  });

  group('LexiconSearchService online merge', () {
    test('prefers lexicon section ordering with injected ancillary', () async {
      final service = LexiconSearchService(
        languageCode: 'yo',
        remoteSearch: (_, __) async => [
          _lexeme(id: 'yo.lex.remote', lemma: 'ẹ kú', standard: 'ẹ kú'),
        ],
        ancillarySearch: (_, __) async => [
          GlobalSearchHit.lessonPlaceholder('Lesson stub'),
        ],
      );
      final result = await service.search('e ku');
      expect(result.hits.first.kind, GlobalSearchResultKind.lexiconWord);
      expect(
        result.hits.any((h) => h.kind == GlobalSearchResultKind.lesson),
        isTrue,
      );
    });
  });
}
