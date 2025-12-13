import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Performance Monitor Service
/// Tracks app performance metrics
class PerformanceMonitor {
  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _durations = {};
  final Map<String, int> _counters = {};

  /// Start timing an operation
  void startTiming(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  /// End timing an operation
  Duration? endTiming(String operation) {
    final startTime = _startTimes.remove(operation);
    if (startTime == null) return null;

    final duration = DateTime.now().difference(startTime);
    _durations.putIfAbsent(operation, () => []).add(duration);
    
    // Keep only last 100 measurements
    final durations = _durations[operation]!;
    if (durations.length > 100) {
      durations.removeAt(0);
    }

    return duration;
  }

  /// Record a timing measurement
  void recordTiming(String operation, Duration duration) {
    _durations.putIfAbsent(operation, () => []).add(duration);
    
    final durations = _durations[operation]!;
    if (durations.length > 100) {
      durations.removeAt(0);
    }
  }

  /// Increment a counter
  void incrementCounter(String counter) {
    _counters[counter] = (_counters[counter] ?? 0) + 1;
  }

  /// Get average duration for an operation
  Duration? getAverageDuration(String operation) {
    final durations = _durations[operation];
    if (durations == null || durations.isEmpty) return null;

    final total = durations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: total ~/ durations.length);
  }

  /// Get all performance metrics
  Map<String, dynamic> getMetrics() {
    final metrics = <String, dynamic>{};
    
    // Average durations
    for (final entry in _durations.entries) {
      final avg = getAverageDuration(entry.key);
      if (avg != null) {
        metrics['${entry.key}_avg_ms'] = avg.inMilliseconds;
        metrics['${entry.key}_count'] = entry.value.length;
      }
    }
    
    // Counters
    metrics.addAll(_counters.map((k, v) => MapEntry('${k}_count', v)));
    
    return metrics;
  }

  /// Get performance report
  String getPerformanceReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Performance Report ===');
    
    // Durations
    for (final entry in _durations.entries) {
      final avg = getAverageDuration(entry.key);
      if (avg != null) {
        buffer.writeln('${entry.key}:');
        buffer.writeln('  Average: ${avg.inMilliseconds}ms');
        buffer.writeln('  Samples: ${entry.value.length}');
      }
    }
    
    // Counters
    if (_counters.isNotEmpty) {
      buffer.writeln('\nCounters:');
      for (final entry in _counters.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
    }
    
    return buffer.toString();
  }

  /// Clear all metrics
  void clearMetrics() {
    _startTimes.clear();
    _durations.clear();
    _counters.clear();
  }

  /// Log performance metrics
  void logMetrics() {
    debugPrint(getPerformanceReport());
  }
}

final performanceMonitorProvider = Provider<PerformanceMonitor>((ref) {
  return PerformanceMonitor();
});

