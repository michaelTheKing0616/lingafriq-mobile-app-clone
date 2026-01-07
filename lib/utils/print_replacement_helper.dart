/// Print Statement Replacement Helper
/// Provides utilities to help migrate from print/debugPrint to structured logging
/// 
/// This file contains helper functions and documentation for replacing print statements
/// with structured logging throughout the codebase.

import 'package:lingafriq/utils/structured_logger.dart';

/// Migration guide:
/// 
/// Replace patterns:
/// 
/// 1. Simple print statements:
///    OLD: print('Message');
///    NEW: logger.info('Message');
/// 
/// 2. Debug print statements:
///    OLD: debugPrint('Debug message');
///    NEW: logger.debug('Debug message');
/// 
/// 3. Error print statements:
///    OLD: print('Error: $e');
///    NEW: logger.error('Error message', error: e);
/// 
/// 4. Print with context:
///    OLD: print('User logged in: $userId');
///    NEW: logger.info('User logged in', context: {'userId': userId});
/// 
/// 5. Conditional print:
///    OLD: if (kDebugMode) print('Debug info');
///    NEW: logger.debug('Debug info'); // Logger handles debug mode automatically
/// 
/// Benefits:
/// - Structured logging with levels
/// - Sentry integration for errors
/// - Log buffering and statistics
/// - Production-ready logging

/// Quick replacement functions for common patterns
class PrintReplacement {
  /// Replace print with info log
  static void info(String message, {Map<String, dynamic>? context}) {
    logger.info(message, context: context);
  }

  /// Replace debugPrint with debug log
  static void debug(String message, {Map<String, dynamic>? context}) {
    logger.debug(message, context: context);
  }

  /// Replace error print with error log
  static void error(String message, {Object? error, Map<String, dynamic>? context}) {
    logger.error(message, error: error, context: context);
  }

  /// Replace warning print with warn log
  static void warn(String message, {Map<String, dynamic>? context}) {
    logger.warn(message, context: context);
  }
}

