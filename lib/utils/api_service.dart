// API Service - Centralized HTTP client for backend communication
// Provides clean, type-safe API calls with error handling and authentication

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/utils/rate_limiter.dart';
import 'package:lingafriq/utils/certificate_pinning.dart';
import 'package:lingafriq/utils/security_headers_validator.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';

class ApiService {
  static late Dio _dio;
  static bool _initialized = false;
  static const int _maxRetryAttempts = 3;

  static bool _isRetryableStatus(int? statusCode) {
    if (statusCode == null) return false;
    if (statusCode == 429) return true;
    return statusCode >= 500;
  }

  static Future<Response> _requestWithRetry(Future<Response> Function() requestFn) async {
    Exception? lastOtherError;
    DioException? lastDioError;

    for (var attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        final response = await requestFn();
        if (_isRetryableStatus(response.statusCode) && attempt < _maxRetryAttempts) {
          await Future.delayed(Duration(milliseconds: 250 * attempt));
          continue;
        }
        return response;
      } on DioException catch (e) {
        lastDioError = e;
        if (!TransportErrorPolicy.isRetryable(e) || attempt >= _maxRetryAttempts) {
          throw _handleError(e);
        }
        await Future.delayed(Duration(milliseconds: 250 * attempt));
      } catch (e) {
        lastOtherError = Exception(e.toString());
        if (attempt >= _maxRetryAttempts) {
          throw lastOtherError;
        }
        await Future.delayed(Duration(milliseconds: 250 * attempt));
      }
    }

    if (lastDioError != null) throw _handleError(lastDioError);
    if (lastOtherError != null) throw lastOtherError;
    throw Exception('Request failed');
  }

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
      (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
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
    return _requestWithRetry(
      () => _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  /// POST request
  static Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_initialized) await initialize();
    return _requestWithRetry(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  /// PUT request
  static Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_initialized) await initialize();
    return _requestWithRetry(
      () => _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  /// DELETE request
  static Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_initialized) await initialize();
    return _requestWithRetry(
      () => _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  /// PATCH request
  static Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!_initialized) await initialize();
    return _requestWithRetry(
      () => _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  /// Upload file with multipart/form-data
  static Future<Response> uploadFile(
    String path,
    String filePath, {
    Map<String, dynamic>? additionalData,
    String fileFieldName = 'file',
    Options? options,
    ProgressCallback? onSendProgress,
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
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors and convert to user-friendly messages
  static Exception _handleError(DioException error) {
    return Exception(TransportErrorPolicy.toUserMessage(error));
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

