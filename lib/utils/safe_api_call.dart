import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';

/// Result wrapper for safe API calls
class SafeApiResult<T> {
  final T? data;
  final String? error;
  final bool success;
  final int? statusCode;

  SafeApiResult.success(this.data)
      : error = null,
        success = true,
        statusCode = null;

  SafeApiResult.failure(this.error, [this.statusCode])
      : data = null,
        success = false;
}

/// Utility for safe API calls with retry logic and error handling
class SafeApiCall {
  /// Execute an API call with automatic retry logic
  /// 
  /// [call] - The async function that performs the API call
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [retryDelay] - Delay between retries in seconds (default: 2)
  /// [retryCondition] - Optional function to determine if a retry should be attempted
  static Future<SafeApiResult<T>> execute<T>({
    required Future<T> Function() call,
    int maxRetries = 3,
    int retryDelay = 2,
    bool Function(DioException?)? retryCondition,
  }) async {
    int attempts = 0;
    DioException? lastException;

    while (attempts < maxRetries) {
      try {
        final result = await call();
        return SafeApiResult.success(result);
      } on DioException catch (e) {
        lastException = e;
        attempts++;

        // Check if we should retry
        final shouldRetry = retryCondition?.call(e) ?? _defaultRetryCondition(e);
        
        if (!shouldRetry || attempts >= maxRetries) {
          return SafeApiResult.failure(
            _getErrorMessage(e),
            e.response?.statusCode,
          );
        }

        // Wait before retrying
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: retryDelay * attempts));
          debugPrint('Retrying API call (attempt $attempts/$maxRetries)...');
        }
      } catch (e) {
        // Non-DioException errors
        return SafeApiResult.failure(
          e.toString(),
          null,
        );
      }
    }

    return SafeApiResult.failure(
      _getErrorMessage(lastException),
      lastException?.response?.statusCode,
    );
  }

  /// Default retry condition using unified TransportErrorPolicy
  static bool _defaultRetryCondition(DioException e) {
    return TransportErrorPolicy.isRetryable(e);
  }

  /// Get user-friendly error message from exception
  static String _getErrorMessage(DioException? e) {
    if (e == null) {
      return 'An unknown error occurred';
    }

    return TransportErrorPolicy.toUserMessage(e);
  }

  /// Execute an API call with null safety checks
  static Future<SafeApiResult<T?>> executeNullable<T>({
    required Future<T?> Function() call,
    int maxRetries = 3,
    int retryDelay = 2,
  }) async {
    return execute<T?>(
      call: call,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
    );
  }

  /// Execute multiple API calls in parallel with error handling
  static Future<List<SafeApiResult<T>>> executeParallel<T>({
    required List<Future<T> Function()> calls,
    int maxRetries = 3,
    int retryDelay = 2,
  }) async {
    final results = await Future.wait(
      calls.map((call) => execute(
        call: call,
        maxRetries: maxRetries,
        retryDelay: retryDelay,
      )),
    );
    return results;
  }
}

/// Extension for safe null checks
extension SafeAccess on dynamic {
  /// Safely access a property, returning null if the object is null
  T? safeGet<T>(T Function() getter) {
    try {
      if (this == null) return null;
      return getter();
    } catch (e) {
      debugPrint('Safe access error: $e');
      return null;
    }
  }

  /// Safely access a nested property
  T? safeNested<T>(T Function() getter) {
    try {
      return getter();
    } catch (e) {
      debugPrint('Safe nested access error: $e');
      return null;
    }
  }
}

/// Extension for safe list operations
extension SafeList<T> on List<T>? {
  /// Safely get first element or null
  T? get safeFirst => this?.isNotEmpty == true ? this!.first : null;

  /// Safely get last element or null
  T? get safeLast => this?.isNotEmpty == true ? this!.last : null;

  /// Safely get element at index or null
  T? safeAt(int index) {
    if (this == null || index < 0 || index >= this!.length) return null;
    return this![index];
  }
}

/// Extension for safe map operations
extension SafeMap<K, V> on Map<K, V>? {
  /// Safely get value or null
  V? safeGet(K key) => this?[key];

  /// Safely get value with default
  V safeGetOrDefault(K key, V defaultValue) => this?[key] ?? defaultValue;
}

