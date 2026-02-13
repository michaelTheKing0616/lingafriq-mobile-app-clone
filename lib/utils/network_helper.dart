import 'package:dio/dio.dart';
import 'package:lingafriq/services/error/error_recovery_service.dart';
import 'package:lingafriq/services/monitoring/performance_analytics.dart';
import 'package:lingafriq/services/monitoring/sentry_service.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'dart:async';

/// World-class network helper utility
/// Provides error recovery, performance tracking, and consistent error handling
/// for all network operations across the app
class NetworkHelper {
  static final ErrorRecoveryService _errorRecovery = ErrorRecoveryService();
  static final PerformanceAnalytics _performanceAnalytics = PerformanceAnalytics();

  /// Execute Dio request with error recovery and performance tracking
  static Future<Response<T>> executeRequest<T>({
    required Future<Response<T>> Function() request,
    String? operationName,
    int? maxRetries,
    bool Function(dynamic error)? shouldRetry,
    T? fallbackResponse,
    Map<String, dynamic>? metadata,
  }) async {
    final opName = operationName ?? 'network_request';
    
    // Start performance tracking
    final trackingId = _performanceAnalytics.startTracking(
      operationName: opName,
      metadata: metadata ?? {},
    );

    try {
      // Execute with error recovery
      final response = await _errorRecovery.executeWithRecovery(
        operation: request,
        maxRetries: maxRetries,
        operationName: opName,
        shouldRetry: shouldRetry ?? (error) {
          if (error is DioException) {
            return TransportErrorPolicy.isRetryable(error);
          }
          return error is TimeoutException;
        },
        fallbackValue: fallbackResponse != null 
            ? Response<T>(
                requestOptions: RequestOptions(path: ''),
                data: fallbackResponse,
                statusCode: 200,
              )
            : null,
      );

      // Stop performance tracking
      _performanceAnalytics.stopTracking(
        trackingId: trackingId,
        operationName: opName,
        additionalMetadata: {
          'status_code': response.statusCode,
          'success': response.statusCode != null && response.statusCode! < 400,
        },
      );

      return response;
    } catch (e, stackTrace) {
      // Stop performance tracking with error
      _performanceAnalytics.stopTracking(
        trackingId: trackingId,
        operationName: opName,
        additionalMetadata: {
          'error': e.toString(),
          'success': false,
        },
      );

      // Log to Sentry
      SentryService().captureException(
        e,
        stackTrace: stackTrace,
        context: {
          'operation': opName,
          'metadata': metadata,
        },
      );

      rethrow;
    }
  }

  /// Execute GET request with error recovery
  static Future<Response<T>> get<T>(
    Dio dio,
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    String? operationName,
    int? maxRetries,
    T? fallbackResponse,
    Map<String, dynamic>? metadata,
  }) {
    return executeRequest<T>(
      request: () => dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      operationName: operationName ?? 'GET_$path',
      maxRetries: maxRetries,
      fallbackResponse: fallbackResponse,
      metadata: {
        ...?metadata,
        'method': 'GET',
        'path': path,
      },
    );
  }

  /// Execute POST request with error recovery
  static Future<Response<T>> post<T>(
    Dio dio,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    String? operationName,
    int? maxRetries,
    T? fallbackResponse,
    Map<String, dynamic>? metadata,
  }) {
    return executeRequest<T>(
      request: () => dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      operationName: operationName ?? 'POST_$path',
      maxRetries: maxRetries,
      fallbackResponse: fallbackResponse,
      metadata: {
        ...?metadata,
        'method': 'POST',
        'path': path,
      },
    );
  }

  /// Execute PUT request with error recovery
  static Future<Response<T>> put<T>(
    Dio dio,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    String? operationName,
    int? maxRetries,
    T? fallbackResponse,
    Map<String, dynamic>? metadata,
  }) {
    return executeRequest<T>(
      request: () => dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      operationName: operationName ?? 'PUT_$path',
      maxRetries: maxRetries,
      fallbackResponse: fallbackResponse,
      metadata: {
        ...?metadata,
        'method': 'PUT',
        'path': path,
      },
    );
  }

  /// Execute DELETE request with error recovery
  static Future<Response<T>> delete<T>(
    Dio dio,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    String? operationName,
    int? maxRetries,
    T? fallbackResponse,
    Map<String, dynamic>? metadata,
  }) {
    return executeRequest<T>(
      request: () => dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      operationName: operationName ?? 'DELETE_$path',
      maxRetries: maxRetries,
      fallbackResponse: fallbackResponse,
      metadata: {
        ...?metadata,
        'method': 'DELETE',
        'path': path,
      },
    );
  }

  /// Execute PATCH request with error recovery
  static Future<Response<T>> patch<T>(
    Dio dio,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    String? operationName,
    int? maxRetries,
    T? fallbackResponse,
    Map<String, dynamic>? metadata,
  }) {
    return executeRequest<T>(
      request: () => dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      operationName: operationName ?? 'PATCH_$path',
      maxRetries: maxRetries,
      fallbackResponse: fallbackResponse,
      metadata: {
        ...?metadata,
        'method': 'PATCH',
        'path': path,
      },
    );
  }

  /// Execute request with offline handling
  static Future<T?> executeWithOfflineHandling<T>({
    required Future<T> Function() onlineOperation,
    required Future<T?> Function() offlineOperation,
    T? Function()? fallbackValue,
    String? operationName,
  }) {
    return _errorRecovery.executeWithOfflineHandling(
      onlineOperation: onlineOperation,
      offlineOperation: offlineOperation,
      fallbackValue: fallbackValue,
      operationName: operationName,
    );
  }

  /// Execute request with graceful degradation
  static Future<T> executeWithGracefulDegradation<T>({
    required Future<T> Function() primaryOperation,
    required Future<T> Function() fallbackOperation,
    String? operationName,
  }) {
    return _errorRecovery.executeWithGracefulDegradation(
      primaryOperation: primaryOperation,
      fallbackOperation: fallbackOperation,
      operationName: operationName,
    );
  }
}

