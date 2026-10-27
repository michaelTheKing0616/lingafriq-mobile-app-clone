import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/games/tone_forge/tone_forge_scoring.dart';
import 'package:lingafriq/learning/pronunciation/tone_models.dart';

void main() {
  test('tone_forge is featured on the tone shelf', () {
    final featured = AllGamesRegistry.featuredOnShelf(ArcadeSkillShelf.tone);
    expect(featured, isNotNull);
    expect(featured!.gameId, AllGamesRegistry.toneForgeGameId);
    expect(featured!.featured, isTrue);
    expect(featured!.elevationCardId, 'P8-914');
  });

  test('registry defines tone_forge manifest', () {
    final def = AllGamesRegistry.getGame(AllGamesRegistry.toneForgeGameId);
    expect(def, isNotNull);
    expect(def!.displayName, 'Tone Forge');
  });

  test('arcade shelf coverage includes catalog and tone_forge', () {
    expect(AllGamesRegistry.validateArcadeShelfCoverage(), isEmpty);
  });

  test('tone_forge stays practice until live scorer adapter passes', () {
    expect(
      gameKitRealScorerLiveForGame(
        featureFlagOn: true,
        gameId: AllGamesRegistry.toneForgeGameId,
        isSpeakingGame: true,
      ),
      isFalse,
    );
    expect(
      gameKitPracticeNotScoredMode(
        isSpeakingGame: true,
        realScorerLive: false,
      ),
      isTrue,
    );
  });

  test('inventory scoring uses per-language levels', () {
    final model = ToneLanguageModel(
      languageCode: 'yo',
      systemId: 'yo_hml',
      levels: const ['H', 'M', 'L'],
      contourKinds: const ['level'],
      sourceId: 'test',
    );
    final score = scoreToneInventoryChoice(
      inventory: model,
      lexiconTonePattern: const ['H'],
      syllableIndex: 0,
      selectedInventoryIndex: 0,
    );
    expect(score.isPerfect, isTrue);
  });
}
