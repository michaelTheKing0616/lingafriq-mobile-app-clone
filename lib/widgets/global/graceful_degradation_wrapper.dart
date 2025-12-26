/// Graceful Degradation Wrapper
/// Provides fallback UI when features are unavailable
/// 
/// Features:
/// - Automatic feature detection
/// - Fallback UI rendering
/// - Feature availability checks

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GracefulDegradationWrapper extends StatelessWidget {
  final Widget child;
  final Widget? offlineFallback;
  final Widget? errorFallback;
  final bool checkConnectivity;
  final bool checkPermissions;
  final Function()? onRetry;

  const GracefulDegradationWrapper({
    Key? key,
    required this.child,
    this.offlineFallback,
    this.errorFallback,
    this.checkConnectivity = true,
    this.checkPermissions = false,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _FeatureCheckWrapper(
      checkConnectivity: checkConnectivity,
      checkPermissions: checkPermissions,
      offlineFallback: offlineFallback,
      errorFallback: errorFallback,
      onRetry: onRetry,
      child: child,
    );
  }
}

class _FeatureCheckWrapper extends StatefulWidget {
  final Widget child;
  final Widget? offlineFallback;
  final Widget? errorFallback;
  final bool checkConnectivity;
  final bool checkPermissions;
  final Function()? onRetry;

  const _FeatureCheckWrapper({
    Key? key,
    required this.child,
    this.offlineFallback,
    this.errorFallback,
    this.checkConnectivity = true,
    this.checkPermissions = false,
    this.onRetry,
  }) : super(key: key);

  @override
  State<_FeatureCheckWrapper> createState() => _FeatureCheckWrapperState();
}

class _FeatureCheckWrapperState extends State<_FeatureCheckWrapper> {
  bool _isOnline = true;
  bool _hasPermissions = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFeatures();
  }

  Future<void> _checkFeatures() async {
    setState(() {
      _isLoading = true;
    });

    if (widget.checkConnectivity) {
      try {
        final result = await Connectivity().checkConnectivity();
        _isOnline = result != ConnectivityResult.none;
      } catch (e) {
        _isOnline = true; // Assume online if check fails
      }
    }

    if (widget.checkPermissions) {
      // Check platform-specific permissions
      // This would need platform channels in production
      _hasPermissions = true; // Placeholder
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermissions && widget.errorFallback != null) {
      return widget.errorFallback!;
    }

    if (!_isOnline && widget.offlineFallback != null) {
      return widget.offlineFallback!;
    }

    return widget.child;
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';

// Note: connectivity_plus package required: flutter pub add connectivity_plus

