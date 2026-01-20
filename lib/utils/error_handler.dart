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

  /// Handle Dio-specific errors
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connection.';
      
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
          return 'Server error. Please try again later.';
        } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          final message = error.response?.data?['message'] as String?;
          return message ?? 'Request failed. Please try again.';
        } else {
          return 'Server error. Please try again later.';
        }
      
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network settings.';
      
      case DioExceptionType.badCertificate:
        return 'Security certificate error. Please try again.';
      
      case DioExceptionType.unknown:
      default:
        return 'Network error. Please check your connection and try again.';
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

