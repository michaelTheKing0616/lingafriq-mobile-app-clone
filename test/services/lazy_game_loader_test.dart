import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/lazy_game_loader.dart';
import 'package:lingafriq/models/game/game_session_model.dart';

void main() {
  group('LazyGameLoader Tests', () {
    test('LazyGameLoader initialization', () {
      final container = ProviderContainer();
      final loader = container.read(lazyGameLoaderProvider);
      
      expect(loader, isNotNull);
    });

    test('Preload common games', () async {
      final container = ProviderContainer();
      final loader = container.read(lazyGameLoaderProvider);
      
      // Preload some common games
      await loader.preloadCommonGames([
        GameType.wordMatchAudio,
        GameType.pronunciationDuel,
      ]);
      
      // Verify games are marked as loaded
      expect(loader.isGameLoaded(GameType.wordMatchAudio), isTrue);
      expect(loader.isGameLoaded(GameType.pronunciationDuel), isTrue);
    });

    test('Load game on demand', () async {
      final container = ProviderContainer();
      final loader = container.read(lazyGameLoaderProvider);
      
      // Load a game on demand
      await loader.loadGameOnDemand(GameType.toneTrainer);
      
      // Verify game is loaded
      expect(loader.isGameLoaded(GameType.toneTrainer), isTrue);
    });

    test('Clear loaded games', () {
      final container = ProviderContainer();
      final loader = container.read(lazyGameLoaderProvider);
      
      // Clear all loaded games
      loader.clearLoadedGames();
      
      // Verify games are cleared
      expect(loader.isGameLoaded(GameType.wordMatchAudio), isFalse);
    });
  });
}

