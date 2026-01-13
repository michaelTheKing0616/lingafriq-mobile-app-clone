import 'package:flutter/foundation.dart';

/// Minimal structured logger used across services/providers.
///
/// This keeps the app compiling even when advanced logging backends are not
/// wired up yet. In production you can route these to Sentry/analytics.
class StructuredLogger {
  const StructuredLogger();

  void debug(String message, {Map<String, dynamic>? context, Object? error}) {
    _log('DEBUG', message, context: context, error: error);
  }

  void info(String message, {Map<String, dynamic>? context, Object? error}) {
    _log('INFO', message, context: context, error: error);
  }

  void warn(String message, {Map<String, dynamic>? context, Object? error}) {
    _log('WARN', message, context: context, error: error);
  }

  void error(String message, {Map<String, dynamic>? context, Object? error}) {
    _log('ERROR', message, context: context, error: error);
  }

  void _log(
    String level,
    String message, {
    Map<String, dynamic>? context,
    Object? error,
  }) {
    final ctx = context == null ? '' : ' ctx=$context';
    final err = error == null ? '' : ' err=$error';
    debugPrint('[$level] $message$ctx$err');
  }
}

/// Global logger instance.
const logger = StructuredLogger();

