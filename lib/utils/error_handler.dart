// Error Handler Utility
// Provides consistent error handling and user-friendly error messages
// 
// Features:
// - Comprehensive error categorization
// - User-friendly error messages
// - Retry mechanisms with exponential backoff
// - Error logging and tracking support
// - Global error boundary widget

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:io';
import 'package:lingafriq/utils/transport_error_policy.dart';

/// Error category for analytics and handling
enum ErrorCategory {
  network,      // No internet, DNS failures
  backend,      // Server errors, timeouts
  auth,         // Authentication/authorization failures
  validation,   // Input validation errors
  rateLimit,    // Rate limiting errors
  notFound,     // Resource not found
  permission,   // Permission denied
  client,       // Client-side errors
  unknown,      // Unclassified errors
}

/// Error severity for logging
enum ErrorSeverity {
  low,       // User can easily recover
  medium,    // May require retry
  high,      // May require user action
  critical,  // App may not function properly
}

/// Structured error info for logging and analytics
class ErrorInfo {
  final String message;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final int? statusCode;
  final String? originalError;
  final DateTime timestamp;
  final String? endpoint;
  final Map<String, dynamic>? metadata;

  ErrorInfo({
    required this.message,
    required this.category,
    required this.severity,
    this.statusCode,
    this.originalError,
    this.endpoint,
    this.metadata,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
    'message': message,
    'category': category.name,
    'severity': severity.name,
    'statusCode': statusCode,
    'originalError': originalError,
    'timestamp': timestamp.toIso8601String(),
    'endpoint': endpoint,
    'metadata': metadata,
  };
}

/// Error logging callback type
typedef ErrorLogger = void Function(ErrorInfo info);

/// Global error logging configuration
class ErrorLogging {
  static ErrorLogger? _logger;
  static final List<ErrorInfo> _recentErrors = [];
  static const int _maxRecentErrors = 50;

  /// Set custom error logger
  static void setLogger(ErrorLogger logger) {
    _logger = logger;
  }

  /// Log an error
  static void log(ErrorInfo info) {
    _recentErrors.add(info);
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeAt(0);
    }
    
    _logger?.call(info);
    
    // Also log to console in debug mode
    if (kDebugMode) {
      debugPrint('[${info.severity.name.toUpperCase()}] ${info.category.name}: ${info.message}');
      if (info.originalError != null) {
        debugPrint('  Original: ${info.originalError}');
      }
    }
  }

  /// Get recent errors for debugging
  static List<ErrorInfo> get recentErrors => List.unmodifiable(_recentErrors);

  /// Clear error history
  static void clearHistory() => _recentErrors.clear();
}

class ErrorHandler {
  /// Alias for getUserFriendlyError (backward compatibility)
  static String userFacingMessage(dynamic error) => getUserFriendlyError(error);

  /// Categorize an error
  static ErrorCategory categorizeError(dynamic error) {
    if (error is DioException) {
      if (_isBackendError(error)) return ErrorCategory.backend;
      if (_isNetworkError(error)) return ErrorCategory.network;
      
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) return ErrorCategory.auth;
      if (statusCode == 403) return ErrorCategory.permission;
      if (statusCode == 404) return ErrorCategory.notFound;
      if (statusCode == 429) return ErrorCategory.rateLimit;
      if (statusCode != null && statusCode >= 400 && statusCode < 500) return ErrorCategory.validation;
      
      return ErrorCategory.unknown;
    }
    
    if (error is FormatException) return ErrorCategory.validation;
    if (error is TimeoutException) return ErrorCategory.backend;
    if (error is SocketException) return ErrorCategory.network;
    if (error is ApiError) {
      if (error.statusCode == 401) return ErrorCategory.auth;
      if (error.statusCode == 403) return ErrorCategory.permission;
      if (error.statusCode == 404) return ErrorCategory.notFound;
      if (error.statusCode == 429) return ErrorCategory.rateLimit;
      return ErrorCategory.backend;
    }
    
