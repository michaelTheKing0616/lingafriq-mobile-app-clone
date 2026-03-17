import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';
import 'package:lingafriq/models/game/game_session_model.dart';

void main() {
  group('AllGamesRegistry', () {
    test('contains definitions for every GameType canonical id', () {
      for (final type in GameType.values) {
        final definition = AllGamesRegistry.getGame(type.name);
        expect(
          definition,
          isNotNull,
          reason: 'Missing canonical definition for ${type.name}',
        );
      }
    });

    test('resolves legacy aliases to canonical definitions', () {
      expect(
        AllGamesRegistry.getGame('tone_forge')?.gameId,
        equals(GameType.toneTrainer.name),
      );
      expect(
        AllGamesRegistry.getGame('speed_round')?.gameId,
        equals(GameType.speedRoundRemix.name),
      );
      expect(
        AllGamesRegistry.getGame('drum_word')?.gameId,
        equals(GameType.drumToWordMatching.name),
      );
    });
  });
}
