import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/offline/lexicon_pack_service.dart';

List<LexiconPackEntry> _sampleEntries() => [
      LexiconPackEntry(
        lexemeId: 'yo.lex.aa',
        lemma: 'báwo',
        standard: 'báwo',
        adjustedRank: 1,
        audioUris: ['audio/yo/abc123.wav'],
      ),
      LexiconPackEntry(
        lexemeId: 'yo.lex.bb',
        lemma: 'ọkọ',
        standard: 'ọkọ̀',
        adjustedRank: 2,
        audioUris: const [],
      ),
    ];

LexiconPackManifest _manifestFor(List<LexiconPackEntry> entries, {String version = '1.0.0'}) {
  return LexiconPackManifest(
    language: 'yo',
    version: version,
    entryCount: entries.length,
    entriesSha256: lexiconPackEntriesDigest(entries),
    audioBytesEstimate: 96_000,
  );
}

void main() {
  group('lexicon pack integrity', () {
    test('passes when digest matches entry payload', () {
      final entries = _sampleEntries();
      final manifest = _manifestFor(entries);
      expect(verifyLexiconPackIntegrity(manifest, entries), isTrue);
    });

    test('fails when entry count drifts', () {
      final entries = _sampleEntries();
      final manifest = _manifestFor(entries);
      expect(verifyLexiconPackIntegrity(manifest, entries.sublist(0, 1)), isFalse);
    });
  });

  group('LexiconPackService', () {
    late LexiconPackService service;

    setUp(() {
      service = LexiconPackService(availableBytesProvider: () async => 200 * 1024 * 1024);
      service.resetForTests();
    });

    test('installs verified pack for offline lookup', () async {
      final entries = _sampleEntries();
      final manifest = _manifestFor(entries);
      await service.installVerifiedPack(manifest: manifest, entries: entries);

      expect(service.lookupLemma('báwo')?.lexemeId, 'yo.lex.aa');
      expect(service.searchPrefix('ọ').single.lexemeId, 'yo.lex.bb');
      expect(service.lookupLexemeId('yo.lex.aa')?.audioUris, isNotEmpty);
    });

    test('rejects corrupt pack before swap', () async {
      final entries = _sampleEntries();
      final manifest = LexiconPackManifest(
        language: 'yo',
        version: '1.0.0',
        entryCount: entries.length,
        entriesSha256: 'deadbeef',
        audioBytesEstimate: 1,
      );
      await expectLater(
        () => service.installVerifiedPack(manifest: manifest, entries: entries),
        throwsA(isA<LexiconPackCorruptException>()),
      );
    });

    test('warns before download when storage is low', () async {
      service = LexiconPackService(
        lowStorageThresholdBytes: 100 * 1024 * 1024,
        availableBytesProvider: () async => 1024,
      );
      final manifest = _manifestFor(_sampleEntries());
      await expectLater(
        () => service.assertStorageForDownload(manifest),
        throwsA(isA<LexiconPackLowStorageWarning>()),
      );
    });

    test('incremental sync keeps old pack until merged payload verifies', () async {
      final base = _sampleEntries();
      await service.installVerifiedPack(manifest: _manifestFor(base, version: '1.0.0'), entries: base);

      final delta = [
        LexiconPackEntry(
          lexemeId: 'yo.lex.cc',
          lemma: 'ẹ',
          standard: 'ẹ',
          adjustedRank: 3,
          audioUris: const [],
        ),
      ];
      final merged = [...base, ...delta];
      final manifest = LexiconPackManifest(
        language: 'yo',
        version: '1.1.0',
        entryCount: merged.length,
        entriesSha256: lexiconPackEntriesDigest(merged),
        audioBytesEstimate: 120_000,
        baseVersion: '1.0.0',
      );

      await service.syncIncrementalPack(manifest: manifest, deltaEntries: delta);
      expect(service.lookupLemma('ẹ')?.lexemeId, 'yo.lex.cc');
      expect(service.activePack?.manifest.version, '1.1.0');
    });

    test('openActivePack surfaces corrupt installed state', () async {
      final entries = _sampleEntries();
      await service.installVerifiedPack(manifest: _manifestFor(entries), entries: entries);
      service.activePack!.entries.removeLast();
      expect(() => service.openActivePack(), throwsA(isA<LexiconPackCorruptException>()));
    });
  });
}
