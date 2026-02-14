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
import '../../services/offline/offline_handler.dart';

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
  final OfflineHandler _offlineHandler = OfflineHandler();
  bool _isOnline = true;
  Map<String, dynamic> _syncStatus = {};
  Timer? _connectivityTimer;
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
    Future.delayed(const Duration(seconds: 5), () {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showBanner = widget.showWhenOnline ? _isOnline : !_isOnline;

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

  Widget _buildBanner() {
    if (_isOnline) {
      final pendingCount = _syncStatus['pending_count'] ?? 0;
      if (pendingCount > 0) {
        return _buildSyncBanner(pendingCount);
      }
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.orange[700],
      child: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) => Row(
            children: [
              Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.onSurface, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are offline',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
                ),
              ),
              if (_syncStatus['queue_length'] != null && _syncStatus['queue_length'] > 0)
                Text(
                  '${_syncStatus['queue_length']} pending',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncBanner(int pendingCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.blue[700],
      child: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) => Row(
            children: [
              Icon(Icons.sync, color: Theme.of(context).colorScheme.onSurface, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Syncing $pendingCount item${pendingCount != 1 ? 's' : ''}...',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
                ),
              ),
              if (_syncStatus['is_syncing'] == true)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurface),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

