/// Screen Integration Helper
/// Provides utilities for integrating error handling and performance utilities across screens
/// 
/// Features:
/// - Error boundary wrapping
/// - Performance monitoring
/// - Cache integration
/// - Debounced actions

import 'package:flutter/material.dart';
import '../core/errors/global_error_handler.dart';
import '../core/errors/app_exceptions.dart';
import '../core/utils/retry_helper.dart';
import 'simple_cache.dart';
import 'debouncer.dart';

/// Wrap screen with error handling and performance utilities
Widget withScreenIntegration({
  required Widget child,
  String? errorMessage,
  VoidCallback? onRetry,
  bool enableCache = true,
  bool enableErrorBoundary = true,
}) {
  Widget result = child;

  if (enableErrorBoundary) {
    result = ErrorBoundary(
      errorMessage: errorMessage,
      onRetry: onRetry,
      child: result,
    );
  }

  return result;
}

/// Safe async operation with retry and error handling
Future<T?> safeAsyncOperation<T>({
  required Future<T> Function() operation,
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  String? cacheKey,
  Duration? cacheTTL,
  bool Function(dynamic error)? shouldRetry,
  void Function(int attempt, dynamic error)? onRetry,
}) async {
  try {
    // Check cache first if key provided
    if (cacheKey != null && cacheTTL != null) {
      final cached = SimpleCache().get<T>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    // Execute with retry
    final result = await RetryHelper.retry(
      operation: operation,
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
      shouldRetry: shouldRetry ?? (error) => error is! NetworkException,
      onRetry: onRetry,
    );

    // Cache result if key provided
    if (cacheKey != null && cacheTTL != null && result != null) {
      SimpleCache().set(cacheKey, result, ttl: cacheTTL);
    }

    return result;
  } catch (e) {
    debugPrint('Safe async operation failed: $e');
    return null;
  }
}

/// Debounced search helper
class DebouncedSearch {
  final Debouncer _debouncer;
  final Function(String query) onSearch;
  final Duration delay;

  DebouncedSearch({
    required this.onSearch,
    Duration? delay,
  })  : delay = delay ?? const Duration(milliseconds: 500),
        _debouncer = Debouncer(delay: delay ?? const Duration(milliseconds: 500));

  void search(String query) {
    _debouncer.debounce(() {
      onSearch(query);
    });
  }

  void cancel() {
    _debouncer.cancel();
  }

  void dispose() {
    _debouncer.cancel();
  }
}

/// Mixin for screens with performance utilities
mixin PerformanceScreenMixin<T extends StatefulWidget> on State<T> {
  final SimpleCache _cache = SimpleCache();
  final Map<String, Debouncer> _debouncers = {};

  @override
  void dispose() {
    // Clean up debouncers
    for (final debouncer in _debouncers.values) {
      debouncer.cancel();
    }
    _debouncers.clear();
    super.dispose();
  }

  /// Get or compute cached value
  Future<R> getCached<R>(
    String key,
    Future<R> Function() compute, {
    Duration? ttl,
  }) async {
    return await _cache.getOrCompute(key, compute, ttl: ttl);
  }

  /// Get debouncer for a key
  Debouncer getDebouncer(String key, {Duration? delay}) {
    if (!_debouncers.containsKey(key)) {
      _debouncers[key] = Debouncer(delay: delay ?? const Duration(milliseconds: 500));
    }
    return _debouncers[key]!;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Safe async operation
  Future<R?> safeOperation<R>({
    required Future<R> Function() operation,
    int maxAttempts = 3,
    String? cacheKey,
    Duration? cacheTTL,
  }) async {
    return await safeAsyncOperation<R>(
      operation: operation,
      maxAttempts: maxAttempts,
      cacheKey: cacheKey,
      cacheTTL: cacheTTL,
    );
  }
}

/// Error-aware FutureBuilder
class SafeFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)? errorBuilder;
  final Widget? loadingWidget;
  final String? cacheKey;
  final Duration? cacheTTL;

  const SafeFutureBuilder({
    Key? key,
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.loadingWidget,
    this.cacheKey,
    this.cacheTTL,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: cacheKey != null
          ? SimpleCache().getOrCompute(cacheKey!, () => future, ttl: cacheTTL)
          : future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(
              context,
              snapshot.error!,
              () {
                // Trigger rebuild
                (context as Element).markNeedsBuild();
              },
            );
          }

          return ErrorBoundary(
            errorMessage: snapshot.error.toString(),
            onRetry: () {
              (context as Element).markNeedsBuild();
            },
            child: const SizedBox.shrink(),
          );
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data!);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