    return ErrorCategory.unknown;
  }

  /// Get error severity
  static ErrorSeverity getErrorSeverity(dynamic error) {
    final category = categorizeError(error);
    
    switch (category) {
      case ErrorCategory.network:
        return ErrorSeverity.medium;
      case ErrorCategory.backend:
        return ErrorSeverity.medium;
      case ErrorCategory.auth:
        return ErrorSeverity.high;
      case ErrorCategory.validation:
        return ErrorSeverity.low;
      case ErrorCategory.rateLimit:
        return ErrorSeverity.low;
      case ErrorCategory.notFound:
        return ErrorSeverity.low;
      case ErrorCategory.permission:
        return ErrorSeverity.high;
      case ErrorCategory.client:
        return ErrorSeverity.high;
      case ErrorCategory.unknown:
        return ErrorSeverity.medium;
    }
  }

  /// Handle error with logging
  static String handleError(
    dynamic error, {
    String? endpoint,
    Map<String, dynamic>? metadata,
    bool log = true,
  }) {
    final message = getUserFriendlyError(error);
    
    if (log) {
      final info = ErrorInfo(
        message: message,
        category: categorizeError(error),
        severity: getErrorSeverity(error),
        statusCode: error is DioException ? error.response?.statusCode : null,
        originalError: error.toString(),
        endpoint: endpoint,
        metadata: metadata,
      );
      ErrorLogging.log(info);
    }
    
    return message;
  }

  /// Get user-friendly error message from exception
  static String getUserFriendlyError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is FormatException) {
      return 'Invalid data format. Please try again.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    } else if (error is Exception) {
      final msg = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
      if (msg.isEmpty) return 'Something went wrong. Please try again.';
      final lower = msg.toLowerCase();
      if (lower.contains('an error occurred') || lower.contains('error occurred') || lower == 'something went wrong') {
        return 'Something went wrong. Please check your connection and try again.';
      }
      return msg.length > 200 ? '${msg.substring(0, 200)}…' : msg;
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Check if error is due to network connectivity (no internet)
  /// This should only return true for actual network-level failures
  static bool _isNetworkError(DioException error) {
    return TransportErrorPolicy.isNetworkIssue(error);
  }

  /// Check if error is due to backend being unavailable (internet works, backend doesn't)
  /// This includes timeouts, connection refused, and server errors
  static bool _isBackendError(DioException error) {
    return TransportErrorPolicy.isBackendIssue(error);
  }

  /// Handle Dio-specific errors with better distinction between network and backend issues
  static String _handleDioError(DioException error) {
    return TransportErrorPolicy.toUserMessage(error);
  }

  /// Show error snackbar
  static void showError(BuildContext context, dynamic error, {String? customMessage}) {
    if (!context.mounted) return;
    
    final message = customMessage ?? getUserFriendlyError(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onError),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.onPrimary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Show info snackbar
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Handle error with retry option
  static Future<T?> handleErrorWithRetry<T>({
    required BuildContext context,
    required Future<T> Function() action,
    String? errorMessage,
    String retryText = 'Retry',
  }) async {
    try {
      return await action();
    } catch (error) {
      if (!context.mounted) return null;
      
      final message = errorMessage ?? getUserFriendlyError(error);
      
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(retryText),
            ),
          ],
        ),
      );
      
      if (result == true && context.mounted) {
        return handleErrorWithRetry(
          context: context,
          action: action,
          errorMessage: errorMessage,
          retryText: retryText,
        );
      }
      
      return null;
    }
  }
}

/// Timeout exception for better error handling
class TimeoutException implements Exception {
  final String message;
  TimeoutException([this.message = 'Operation timed out']);
  
  @override
  String toString() => message;
}

/// Base error class for application errors
abstract class AppError implements Exception {
  final String message;
  final dynamic originalError;
  
  AppError(this.message, [this.originalError]);
  
  @override
  String toString() => message;
}

/// API-specific error
class ApiError extends AppError {
  final int? statusCode;
  final Map<String, dynamic>? responseData;
  
  ApiError(String message, {this.statusCode, this.responseData, dynamic originalError})
      : super(message, originalError);
}

/// Generic AppError implementation
class _GenericAppError extends AppError {
  _GenericAppError(String message, [dynamic originalError]) : super(message, originalError);
}

