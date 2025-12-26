/// Offline Service - Manages offline data synchronization and caching
/// Provides offline-first architecture with automatic sync when online

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  final List<Function()> _syncQueue = [];
  bool _isSyncing = false;

  /// Initialize offline service
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result.any((r) => r != ConnectivityResult.none);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = results.any((r) => r != ConnectivityResult.none);
        
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

  /// Sync pending changes
  Future<void> _syncPendingChanges() async {
    if (_isSyncing || !_isOnline || _syncQueue.isEmpty) return;

    _isSyncing = true;
    try {
      while (_syncQueue.isNotEmpty && _isOnline) {
        final syncFunction = _syncQueue.removeAt(0);
        try {
          await syncFunction();
        } catch (e) {
          debugPrint('Sync error: $e');
          // Re-queue failed sync
          _syncQueue.add(syncFunction);
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

/// Background sync callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Background sync implementation
    return Future.value(true);
  });
}

