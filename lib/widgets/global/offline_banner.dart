/// Offline Banner Widget
/// Displays a banner when device is offline
/// 
/// Features:
/// - Automatic visibility based on connectivity
/// - Shows sync queue status
/// - Manual sync trigger

import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/offline/offline_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;
  final bool showWhenOnline;

  const OfflineBanner({
    Key? key,
    required this.child,
    this.showWhenOnline = false,
  }) : super(key: key);

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final OfflineHandler _offlineHandler = OfflineHandler();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;
  Map<String, dynamic> _syncStatus = {};

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result.any((r) => r != ConnectivityResult.none);
        _syncStatus = _offlineHandler.getSyncStatus();
      });
    });

    // Update sync status periodically
    _updateSyncStatus();
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = result.any((r) => r != ConnectivityResult.none);
      _syncStatus = _offlineHandler.getSyncStatus();
    });
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
    _connectivitySub?.cancel();
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
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'You are offline',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
            if (_syncStatus['queue_length'] != null && _syncStatus['queue_length'] > 0)
              Text(
                '${_syncStatus['queue_length']} pending',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
          ],
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
        child: Row(
          children: [
            const Icon(Icons.sync, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Syncing $pendingCount item${pendingCount != 1 ? 's' : ''}...',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
            if (_syncStatus['is_syncing'] == true)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

