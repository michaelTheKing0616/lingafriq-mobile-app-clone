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

  /// Tasks that permanently failed after exhausting retries.
  /// Exposed so the UI can show a banner / retry action.
  final List<SyncTask> permanentlyFailedTasks;

  /// True when at least one task has permanently failed.
  bool get hasPermanentFailures => permanentlyFailedTasks.isNotEmpty;

  BackendSyncState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.pendingSyncs = 0,
    Map<String, SyncStatus>? syncStatuses,
    List<SyncTask>? permanentlyFailedTasks,
  })  : syncStatuses = syncStatuses ?? {},
        permanentlyFailedTasks = permanentlyFailedTasks ?? [];

  BackendSyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? pendingSyncs,
    Map<String, SyncStatus>? syncStatuses,
    List<SyncTask>? permanentlyFailedTasks,
  }) {
    return BackendSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingSyncs: pendingSyncs ?? this.pendingSyncs,
      syncStatuses: syncStatuses ?? this.syncStatuses,
      permanentlyFailedTasks: permanentlyFailedTasks ?? this.permanentlyFailedTasks,
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
    ref.onDispose(() {
      _syncTimer?.cancel();
    });
    _loadSyncQueue();
    _startPeriodicSync();

    // If onboarding is completed while unauthenticated, sync tasks will queue up.
    // As soon as the user becomes available, trigger an immediate sync so the
    // "pending syncs" badge reflects reality quickly.
    ref.listen(userProvider, (prev, next) {
      if (prev == null && next != null) {
        // Fire-and-forget; syncAll guards against concurrent runs.
        syncAll();
      }
    });

    return BackendSyncState();
  }

  void _dedupeOnboardingQueueInPlace() {
    // Keep only the most recent onboarding task per `step`.
    // This prevents the queue (and UI badge) from growing when a user re-runs onboarding.
    final Map<String, SyncTask> latestByStep = {};
    final List<SyncTask> passthrough = [];

    for (final t in _syncQueue) {
      if (t.type == SyncType.onboarding) {
        final step = (t.data['step'] ?? '').toString();
        if (step.isEmpty) {
          passthrough.add(t);
          continue;
        }

        final existing = latestByStep[step];
        if (existing == null || t.timestamp.isAfter(existing.timestamp)) {
          latestByStep[step] = t;
        }
        continue;
      }

      passthrough.add(t);
    }

    final dedupedOnboarding = latestByStep.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    _syncQueue
      ..clear()
      ..addAll(passthrough)
      ..addAll(dedupedOnboarding);
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
        _dedupeOnboardingQueueInPlace();
        state = state.copyWith(pendingSyncs: _syncQueue.length);

        // If user is already logged in at startup, flush immediately.
        final user = ref.read(userProvider);
        if (user != null && _syncQueue.isNotEmpty) {
          // Fire-and-forget; syncAll will persist queue updates.
          syncAll();
        } else {
          // Persist dedupe changes if any. Avoid writing in the common "no changes" path.
          await prefs.setString(
            _syncQueueKey,
            jsonEncode(_syncQueue.map((e) => e.toJson()).toList()),
          );
        }
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
    // Dedupe onboarding steps (same step can be set multiple times across runs).
    if (task.type == SyncType.onboarding) {
      final step = (task.data['step'] ?? '').toString();
      if (step.isNotEmpty) {
        _syncQueue.removeWhere((t) => t.type == SyncType.onboarding && (t.data['step'] ?? '').toString() == step);
      }
    }
    _syncQueue.add(task);
    _dedupeOnboardingQueueInPlace();
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
      final List<SyncTask> retryableTasks = [];
      final List<SyncTask> newPermanentlyFailed = [];

      for (final task in List<SyncTask>.from(_syncQueue)) {
        try {
          await _executeSyncTask(task);
          _syncQueue.remove(task);
        } catch (e) {
          logger.error('Sync task failed', tag: 'backend-sync', error: e, context: {'taskType': task.type.name});
          task.retries++;
          if (task.retries < 3) {
            retryableTasks.add(task);
          } else {
            logger.warn('Task permanently failed after 3 retries',
              tag: 'backend-sync',
              context: {'taskType': task.type.name, 'retries': task.retries},
            );
            newPermanentlyFailed.add(task);
          }
        }
      }

      _syncQueue.clear();
      _syncQueue.addAll(retryableTasks);
      await _saveSyncQueue();

      // Merge newly failed tasks with any existing permanently failed tasks
      final allFailed = [
        ...state.permanentlyFailedTasks,
        ...newPermanentlyFailed,
      ];

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        pendingSyncs: _syncQueue.length,
        permanentlyFailedTasks: allFailed,
      );
    } catch (e) {
      logger.error('Error during sync', tag: 'backend-sync', error: e);
      state = state.copyWith(isSyncing: false);
    }
  }

  /// Re-queue permanently failed tasks so users can retry from the UI.
  /// Resets retry count and clears the permanent failure list.
  Future<void> retryFailedTasks() async {
    if (state.permanentlyFailedTasks.isEmpty) return;

    for (final task in state.permanentlyFailedTasks) {
      task.retries = 0; // Reset retries
      _syncQueue.add(task);
    }
    await _saveSyncQueue();

    state = state.copyWith(
      permanentlyFailedTasks: [],
      pendingSyncs: _syncQueue.length,
    );

    // Trigger a sync attempt immediately
    syncAll();
  }

  /// Dismiss permanently failed tasks (user acknowledges the failures).
  void dismissFailedTasks() {
    state = state.copyWith(permanentlyFailedTasks: []);
  }

  Future<void> _executeSyncTask(SyncTask task) async {
    final api = ref.read(apiProvider.notifier);

    switch (task.type) {
      case SyncType.gamification:
        final ok = await api.syncGamification(task.data);
        if (!ok) throw Exception('Gamification sync returned false');
        break;
      case SyncType.gameSession:
        final ok = await api.syncGameSession(task.data);
        if (!ok) throw Exception('Game session sync returned false');
        break;
      case SyncType.gameSRS:
        final ok = await api.syncGameSRS(task.data);
        if (!ok) throw Exception('Game SRS sync returned false');
        break;
      case SyncType.aiChatHistory:
        final ok = await api.syncAIChatHistory(task.data);
        if (!ok) throw Exception('AI chat history sync returned false');
        break;
      case SyncType.aiChatSRS:
        final ok = await api.syncAIChatSRS(task.data);
        if (!ok) throw Exception('AI chat SRS sync returned false');
        break;
      case SyncType.progress:
        final ok = await api.syncProgress(task.data);
        if (!ok) throw Exception('Progress sync returned false');
        break;
      case SyncType.onboarding:
        // syncOnboarding already wraps data in 'onboarding_data' field
        // task.data contains the step data (e.g., { step: 'proficiency_language', proficiency_language: 'en' })
        final ok = await api.syncOnboarding(task.data);
        if (!ok) throw Exception('Onboarding sync returned false');
        break;
      case SyncType.telemetry:
        final ok = await api.syncTelemetry(task.data);
        if (!ok) throw Exception('Telemetry sync returned false');
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

