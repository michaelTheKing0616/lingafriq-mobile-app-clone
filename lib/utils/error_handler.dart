/// Error Handler Utility
/// Provides consistent error handling and user-friendly error messages

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:io';

class ErrorHandler {
  /// Get user-friendly error message from exception
  static String getUserFriendlyError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is FormatException) {
      return 'Invalid data format. Please try again.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    } else if (error is Exception) {
      return 'An error occurred: ${error.toString()}';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Check if error is due to network connectivity (no internet)
  /// This should only return true for actual network-level failures
  static bool _isNetworkError(DioException error) {
    // ConnectionError typically means DNS failure, no route to host, etc.
    // This is a true network-level issue
    if (error.type == DioExceptionType.connectionError) {
      // Check the error message for specific network failure indicators
      final message = error.message?.toLowerCase() ?? '';
      final errorStr = error.toString().toLowerCase();
      
      // True network errors: DNS failures, no route to host, network unreachable
      if (message.contains('failed host lookup') ||
          message.contains('name resolution') ||
          message.contains('network is unreachable') ||
          message.contains('no route to host') ||
          errorStr.contains('socketexception') ||
          errorStr.contains('os error')) {
        return true;
      }
      
      // If connectionError but we can't determine, be conservative
      // Assume it might be backend connectivity issue, not network
      return false;
    }
    
    return false;
  }

  /// Check if error is due to backend being unavailable (internet works, backend doesn't)
  /// This includes timeouts, connection refused, and server errors
  static bool _isBackendError(DioException error) {
    final statusCode = error.response?.statusCode;
    
    // Timeouts usually mean backend is slow or unreachable (but internet works)
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    
    // Server errors (5xx) mean backend is reachable but having issues
    if (statusCode != null && statusCode >= 500) {
      return true;
    }
    
    // ConnectionError that's not a true network issue (e.g., connection refused)
    if (error.type == DioExceptionType.connectionError) {
      final message = error.message?.toLowerCase() ?? '';
      // Connection refused means backend is not running or not accessible
      if (message.contains('connection refused') ||
          message.contains('connection reset') ||
          message.contains('connection closed')) {
        return true;
      }
    }
    
    return false;
  }

  /// Handle Dio-specific errors with better distinction between network and backend issues
  static String _handleDioError(DioException error) {
    // First check if it's a network connectivity issue (no internet)
    if (_isNetworkError(error)) {
      return 'No internet connection. Please check your network settings and try again.';
    }
    
    // Then check if it's a backend issue (internet works, backend unavailable)
    if (_isBackendError(error)) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return 'Server is temporarily unavailable. Your data is saved locally and will sync when the server is back online.';
      }
      
      // Check for connection refused (backend not running or wrong URL)
      final message = error.message?.toLowerCase() ?? '';
      if (message.contains('connection refused') || 
          message.contains('connection reset')) {
        return 'Cannot connect to server. Please check your connection or try again later.';
      }
      
      // Timeout or other backend issues
      return 'Server is taking too long to respond. Your data is saved locally and will sync automatically.';
    }
    
    switch (error.type) {
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Authentication failed. Please log in again.';
        } else if (statusCode == 403) {
          return 'You don\'t have permission to perform this action.';
        } else if (statusCode == 404) {
          return 'The requested resource was not found.';
        } else if (statusCode == 429) {
          // CRITICAL: Never show raw 429 to users - use friendly message
          final retryAfter = error.response?.headers.value('retry-after');
          if (retryAfter != null) {
            final seconds = int.tryParse(retryAfter) ?? 60;
            final minutes = (seconds / 60).ceil();
            return 'Please slow down. Try again in ${minutes} minute${minutes > 1 ? 's' : ''}.';
          }
          return 'You\'re making requests too quickly. Please wait a moment and try again.';
        } else if (statusCode == 500) {
          return 'Server error. Your data is saved locally and will sync when the server is back online.';
        } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          final message = error.response?.data?['message'] as String?;
          return message ?? 'Request failed. Please try again.';
        } else {
          return 'Server error. Your data is saved locally and will sync when the server is back online.';
        }
      
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      
      case DioExceptionType.badCertificate:
        return 'Security certificate error. Please try again.';
      
      case DioExceptionType.unknown:
      default:
        // Try to determine if it's network or backend
        final message = error.message?.toLowerCase() ?? '';
        if (message.contains('network') || message.contains('internet') || message.contains('connection')) {
          return 'Network error. Please check your internet connection and try again.';
        }
        return 'Unable to reach server. Your data is saved locally and will sync automatically when connection is restored.';
    }
  }

  /// Show error snackbar
  static void showError(BuildContext context, dynamic error, {String? customMessage}) {
    if (!context.mounted) return;
    
    final message = customMessage ?? getUserFriendlyError(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
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
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
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
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
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
    
    String message;
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timed out. Please check your internet connection.';
        break;
        
      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          message = 'Authentication failed. Please log in again.';
        } else if (statusCode == 403) {
          message = 'You don\'t have permission to perform this action.';
        } else if (statusCode == 404) {
          message = 'The requested resource was not found.';
        } else if (statusCode == 429) {
          // CRITICAL: Never show raw 429 to users - use friendly message
          final retryAfter = error.response?.headers.value('retry-after');
          if (retryAfter != null) {
            final seconds = int.tryParse(retryAfter) ?? 60;
            final minutes = (seconds / 60).ceil();
            message = 'Please slow down. Try again in ${minutes} minute${minutes > 1 ? 's' : ''}.';
          } else {
            message = 'You\'re making requests too quickly. Please wait a moment and try again.';
          }
        } else if (statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          message = responseData?['message'] as String? ??
                    responseData?['error'] as String? ??
                    responseData?['detail'] as String? ??
                    'Request failed. Please try again.';
        } else {
          message = 'Server error. Please try again later.';
        }
        break;
        
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
        
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network settings.';
        break;
        
      case DioExceptionType.badCertificate:
        message = 'Security certificate error. Please try again.';
        break;
        
      case DioExceptionType.unknown:
      default:
        message = 'Network error. Please check your connection and try again.';
    }
    
    return ApiError(message, statusCode: statusCode, responseData: responseData, originalError: error);
  }
  
  /// Get user-friendly error message from AppError
  static String getUserMessage(AppError error) {
    return error.message;
  }
}