/// Error converter utility
class ErrorConverter {
  /// Convert any error to AppError
  static AppError toAppError(dynamic error) {
    if (error is AppError) {
      return error;
    }
    
    if (error is DioException) {
      return _fromDioError(error);
    }
    
    if (error is FormatException) {
      return _GenericAppError('Invalid data format. Please try again.', error);
    }
    
    if (error is TimeoutException) {
      return _GenericAppError('Request timed out. Please check your connection and try again.', error);
    }
    
    if (error is SocketException) {
      return _GenericAppError('No internet connection. Please check your network settings.', error);
    }
    
    // Generic error
    final message = error?.toString() ?? 'An unexpected error occurred. Please try again.';
    return _GenericAppError(message, error);
  }
  
  /// Convert DioException to ApiError
  static ApiError _fromDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data is Map
        ? Map<String, dynamic>.from(error.response!.data)
        : null;

    // Delegate to the single transport error policy so all DioException mapping
    // lives in one place. This eliminates the duplicated switch/case that
    // previously drifted out of sync with ErrorHandler._handleDioError.
    final message = TransportErrorPolicy.toUserMessage(error);
    
    return ApiError(message, statusCode: statusCode, responseData: responseData, originalError: error);
  }
  
  /// Get user-friendly error message from AppError
  static String getUserMessage(AppError error) {
    return error.message;
  }
}

/// Global Error Boundary Widget
/// Catches errors in the widget tree and displays a fallback UI
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails details)? errorBuilder;
  final void Function(FlutterErrorDetails details)? onError;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
    this.onError,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
    // Set up error handling for this widget tree
    FlutterError.onError = _handleError;
  }

  void _handleError(FlutterErrorDetails details) {
    // Log the error
    ErrorLogging.log(ErrorInfo(
      message: details.exceptionAsString(),
      category: ErrorCategory.client,
      severity: ErrorSeverity.critical,
      originalError: details.stack.toString(),
      metadata: {'library': details.library},
    ));

    // Call custom error handler
    widget.onError?.call(details);

    // Update UI
    if (mounted) {
      setState(() => _error = details);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? _DefaultErrorWidget(details: _error!);
    }
    return widget.child;
  }
}

/// Default error widget shown when an error occurs
class _DefaultErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const _DefaultErrorWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isDark ? const Color(0xFF1A1A1A) : Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The app encountered an unexpected error. Please try again.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (kDebugMode) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      details.exceptionAsString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade900,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Async Error Handler Mixin
/// Provides error handling utilities for StatefulWidgets
mixin AsyncErrorHandler<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Execute async operation with error handling
  Future<R?> runAsync<R>(
    Future<R> Function() operation, {
    void Function(R result)? onSuccess,
    void Function(String error)? onError,
    bool showError = true,
  }) async {
    if (_isLoading) return null;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await operation();
      onSuccess?.call(result);
      return result;
    } catch (e) {
      final message = ErrorHandler.handleError(e);
      
      if (mounted) {
        setState(() => _errorMessage = message);
        
        if (showError) {
          ErrorHandler.showError(context, e);
        }
        
        onError?.call(message);
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Clear error state
  void clearError() {
    if (mounted) {
      setState(() => _errorMessage = null);
    }
  }
}

/// Result type for operations that can fail
class Result<T> {
  final T? data;
  final String? error;
  final ErrorCategory? errorCategory;

  Result._({this.data, this.error, this.errorCategory});

  factory Result.success(T data) => Result._(data: data);
  factory Result.failure(String error, [ErrorCategory? category]) => 
      Result._(error: error, errorCategory: category ?? ErrorCategory.unknown);

  bool get isSuccess => data != null && error == null;
  bool get isFailure => error != null;

  /// Transform the success value
  Result<R> map<R>(R Function(T data) transform) {
    if (isSuccess) {
      return Result.success(transform(data as T));
    }
    return Result.failure(error!, errorCategory);
  }

  /// Handle both success and failure cases
  R fold<R>(R Function(String error) onFailure, R Function(T data) onSuccess) {
    if (isSuccess) {
      return onSuccess(data as T);
    }
    return onFailure(error!);
  }

  /// Convert to Result from try-catch
  static Future<Result<T>> guard<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      return Result.success(result);
    } catch (e) {
      final message = ErrorHandler.getUserFriendlyError(e);
      final category = ErrorHandler.categorizeError(e);
      return Result.failure(message, category);
    }
  }
}

