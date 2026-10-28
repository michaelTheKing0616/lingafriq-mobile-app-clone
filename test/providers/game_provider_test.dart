import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/features/games/providers/games_providers.dart';
import 'package:lingafriq/providers/game_provider.dart';

const _featureRoot = 'lib/features/games/providers';
const _maxLinesPerFile = 500;
const _gamesBarrel = 'package:lingafriq/features/games/providers/games_providers.dart';

void main() {
  test('P12-007: games provider parts <= $_maxLinesPerFile lines', () {
    for (final entity in Directory(_featureRoot).listSync()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('games_providers.dart')) continue;
      final count = entity.readAsLinesSync().length;
      expect(count, lessThanOrEqualTo(_maxLinesPerFile), reason: entity.path);
    }
    expect(
      File('lib/providers/game_provider.dart').readAsLinesSync().length,
      lessThanOrEqualTo(_maxLinesPerFile),
      reason: 'lib/providers/game_provider.dart',
    );
  });

  test('P12-007: import boundary — non-games features use games barrel', () {
    final offenders = <String>[];
    final features = Directory('lib/features');
    for (final entity in features.listSync()) {
      if (entity is! Directory) continue;
      if (entity.path.endsWith('/games')) continue;
      for (final file in entity.listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final src = file.readAsStringSync();
        if (src.contains('providers/game_provider.dart')) {
          offenders.add(file.path);
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Use $_gamesBarrel from other features: $offenders',
    );
  });

  test('P12-007: public barrel exports gameProvider', () {
    expect(gameProvider, isNotNull);
    expect(GameProvider.classifyGameContentFailure, isNotNull);
  });
}
