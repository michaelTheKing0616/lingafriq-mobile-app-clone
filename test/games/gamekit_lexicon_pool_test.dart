import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/festival/festival_theme_service.dart';
import 'package:lingafriq/games/gamekit/batch_game_factory.dart';
import 'package:lingafriq/games/learning_game_adapter.dart';
import 'package:lingafriq/models/game/game_content_failure.dart';
import 'package:lingafriq/models/game/game_content_models.dart';
import 'package:lingafriq/models/verified_lexeme.dart';

VerifiedLexeme _lexeme({
  required String id,
  String? audioUri,
  String licence = 'FSI-PD',
}) {
  return VerifiedLexeme(
    lexemeId: id,
    language: 'yo',
    verificationStatus: 'expert_reviewed',
    lemma: 'oko',
    standardOrthography: 'ọkọ',
    exampleSentence: 'spouse',
    audioUris: audioUri == null ? const [] : [audioUri],
    raw: {
      'id': id,
      'lemma': 'oko',
      'orthography': {'standard': 'ọkọ'},
      if (audioUri != null)
        'audio': [
          {'uri': audioUri, 'kind': 'human', 'licence_id': licence},
        ],
    },
  );
}

void main() {
  // Pool building is unit-tested offline: seed the festival cache with the
  // deterministic local schedule instead of calling the backend.
  setUp(() {
    FestivalThemeService.instance.seedCacheForTests(
      FestivalThemeService.instance.snapshotAt(DateTime.utc(2026, 1, 5)),
    );
  });
  tearDown(FestivalThemeService.instance.clearCacheForTests);

  group('GameLexiconPoolBuilder', () {
    test('maps lexeme to pool item with licence and audio', () {
      final item = verifiedLexemeToPoolItem(
        _lexeme(id: 'yo.lex.1', audioUri: 'https://cdn.example/a.mp3'),
      );
      expect(item.id, 'yo.lex.1');
      expect(item.language, 'yo');
      expect(item.toneMarkedForm, 'ọkọ');
      expect(item.audioUri, 'https://cdn.example/a.mp3');
      expect(item.licenceTag, 'FSI-PD');
    });

    test('excludes items without audio when requireAudio', () async {
      final builder = GameLexiconPoolBuilder(
        fetch: (_, {required int limit}) async => [
          _lexeme(id: 'yo.lex.1'),
          _lexeme(id: 'yo.lex.2', audioUri: 'https://cdn.example/b.mp3'),
          _lexeme(id: 'yo.lex.3', audioUri: 'https://cdn.example/c.mp3'),
        ],
      );
      final result = await builder.build(
        const GameLexiconPoolRequest(
          languageCode: 'yo',
          minimumItems: 2,
          requireAudio: true,
        ),
      );
      expect(result.items.length, 2);
      expect(result.excludedMissingAudio, 1);
      expect(result.failure.type, GameContentFailureType.none);
      expect(result.items.every((i) => i.hasPlayableAudio), isTrue);
    });

    test('returns insufficientPool when below minimum', () async {
      final builder = GameLexiconPoolBuilder(
        fetch: (_, {required int limit}) async => [
          _lexeme(id: 'yo.lex.1', audioUri: 'https://cdn.example/a.mp3'),
        ],
      );
      final result = await builder.build(
        const GameLexiconPoolRequest(
          languageCode: 'yo',
          minimumItems: 3,
          requireAudio: true,
        ),
      );
      expect(result.failure.type, GameContentFailureType.insufficientPool);
      expect(result.failure.message, contains('3 needed'));
    });

    test('BatchGameFactory uses injectable fetch', () async {
      final result = await BatchGameFactory.buildLexiconWordPool(
        const GameLexiconPoolRequest(languageCode: 'yo', minimumItems: 1),
        fetch: (_, {required int limit}) async => [
          _lexeme(id: 'yo.lex.9', audioUri: 'https://cdn.example/z.mp3'),
        ],
      );
      expect(result.isOk, isTrue);
      expect(result.source, 'verified_lexicon_api');
      expect(result.items.first.toneMarkedForm, 'ọkọ');
    });

    test('GameKitLexiconPool adapter delegates', () async {
      final result = await GameKitLexiconPool.load(
        languageCode: 'yo',
        minimumItems: 1,
        fetch: (_, {required int limit}) async => [
          _lexeme(id: 'yo.lex.10', audioUri: 'https://cdn.example/d.mp3'),
        ],
      );
      expect(result.items.single.id, 'yo.lex.10');
    });
  });

  test('gamekit allowlist files do not reference bundled game_content.json', () {
    final root = Directory.current.path.endsWith('lingafriq-mobile-app-clone')
        ? Directory.current
        : Directory('lingafriq-mobile-app-clone');
    final targets = [
      'lib/games/gamekit/batch_game_factory.dart',
      'lib/games/gamekit/game_factory_helper.dart',
      'lib/games/learning_game_adapter.dart',
    ];
    for (final relative in targets) {
      final text = File('${root.path}/$relative').readAsStringSync();
      expect(
        text.contains('game_content.json'),
        isFalse,
        reason: '$relative must not load legacy seed JSON',
      );
    }
  });
}
