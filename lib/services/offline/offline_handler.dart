import 'dart:async';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';

/// Connectivity and durable-outbox status. There is no second queue.
/// Queued work lives only in [PersistedOutboxService].
class OfflineHandler {
  static final OfflineHandler _instance = OfflineHandler._internal();
  factory OfflineHandler() {
    unawaited(PersistedOutboxService.instance.ensureOpen());
    return _instance;
  }
  OfflineHandler._internal();

  bool _isOnline = true;
  bool _isSyncing = false;
  Timer? _syncTimer;
  static const Duration _syncInterval = Duration(minutes: 5);

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    await _refreshConnectivityStatus();
    await PersistedOutboxService.instance.ensureOpen();
  }

  Future<void> _refreshConnectivityStatus() async {
    try {
      final wasOnline = _isOnline;
      _isOnline = await ConnectivityService.hasInternet();
      if (!wasOnline && _isOnline) {
        _startPeriodicSync();
        unawaited(_flushDurableOutbox());
      } else if (!_isOnline) {
        _stopPeriodicSync();
      }
    } catch (_) {}
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      unawaited(_flushDurableOutbox());
    });
  }

  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _flushDurableOutbox() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await PersistedOutboxService.instance.flushPending();
    } finally {
      _isSyncing = false;
    }
  }

  Map<String, dynamic> getSyncStatus() {
    return {
      'is_online': _isOnline,
      'is_syncing': _isSyncing,
      'queue_length': PersistedOutboxService.instance.pendingCount,
      'pending_count': PersistedOutboxService.instance.pendingCount,
      'failed_count': PersistedOutboxService.instance.retryingCount,
    };
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
