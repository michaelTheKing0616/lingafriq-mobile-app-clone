import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../screens/games/game_router.dart';
import '../models/game/game_session_model.dart';
import '../providers/game_provider.dart';
import '../providers/onboarding_provider.dart';

/// Lazy Game Loader Service
/// Optimizes game loading by preloading common games and lazy-loading others
class LazyGameLoader {
  final Ref _ref;
  final Map<GameType, bool> _loadedGames = {};
  final Map<GameType, DateTime> _loadTimes = {};
  static const Duration _preloadWindow = Duration(minutes: 5);

  LazyGameLoader(this._ref);

  /// Preload commonly used games
  Future<void> preloadCommonGames() async {
    final commonGames = [
      GameType.wordMatchAudio,
      GameType.pronunciationDuel,
      GameType.proverbUnlocker,
      GameType.drumRhythmShadowing,
    ];

    for (final gameType in commonGames) {
      if (_loadedGames[gameType] != true) {
        try {
          await _preloadGame(gameType);
          _loadedGames[gameType] = true;
          _loadTimes[gameType] = DateTime.now();
        } catch (e) {
          debugPrint('Error preloading game $gameType: $e');
        }
      }
    }
  }

  /// Preload a specific game
  Future<void> _preloadGame(GameType gameType) async {
    try {
      // Use onboarding preferences to decide which language/level to warm up.
      final onboarding = _ref.read(onboardingProvider);
      final language =
          (onboarding.selectedLanguage ?? 'swahili').toLowerCase();
      final level = onboarding.proficiencyLevel ?? 'A1';

      debugPrint(
        'Preloading game content for ${gameType.displayName} ($language, $level)...',
      );

      // Ask the central GameProvider to warm up cards/content for this game.
      final gameProviderNotifier = _ref.read(gameProvider.notifier);
      await gameProviderNotifier.warmupGameContent(
        gameType: gameType,
        language: language,
        level: level,
        count: 12,
      );
    } catch (e) {
      debugPrint('Error preloading game ${gameType.displayName}: $e');
    }
  }

  /// Check if game is loaded
  bool isGameLoaded(GameType gameType) {
    return _loadedGames[gameType] ?? false;
  }

  /// Load game on demand
  Future<void> loadGameOnDemand(GameType gameType) async {
    if (_loadedGames[gameType] ?? false) {
      // Check if still fresh
      final loadTime = _loadTimes[gameType];
      if (loadTime != null && DateTime.now().difference(loadTime) < _preloadWindow) {
        return; // Already loaded and fresh
      }
    }

    try {
      await _preloadGame(gameType);
      _loadedGames[gameType] = true;
      _loadTimes[gameType] = DateTime.now();
    } catch (e) {
      debugPrint('Error loading game on demand: $e');
    }
  }

  /// Clear loaded games (memory management)
  void clearLoadedGames() {
    _loadedGames.clear();
    _loadTimes.clear();
  }

  /// Get loading statistics
  Map<String, dynamic> getLoadingStats() {
    return {
      'loaded_games': _loadedGames.length,
      'games': _loadedGames.keys.map((g) => g.displayName).toList(),
    };
  }
}

final lazyGameLoaderProvider = Provider<LazyGameLoader>((ref) {
  return LazyGameLoader(ref);
});

