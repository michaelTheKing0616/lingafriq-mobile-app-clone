import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/url_constants.dart';
import '../utils/api.dart';

/// Test result structure for backend connectivity tests
class ConnectivityResult {
  final bool isConnected;
  final String? errorMessage;
  final String backendUrl;
  final int? statusCode;
  final Duration? responseTime;
  final bool hasInternet;

  ConnectivityResult({
    required this.isConnected,
    this.errorMessage,
    required this.backendUrl,
    this.statusCode,
    this.responseTime,
    required this.hasInternet,
  });

  @override
  String toString() {
    return 'ConnectivityResult('
        'connected: $isConnected, '
        'hasInternet: $hasInternet, '
        'backendUrl: $backendUrl, '
        'statusCode: $statusCode, '
        'responseTime: ${responseTime?.inMilliseconds}ms'
        ')';
  }
}

/// Backend Connectivity Test Service
/// Tests actual connectivity to the backend API to verify frontend-backend communication
class BackendConnectivityTest {
  final Dio _dio;

  BackendConnectivityTest() : _dio = Dio();

  /// Test internet connectivity (not backend-specific)
  Future<bool> testInternetConnectivity() async {
    try {
      final response = await _dio.head(
        UrlConstants.connectivityProbe,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode != null;
    } catch (e) {
      debugPrint('Internet connectivity test failed: $e');
      return false;
    }
  }

  /// Test backend health endpoint
  Future<ConnectivityResult> testBackendHealth() async {
    final backendUrl = Api.baseurl;
    final startTime = DateTime.now();
    
    // First check internet connectivity
    final hasInternet = await testInternetConnectivity();
    
    if (!hasInternet) {
      return ConnectivityResult(
        isConnected: false,
        hasInternet: false,
        backendUrl: backendUrl,
        errorMessage: 'No internet connectivity detected',
      );
    }

    try {
      // Test health endpoint first (lightweight)
      final response = await _dio.get(
        '${backendUrl}healthcheck',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final responseTime = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        return ConnectivityResult(
          isConnected: true,
          hasInternet: true,
          backendUrl: backendUrl,
          statusCode: response.statusCode,
          responseTime: responseTime,
        );
      }

      return ConnectivityResult(
        isConnected: false,
        hasInternet: true,
        backendUrl: backendUrl,
        statusCode: response.statusCode,
        responseTime: responseTime,
        errorMessage: 'Backend returned status ${response.statusCode}',
      );
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime);
      
      // Try fallback endpoint (login endpoint - lightweight HEAD request)
      try {
        final fallbackResponse = await _dio.head(
          '${backendUrl}${Api.login}',
          options: Options(
            receiveTimeout: const Duration(seconds: 5),
            sendTimeout: const Duration(seconds: 5),
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        final fallbackTime = DateTime.now().difference(startTime);
        
        // If we get any response (even 401/404), backend is reachable
        if (fallbackResponse.statusCode != null) {
          return ConnectivityResult(
            isConnected: true,
            hasInternet: true,
            backendUrl: backendUrl,
            statusCode: fallbackResponse.statusCode,
            responseTime: fallbackTime,
          );
        }
      } catch (fallbackError) {
        debugPrint('Fallback connectivity test also failed: $fallbackError');
      }

      // Determine error type
      String errorMessage;
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Backend connection timeout. Server may be slow or unreachable.';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Cannot connect to backend. Check if backend is running and URL is correct.';
            break;
          case DioExceptionType.badCertificate:
            errorMessage = 'SSL certificate error. Backend URL may be incorrect.';
            break;
          default:
            errorMessage = 'Backend connectivity error: ${e.message ?? e.toString()}';
        }
      } else {
        errorMessage = 'Unexpected error: ${e.toString()}';
      }

      return ConnectivityResult(
        isConnected: false,
        hasInternet: true,
        backendUrl: backendUrl,
        responseTime: responseTime,
        errorMessage: errorMessage,
      );
    }
  }

  /// Test specific endpoint
  Future<ConnectivityResult> testEndpoint(String endpoint) async {
    final backendUrl = Api.baseurl;
    final hasInternet = await testInternetConnectivity();
    
    if (!hasInternet) {
      return ConnectivityResult(
        isConnected: false,
        hasInternet: false,
        backendUrl: backendUrl,
        errorMessage: 'No internet connectivity',
      );
    }

    final startTime = DateTime.now();
    final fullUrl = endpoint.startsWith('http') ? endpoint : '${backendUrl}$endpoint';

    try {
      final response = await _dio.head(
        fullUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final responseTime = DateTime.now().difference(startTime);

      return ConnectivityResult(
        isConnected: response.statusCode != null,
        hasInternet: true,
        backendUrl: fullUrl,
        statusCode: response.statusCode,
        responseTime: responseTime,
      );
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime);
      
      String errorMessage;
      if (e is DioException) {
        errorMessage = 'Endpoint test failed: ${e.message ?? e.toString()}';
      } else {
        errorMessage = 'Unexpected error: ${e.toString()}';
      }

      return ConnectivityResult(
        isConnected: false,
        hasInternet: true,
        backendUrl: fullUrl,
        responseTime: responseTime,
        errorMessage: errorMessage,
      );
    }
  }

  /// Test critical endpoints for onboarding and login
  Future<Map<String, ConnectivityResult>> testCriticalEndpoints() async {
    final results = <String, ConnectivityResult>{};

    // Test health endpoint
    results['health'] = await testBackendHealth();

    // Test loading screen endpoint (used on app startup)
    results['loading_screen'] = await testEndpoint('api/loading-screen');

    // Test login endpoint (critical for authentication)
    results['login'] = await testEndpoint(Api.login);

    // Test onboarding endpoint
    results['onboarding'] = await testEndpoint('onboarding/check-username?username=test');

    return results;
  }

  /// Get detailed connectivity report
  Future<Map<String, dynamic>> getConnectivityReport() async {
    final backendUrl = Api.baseurl;
    final hasInternet = await testInternetConnectivity();
    final backendHealth = await testBackendHealth();
    final criticalEndpoints = await testCriticalEndpoints();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'backend_url': backendUrl,
      'backend_url_source': 'EnvConfig.backendBaseUrl',
      'has_internet': hasInternet,
      'backend_health': {
        'connected': backendHealth.isConnected,
        'status_code': backendHealth.statusCode,
        'response_time_ms': backendHealth.responseTime?.inMilliseconds,
        'error': backendHealth.errorMessage,
      },
      'critical_endpoints': criticalEndpoints.map((key, value) => MapEntry(
        key,
        {
          'connected': value.isConnected,
          'status_code': value.statusCode,
          'response_time_ms': value.responseTime?.inMilliseconds,
          'error': value.errorMessage,
        },
      )),
      'summary': {
        'all_connected': criticalEndpoints.values.every((r) => r.isConnected),
        'any_connected': criticalEndpoints.values.any((r) => r.isConnected),
        'total_tested': criticalEndpoints.length,
        'successful': criticalEndpoints.values.where((r) => r.isConnected).length,
      },
    };
  }
}
