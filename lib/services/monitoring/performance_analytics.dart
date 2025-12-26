import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/services/monitoring/sentry_service.dart';

/// World-class performance analytics service
/// Tracks performance metrics for all optimized components
/// Provides insights for performance optimization
class PerformanceAnalytics {
  static const String _metricsKey = 'performance_metrics';
  static const int _maxMetricsHistory = 1000; // Keep last 1000 metrics

  final Map<String, List<PerformanceMetric>> _metrics = {};
  final Map<String, Timer> _activeTimers = {};

  /// Start performance tracking for an operation
  String startTracking({
    required String operationName,
    Map<String, dynamic>? metadata,
  }) {
    final trackingId = '${operationName}_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();

    _activeTimers[trackingId] = Timer(Duration.zero, () {
      // Placeholder - actual tracking happens in stopTracking
    });

    // Store start metadata
    if (metadata != null) {
      _metrics[operationName] ??= [];
      _metrics[operationName]!.add(
        PerformanceMetric(
          operationName: operationName,
          duration: Duration.zero,
          startTime: startTime,
          metadata: metadata,
        ),
      );
    }

    return trackingId;
  }

  /// Stop performance tracking and record metric
  void stopTracking({
    required String trackingId,
    required String operationName,
    Map<String, dynamic>? additionalMetadata,
  }) {
    try {
      final timer = _activeTimers.remove(trackingId);
      if (timer == null) {
        debugPrint('Warning: No active timer found for $trackingId');
        return;
      }

      // Find the metric and update it
      final metrics = _metrics[operationName];
      if (metrics != null && metrics.isNotEmpty) {
        final metric = metrics.last;
        final duration = DateTime.now().difference(metric.startTime);
        
        // Update metric with duration
        final updatedMetric = PerformanceMetric(
          operationName: operationName,
          duration: duration,
          startTime: metric.startTime,
          endTime: DateTime.now(),
          metadata: {
            ...metric.metadata,
            ...?additionalMetadata,
          },
        );

        // Replace last metric with updated one
        metrics[metrics.length - 1] = updatedMetric;

        // Limit history size
        if (metrics.length > _maxMetricsHistory) {
          metrics.removeRange(0, metrics.length - _maxMetricsHistory);
        }

        // Log slow operations
        if (duration.inMilliseconds > 1000) {
          debugPrint('Slow operation detected: $operationName took ${duration.inMilliseconds}ms');
          SentryService().captureMessage(
            'Slow operation: $operationName',
            context: {
              'operation': operationName,
              'duration_ms': duration.inMilliseconds,
              'metadata': updatedMetric.metadata,
            },
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error stopping performance tracking: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
    }
  }

  /// Track performance metric directly
  void trackMetric({
    required String operationName,
    required Duration duration,
    Map<String, dynamic>? metadata,
  }) {
    try {
      _metrics[operationName] ??= [];
      _metrics[operationName]!.add(
        PerformanceMetric(
          operationName: operationName,
          duration: duration,
          startTime: DateTime.now().subtract(duration),
          endTime: DateTime.now(),
          metadata: metadata ?? {},
        ),
      );

      // Limit history size
      final metrics = _metrics[operationName]!;
      if (metrics.length > _maxMetricsHistory) {
        metrics.removeRange(0, metrics.length - _maxMetricsHistory);
      }
    } catch (e, stackTrace) {
      debugPrint('Error tracking metric: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
    }
  }

  /// Get performance statistics for an operation
  PerformanceStats getPerformanceStats(String operationName) {
    final metrics = _metrics[operationName] ?? [];
    
    if (metrics.isEmpty) {
      return PerformanceStats(
        operationName: operationName,
        count: 0,
        averageDuration: Duration.zero,
        minDuration: Duration.zero,
        maxDuration: Duration.zero,
        p50Duration: Duration.zero,
        p95Duration: Duration.zero,
        p99Duration: Duration.zero,
      );
    }

    final durations = metrics.map((m) => m.duration.inMilliseconds).toList()..sort();
    
    return PerformanceStats(
      operationName: operationName,
      count: metrics.length,
      averageDuration: Duration(
        milliseconds: (durations.reduce((a, b) => a + b) / durations.length).round(),
      ),
      minDuration: Duration(milliseconds: durations.first),
      maxDuration: Duration(milliseconds: durations.last),
      p50Duration: Duration(milliseconds: durations[durations.length ~/ 2]),
      p95Duration: Duration(
        milliseconds: durations[(durations.length * 0.95).round()],
      ),
      p99Duration: Duration(
        milliseconds: durations[(durations.length * 0.99).round()],
      ),
    );
  }

  /// Get all performance statistics
  Map<String, PerformanceStats> getAllPerformanceStats() {
    final stats = <String, PerformanceStats>{};
    
    for (final operationName in _metrics.keys) {
      stats[operationName] = getPerformanceStats(operationName);
    }
    
    return stats;
  }

  /// Get slow operations (above threshold)
  List<PerformanceMetric> getSlowOperations({
    Duration threshold = const Duration(milliseconds: 1000),
    int limit = 10,
  }) {
    final slowOperations = <PerformanceMetric>[];

    for (final metrics in _metrics.values) {
      for (final metric in metrics) {
        if (metric.duration > threshold) {
          slowOperations.add(metric);
        }
      }
    }

    slowOperations.sort((a, b) => b.duration.compareTo(a.duration));
    return slowOperations.take(limit).toList();
  }

  /// Clear performance metrics
  Future<void> clearMetrics({String? operationName}) async {
    try {
      if (operationName != null) {
        _metrics.remove(operationName);
      } else {
        _metrics.clear();
      }

      // Clear from storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_metricsKey);
    } catch (e, stackTrace) {
      debugPrint('Error clearing metrics: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
    }
  }

  /// Save performance metrics to storage
  Future<void> saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = _metrics.map(
        (key, value) => MapEntry(
          key,
          value.map((m) => m.toJson()).toList(),
        ),
      );
      
      // Convert to JSON string (simplified - in production, use proper serialization)
      await prefs.setString(_metricsKey, metricsJson.toString());
    } catch (e, stackTrace) {
      debugPrint('Error saving metrics: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
    }
  }

  /// Load performance metrics from storage
  Future<void> loadMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = prefs.getString(_metricsKey);
      
      if (metricsJson != null) {
        // Parse JSON (simplified - in production, use proper deserialization)
        // For now, just clear and start fresh
        _metrics.clear();
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading metrics: $e');
      SentryService().captureException(e, stackTrace: stackTrace);
    }
  }
}

/// Performance metric model
class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.startTime,
    this.endTime,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'operation_name': operationName,
      'duration_ms': duration.inMilliseconds,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Performance statistics model
class PerformanceStats {
  final String operationName;
  final int count;
  final Duration averageDuration;
  final Duration minDuration;
  final Duration maxDuration;
  final Duration p50Duration;
  final Duration p95Duration;
  final Duration p99Duration;

  PerformanceStats({
    required this.operationName,
    required this.count,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.p50Duration,
    required this.p95Duration,
    required this.p99Duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation_name': operationName,
      'count': count,
      'average_duration_ms': averageDuration.inMilliseconds,
      'min_duration_ms': minDuration.inMilliseconds,
      'max_duration_ms': maxDuration.inMilliseconds,
      'p50_duration_ms': p50Duration.inMilliseconds,
      'p95_duration_ms': p95Duration.inMilliseconds,
      'p99_duration_ms': p99Duration.inMilliseconds,
    };
  }
}

