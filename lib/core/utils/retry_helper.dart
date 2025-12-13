import 'package:flutter/foundation.dart';
import 'dart:async';

/// Retry Helper Utility
/// Provides retry logic with exponential backoff
class RetryHelper {
  /// Execute a function with retry logic
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        // Check if we should retry
        if (shouldRetry != null && !shouldRetry(error)) {
          debugPrint('Error not retryable: $error');
          rethrow;
        }

        // If this was the last attempt, rethrow
        if (attempt >= maxAttempts) {
          debugPrint('Max retry attempts ($maxAttempts) reached');
          rethrow;
        }

        // Call onRetry callback if provided
        if (onRetry != null) {
          onRetry(attempt, error);
        }

        debugPrint('Retry attempt $attempt/$maxAttempts after ${delay.inSeconds}s');
        
        // Wait before retrying
        await Future.delayed(delay);
        
        // Increase delay for next retry (exponential backoff)
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }

    // Should never reach here, but just in case
    throw Exception('Retry logic failed unexpectedly');
  }

  /// Execute with exponential backoff
  static Future<T> withExponentialBackoff<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    return retry(
      operation: operation,
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
      backoffMultiplier: 2.0,
    );
  }

  /// Execute with fixed delay
  static Future<T> withFixedDelay<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    return retry(
      operation: operation,
      maxAttempts: maxAttempts,
      initialDelay: delay,
      backoffMultiplier: 1.0,
    );
  }
}

