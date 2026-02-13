import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/backend_health_service.dart';
import '../../services/polie_cache_service.dart';
import '../../services/lazy_game_loader.dart';
import '../../core/errors/app_exceptions.dart';

/// App Initialization Service
/// Handles all app startup initialization tasks
class AppInitializer {
  final Ref _ref;

  AppInitializer(this._ref);

  /// Initialize the app
  /// Returns true if initialization was successful
  Future<AppInitializationResult> initialize() async {
    final startTime = DateTime.now();
    final results = <String, bool>{};

    try {
      // 1. Check backend health
      debugPrint('🔍 Checking backend health...');
      final healthService = _ref.read(backendHealthServiceProvider);
      final healthStatus = await healthService.getConnectionStatus();
      results['backend_health'] = healthStatus.isConnected;
      
      if (healthStatus.isConnected) {
        debugPrint('✅ Backend is connected');
      } else {
        debugPrint('⚠️ Backend connection issues detected');
      }

      // 2. Verify critical endpoints
      debugPrint('🔍 Verifying critical endpoints...');
      final endpointStatus = await healthService.verifyCriticalEndpoints();
      final availableEndpoints = endpointStatus.values.where((v) => v).length;
      final totalEndpoints = endpointStatus.length;
      results['endpoints'] = availableEndpoints == totalEndpoints;
      
      debugPrint('📊 Endpoints: $availableEndpoints/$totalEndpoints available');

      // 3. Warm up Polie cache (check cache stats)
      debugPrint('🔍 Checking Polie cache...');
      try {
        final cacheStats = await PolieCacheService.getCacheStats();
        final validEntries = cacheStats['valid_entries'] as int? ?? 0;
        results['polie_cache'] = true;
        debugPrint('✅ Polie cache: $validEntries valid entries');
      } catch (e) {
        debugPrint('⚠️ Polie cache check failed: $e');
        results['polie_cache'] = false;
      }

      // 4. Preload common games
      debugPrint('🔍 Preloading common games...');
      try {
        final gameLoader = _ref.read(lazyGameLoaderProvider);
        await gameLoader.preloadCommonGames();
        results['game_preload'] = true;
        debugPrint('✅ Game preloading complete');
      } catch (e) {
        debugPrint('⚠️ Game preloading failed: $e');
        results['game_preload'] = false;
      }

      final duration = DateTime.now().difference(startTime);
      final allSuccessful = results.values.every((v) => v);

      return AppInitializationResult(
        success: allSuccessful,
        duration: duration,
        results: results,
        backendStatus: healthStatus,
      );
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
      final exception = ExceptionHandler.handleError(e);
      
      return AppInitializationResult(
        success: false,
        duration: DateTime.now().difference(startTime),
        results: results,
        error: exception,
      );
    }
  }

  /// Quick initialization (non-blocking)
  /// For features that can load in background
  Future<void> initializeBackground() async {
    try {
      // Warm up cache
      await PolieCacheService.getCacheStats();
      
      // Preload games in background
      final gameLoader = _ref.read(lazyGameLoaderProvider);
      gameLoader.preloadCommonGames().catchError((e) {
        debugPrint('Background game preload failed: $e');
        return <GameLoadResult>[];
      });
    } catch (e) {
      debugPrint('Background initialization error: $e');
    }
  }
}

/// App initialization result
class AppInitializationResult {
  final bool success;
  final Duration duration;
  final Map<String, bool> results;
  final BackendConnectionStatus? backendStatus;
  final AppException? error;

  AppInitializationResult({
    required this.success,
    required this.duration,
    required this.results,
    this.backendStatus,
    this.error,
  });

  bool get isFullyInitialized => success && (backendStatus?.isFullyOperational ?? false);
  bool get hasPartialInitialization => success && !isFullyInitialized;

  @override
  String toString() {
    return 'AppInitializationResult('
        'success: $success, '
        'duration: ${duration.inMilliseconds}ms, '
        'results: $results'
        ')';
  }
}

final appInitializerProvider = Provider<AppInitializer>((ref) {
  return AppInitializer(ref);
});

