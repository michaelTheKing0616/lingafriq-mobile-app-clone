import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/minimal_pair_duel/league_scoring.dart';
import 'package:lingafriq/games/minimal_pair_duel/minimal_pair_duel_game.dart';
import 'package:lingafriq/lessons/tone_perception_drill.dart';

TonePerceptionDrillSpec _yoFixtureDrill() {
  return TonePerceptionDrillSpec(
    id: 'yo.tone.oko_hoe_vehicle',
    promptGlossEn: 'Which word means vehicle?',
    correctOptionId: 'yo.lex.ọkọ.vehicle',
    options: const [
      TonePerceptionOption(
        id: 'yo.lex.ọkọ.hoe',
        form: 'ọkọ́',
        glossEn: 'hoe',
        sourceId: 'register:fsi-yoruba',
      ),
      TonePerceptionOption(
        id: 'yo.lex.ọkọ.vehicle',
        form: 'ọkọ̀',
        glossEn: 'vehicle',
        sourceId: 'curriculum/lexicon/yo/vehicle-draft',
      ),
    ],
    pairSourceId: 'yo.lex.ọkọ.vehicle',
    audioUri: 'audio/yo/a1b2c3d4e5f67890.ogg',
  );
}

Map<String, MinimalPairDuelMedia> _mediaFixture() {
  return {
    'yo.lex.ọkọ.hoe': const MinimalPairDuelMedia(
      audioUri: 'audio/yo/hoe.ogg',
      imageUri: 'images/yo/hoe.png',
      imageAlt: 'A hoe',
    ),
    'yo.lex.ọkọ.vehicle': const MinimalPairDuelMedia(
      audioUri: 'audio/yo/vehicle.ogg',
      imageUri: 'images/yo/vehicle.png',
      imageAlt: 'A car',
    ),
  };
}

void main() {
  test('excludes sets missing audio or picture', () {
    final drill = _yoFixtureDrill();
    final partial = Map<String, MinimalPairDuelMedia>.from(_mediaFixture());
    partial.remove('yo.lex.ọkọ.hoe');
    expect(buildDuelSetFromDrill(drill: drill, mediaByOptionId: partial), isNull);
    expect(
      buildDuelSetFromDrill(drill: drill, mediaByOptionId: _mediaFixture()),
      isNotNull,
    );
  });

  test('item set order is deterministic from seed', () {
    final set = buildDuelSetFromDrill(
      drill: _yoFixtureDrill(),
      mediaByOptionId: _mediaFixture(),
    )!;
    final a = deriveAsyncItemSetIds(
      itemSetSeed: 'friend-challenge-seed',
      eligibleSets: [set, set],
      maxSets: 2,
    );
    final b = deriveAsyncItemSetIds(
      itemSetSeed: 'friend-challenge-seed',
      eligibleSets: [set, set],
      maxSets: 2,
    );
    expect(a, b);
  });

  test('league ranking prefers accuracy then speed', () {
    const accurateSlow = MinimalPairDuelLeagueScore(
      correctCount: 5,
      totalCount: 5,
      totalTimeMs: 50_000,
    );
    const lessAccurateFast = MinimalPairDuelLeagueScore(
      correctCount: 4,
      totalCount: 5,
      totalTimeMs: 10_000,
    );
    expect(
      compareMinimalPairDuelLeagueScores(accurateSlow, lessAccurateFast),
      lessThan(0),
    );
    const tieAcc = MinimalPairDuelLeagueScore(
      correctCount: 4,
      totalCount: 5,
      totalTimeMs: 20_000,
    );
    const tieAccFaster = MinimalPairDuelLeagueScore(
      correctCount: 4,
      totalCount: 5,
      totalTimeMs: 12_000,
    );
    expect(
      compareMinimalPairDuelLeagueScores(tieAcc, tieAccFaster),
      greaterThan(0),
    );
  });

  test('wrong tap returns confused pair ids', () {
    final set = buildDuelSetFromDrill(
      drill: _yoFixtureDrill(),
      mediaByOptionId: _mediaFixture(),
    )!;
    final turn = buildMinimalPairDuelTurn(set: set, rng: Random(1));
    final wrongId = turn.options
        .firstWhere((o) => o.id != turn.heardOptionId)
        .id;
    final graded = gradeMinimalPairDuelTap(
      turn: turn,
      selectedOptionId: wrongId,
    );
    expect(graded.correct, isFalse);
    expect(graded.confusedPairOptionIds, contains(turn.heardOptionId));
    expect(graded.confusedPairOptionIds, contains(wrongId));
  });
}
