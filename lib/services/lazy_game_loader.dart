import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';

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
  // ignore: unused_field
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
  Future<List<GameLoadResult>> preloadCommonGames({String language = 'yoruba'}) async {
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
          await _preloadGame(gameType, language: language);
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
  Future<void> _preloadGame(GameType gameType, {required String language}) async {
    try {
      await _prefetchCardsFromBackend(gameType, language: language);
      debugPrint('Successfully preloaded game: ${gameType.displayName}');
    } catch (e) {
      debugPrint('Error preloading game ${gameType.displayName}: $e');
      rethrow;
    }
  }

  /// Warms Polie-backed card payloads via the legacy GET `/api/games/cards` route
  /// (see `node-backend-safe-push` `getGameCards`).
  Future<void> _prefetchCardsFromBackend(GameType gameType, {required String language}) async {
    final res = await ApiService.get(
      ApiContract.url(ApiContract.games.cards),
      queryParameters: <String, dynamic>{
        'language': language,
        'game_id': gameType.name,
        'difficulty': 'A1',
        'count': 3,
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Game prefetch HTTP ${res.statusCode}');
    }
  }

  /// Check if game is loaded
  bool isGameLoaded(GameType gameType) {
    return _loadedGames[gameType] ?? false;
  }

  /// Load game on demand - returns result with success/failure status
  Future<GameLoadResult> loadGameOnDemand(
    GameType gameType, {
    String language = 'yoruba',
  }) async {
    if (_loadedGames[gameType] ?? false) {
      // Check if still fresh
      final loadTime = _loadTimes[gameType];
      if (loadTime != null && DateTime.now().difference(loadTime) < _preloadWindow) {
        return GameLoadResult.success(gameType); // Already loaded and fresh
      }
    }

    try {
      await _preloadGame(gameType, language: language);
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
  Future<GameLoadResult> retryGameLoad(
    GameType gameType, {
    String language = 'yoruba',
  }) async {
    clearError(gameType);
    _loadedGames.remove(gameType);
    return loadGameOnDemand(gameType, language: language);
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

