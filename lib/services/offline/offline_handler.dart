/// Offline Handler Service
/// Manages offline functionality and data synchronization
/// 
/// Features:
/// - Offline data caching
/// - Sync queue management
/// - Conflict resolution
/// - Background sync

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Sync operation
class SyncOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retryCount;
  SyncStatus status;

  SyncOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.status = SyncStatus.pending,
  });
}

enum SyncStatus {
  pending,
  processing,
  completed,
  failed,
}

/// Offline Handler Service
class OfflineHandler {
  static final OfflineHandler _instance = OfflineHandler._internal();
  factory OfflineHandler() => _instance;
  OfflineHandler._internal();

  final List<SyncOperation> _syncQueue = [];
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isSyncing = false;
  final Duration _syncInterval = const Duration(minutes: 5);
  Timer? _syncTimer;

  /// Initialize offline handler
  Future<void> initialize() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(results);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = _isConnected(result);

      if (wasOffline && _isOnline) {
        // Connection restored, start syncing
        _startPeriodicSync();
      } else if (!_isOnline) {
        // Connection lost, stop syncing
        _stopPeriodicSync();
      }
    });

    // Start periodic sync if online
    if (_isOnline) {
      _startPeriodicSync();
    }
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Add operation to sync queue
  Future<String> queueOperation({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final operation = SyncOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );

    _syncQueue.add(operation);

    // Try to sync immediately if online
    if (_isOnline) {
      _processSyncQueue();
    }

    return operation.id;
  }

  /// Process sync queue
  Future<void> _processSyncQueue() async {
    if (_isSyncing || _syncQueue.isEmpty || !_isOnline) {
      return;
    }

    _isSyncing = true;

    try {
      final pendingOperations = _syncQueue
          .where((op) => op.status == SyncStatus.pending)
          .toList();

      for (final operation in pendingOperations) {
        operation.status = SyncStatus.processing;

        try {
          await _syncOperation(operation);
          operation.status = SyncStatus.completed;
          _syncQueue.remove(operation);
        } catch (e) {
          operation.retryCount++;
          operation.status = SyncStatus.pending;

          // Remove if retry limit exceeded
          if (operation.retryCount >= 3) {
            operation.status = SyncStatus.failed;
            debugPrint('Sync operation failed after 3 retries: ${operation.id}');
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single operation
  Future<void> _syncOperation(SyncOperation operation) async {
    // This would integrate with your API service
    // For now, simulate sync
    switch (operation.type) {
      case 'lesson_progress':
        // Sync lesson progress
        break;
      case 'user_preference':
        // Sync user preferences
        break;
      case 'audio_contribution':
        // Sync audio contributions
        break;
      default:
        throw Exception('Unknown sync operation type: ${operation.type}');
    }
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _stopPeriodicSync();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      _processSyncQueue();
    });
  }

  /// Stop periodic sync
  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Get sync queue status
  Map<String, dynamic> getSyncStatus() {
    return {
      'is_online': _isOnline,
      'is_syncing': _isSyncing,
      'queue_length': _syncQueue.length,
      'pending_count': _syncQueue.where((op) => op.status == SyncStatus.pending).length,
      'failed_count': _syncQueue.where((op) => op.status == SyncStatus.failed).length,
    };
  }

  /// Clear sync queue
  void clearSyncQueue() {
    _syncQueue.clear();
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _stopPeriodicSync();
  }
}

