// Integrated Performance Monitor
// Tracks performance metrics for all optimized components
// 
// Features:
// - Screen load time tracking
// - List rendering performance
// - Image loading metrics
// - Cache hit/miss rates
// - API call performance
// - Memory usage tracking

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;

/// Performance metric types
enum MetricType {
  screenLoad,
  listRender,
  imageLoad,
  apiCall,
  cacheHit,
  cacheMiss,
  memoryUsage,
  widgetBuild,
}

/// Performance metric
class PerformanceMetric {
  final MetricType type;
  final String identifier;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceMetric({
    required this.type,
    required this.identifier,
    required this.value,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'identifier': identifier,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Performance statistics
class PerformanceStats {
  final String identifier;
  final MetricType type;
  final double average;
  final double min;
  final double max;
  final int count;
  final double p50;
  final double p95;
  final double p99;

  PerformanceStats({
    required this.identifier,
    required this.type,
    required this.average,
    required this.min,
    required this.max,
    required this.count,
    required this.p50,
    required this.p95,
    required this.p99,
  });
}

/// Integrated Performance Monitor
class PerformanceMonitorIntegrated {
  static final PerformanceMonitorIntegrated _instance = PerformanceMonitorIntegrated._internal();
  factory PerformanceMonitorIntegrated() => _instance;
  PerformanceMonitorIntegrated._internal();

  final List<PerformanceMetric> _metrics = [];
  final Map<String, Stopwatch> _activeTimers = {};
  final int _maxMetrics = 10000;
  bool _enabled = true;

  /// Enable/disable performance monitoring
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Start tracking a metric
  void startTimer(String identifier, {MetricType type = MetricType.widgetBuild}) {
    if (!_enabled) return;

    _activeTimers[identifier] = Stopwatch()..start();
  }

  /// Stop tracking and record metric
  void stopTimer(String identifier, {MetricType type = MetricType.widgetBuild, Map<String, dynamic>? metadata}) {
    if (!_enabled) return;

    final timer = _activeTimers.remove(identifier);
    if (timer != null) {
      timer.stop();
      recordMetric(
        type: type,
        identifier: identifier,
        value: timer.elapsedMilliseconds.toDouble(),
        metadata: metadata,
      );
    }
  }

  /// Record a performance metric
  void recordMetric({
    required MetricType type,
    required String identifier,
    required double value,
    Map<String, dynamic>? metadata,
  }) {
    if (!_enabled) return;

    final metric = PerformanceMetric(
      type: type,
      identifier: identifier,
      value: value,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _metrics.add(metric);

    // Evict old metrics if needed
    if (_metrics.length > _maxMetrics) {
      _metrics.removeRange(0, _metrics.length - _maxMetrics);
    }

    if (kDebugMode) {
      debugPrint('📊 Performance: ${type.name} - $identifier: ${value.toStringAsFixed(2)}ms');
    }
  }

  /// Get metrics for identifier
  List<PerformanceMetric> getMetrics(String identifier, {MetricType? type}) {
    return _metrics.where((m) {
      if (m.identifier != identifier) return false;
      if (type != null && m.type != type) return false;
      return true;
    }).toList();
  }

  /// Get statistics for identifier
  PerformanceStats? getStats(String identifier, {MetricType? type}) {
    final metrics = getMetrics(identifier, type: type);
    if (metrics.isEmpty) return null;

    final values = metrics.map((m) => m.value).toList()..sort();
    final count = values.length;
    final sum = values.reduce((a, b) => a + b);
    final average = sum / count;

    return PerformanceStats(
      identifier: identifier,
      type: type ?? MetricType.widgetBuild,
      average: average,
      min: values.first,
      max: values.last,
      count: count,
      p50: _percentile(values, 0.5),
      p95: _percentile(values, 0.95),
      p99: _percentile(values, 0.99),
    );
  }

  double _percentile(List<double> sortedValues, double percentile) {
    if (sortedValues.isEmpty) return 0.0;
    final index = (sortedValues.length * percentile).floor();
    return sortedValues[math.min(index, sortedValues.length - 1)];
  }

  /// Track screen load time
  void trackScreenLoad(String screenName, Duration loadTime) {
    recordMetric(
      type: MetricType.screenLoad,
      identifier: screenName,
      value: loadTime.inMilliseconds.toDouble(),
    );
  }

  /// Track list rendering performance
  void trackListRender(String listId, int itemCount, Duration renderTime) {
    recordMetric(
      type: MetricType.listRender,
      identifier: listId,
      value: renderTime.inMilliseconds.toDouble(),
      metadata: {'item_count': itemCount},
    );
  }

  /// Track image load time
  void trackImageLoad(String imageUrl, Duration loadTime, {bool cached = false}) {
    recordMetric(
      type: cached ? MetricType.cacheHit : MetricType.imageLoad,
      identifier: imageUrl,
      value: loadTime.inMilliseconds.toDouble(),
      metadata: {'cached': cached},
    );
  }

  /// Track API call performance
  void trackApiCall(String endpoint, Duration duration, {int? statusCode, int? responseSize}) {
    recordMetric(
      type: MetricType.apiCall,
      identifier: endpoint,
      value: duration.inMilliseconds.toDouble(),
      metadata: {
        if (statusCode != null) 'status_code': statusCode,
        if (responseSize != null) 'response_size': responseSize,
      },
    );
  }

  /// Track cache hit
  void trackCacheHit(String cacheKey) {
    recordMetric(
      type: MetricType.cacheHit,
      identifier: cacheKey,
      value: 1.0,
    );
  }

  /// Track cache miss
  void trackCacheMiss(String cacheKey) {
    recordMetric(
      type: MetricType.cacheMiss,
      identifier: cacheKey,
      value: 1.0,
    );
  }

  /// Get all metrics
  List<PerformanceMetric> getAllMetrics({MetricType? type}) {
    if (type != null) {
      return _metrics.where((m) => m.type == type).toList();
    }
    return List.unmodifiable(_metrics);
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _activeTimers.clear();
  }

  /// Get cache hit rate
  double getCacheHitRate(String cacheKey) {
    final hits = _metrics.where((m) =>
        m.identifier == cacheKey && m.type == MetricType.cacheHit).length;
    final misses = _metrics.where((m) =>
        m.identifier == cacheKey && m.type == MetricType.cacheMiss).length;
    final total = hits + misses;
    return total > 0 ? hits / total : 0.0;
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{
      'total_metrics': _metrics.length,
      'active_timers': _activeTimers.length,
      'metrics_by_type': {},
      'top_slow_screens': [],
      'cache_stats': {},
    };

    // Group by type
    final byType = <MetricType, List<PerformanceMetric>>{};
    for (final metric in _metrics) {
      byType.putIfAbsent(metric.type, () => []).add(metric);
    }

    for (final entry in byType.entries) {
      report['metrics_by_type'][entry.key.name] = entry.value.length;
    }

    // Top slow screens
    final screenMetrics = _metrics
        .where((m) => m.type == MetricType.screenLoad)
        .toList();
    screenMetrics.sort((a, b) => b.value.compareTo(a.value));
    report['top_slow_screens'] = screenMetrics.take(10).map((m) => {
      'screen': m.identifier,
      'avg_load_time_ms': m.value,
    }).toList();

    return report;
  }

  /// Export metrics for analytics
  Future<void> exportMetrics(Function(List<Map<String, dynamic>>) exporter) async {
    final jsonMetrics = _metrics.map((m) => m.toJson()).toList();
    await exporter(jsonMetrics);
  }
}

