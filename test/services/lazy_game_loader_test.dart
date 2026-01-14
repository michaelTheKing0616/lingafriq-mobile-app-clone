import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/lazy_game_loader.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LazyGameLoader Tests', () {
    late SharedPreferences _prefs;
    late ProviderContainer _container;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      _prefs = await SharedPreferences.getInstance();
    });

    setUp(() {
      _container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            SharedPreferencesProvider(_prefs),
          ),
        ],
      );
    });

    tearDown(() {
      _container.dispose();
    });

    test('LazyGameLoader initialization', () {
      final loader = _container.read(lazyGameLoaderProvider);
      
      expect(loader, isNotNull);
    });

    test('Preload common games', () async {
      final loader = _container.read(lazyGameLoaderProvider);
      
      // Preload common games (loader defines the list internally)
      await loader.preloadCommonGames();
      
      // Verify games are marked as loaded
      expect(loader.isGameLoaded(GameType.wordMatchAudio), isTrue);
      expect(loader.isGameLoaded(GameType.pronunciationDuel), isTrue);
    });

    test('Load game on demand', () async {
      final loader = _container.read(lazyGameLoaderProvider);
      
      // Load a game on demand
      await loader.loadGameOnDemand(GameType.toneTrainer);
      
      // Verify game is loaded
      expect(loader.isGameLoaded(GameType.toneTrainer), isTrue);
    });

    test('Clear loaded games', () {
      final loader = _container.read(lazyGameLoaderProvider);
      
      // Clear all loaded games
      loader.clearLoadedGames();
      
      // Verify games are cleared
      expect(loader.isGameLoaded(GameType.wordMatchAudio), isFalse);
    });
  });
}

