import 'package:dio/dio.dart';
import '../errors/app_exceptions.dart';
import '../../utils/structured_logger.dart';

/// API Error Handler
/// Wraps API calls with proper error handling and converts to AppException
class ApiErrorHandler {
  /// Execute API call with error handling
  static Future<T> execute<T>({
    required Future<T> Function() apiCall,
    String? errorMessage,
    T? fallbackValue,
  }) async {
    try {
      return await apiCall();
    } catch (e) {
      final exception = ExceptionHandler.handleError(e);
      
      logger.error(
        'API error occurred',
        tag: 'api-error-handler',
        context: {
          'errorMessage': errorMessage,
          'exceptionType': exception.runtimeType.toString(),
          'message': exception.message,
          if (e is DioException) ...{
            'dioExceptionType': e.type.toString(),
            'statusCode': e.response?.statusCode,
            'responseData': e.response?.data?.toString(),
          },
        },
        error: e,
      );
      
      // If fallback value provided, return it instead of throwing
      if (fallbackValue != null) {
        return fallbackValue;
      }
      
      // Re-throw as AppException
      throw exception;
    }
  }

  /// Execute API call with retry logic
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() apiCall,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
    T? fallbackValue,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await apiCall();
      } catch (e) {
        attempts++;
        
        // Check if we should retry
        if (shouldRetry != null && !shouldRetry(e)) {
          throw ExceptionHandler.handleError(e);
        }
        
        // Don't retry on last attempt
        if (attempts >= maxRetries) {
          if (fallbackValue != null) {
            return fallbackValue;
          }
          throw ExceptionHandler.handleError(e);
        }
        
        // Wait before retrying
        await Future.delayed(retryDelay * attempts);
        logger.info(
          'Retrying API call',
          tag: 'api-error-handler',
          context: {
            'attempt': attempts,
            'maxRetries': maxRetries,
          },
        );
      }
    }
    
    // Should never reach here, but just in case
    throw UnknownException('Failed after $maxRetries attempts');
  }

  /// Check if error is retryable
  static bool isRetryable(dynamic error) {
    if (error is DioException) {
      // Retry on network errors and 5xx server errors
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError ||
          (error.response?.statusCode != null && error.response!.statusCode! >= 500);
    }
    return false;
  }

  /// Handle DioException and convert to AppException
  static AppException handleDioError(DioException error) {
    return ExceptionHandler.handleError(error);
  }
}

