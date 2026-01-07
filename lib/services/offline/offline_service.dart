/// Offline Service - Manages offline data synchronization and caching
/// Provides offline-first architecture with automatic sync when online

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:lingafriq/utils/structured_logger.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  final List<Function()> _syncQueue = [];
  bool _isSyncing = false;

  /// Initialize offline service
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        final wasOnline = _isOnline;
        _isOnline = result != ConnectivityResult.none;
        
        if (!wasOnline && _isOnline) {
          // Just came online - trigger sync
          _syncPendingChanges();
        }
      },
    );

    // Initialize background sync
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
  }

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Queue a sync operation for when device comes online
  void queueSync(Function() syncFunction) {
    _syncQueue.add(syncFunction);
    if (_isOnline) {
      _syncPendingChanges();
    }
  }

  /// Sync pending changes (internal method)
  Future<void> _syncPendingChanges() async {
    if (_isSyncing || !_isOnline || _syncQueue.isEmpty) return;

    _isSyncing = true;
    try {
      while (_syncQueue.isNotEmpty && _isOnline) {
        final syncFunction = _syncQueue.removeAt(0);
        try {
          await syncFunction();
        } catch (e) {
          logger.error('Sync error', error: e);
          // Re-queue failed sync
          _syncQueue.add(syncFunction);
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Public method to trigger sync (for background tasks)
  Future<void> syncPendingChanges() async {
    await _syncPendingChanges();
  }

  /// Get cache statistics with actual size calculation
  Future<Map<String, dynamic>> getCacheStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    // Calculate actual cache size
    int totalSizeBytes = 0;
    final keySizes = <String, int>{};
    
    for (final key in keys) {
      final value = prefs.get(key);
      int size = 0;
      
      if (value is String) {
        size = value.length * 2; // UTF-16 encoding: 2 bytes per character
      } else if (value is int) {
        size = 8; // 64-bit integer
      } else if (value is double) {
        size = 8; // 64-bit double
      } else if (value is bool) {
        size = 1; // Boolean
      } else if (value is List) {
        // Estimate list size (rough calculation)
        size = value.length * 16; // Rough estimate
      } else if (value is Map) {
        // Estimate map size (rough calculation)
        size = value.length * 32; // Rough estimate
      }
      
      // Add key size (UTF-16: 2 bytes per character)
      size += key.length * 2;
      
      totalSizeBytes += size;
      keySizes[key] = size;
    }
    
    // Format size for display
    String formatSize(int bytes) {
      if (bytes < 1024) return '${bytes}B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)}KB';
      if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
    }
    
    // Get largest keys
    final sortedKeys = keySizes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topKeys = sortedKeys.take(10).map((e) => {
      'key': e.key,
      'size': formatSize(e.value),
      'sizeBytes': e.value,
    }).toList();
    
    return {
      'totalKeys': keys.length,
      'cacheSize': formatSize(totalSizeBytes),
      'cacheSizeBytes': totalSizeBytes,
      'lastSync': prefs.getString('last_sync') ?? 'Never',
      'topKeys': topKeys,
      'averageKeySize': keys.isNotEmpty ? formatSize(totalSizeBytes ~/ keys.length) : '0B',
    };
  }

  /// Clear cache
  Future<void> clearCache(String? cacheType) async {
    final prefs = await SharedPreferences.getInstance();
    if (cacheType == null) {
      // Clear all cache
      await prefs.clear();
    } else {
      // Clear specific cache type (implementation depends on cache structure)
      logger.info('Clearing cache type', context: {'cacheType': cacheType});
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

/// Background sync callback
/// This is called by WorkManager when a background sync task is triggered
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      logger.info('Background sync task started', context: {'task': task});
      
      // Get the offline service instance
      final offlineService = OfflineService();
      
      // Check if device is online
      if (!offlineService.isOnline) {
        logger.debug('Device is offline, skipping background sync');
        return Future.value(false);
      }
      
      // Trigger sync of pending changes
      // This will process the sync queue that was built up while offline
      await offlineService.syncPendingChanges();
      
      logger.info('Background sync task completed successfully');
      return Future.value(true);
    } catch (e) {
      logger.error('Background sync task failed', error: e);
      return Future.value(false);
    }
  });
}

