/// Graceful Degradation Wrapper
/// Provides fallback UI when features are unavailable
/// 
/// Features:
/// - Automatic feature detection
/// - Fallback UI rendering
/// - Feature availability checks

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
        _isOnline = result.any((r) => r != ConnectivityResult.none);
      } catch (e) {
        _isOnline = true; // Assume online if check fails
      }
    }

    if (widget.checkPermissions) {
      // Check platform-specific permissions
      // For most features, we assume permissions are granted at app level
      // Specific permission checks should be done in feature-specific code
      try {
        // In production, this would check specific permissions:
        // - Microphone for voice features
        // - Camera for AR features
        // - Storage for offline content
        // For now, assume granted (permissions requested at feature level)
        _hasPermissions = true;
      } catch (e) {
        // If permission check fails, assume granted to avoid blocking UI
        _hasPermissions = true;
      }
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

