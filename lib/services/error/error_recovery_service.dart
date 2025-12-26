import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lingafriq/services/monitoring/sentry_service.dart';

/// World-class error recovery service
/// Provides retry logic, offline handling, and graceful degradation
/// Production-ready error recovery for all network operations
class ErrorRecoveryService {
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(seconds: 30);

  final Connectivity _connectivity = Connectivity();

  /// Execute operation with automatic retry and error recovery
  Future<T> executeWithRecovery<T>({
    required Future<T> Function() operation,
    int? maxRetries,
    Duration? baseRetryDelay,
    bool Function(dynamic error)? shouldRetry,
    Future<void> Function(int attempt, dynamic error)? onRetry,
    T? fallbackValue,
    String? operationName,
  }) async {
    final retries = maxRetries ?? _maxRetries;
    final delay = baseRetryDelay ?? _baseRetryDelay;
    final shouldRetryFn = shouldRetry ?? _defaultShouldRetry;
    final opName = operationName ?? 'operation';

    int attempt = 0;
    dynamic lastError;
    StackTrace? lastStackTrace;

    while (attempt <= retries) {
      try {
        // Check connectivity before attempting
        if (attempt > 0) {
          final isConnected = await _checkConnectivity();
          if (!isConnected) {
            throw SocketException('No internet connection');
          }
        }

        // Execute operation
        return await operation();
      } catch (e, stackTrace) {
        lastError = e;
        lastStackTrace = stackTrace;

        debugPrint('Error in $opName (attempt ${attempt + 1}/$retries): $e');

        // Check if we should retry
        if (attempt < retries && shouldRetryFn(e)) {
          attempt++;
          
          // Calculate exponential backoff delay
          final retryDelay = _calculateRetryDelay(attempt, delay);
          
          debugPrint('Retrying $opName in ${retryDelay.inSeconds} seconds...');
          
          // Call onRetry callback if provided
          if (onRetry != null) {
            await onRetry(attempt, e);
          }

          // Wait before retrying
          await Future.delayed(retryDelay);
        } else {
          // No more retries or shouldn't retry
          break;
        }
      }
    }

    // All retries exhausted or error shouldn't be retried
    debugPrint('Failed $opName after $retries retries: $lastError');
    
    // Log to Sentry
    SentryService().captureException(
      lastError,
      stackTrace: lastStackTrace,
      context: {
        'operation': opName,
        'attempts': attempt,
        'max_retries': retries,
      },
    );

    // Return fallback value if provided
    if (fallbackValue != null) {
      debugPrint('Returning fallback value for $opName');
      return fallbackValue;
    }

    // Re-throw error if no fallback
    throw lastError ?? Exception('Operation failed after $retries retries');
  }

  /// Execute operation with offline handling
  Future<T?> executeWithOfflineHandling<T>({
    required Future<T> Function() onlineOperation,
    required Future<T?> Function() offlineOperation,
    T? Function()? fallbackValue,
    String? operationName,
  }) async {
    try {
      // Check connectivity
      final isConnected = await _checkConnectivity();

      if (isConnected) {
        // Try online operation with recovery
        return await executeWithRecovery(
          operation: onlineOperation,
          operationName: operationName ?? 'online_operation',
        );
      } else {
        // Use offline operation
        debugPrint('Offline mode: Using offline operation for ${operationName ?? 'operation'}');
        return await offlineOperation();
      }
    } catch (e, stackTrace) {
      debugPrint('Error in offline handling: $e');
      SentryService().captureException(e, stackTrace: stackTrace);

      // Try offline operation as fallback
      try {
        return await offlineOperation();
      } catch (offlineError) {
        debugPrint('Offline operation also failed: $offlineError');
        
        // Return fallback value if provided
        if (fallbackValue != null) {
          return fallbackValue();
        }
        
        return null;
      }
    }
  }

  /// Graceful degradation: Try primary, fallback to secondary
  Future<T> executeWithGracefulDegradation<T>({
    required Future<T> Function() primaryOperation,
    required Future<T> Function() fallbackOperation,
    String? operationName,
  }) async {
    try {
      return await executeWithRecovery(
        operation: primaryOperation,
        operationName: operationName ?? 'primary_operation',
      );
    } catch (e, stackTrace) {
      debugPrint('Primary operation failed, trying fallback: $e');
      SentryService().captureException(
        e,
        stackTrace: stackTrace,
        context: {
          'operation': operationName ?? 'primary_operation',
          'fallback_triggered': true,
        },
      );

      try {
        return await executeWithRecovery(
          operation: fallbackOperation,
          operationName: '${operationName ?? 'operation'}_fallback',
        );
      } catch (fallbackError, fallbackStackTrace) {
        debugPrint('Fallback operation also failed: $fallbackError');
        SentryService().captureException(
          fallbackError,
          stackTrace: fallbackStackTrace,
          context: {
            'operation': '${operationName ?? 'operation'}_fallback',
            'primary_failed': true,
          },
        );
        rethrow;
      }
    }
  }

  /// Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      // Assume connected if check fails (to avoid blocking operations)
      return true;
    }
  }

  /// Calculate exponential backoff delay
  Duration _calculateRetryDelay(int attempt, Duration baseDelay) {
    // Exponential backoff: baseDelay * 2^(attempt-1)
    final exponentialDelay = baseDelay * (1 << (attempt - 1));
    
    // Add jitter to prevent thundering herd
    final jitter = Duration(
      milliseconds: (exponentialDelay.inMilliseconds * 0.1 * (0.5 + (attempt % 2))).round(),
    );
    
    final totalDelay = exponentialDelay + jitter;
    
    // Cap at max delay
    return totalDelay > _maxRetryDelay ? _maxRetryDelay : totalDelay;
  }

  /// Default should retry logic
  bool _defaultShouldRetry(dynamic error) {
    // Retry on network errors
    if (error is SocketException || error is TimeoutException) {
      return true;
    }

    // Retry on HTTP 5xx errors (server errors)
    if (error is HttpException) {
      return true;
    }

    // Retry on specific error messages
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('503') ||
        errorString.contains('502') ||
        errorString.contains('504')) {
      return true;
    }

    // Don't retry on 4xx errors (client errors)
    if (errorString.contains('400') ||
        errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('404')) {
      return false;
    }

    // Default: retry
    return true;
  }

  /// Get retry strategy for specific error types
  RetryStrategy getRetryStrategy(dynamic error) {
    if (error is SocketException) {
      return RetryStrategy(
        maxRetries: 5,
        baseDelay: Duration(seconds: 1),
        shouldRetry: true,
      );
    }

    if (error is TimeoutException) {
      return RetryStrategy(
        maxRetries: 3,
        baseDelay: Duration(seconds: 2),
        shouldRetry: true,
      );
    }

    final errorString = error.toString().toLowerCase();
    if (errorString.contains('429')) {
      // Rate limit: longer delay
      return RetryStrategy(
        maxRetries: 3,
        baseDelay: Duration(seconds: 5),
        shouldRetry: true,
      );
    }

    // Default strategy
    return RetryStrategy(
      maxRetries: 3,
      baseDelay: Duration(seconds: 2),
      shouldRetry: _defaultShouldRetry(error),
    );
  }
}

/// Retry strategy configuration
class RetryStrategy {
  final int maxRetries;
  final Duration baseDelay;
  final bool shouldRetry;

  RetryStrategy({
    required this.maxRetries,
    required this.baseDelay,
    required this.shouldRetry,
  });
}

