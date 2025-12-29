import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/error/error_recovery_service.dart';

/// Dio Interceptor for automatic error recovery
/// Applies retry logic, offline handling, and graceful degradation to all API calls
class ErrorRecoveryInterceptor extends Interceptor {
  final ErrorRecoveryService _errorRecoveryService = ErrorRecoveryService();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('ErrorRecoveryInterceptor: ${err.type} - ${err.requestOptions.method} ${err.requestOptions.path}');
    
    // Check if this error should be retried
    if (_shouldRetry(err)) {
      debugPrint('Error is retryable, attempting recovery...');
      
      try {
        // Use error recovery service to retry
        final response = await _errorRecoveryService.executeWithRecovery(
          operation: () async {
            // Retry using the same dio instance by creating a new request
            final options = err.requestOptions;
            final dio = Dio(BaseOptions(
              baseUrl: options.baseUrl,
              connectTimeout: options.connectTimeout,
              receiveTimeout: options.receiveTimeout,
              sendTimeout: options.sendTimeout,
              headers: options.headers,
            ));
            
            return await dio.request(
              options.path,
              data: options.data,
              queryParameters: options.queryParameters,
              options: Options(
                method: options.method,
                headers: options.headers,
                extra: options.extra,
                sendTimeout: options.sendTimeout,
                receiveTimeout: options.receiveTimeout,
              ),
            );
          },
          shouldRetry: (error) {
            if (error is DioException) {
              return _shouldRetry(error);
            }
            return false;
          },
          operationName: '${err.requestOptions.method} ${err.requestOptions.path}',
        );

        // Successfully retried, return the response
        debugPrint('Error recovery successful after retry');
        handler.resolve(response);
        return;
      } catch (e) {
        debugPrint('Error recovery failed: $e');
        // Retry failed, continue with original error
        handler.reject(err);
        return;
      }
    }

    // Don't retry, continue with error handling
    debugPrint('Error is not retryable, passing through');
    handler.reject(err);
  }

  bool _shouldRetry(dynamic error) {
    if (error is! DioException) {
      return false;
    }

    // Retry on network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on 5xx server errors
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      if (statusCode != null && statusCode >= 500 && statusCode < 600) {
        return true;
      }

      // Retry on 429 (rate limit) with longer delay
      if (statusCode == 429) {
        return true;
      }

      // Don't retry on 4xx client errors (except 429)
      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        return false;
      }
    }

    return false;
  }
}

/// Enhanced Dio client with automatic error recovery
class DioWithErrorRecovery {
  static Dio create({
    String? baseUrl,
    Map<String, dynamic>? headers,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? '',
      headers: headers,
      connectTimeout: connectTimeout ?? const Duration(seconds: 30),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
    ));

    // Add error recovery interceptor
    dio.interceptors.add(ErrorRecoveryInterceptor());

    return dio;
  }
}

