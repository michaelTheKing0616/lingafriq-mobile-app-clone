import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/festival/festival_lexicon_weighting.dart';
import 'package:lingafriq/games/festival/festival_theme_service.dart';
import 'package:lingafriq/games/gamekit/batch_game_factory.dart';
import 'package:lingafriq/models/game/game_content_failure.dart';
import 'package:lingafriq/models/game/game_content_models.dart';
import 'package:lingafriq/models/verified_lexeme.dart';

VerifiedLexeme _lexeme({
  required String id,
  List<String> topics = const [],
}) {
  return VerifiedLexeme(
    lexemeId: id,
    language: 'yo',
    verificationStatus: 'expert_reviewed',
    lemma: 'oko',
    standardOrthography: 'ọkọ',
    exampleSentence: 'spouse',
    audioUris: const ['https://cdn.example/a.mp3'],
    raw: {
      'id': id,
      'topics': topics,
      'audio': [
        {'uri': 'https://cdn.example/a.mp3', 'kind': 'human', 'licence_id': 'FSI-PD'},
      ],
    },
  );
}

void main() {
  tearDown(() {
    FestivalThemeService.instance.clearCacheForTests();
  });

  group('festival week rollover', () {
    test('theme rotates by ISO week key', () {
      expect(
        festivalThemeForWeekKey('2026-W1'),
        VillageFestivalThemeId.food,
      );
      expect(
        festivalThemeForWeekKey('2026-W2'),
        VillageFestivalThemeId.family,
      );
      expect(
        festivalThemeForWeekKey('2026-W3'),
        VillageFestivalThemeId.travel,
      );
      expect(
        festivalThemeForWeekKey('2026-W4'),
        VillageFestivalThemeId.food,
      );
    });
  });

  group('theme pool weighting', () {
    test('boosts themed rows without dropping items', () {
      final lexemes = [
        _lexeme(id: 'yo.lex.1'),
        _lexeme(id: 'yo.lex.2', topics: ['village_festival:family']),
        _lexeme(id: 'yo.lex.3'),
      ];
      final items = lexemes
          .map((l) => verifiedLexemeToPoolItem(l))
          .toList();
      final reordered = reorderPoolForFestival(
        items: items,
        lexemes: lexemes,
        themeId: VillageFestivalThemeId.family,
      );
      expect(reordered.length, 3);
      expect(reordered.first.id, 'yo.lex.2');
    });

    test('applyToPool leaves pool unchanged when no themed lexemes', () {
      final lexemes = [
        _lexeme(id: 'yo.lex.1'),
        _lexeme(id: 'yo.lex.2'),
      ];
      final base = GameLexiconPoolBuildResult(
        items: lexemes.map(verifiedLexemeToPoolItem).toList(),
        failure: GameContentFailure.none(),
        excludedMissingAudio: 0,
        queriedCount: 2,
        source: 'test',
      );
      final festival = FestivalThemeService.instance.snapshotAt(
        DateTime.utc(2026, 1, 8),
      );
      final out = FestivalThemeService.instance.applyToPool(
        base: base,
        sourceLexemes: lexemes,
        festival: festival,
        gameId: 'tone_forge',
      );
      expect(out.items.map((i) => i.id), base.items.map((i) => i.id));
      expect(FestivalThemeService.instance.lastPoolNote, 'no_festival_content');
    });
  });

  test('builder applies festival weighting for supported game', () async {
    final builder = GameLexiconPoolBuilder(
      fetch: (_, {required int limit}) async => [
        _lexeme(id: 'yo.lex.1'),
        _lexeme(id: 'yo.lex.2', topics: ['village_festival:family']),
      ],
    );
    FestivalThemeService.instance.seedCacheForTests(
      FestivalThemeService.instance.snapshotAt(DateTime.utc(2026, 1, 8)),
    );
    final result = await builder.build(
      const GameLexiconPoolRequest(languageCode: 'yo', minimumItems: 2),
      gameId: 'tone_forge',
    );
    expect(result.failure.type, GameContentFailureType.none);
    expect(result.items.first.id, 'yo.lex.2');
    expect(result.source, contains('festival'));
  });
}
