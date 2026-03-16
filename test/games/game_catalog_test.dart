import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/screens/games/game_catalog.dart';

void main() {
  group('GameCatalog', () {
    test('contains an entry for every GameType', () {
      expect(GameCatalog.entries.length, equals(GameType.values.length));
      for (final gameType in GameType.values) {
        expect(GameCatalog.byType.containsKey(gameType), isTrue);
      }
    });

    test('has no duplicate display names', () {
      final names = GameCatalog.entries.map((e) => e.name).toList();
      final unique = names.toSet();
      expect(unique.length, equals(names.length));
    });
  });
}
