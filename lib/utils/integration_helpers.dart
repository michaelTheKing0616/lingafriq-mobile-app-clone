// Integration Helpers
// Utilities to quickly integrate ErrorHandler and Performance utilities
// across all screens
// 
// Production-ready integration helpers (December 2025)

import 'package:flutter/material.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/services/monitoring/sentry_service.dart';

/// Safe async execution with error handling
/// 
/// Wraps async operations with ErrorHandler and Sentry tracking
/// 
/// Example:
/// ```dart
/// await safeAsync(
///   context: context,
///   operation: () async {
///     await apiCall();
///   },
///   onError: (error) {
///     // Optional custom error handling
///   },
/// );
/// ```
Future<T?> safeAsync<T>({
  required BuildContext context,
  required Future<T> Function() operation,
  void Function(dynamic error)? onError,
  String? errorContext,
  bool showError = true,
}) async {
  try {
    return await operation();
  } catch (e, stackTrace) {
    // Log to Sentry
    SentryService().captureException(
      e,
      stackTrace: stackTrace,
      context: {
        'context': errorContext ?? 'Unknown',
        'screen': context.widget.runtimeType.toString(),
      },
    );

    // Show user-friendly error
    if (showError && context.mounted) {
      ErrorHandler.showError(context, e);
    }

    // Custom error handling
    if (onError != null) {
      onError(e);
    }

    return null;
  }
}

/// Safe async execution without UI error display
/// Useful for background operations
Future<T?> safeAsyncSilent<T>({
  required Future<T> Function() operation,
  void Function(dynamic error)? onError,
  String? errorContext,
}) async {
  try {
    return await operation();
  } catch (e, stackTrace) {
    // Log to Sentry
    SentryService().captureException(
      e,
      stackTrace: stackTrace,
      context: {
        'context': errorContext ?? 'Unknown',
      },
    );

    // Custom error handling
    if (onError != null) {
      onError(e);
    }

    return null;
  }
}

/// Create a debounced search function
/// 
/// Example:
/// ```dart
/// final searchDebouncer = createSearchDebouncer(
///   onSearch: (query) async {
///     final results = await searchUsers(query);
///     setState(() => searchResults = results);
///   },
/// );
/// 
/// // In TextField onChanged:
/// searchDebouncer(query);
/// ```
void Function(String query) createSearchDebouncer({
  required Future<void> Function(String query) onSearch,
  Duration delay = const Duration(milliseconds: 300),
}) {
  final debouncer = Debouncer(delay: delay);
  
  return (String query) {
    debouncer.run(() async {
      await onSearch(query);
    });
  };
}

/// Create a cached data fetcher
/// 
/// Example:
/// ```dart
/// final userCache = createDataCache<User>(
///   fetcher: (id) => fetchUser(id),
///   ttl: Duration(minutes: 5),
/// );
/// 
/// final user = await userCache.get('user_123');
/// ```
SimpleCache<String, T> createDataCache<T>({
  required Future<T> Function(String key) fetcher,
  Duration? ttl,
}) {
  return SimpleCache<String, T>(
    ttl: ttl ?? const Duration(minutes: 5),
    fetcher: fetcher,
  );
}

/// Wrap ListView with OptimizedListView
/// 
/// Automatically optimizes list rendering for better performance
Widget optimizedList({
  required int itemCount,
  required Widget Function(BuildContext, int) itemBuilder,
  ScrollController? controller,
  bool shrinkWrap = false,
  EdgeInsetsGeometry? padding,
  Axis scrollDirection = Axis.vertical,
}) {
  return OptimizedListView(
    itemCount: itemCount,
    itemBuilder: itemBuilder,
    controller: controller, padding: padding, );
}

/// Create a lazy image widget
/// 
/// Automatically handles caching and loading states
Widget lazyImage({
  required String imageUrl,
  Widget? placeholder,
  Widget? errorWidget,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  return LazyImage(
    imageUrl: imageUrl,
    placeholder: placeholder ?? const CircularProgressIndicator(),
    errorWidget: errorWidget ?? const Icon(Icons.error),
    fit: fit,
    width: width,
    height: height,
  );
}

/// Batch safe async operations
/// 
/// Executes multiple async operations safely and returns results
/// 
/// Example:
/// ```dart
/// final results = await batchSafeAsync(
///   context: context,
///   operations: [
///     () => fetchUserData(),
///     () => fetchSettings(),
///     () => fetchNotifications(),
///   ],
/// );
/// ```
Future<List<T?>> batchSafeAsync<T>({
  required BuildContext context,
  required List<Future<T> Function()> operations,
  String? errorContext,
}) async {
  final results = <T?>[];
  
  for (int i = 0; i < operations.length; i++) {
    final result = await safeAsync(
      context: context,
      operation: operations[i],
      errorContext: errorContext != null ? '$errorContext[$i]' : null,
      showError: false, // Don't show error for each, handle at end
    );
    results.add(result);
  }
  
  // Show error if all failed
  if (results.every((r) => r == null) && context.mounted) {
    ErrorHandler.showError(
      context,
      Exception('Failed to load data'),
    );
  }
  
  return results;
}

/// Retry mechanism with exponential backoff
/// 
/// Retries an operation with exponential backoff on failure
/// 
/// Example:
/// ```dart
/// final result = await retryWithBackoff(
///   operation: () => apiCall(),
///   maxRetries: 3,
/// );
/// ```
Future<T?> retryWithBackoff<T>({
  required Future<T> Function() operation,
  int maxRetries = 3,
  Duration initialDelay = const Duration(seconds: 1),
  double backoffMultiplier = 2.0,
}) async {
  int retries = 0;
  Duration delay = initialDelay;
  
  while (retries < maxRetries) {
    try {
      return await operation();
    } catch (e) {
      retries++;
      if (retries >= maxRetries) {
        rethrow;
      }
      await Future.delayed(delay);
      delay = Duration(milliseconds: (delay.inMilliseconds * backoffMultiplier).round());
    }
  }
  
  return null;
}

/// Safe navigation with error handling
/// 
/// Navigates to a screen and handles any errors during navigation
Future<T?> safeNavigate<T>({
  required BuildContext context,
  required Widget destination,
  bool replace = false,
}) async {
  try {
    if (replace) {
      return await Navigator.pushReplacement<T, void>(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } else {
      return await Navigator.push<T>(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ErrorHandler.showError(context, e);
    }
    return null;
  }
}

