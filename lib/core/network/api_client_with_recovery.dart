import 'package:dio/dio.dart';
import '../../services/error/error_recovery_service.dart';

/// API Client wrapper with automatic error recovery
/// Use this instead of Dio directly for automatic retry and offline handling
class ApiClientWithRecovery {
  final Dio _dio;
  final ErrorRecoveryService _errorRecoveryService = ErrorRecoveryService();

  ApiClientWithRecovery(this._dio);

  /// GET request with error recovery
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    T? Function()? fallbackValue,
  }) async {
    return _errorRecoveryService.executeWithRecovery(
      operation: () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      ),
      operationName: 'GET $path',
      fallbackValue: fallbackValue != null ? Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: fallbackValue(),
      ) : null,
    );
  }

  /// POST request with error recovery
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T? Function()? fallbackValue,
  }) async {
    return _errorRecoveryService.executeWithRecovery(
      operation: () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      operationName: 'POST $path',
      fallbackValue: fallbackValue != null ? Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: fallbackValue(),
      ) : null,
    );
  }

  /// PUT request with error recovery
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T? Function()? fallbackValue,
  }) async {
    return _errorRecoveryService.executeWithRecovery(
      operation: () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      operationName: 'PUT $path',
      fallbackValue: fallbackValue != null ? Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: fallbackValue(),
      ) : null,
    );
  }

  /// DELETE request with error recovery
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T? Function()? fallbackValue,
  }) async {
    return _errorRecoveryService.executeWithRecovery(
      operation: () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      operationName: 'DELETE $path',
      fallbackValue: fallbackValue != null ? Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: fallbackValue(),
      ) : null,
    );
  }

  /// Execute request with offline handling
  Future<Response<T>?> executeWithOfflineHandling<T>({
    required Future<Response<T>> Function() onlineOperation,
    required Future<Response<T>?> Function() offlineOperation,
    Response<T>? Function()? fallbackValue,
    String? operationName,
  }) async {
    return await _errorRecoveryService.executeWithOfflineHandling(
      onlineOperation: onlineOperation,
      offlineOperation: offlineOperation,
      fallbackValue: fallbackValue,
      operationName: operationName,
    );
  }

  /// Execute with graceful degradation
  Future<Response<T>> executeWithGracefulDegradation<T>({
    required Future<Response<T>> Function() primaryOperation,
    required Future<Response<T>> Function() fallbackOperation,
    String? operationName,
  }) async {
    return await _errorRecoveryService.executeWithGracefulDegradation(
      primaryOperation: primaryOperation,
      fallbackOperation: fallbackOperation,
      operationName: operationName,
    );
  }
}

/// Extension to add recovery methods to Dio instance
extension DioRecoveryExtension on Dio {
  /// Get API client with recovery for this Dio instance
  ApiClientWithRecovery get withRecovery => ApiClientWithRecovery(this);
}

