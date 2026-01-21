/// Screen Performance Tracker
/// Automatically tracks screen load times and performance metrics
/// 
/// Features:
/// - Automatic screen load tracking
/// - Route transition monitoring
/// - Memory usage tracking
/// - Navigation performance

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/painting.dart';
import 'dart:async';
import 'performance_monitor_integrated.dart';

/// Mixin for tracking screen performance
mixin ScreenPerformanceTracker<T extends StatefulWidget> on State<T> {
  final PerformanceMonitorIntegrated _monitor = PerformanceMonitorIntegrated();
  DateTime? _screenLoadStart;
  String? _screenName;
  Timer? _memoryCheckTimer;

  @override
  void initState() {
    super.initState();
    _screenName = widget.runtimeType.toString();
    _screenLoadStart = DateTime.now();

    // Track initial build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _trackScreenLoaded();
    });

    // Periodic memory check
    _memoryCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkMemoryUsage();
    });
  }

  @override
  void dispose() {
    _memoryCheckTimer?.cancel();
    super.dispose();
  }

  void _trackScreenLoaded() {
    if (_screenLoadStart != null) {
      final loadTime = DateTime.now().difference(_screenLoadStart!);
      _monitor.trackScreenLoad(_screenName ?? 'unknown', loadTime);
      _screenLoadStart = null;
    }
  }

  void _checkMemoryUsage() {
    if (mounted) {
      // Best-effort memory proxy without platform channels:
      // Flutter image cache size is a strong indicator of memory pressure for UI-heavy screens.
      final imageCache = PaintingBinding.instance.imageCache;
      final bytes = imageCache.currentSizeBytes;
      final mb = bytes / (1024 * 1024);
      _monitor.recordMetric(
        type: MetricType.memoryUsage,
        identifier: _screenName ?? 'unknown',
        value: mb,
        metadata: {
          'timestamp': DateTime.now().toIso8601String(),
          'image_cache_bytes': bytes,
          'image_cache_entries': imageCache.currentSize,
        },
      );
    }
  }

  /// Manually track a custom metric for this screen
  void trackMetric({
    required MetricType type,
    required String identifier,
    required double value,
    Map<String, dynamic>? metadata,
  }) {
    _monitor.recordMetric(
      type: type,
      identifier: '${_screenName}_$identifier',
      value: value,
      metadata: metadata,
    );
  }

  /// Start a timer for this screen
  void startTimer(String identifier, {MetricType type = MetricType.widgetBuild}) {
    _monitor.startTimer('${_screenName}_$identifier', type: type);
  }

  /// Stop a timer for this screen
  void stopTimer(String identifier, {MetricType type = MetricType.widgetBuild, Map<String, dynamic>? metadata}) {
    _monitor.stopTimer('${_screenName}_$identifier', type: type, metadata: metadata);
  }
}

/// Navigator observer for tracking route performance
class PerformanceNavigatorObserver extends NavigatorObserver {
  final PerformanceMonitorIntegrated _monitor = PerformanceMonitorIntegrated();
  final Map<String, DateTime> _routeStarts = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _routeStarts[route.settings.name ?? route.hashCode.toString()] = DateTime.now();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final routeName = route.settings.name ?? route.hashCode.toString();
    final startTime = _routeStarts.remove(routeName);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _monitor.recordMetric(
        type: MetricType.screenLoad,
        identifier: 'route_$routeName',
        value: duration.inMilliseconds.toDouble(),
        metadata: {
          'route': routeName,
          'previous_route': previousRoute?.settings.name,
        },
      );
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      final routeName = oldRoute.settings.name ?? oldRoute.hashCode.toString();
      _routeStarts.remove(routeName);
    }
    if (newRoute != null) {
      _routeStarts[newRoute.settings.name ?? newRoute.hashCode.toString()] = DateTime.now();
    }
  }
}

