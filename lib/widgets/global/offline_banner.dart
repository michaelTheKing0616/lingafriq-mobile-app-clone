// Offline Banner Widget
// Displays a banner when device is offline
// 
// Features:
// - Automatic visibility based on connectivity
// - Shows sync queue status
// - Manual sync trigger

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import '../../services/offline/persisted_outbox_service.dart';
import '../sync_status_chip.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;
  final bool showWhenOnline;

  const OfflineBanner({
    super.key,
    required this.child,
    this.showWhenOnline = false,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final PersistedOutboxService _offlineHandler = PersistedOutboxService.instance;
  bool _isOnline = true;
  Map<String, dynamic> _syncStatus = {};
  Timer? _connectivityTimer;
  Timer? _syncStatusTimer;
  static const Duration _connectivityPollInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _refreshConnectivity();
    _startConnectivityPolling();
    // Update sync status periodically
    _updateSyncStatus();
  }

  void _startConnectivityPolling() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(
      _connectivityPollInterval,
      (_) => unawaited(_refreshConnectivity()),
    );
  }

  Future<void> _refreshConnectivity() async {
    try {
      final isOnline = await ConnectivityService.hasInternet();
      if (!mounted) return;
      setState(() {
        _isOnline = isOnline;
        _syncStatus = _offlineHandler.getSyncStatus();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _syncStatus = _offlineHandler.getSyncStatus();
      });
    }
  }

  void _updateSyncStatus() {
    _syncStatusTimer?.cancel();
    _syncStatusTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _syncStatus = _offlineHandler.getSyncStatus();
        });
        _updateSyncStatus();
      }
    });
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _syncStatusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needsAttention = !_isOnline ||
        _syncStatus['is_syncing'] == true ||
        _count('pending_count') > 0 ||
        _count('dead_letter_count') > 0;
    final showBanner = needsAttention || widget.showWhenOnline;

    return Stack(
      children: [
        widget.child,
        if (showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildBanner(),
          ),
      ],
    );
  }

  int _count(String key) {
    final value = _syncStatus[key];
    return value is int ? value : 0;
  }

  Widget _buildBanner() {
    final chip = SyncStatusChip(
      online: _isOnline,
      syncing: _syncStatus['is_syncing'] == true,
      pending: _count('pending_count'),
      failed: _count('dead_letter_count'),
      onRetry: () {
        unawaited(PersistedOutboxService.instance.flushPending());
      },
    );
    if (_isOnline &&
        _syncStatus['is_syncing'] != true &&
        _count('pending_count') == 0 &&
        _count('dead_letter_count') == 0) {
      return const SizedBox.shrink();
    }
    return SafeArea(bottom: false, child: chip);
  }
}

