/// Offline Indicator Widget - Shows connection status
/// Displays a banner when device is offline

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lingafriq/services/connectivity_service.dart';

class OfflineIndicator extends StatefulWidget {
  final Widget child;
  final Color? offlineColor;
  final Color? onlineColor;
  final Duration animationDuration;

  const OfflineIndicator({
    Key? key,
    required this.child,
    this.offlineColor,
    this.onlineColor,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator>
    with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  Timer? _connectivityTimer;
  static const Duration _connectivityPollInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _checkConnectivity();
    _startConnectivityPolling();
  }

  Future<void> _checkConnectivity() async {
    try {
      final isOnline = await ConnectivityService.hasInternet();
      _updateStatus(isOnline);
    } catch (_) {
      // Keep previous status on failure to avoid unnecessary toggles.
    }
  }

  void _startConnectivityPolling() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(
      _connectivityPollInterval,
      (_) => unawaited(_checkConnectivity()),
    );
  }

  void _updateStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      setState(() {
        _isOnline = isOnline;
      });

      if (!isOnline) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Positioned(
              top: _slideAnimation.value * 50,
              left: 0,
              right: 0,
              child: _isOnline
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: widget.offlineColor ?? Colors.red,
                      child: Builder(
                        builder: (context) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Offline Mode',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }
}

