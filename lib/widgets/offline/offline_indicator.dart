/// Offline Indicator Widget - Shows connection status
/// Displays a banner when device is offline

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lingafriq/services/offline/offline_service.dart';

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
    _listenToConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final isOnline = result != ConnectivityResult.none;
    _updateStatus(isOnline);
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final isOnline = result != ConnectivityResult.none;
      _updateStatus(isOnline);
    });
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'No Internet Connection',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }
}

