import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/screens/games/game_catalog.dart';
import 'package:lingafriq/screens/games/game_router.dart';

void main() {
  group('Game router switch coverage', () {
    test('contains routed entry for every GameType', () {
      expect(
        kRoutedGameTypes.length,
        equals(GameType.values.length),
        reason: 'kRoutedGameTypes does not cover all GameType values.',
      );
      for (final type in GameType.values) {
        expect(
          kRoutedGameTypes.contains(type),
          isTrue,
          reason: 'Missing routed game type in kRoutedGameTypes for $type',
        );
      }
    });

    test('catalog entries cover all GameType values', () {
      final catalogTypes = GameCatalog.entries.map((e) => e.type).toSet();
      expect(catalogTypes.length, equals(GameType.values.length));
      for (final type in GameType.values) {
        expect(catalogTypes.contains(type), isTrue);
      }
    });
  });
}
