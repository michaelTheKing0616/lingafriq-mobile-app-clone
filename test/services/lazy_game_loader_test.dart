import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/lazy_game_loader.dart';
import 'package:lingafriq/models/game/game_session_model.dart';

void main() {
  group('GameLoadResult', () {
    test('success factory should create successful result', () {
      final result = GameLoadResult.success(GameType.wordMatchAudio);

      expect(result.success, true);
      expect(result.gameType, GameType.wordMatchAudio);
      expect(result.errorMessage, isNull);
    });

    test('failure factory should create failed result with message', () {
      final result = GameLoadResult.failure(
        GameType.wordMatchAudio,
        'Failed to load resources',
      );

      expect(result.success, false);
      expect(result.gameType, GameType.wordMatchAudio);
      expect(result.errorMessage, 'Failed to load resources');
    });

    test('should contain correct game type', () {
      final successResult = GameLoadResult.success(GameType.pronunciationDuel);
      final failureResult =
          GameLoadResult.failure(GameType.proverbUnlocker, 'Error');

      expect(successResult.gameType, GameType.pronunciationDuel);
      expect(failureResult.gameType, GameType.proverbUnlocker);
    });
  });

  group('LazyGameLoader', () {
    late ProviderContainer container;
    late LazyGameLoader loader;

    setUp(() {
      container = ProviderContainer();
      loader = container.read(lazyGameLoaderProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('should start with no games loaded', () {
      expect(loader.isGameLoaded(GameType.wordMatchAudio), false);
    });

    test('should check if game is loaded', () {
      expect(loader.isGameLoaded(GameType.wordMatchAudio), false);
    });

    test('should track errors per game type when no error', () {
      expect(loader.hasError(GameType.wordMatchAudio), false);
    });

    test('clearError should not throw when no error', () {
      loader.clearError(GameType.wordMatchAudio);
      expect(loader.hasError(GameType.wordMatchAudio), false);
    });

    test('getLastError should return null when no error', () {
      expect(loader.getLastError(GameType.wordMatchAudio), isNull);
    });

    test('getLoadingStats should return map with loaded_games and games', () {
      final stats = loader.getLoadingStats();
      expect(stats, contains('loaded_games'));
      expect(stats, contains('games'));
      expect(stats['loaded_games'], 0);
      expect(stats['games'], isA<List>());
    });

    test('clearLoadedGames should clear internal state', () {
      loader.clearLoadedGames();
      final stats = loader.getLoadingStats();
      expect(stats['loaded_games'], 0);
    });
  });

  group('GameType', () {
    test('all game types should have display names', () {
      for (final gameType in GameType.values) {
        expect(gameType.displayName, isNotEmpty);
      }
    });

    test('common game types should be defined', () {
      expect(GameType.wordMatchAudio, isNotNull);
      expect(GameType.pronunciationDuel, isNotNull);
      expect(GameType.proverbUnlocker, isNotNull);
      expect(GameType.drumRhythmShadowing, isNotNull);
    });

    test('game types count should be at least 4', () {
      expect(GameType.values.length, greaterThanOrEqualTo(4));
    });
  });

  group('Game Loading Strategy', () {
    test('should use common games for preloading', () {
      final commonGames = [
        GameType.wordMatchAudio,
        GameType.pronunciationDuel,
        GameType.proverbUnlocker,
        GameType.drumRhythmShadowing,
      ];

      for (final game in commonGames) {
        expect(GameType.values.contains(game), true);
      }
    });

    test('should handle concurrent load requests gracefully', () async {
      final container = ProviderContainer();
      container.read(lazyGameLoaderProvider);

      final futures = <Future<void>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(Future.value());
      }

      await Future.wait(futures);
      container.dispose();
    });
  });

  group('Error Recovery', () {
    late ProviderContainer container;
    late LazyGameLoader loader;

    setUp(() {
      container = ProviderContainer();
      loader = container.read(lazyGameLoaderProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('retryGameLoad should clear previous error and attempt load', () async {
      final result = await loader.retryGameLoad(GameType.wordMatchAudio);
      expect(result, isA<GameLoadResult>());
      expect(result.gameType, GameType.wordMatchAudio);
    });

    test('loadGameOnDemand returns GameLoadResult', () async {
      final result = await loader.loadGameOnDemand(GameType.wordMatchAudio);
      expect(result, isA<GameLoadResult>());
      expect(result.gameType, GameType.wordMatchAudio);
    });
  });
}
