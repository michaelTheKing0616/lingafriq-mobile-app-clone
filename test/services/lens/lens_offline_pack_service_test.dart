import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/lens_word_card.dart';
import 'package:lingafriq/services/lens/lens_offline_pack_service.dart';
import 'package:lingafriq/services/offline/point_and_say_queue_service.dart';

void main() {
  group('lensOfflinePackExpectedObjectCount', () {
    test('caps at 300', () {
      expect(lensOfflinePackExpectedObjectCount(400), 300);
      expect(lensOfflinePackExpectedObjectCount(4), 4);
    });
  });

  group('LensOfflinePackManifest integrity', () {
    test('round-trip write and open', () async {
      final tmp = await Directory.systemTemp.createTemp('lens_pack_');
      final svc = LensOfflinePackService(packRoot: tmp);
      final row = lensPackRowFromWordCard(
        card: const LensWordCard(
          lexemeId: 'yo.lex.test',
          language: 'yo',
          word: 'ìwé',
          objectSetId: 'afr.book',
          audio: const LensWordCardAudio(
            kind: LensWordCardAudioKind.licensedTts,
            honestyLabel: 'Synthetic voice',
          ),
        ),
      );
      await svc.writePack(language: 'yo', objects: [row]);
      final opened = await svc.openPack('yo');
      expect(opened.objects.length, 1);
      expect(opened.objects.first.objectSetId, 'afr.book');
      final card = svc.wordCardFromOpenPack(opened, 'afr.book');
      expect(card?.word, 'ìwé');
    });

    test('corrupt integrity fails open', () async {
      final tmp = await Directory.systemTemp.createTemp('lens_pack_bad_');
      final dir = Directory('${tmp.path}/yo');
      dir.createSync(recursive: true);
      File('${dir.path}/manifest.json').writeAsStringSync(jsonEncode({
        'format_version': 1,
        'language': 'yo',
        'expected_object_count': 1,
        'objects': [],
        'integrity_sha256': 'deadbeef',
      }));
      final svc = LensOfflinePackService(packRoot: tmp);
      expect(
        () => svc.openPack('yo'),
        throwsA(isA<LensOfflinePackException>()),
      );
    });

    test('missing audio file fails validation', () async {
      final tmp = await Directory.systemTemp.createTemp('lens_pack_audio_');
      final svc = LensOfflinePackService(packRoot: tmp);
      final row = LensOfflinePackObjectRow(
        objectSetId: 'afr.cup',
        lexemeId: 'yo.lex.cup',
        wordCard: {
          'lexeme_id': 'yo.lex.cup',
          'language': 'yo',
          'word': 'ago',
          'object_set_id': 'afr.cup',
          'audio': {'kind': 'nativeHuman', 'play_uri': '/x'},
        },
        audioRelativePath: 'audio/afr.cup.m4a',
        audioSha256: sha256.convert([1, 2, 3]).toString(),
      );
      await svc.writePack(language: 'yo', objects: [row]);
      expect(
        () => svc.openPack('yo'),
        throwsA(
          predicate<Object>((e) =>
              e is LensOfflinePackException &&
              e.kind == LensOfflinePackErrorKind.missingOnDisk),
        ),
      );
    });

    test('cached audio loads from disk', () async {
      final tmp = await Directory.systemTemp.createTemp('lens_pack_ok_');
      final svc = LensOfflinePackService(packRoot: tmp);
      final bytes = [9, 8, 7];
      final digest = sha256.convert(bytes).toString();
      final langDir = Directory('${tmp.path}/yo/audio');
      langDir.createSync(recursive: true);
      File('${langDir.path}/afr.cup.m4a').writeAsBytesSync(bytes);
      final row = LensOfflinePackObjectRow(
        objectSetId: 'afr.cup',
        lexemeId: 'yo.lex.cup',
        wordCard: {
          'lexeme_id': 'yo.lex.cup',
          'language': 'yo',
          'word': 'ago',
          'object_set_id': 'afr.cup',
          'audio': {'kind': 'nativeHuman'},
        },
        audioRelativePath: 'audio/afr.cup.m4a',
        audioSha256: digest,
      );
      await svc.writePack(language: 'yo', objects: [row]);
      final opened = await svc.openPack('yo');
      final path = svc.localAudioPath(opened, 'afr.cup');
      expect(path, isNotNull);
      expect(File(path!).readAsBytesSync(), bytes);
    });
  });

  group('PointAndSaySyncState', () {
    test('failed items stay pending until retry', () {
      expect(
        pointAndSaySyncStateFromRecord({'syncState': 'failed'}),
        PointAndSaySyncState.failed,
      );
      expect(
        pointAndSaySyncStateFromRecord({}),
        PointAndSaySyncState.pending,
      );
    });
  });
}
