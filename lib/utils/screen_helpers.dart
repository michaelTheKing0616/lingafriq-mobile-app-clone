// Screen Helper Utilities
// Provides wrappers and helpers for consistent error handling and performance optimization across all screens

import 'package:flutter/material.dart';
import '../core/errors/global_error_handler.dart';
import '../core/errors/app_exceptions.dart';
import 'performance_utils.dart';

/// Wrapper widget that adds error boundary and performance optimizations to any screen
/// Use this to wrap your screen's build method content
class ScreenWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onRetry;
  final String? errorMessage;

  const ScreenWrapper({
    super.key,
    required this.child,
    this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onRetry: onRetry,
      errorMessage: errorMessage,
      child: child,
    );
  }
}

/// Helper extension for StatefulWidget to add error handling
extension ErrorHandlingStateExtension<T extends StatefulWidget> on State<T> {
  /// Wrap a widget with error boundary
  Widget withErrorBoundary(Widget child, {VoidCallback? onRetry, String? errorMessage}) {
    return ErrorBoundary(
      onRetry: onRetry,
      errorMessage: errorMessage,
      child: child,
    );
  }

  /// Execute an async operation with error handling
  Future<R?> safeAsync<R>(
    Future<R> Function() operation, {
    R? Function(dynamic error)? onError,
    VoidCallback? onRetry,
  }) async {
    try {
      return await operation();
    } catch (e, stack) {
      final exception = ExceptionHandler.handleError(e);
      debugPrint('🚨 Error in ${widget.runtimeType}: ${exception.message}');
      debugPrint('Stack trace: $stack');
      
      if (onError != null) {
        return onError(e);
      }
      
      // Show error dialog if no error handler provided
      if (mounted) {
        _showErrorDialog(context, exception, onRetry);
      }
      
      return null;
    }
  }

  void _showErrorDialog(BuildContext context, AppException exception, VoidCallback? onRetry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(ExceptionHandler.getUserFriendlyMessage(exception)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// Helper extension for StatelessWidget to add error handling
extension ErrorHandlingStatelessExtension on StatelessWidget {
  /// Wrap a widget with error boundary
  Widget withErrorBoundary(Widget child, {VoidCallback? onRetry, String? errorMessage}) {
    return ErrorBoundary(
      onRetry: onRetry,
      errorMessage: errorMessage,
      child: child,
    );
  }
}

/// Mixin for screens that need performance utilities
mixin PerformanceOptimizedScreen<T extends StatefulWidget> on State<T> {
  /// Debouncer instance for search operations
  late final Debouncer searchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  
  /// Cache instance for data caching
  late final SimpleCache cache = SimpleCache();

  @override
  void dispose() {
    searchDebouncer.dispose();
    cache.clear();
    super.dispose();
  }

  /// Debounced search callback
  void debouncedSearch(VoidCallback callback) {
    searchDebouncer.run(callback);
  }

  /// Get cached data or compute and cache
  U? getCachedOrCompute<U>(String key, U Function() compute, {Duration? ttl}) {
    final cached = cache.get(key);
    if (cached != null && cached is U) {
      return cached;
    }
    
    final value = compute();
    if (value != null) {
      cache.set(key, value, ttl: ttl);
    }
    return value;
  }
}

/// Builder widget that automatically applies performance optimizations
class OptimizedScreenBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    Debouncer searchDebouncer,
    SimpleCache cache,
  ) builder;

  const OptimizedScreenBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return _OptimizedScreenBuilderStateful(
      builder: builder,
    );
  }
}

class _OptimizedScreenBuilderStateful extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    Debouncer searchDebouncer,
    SimpleCache cache,
  ) builder;

  const _OptimizedScreenBuilderStateful({
    required this.builder,
  });

  @override
  State<_OptimizedScreenBuilderStateful> createState() => _OptimizedScreenBuilderStatefulState();
}

class _OptimizedScreenBuilderStatefulState extends State<_OptimizedScreenBuilderStateful> {
  late final Debouncer searchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  late final SimpleCache cache = SimpleCache();

  @override
  void dispose() {
    searchDebouncer.dispose();
    cache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, searchDebouncer, cache);
  }
}

