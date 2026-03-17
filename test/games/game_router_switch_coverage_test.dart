import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/screens/games/game_catalog.dart';

void main() {
  group('Game router switch coverage', () {
    final routerPath = 'lib/screens/games/game_router.dart';

    test('contains switch case for every GameType', () {
      final source = File(routerPath).readAsStringSync();

      for (final type in GameType.values) {
        expect(
          source.contains('case GameType.${type.name}:'),
          isTrue,
          reason: 'Missing switch case in game_router.dart for GameType.${type.name}',
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
