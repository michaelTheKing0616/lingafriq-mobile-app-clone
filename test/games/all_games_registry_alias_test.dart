import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';

void main() {
  group('AllGamesRegistry alias resolution', () {
    test('resolves canonical ids to legacy definitions', () {
      expect(AllGamesRegistry.getGame('speed_round_remix'), isNotNull);
      expect(AllGamesRegistry.getGame('listen_and_sketch'), isNotNull);
      expect(AllGamesRegistry.getGame('clan_lineage_story_builder'), isNotNull);
      expect(AllGamesRegistry.getGame('greeting_diplomacy_challenge'), isNotNull);
      expect(AllGamesRegistry.getGame('rapid_tongue_twister_race'), isNotNull);
    });

    test('published game ids include canonical GameType ids', () {
      final ids = AllGamesRegistry.getAllGameIds();
      expect(ids.contains('wordmatch_audio'), isTrue);
      expect(ids.contains('pronunciation_duel'), isTrue);
      expect(ids.contains('market_monopoly_challenge'), isTrue);
    });
  });
}
