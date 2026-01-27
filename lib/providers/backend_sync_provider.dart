import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_provider.dart';
import 'user_provider.dart';
import '../utils/structured_logger.dart';

/// Centralized backend sync provider
/// Handles all data synchronization with backend
/// Implements offline-first architecture with retry logic
final backendSyncProvider = NotifierProvider<BackendSyncProvider, BackendSyncState>(() {
  return BackendSyncProvider();
});

class BackendSyncState {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int pendingSyncs;
  final Map<String, SyncStatus> syncStatuses;

  BackendSyncState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.pendingSyncs = 0,
    Map<String, SyncStatus>? syncStatuses,
  }) : syncStatuses = syncStatuses ?? {};

  BackendSyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? pendingSyncs,
    Map<String, SyncStatus>? syncStatuses,
  }) {
    return BackendSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingSyncs: pendingSyncs ?? this.pendingSyncs,
      syncStatuses: syncStatuses ?? this.syncStatuses,
    );
  }
}

enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}

class BackendSyncProvider extends Notifier<BackendSyncState> {
  static const String _syncQueueKey = 'backend_sync_queue';
  Timer? _syncTimer;
  final List<SyncTask> _syncQueue = [];

  @override
  BackendSyncState build() {
    _loadSyncQueue();
    _startPeriodicSync();
    return BackendSyncState();
  }

  void _startPeriodicSync() {
    // Sync every 5 minutes
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncAll();
    });
  }

  Future<void> _loadSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_syncQueueKey);
      if (queueJson != null) {
        final List<dynamic> queue = jsonDecode(queueJson);
        _syncQueue.clear();
        _syncQueue.addAll(
          queue.map((e) => SyncTask.fromJson(e as Map<String, dynamic>)),
        );
        state = state.copyWith(pendingSyncs: _syncQueue.length);
      }
    } catch (e) {
      logger.error('Error loading sync queue', tag: 'backend-sync', error: e);
    }
  }

  Future<void> _saveSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _syncQueueKey,
        jsonEncode(_syncQueue.map((e) => e.toJson()).toList()),
      );
      state = state.copyWith(pendingSyncs: _syncQueue.length);
    } catch (e) {
      logger.error('Error saving sync queue', tag: 'backend-sync', error: e);
    }
  }

  /// Add a sync task to the queue
  Future<void> queueSync(SyncTask task) async {
    _syncQueue.add(task);
    await _saveSyncQueue();
    // Try to sync immediately if not already syncing
    if (!state.isSyncing) {
      syncAll();
    }
  }

  /// Sync all pending tasks
  Future<void> syncAll() async {
    if (state.isSyncing || _syncQueue.isEmpty) return;

    final user = ref.read(userProvider);
    if (user == null) {
      logger.warn('Cannot sync: User not logged in', tag: 'backend-sync');
      return;
    }

    state = state.copyWith(isSyncing: true);

    try {
      final List<SyncTask> failedTasks = [];

      for (final task in List<SyncTask>.from(_syncQueue)) {
        try {
          await _executeSyncTask(task);
          _syncQueue.remove(task);
        } catch (e) {
          logger.error('Sync task failed', tag: 'backend-sync', error: e, context: {'taskType': task.type});
          task.retries++;
          if (task.retries < 3) {
            failedTasks.add(task);
          } else {
            logger.warn('Task failed after 3 retries, removing', tag: 'backend-sync', context: {'taskType': task.type});
          }
        }
      }

      _syncQueue.clear();
      _syncQueue.addAll(failedTasks);
      await _saveSyncQueue();

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        pendingSyncs: _syncQueue.length,
      );
    } catch (e) {
      logger.error('Error during sync', tag: 'backend-sync', error: e);
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> _executeSyncTask(SyncTask task) async {
    final api = ref.read(apiProvider.notifier);

    switch (task.type) {
      case SyncType.gamification:
        await api.syncGamification(task.data);
        break;
      case SyncType.gameSession:
        await api.syncGameSession(task.data);
        break;
      case SyncType.gameSRS:
        await api.syncGameSRS(task.data);
        break;
      case SyncType.aiChatHistory:
        await api.syncAIChatHistory(task.data);
        break;
      case SyncType.aiChatSRS:
        await api.syncAIChatSRS(task.data);
        break;
      case SyncType.progress:
        await api.syncProgress(task.data);
        break;
      case SyncType.onboarding:
        // syncOnboarding already wraps data in 'onboarding_data' field
        // task.data contains the step data (e.g., { step: 'proficiency_language', proficiency_language: 'en' })
        await api.syncOnboarding(task.data);
        break;
      case SyncType.telemetry:
        await api.syncTelemetry(task.data);
        break;
    }
  }

  /// Force sync a specific data type
  Future<void> syncNow(SyncType type, Map<String, dynamic> data) async {
    await queueSync(SyncTask(type: type, data: data));
    await syncAll();
  }

  void cleanup() {
    _syncTimer?.cancel();
  }
}

enum SyncType {
  gamification,
  gameSession,
  gameSRS,
  aiChatHistory,
  aiChatSRS,
  progress,
  onboarding,
  telemetry,
}

class SyncTask {
  final SyncType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retries;

  SyncTask({
    required this.type,
    required this.data,
    DateTime? timestamp,
    this.retries = 0,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'retries': retries,
      };

  factory SyncTask.fromJson(Map<String, dynamic> json) => SyncTask(
        type: SyncType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => SyncType.gamification,
        ),
        data: json['data'] as Map<String, dynamic>,
        timestamp: DateTime.parse(json['timestamp']),
        retries: json['retries'] ?? 0,
      );
}

