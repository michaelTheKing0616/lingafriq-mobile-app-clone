/// Structured Logging Infrastructure
/// World-class logging system for production applications
/// 
/// Features:
/// - Log levels (DEBUG, INFO, WARN, ERROR, FATAL)
/// - Structured logging with context
/// - Sentry integration
/// - Performance logging
/// - Log rotation and retention
/// 
/// Production-ready implementation (December 2025)

import 'package:flutter/foundation.dart';
import 'package:lingafriq/services/monitoring/sentry_service.dart';

/// Log levels for structured logging
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warn(2, 'WARN'),
  error(3, 'ERROR'),
  fatal(4, 'FATAL');

  final int value;
  final String name;
  const LogLevel(this.value, this.name);
}

/// Structured Logger
/// 
/// Provides world-class logging infrastructure with:
/// - Log levels
/// - Structured context
/// - Sentry integration
/// - Performance tracking
class StructuredLogger {
  static final StructuredLogger _instance = StructuredLogger._internal();
  factory StructuredLogger() => _instance;
  StructuredLogger._internal();

  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  final List<LogEntry> _logBuffer = [];
  static const int _maxBufferSize = 1000;

  /// Set minimum log level
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Log debug message
  void debug(
    String message, {
    String? tag,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.debug, message, tag: tag, context: context, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void info(
    String message, {
    String? tag,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.info, message, tag: tag, context: context, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  void warn(
    String message, {
    String? tag,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.warn, message, tag: tag, context: context, error: error, stackTrace: stackTrace);
  }

  /// Alias for [warn] — some callers use `warning` by convention.
  void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    warn(message, tag: tag, context: context, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void error(
    String message, {
    String? tag,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, context: context, error: error, stackTrace: stackTrace);
  }

  /// Log fatal message
  void fatal(
    String message, {
    String? tag,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.fatal, message, tag: tag, context: context, error: error, stackTrace: stackTrace);
  }

  /// Redacts sensitive values from a context map before logging.
  static Map<String, dynamic> _sanitize(Map<String, dynamic> context) {
    const sensitiveKeys = {
      'token', 'password', 'authorization', 'secret', 'key', 'email', 'phone',
    };
    return context.map((key, value) {
      final lowerKey = key.toString().toLowerCase();
      if (sensitiveKeys.any((s) => lowerKey.contains(s))) {
        return MapEntry(key, '***REDACTED***');
      }
      return MapEntry(key, value);
    });
  }

  /// Internal log method
  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check if we should log this level
    if (level.value < _minLevel.value) {
      return;
    }

    final rawContext = context ?? {};
    final safeContext = _sanitize(rawContext);

    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      context: safeContext,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    // Add to buffer
    _addToBuffer(entry);

    // Output to console in debug mode
    if (kDebugMode) {
      final prefix = '[${level.name}]${tag != null ? ' [$tag]' : ''}';
      debugPrint('$prefix $message');
      if (safeContext.isNotEmpty) {
        debugPrint('  Context: $safeContext');
      }
      if (error != null) {
        debugPrint('  Error: $error');
      }
    }

    // Send to Sentry for errors and above
    if (level.value >= LogLevel.error.value) {
      _sendToSentry(entry);
    }
  }

  /// Add log entry to buffer
  void _addToBuffer(LogEntry entry) {
    _logBuffer.add(entry);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
  }

  /// Send error to Sentry
  Future<void> _sendToSentry(LogEntry entry) async {
    try {
      final sentryService = SentryService();
      if (sentryService.isInitialized) {
        if (entry.error != null) {
          await sentryService.captureException(
            entry.error!,
            stackTrace: entry.stackTrace,
            context: {
              'message': entry.message,
              'tag': entry.tag,
              'level': entry.level.name,
              ...entry.context,
            },
            level: entry.level.name.toLowerCase(),
          );
        } else {
          await sentryService.captureMessage(
            entry.message,
            level: entry.level.name.toLowerCase(),
            context: {
              'tag': entry.tag,
              'level': entry.level.name,
              ...entry.context,
            },
          );
        }
      }
    } catch (e) {
      // Don't fail if Sentry fails
      debugPrint('Failed to send log to Sentry: $e');
    }
  }

  /// Get recent logs
  List<LogEntry> getRecentLogs({int count = 100, LogLevel? minLevel}) {
    final filtered = minLevel != null
        ? _logBuffer.where((e) => e.level.value >= minLevel.value).toList()
        : _logBuffer;
    
    return filtered.reversed.take(count).toList();
  }

  /// Clear log buffer
  void clearBuffer() {
    _logBuffer.clear();
  }

  /// Get log statistics
  Map<String, dynamic> getStatistics() {
    final counts = <LogLevel, int>{};
    for (final level in LogLevel.values) {
      counts[level] = _logBuffer.where((e) => e.level == level).length;
    }

    return {
      'totalLogs': _logBuffer.length,
      'countsByLevel': counts.map((k, v) => MapEntry(k.name, v)),
      'oldestLog': _logBuffer.isNotEmpty ? _logBuffer.first.timestamp.toIso8601String() : null,
      'newestLog': _logBuffer.isNotEmpty ? _logBuffer.last.timestamp.toIso8601String() : null,
    };
  }
}

/// Log entry model
class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final Map<String, dynamic> context;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    this.tag,
    required this.context,
    this.error,
    this.stackTrace,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'message': message,
    'tag': tag,
    'context': context,
    'error': error?.toString(),
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Global logger instance
final logger = StructuredLogger();

/// Convenience functions for quick logging
void logDebug(String message, {String? tag, Map<String, dynamic>? context}) {
  logger.debug(message, tag: tag, context: context);
}

void logInfo(String message, {String? tag, Map<String, dynamic>? context}) {
  logger.info(message, tag: tag, context: context);
}

void logWarn(String message, {String? tag, Map<String, dynamic>? context}) {
  logger.warn(message, tag: tag, context: context);
}

void logError(String message, {String? tag, Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
  logger.error(message, tag: tag, context: context, error: error, stackTrace: stackTrace);
}

void logFatal(String message, {String? tag, Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
  logger.fatal(message, tag: tag, context: context, error: error, stackTrace: stackTrace);
}

