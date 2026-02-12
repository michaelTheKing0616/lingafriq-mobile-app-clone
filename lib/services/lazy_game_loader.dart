import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../screens/games/game_router.dart';
import '../models/game/game_session_model.dart';

/// Result class for game loading operations
class GameLoadResult {
  final bool success;
  final String? errorMessage;
  final GameType gameType;

  const GameLoadResult({
    required this.success,
    required this.gameType,
    this.errorMessage,
  });

  factory GameLoadResult.success(GameType gameType) => GameLoadResult(
    success: true,
    gameType: gameType,
  );

  factory GameLoadResult.failure(GameType gameType, String message) => GameLoadResult(
    success: false,
    gameType: gameType,
    errorMessage: message,
  );
}

/// Lazy Game Loader Service
/// Optimizes game loading by preloading common games and lazy-loading others
class LazyGameLoader {
  final Ref _ref;
  final Map<GameType, bool> _loadedGames = {};
  final Map<GameType, DateTime> _loadTimes = {};
  final Map<GameType, String> _loadErrors = {};
  static const Duration _preloadWindow = Duration(minutes: 5);

  LazyGameLoader(this._ref);

  /// Get the last error for a game type (if any)
  String? getLastError(GameType gameType) => _loadErrors[gameType];

  /// Check if a game had a loading error
  bool hasError(GameType gameType) => _loadErrors.containsKey(gameType);

  /// Clear error for a game (before retry)
  void clearError(GameType gameType) => _loadErrors.remove(gameType);

  /// Preload commonly used games
  Future<List<GameLoadResult>> preloadCommonGames() async {
    final commonGames = [
      GameType.wordMatchAudio,
      GameType.pronunciationDuel,
      GameType.proverbUnlocker,
      GameType.drumRhythmShadowing,
    ];

    final results = <GameLoadResult>[];

    for (final gameType in commonGames) {
      if (_loadedGames[gameType] != true) {
        try {
          await _preloadGame(gameType);
          _loadedGames[gameType] = true;
          _loadTimes[gameType] = DateTime.now();
          _loadErrors.remove(gameType); // Clear any previous error
          results.add(GameLoadResult.success(gameType));
        } catch (e) {
          final errorMsg = 'Failed to preload ${gameType.displayName}: $e';
          debugPrint('⚠️ LazyGameLoader: $errorMsg');
          _loadErrors[gameType] = e.toString();
          results.add(GameLoadResult.failure(gameType, errorMsg));
        }
      } else {
        results.add(GameLoadResult.success(gameType));
      }
    }
    
    return results;
  }

  /// Preload a specific game
  Future<void> _preloadGame(GameType gameType) async {
    try {
      // Preload game assets based on game type
      switch (gameType) {
        case GameType.wordMatchAudio:
        case GameType.pronunciationDuel:
        case GameType.drumRhythmShadowing:
          // Preload audio assets for games that require audio
          await _preloadAudioAssets(gameType);
          break;
        case GameType.proverbUnlocker:
        default:
          // Preload game data (vocabulary, questions, etc.)
          await _preloadGameData(gameType);
      }
      
      debugPrint('Successfully preloaded game: ${gameType.displayName}');
    } catch (e) {
      debugPrint('Error preloading game ${gameType.displayName}: $e');
      rethrow;
    }
  }

  /// Preload audio assets for games that require audio
  Future<void> _preloadAudioAssets(GameType gameType) async {
    // Audio files are loaded on-demand by the game itself when needed
    // This method ensures the game type is registered and ready
    // In production, could pre-cache frequently used audio files here
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// Preload game data (vocabulary, questions, etc.)
  Future<void> _preloadGameData(GameType gameType) async {
    // Game data is loaded on-demand by the game itself when needed
    // This method ensures the game type is registered and ready
    // In production, could pre-fetch and cache game data from API here
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// Check if game is loaded
  bool isGameLoaded(GameType gameType) {
    return _loadedGames[gameType] ?? false;
  }

  /// Load game on demand - returns result with success/failure status
  Future<GameLoadResult> loadGameOnDemand(GameType gameType) async {
    if (_loadedGames[gameType] ?? false) {
      // Check if still fresh
      final loadTime = _loadTimes[gameType];
      if (loadTime != null && DateTime.now().difference(loadTime) < _preloadWindow) {
        return GameLoadResult.success(gameType); // Already loaded and fresh
      }
    }

    try {
      await _preloadGame(gameType);
      _loadedGames[gameType] = true;
      _loadTimes[gameType] = DateTime.now();
      _loadErrors.remove(gameType); // Clear any previous error
      return GameLoadResult.success(gameType);
    } catch (e) {
      final errorMsg = 'Failed to load ${gameType.displayName}: $e';
      debugPrint('⚠️ LazyGameLoader: $errorMsg');
      _loadErrors[gameType] = e.toString();
      return GameLoadResult.failure(gameType, errorMsg);
    }
  }

  /// Retry loading a game that previously failed
  Future<GameLoadResult> retryGameLoad(GameType gameType) async {
    clearError(gameType);
    _loadedGames.remove(gameType);
    return loadGameOnDemand(gameType);
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

