import 'package:dio/dio.dart';

/// Application-level exceptions
/// Centralized error handling for the app

/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

class TimeoutException extends NetworkException {
  TimeoutException(super.message, {super.code, super.originalError});
}

class ConnectionException extends NetworkException {
  ConnectionException(super.message, {super.code, super.originalError});
}

/// Authentication exceptions
class AuthenticationException extends AppException {
  AuthenticationException(super.message, {super.code, super.originalError});
}

class AuthorizationException extends AppException {
  AuthorizationException(super.message, {super.code, super.originalError});
}

/// Data exceptions
class DataException extends AppException {
  DataException(super.message, {super.code, super.originalError});
}

class ValidationException extends DataException {
  ValidationException(super.message, {super.code, super.originalError});
}

class NotFoundException extends DataException {
  NotFoundException(super.message, {super.code, super.originalError});
}

/// AI/Polie exceptions
class PolieException extends AppException {
  PolieException(super.message, {super.code, super.originalError});
}

class ContentGenerationException extends PolieException {
  ContentGenerationException(super.message, {super.code, super.originalError});
}

/// Cache exceptions
class CacheException extends AppException {
  CacheException(super.message, {super.code, super.originalError});
}

/// Unknown exception
class UnknownException extends AppException {
  UnknownException(super.message, {super.code, super.originalError});
}

/// Exception handler utility
class ExceptionHandler {
  /// Convert any error to AppException
  static AppException handleError(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is FormatException) {
      return DataException(
        'Invalid data format: ${error.message}',
        originalError: error,
      );
    }

    return UnknownException(
      'An unexpected error occurred: ${error.toString()}',
      originalError: error,
    );
  }

  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          'Request timed out. Please check your connection.',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return ConnectionException(
          'Unable to connect to server. Please check your internet connection.',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return AuthenticationException(
            'Authentication failed. Please login again.',
            code: '401',
            originalError: error,
          );
        } else if (statusCode == 403) {
          return AuthorizationException(
            'You do not have permission to perform this action.',
            code: '403',
            originalError: error,
          );
        } else if (statusCode == 404) {
          return NotFoundException(
            'The requested resource was not found.',
            code: '404',
            originalError: error,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return NetworkException(
            'Server error. Please try again later.',
            code: statusCode.toString(),
            originalError: error,
          );
        }
        return NetworkException(
          'Request failed with status ${statusCode ?? 'unknown'}',
          code: statusCode?.toString(),
          originalError: error,
        );

      case DioExceptionType.cancel:
        return NetworkException(
          'Request was cancelled.',
          originalError: error,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          'SSL certificate error. Please check your connection.',
          originalError: error,
        );

      case DioExceptionType.unknown:
        return NetworkException(
          'Network error: ${error.message ?? 'Unknown error'}',
          originalError: error,
        );
    }
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(AppException error) {
    if (error is TimeoutException) {
      return 'The request took too long. Please try again.';
    }
    if (error is ConnectionException) {
      return 'No internet connection. Please check your network settings.';
    }
    if (error is AuthenticationException) {
      return 'Please login to continue.';
    }
    if (error is AuthorizationException) {
      return 'You do not have permission for this action.';
    }
    if (error is NotFoundException) {
      return 'The requested content was not found.';
    }
    if (error is ValidationException) {
      return 'Invalid input. Please check your data.';
    }
    if (error is ContentGenerationException) {
      return 'Unable to generate content. Please try again.';
    }
    return error.message;
  }
}

