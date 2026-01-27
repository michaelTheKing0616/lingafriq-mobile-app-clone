/// API Service - Centralized HTTP client for backend communication
/// Provides clean, type-safe API calls with error handling and authentication

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/rate_limiter.dart';
import 'package:lingafriq/utils/certificate_pinning.dart';
import 'package:lingafriq/utils/security_headers_validator.dart';
import 'package:lingafriq/utils/structured_logger.dart';

class ApiService {
  static late Dio _dio;
  static bool _initialized = false;

  /// Initialize the API service with base configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    final baseUrl = EnvConfig.backendBaseUrl.endsWith('/')
        ? EnvConfig.backendBaseUrl
        : '${EnvConfig.backendBaseUrl}/';

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Setup certificate pinning (production only, disabled for HTTP backends)
    // This allows local development with HTTP backends without certificate issues
    setupCertificatePinning(_dio);
    
    // For HTTP backends, disable SSL verification (development only)
    if (baseUrl.startsWith('http://')) {
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) {
          logger.debug('Allowing HTTP connection (no SSL verification)', context: {
            'host': host,
            'port': port,
          });
          return true; // Allow all certificates for HTTP backends
        };
        return client;
      };
      logger.info('HTTP backend detected - SSL verification disabled for development');
    }

    // Add security headers validation interceptor
    _dio.interceptors.add(securityHeadersValidator.createInterceptor());

    // Add interceptors for auth token, rate limiting, and error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Rate limiting check
        final endpoint = options.path.split('/').first; // Extract endpoint category
        if (isRateLimited(endpoint)) {
          final info = getRateLimitInfo(endpoint);
          logger.warn('Rate limit exceeded', context: {
            'endpoint': endpoint,
            'info': info,
          });
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              error: 'Rate limit exceeded. Please try again later.',
            ),
          );
        }

        // Add auth token if available
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        logger.debug('API request', context: {
          'method': options.method,
          'path': options.path,
          'endpoint': endpoint,
        });
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Validate security headers
        securityHeadersValidator.validateHeaders(response);
        
        logger.debug('API response', context: {
          'statusCode': response.statusCode,
          'path': response.requestOptions.path,
        });
        
        return handler.next(response);
      },
      onError: (error, handler) {
        // Handle 401 unauthorized - clear token and redirect to login
        if (error.response?.statusCode == 401) {
          SharedPreferences.getInstance().then((prefs) {
            prefs.remove('auth_token');
            prefs.remove('access_token');
          });
        }
        
        // Handle 429 rate limit
        if (error.response?.statusCode == 429) {
          logger.warn('Rate limit exceeded from server', context: {
            'path': error.requestOptions.path,
          });
        }
        
        logger.error('API error', error: error, context: {
          'statusCode': error.response?.statusCode,
          'path': error.requestOptions.path,
        });
        
        return handler.next(error);
      },
    ));

    _initialized = true;
  }

  /// GET request
  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_initialized) await initialize();
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  static Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_initialized) await initialize();
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  static Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_initialized) await initialize();
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  static Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_initialized) await initialize();
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  static Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_initialized) await initialize();
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file with multipart/form-data
  static Future<Response> uploadFile(
    String path,
    String filePath, {
    Map<String, dynamic>? additionalData,
    String fileFieldName = 'file',
    Options? options,
  }) async {
    if (!_initialized) await initialize();
    try {
      final formDataMap = <String, dynamic>{
        fileFieldName: await MultipartFile.fromFile(filePath),
      };
      if (additionalData != null) {
        formDataMap.addAll(additionalData);
      }
      final formData = FormData.fromMap(formDataMap);

      return await _dio.post(
        path,
        data: formData,
        options: options ?? Options(
          contentType: 'multipart/form-data',
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors and convert to user-friendly messages
  static Exception _handleError(DioException error) {
    String message = 'An error occurred';
    
    if (error.response != null) {
      final data = error.response!.data;
      message = data is Map
          ? (data['message'] ?? data['error'] ?? data['detail'] ?? message)
          : message;
    } else if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = 'Request timeout. Please try again.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Connection error. Please check your internet connection.';
    } else {
      message = error.message ?? message;
    }

    return Exception(message);
  }

  /// Update auth token
  static Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Clear auth token
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('access_token');
  }
}

