// Background Sync Service - Handles background data synchronization
// Uses WorkManager for periodic background sync even when app is closed

import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';

class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  /// Initialize background sync
  Future<void> initialize() async {
    await Workmanager().initialize(
      backgroundSyncCallback,
      isInDebugMode: kDebugMode,
    );
  }

  /// Register periodic sync task
  Future<void> registerPeriodicSync({
    Duration frequency = const Duration(hours: 1),
  }) async {
    await Workmanager().registerPeriodicTask(
      'background-sync',
      'backgroundSync',
      frequency: frequency,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Cancel background sync
  Future<void> cancelSync() async {
    await Workmanager().cancelByUniqueName('background-sync');
  }
}

/// Background sync callback
/// This is called by WorkManager when a periodic background sync task is triggered
@pragma('vm:entry-point')
void backgroundSyncCallback() {
  Workmanager().executeTask((task, inputData) async {
    try {
      logger.info('Periodic background sync task started', context: {'task': task});
      
      // In background isolates, avoid relying on in-memory online state.
      // Use the connectivity probe used by the outbox itself.
      if (!await ConnectivityService.hasInternet()) {
        logger.debug('Device is offline, skipping periodic background sync');
        return Future.value(false);
      }
      
      // Flush persisted outbox (sync v2) — the canonical offline-first mechanism.
      await PersistedOutboxService.instance.ensureOpen();
      await PersistedOutboxService.instance.flushPending();
      
      logger.info('Periodic background sync task completed successfully');
      return Future.value(true);
    } catch (e) {
      logger.error('Periodic background sync task failed', error: e);
      return Future.value(false);
    }
  });
}

