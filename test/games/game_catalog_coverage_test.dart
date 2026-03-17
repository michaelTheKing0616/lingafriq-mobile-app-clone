import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/screens/games/game_catalog.dart';

void main() {
  group('GameCatalog coverage', () {
    test('contains every GameType exactly once', () {
      final types = GameCatalog.entries.map((e) => e.type).toList();
      final unique = types.toSet();

      expect(unique.length, equals(types.length), reason: 'Duplicate GameType entries found.');
      expect(
        unique.length,
        equals(GameType.values.length),
        reason: 'Catalog does not cover all GameType values.',
      );

      for (final type in GameType.values) {
        expect(GameCatalog.byType[type], isNotNull, reason: 'Missing GameCatalog entry for $type');
      }
    });
  });
}
