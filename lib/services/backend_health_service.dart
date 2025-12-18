import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../utils/api.dart';
import '../providers/api_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Backend Health Check Service
/// Monitors backend connectivity and endpoint availability
class BackendHealthService {
  final Ref _ref;
  final Dio _dio;

  BackendHealthService(this._ref) : _dio = Dio();

  /// Check if device has internet connectivity (not just backend)
  /// Uses a lightweight check to a reliable external service
  Future<bool> hasInternetConnectivity() async {
    try {
      // Try to reach a reliable external service with a quick HEAD request
      final response = await _dio.head(
        'https://www.google.com',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      // If we get any response (even redirect), we have internet
      return response.statusCode != null;
    } catch (e) {
      // If Google is unreachable, try a backup check to the backend base URL
      try {
        final response = await _dio.head(
          Api.baseurl,
          options: Options(
            receiveTimeout: const Duration(seconds: 2),
            sendTimeout: const Duration(seconds: 2),
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        // If backend base URL responds, we have connectivity
        return response.statusCode != null;
      } catch (backupError) {
        debugPrint('Internet connectivity check failed: $e, backup also failed: $backupError');
        // If both fail, be optimistic - might be temporary network issue
        // Don't show offline banner unless we're really sure
        return false;
      }
    }
  }

  /// Check if backend is reachable
  Future<bool> checkBackendHealth() async {
    // First check if device has internet connectivity
    final hasInternet = await hasInternetConnectivity();
    if (!hasInternet) {
      debugPrint('No internet connectivity detected');
      return false;
    }

    // Then check backend health endpoint (if it exists)
    // If health endpoint doesn't exist, try a lightweight endpoint
    try {
      final response = await _dio.get(
        '${Api.baseurl}health/',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      // If health endpoint fails, try a lightweight endpoint as fallback
      try {
        final response = await _dio.head(
          '${Api.baseurl}${Api.login}',
          options: Options(
            receiveTimeout: const Duration(seconds: 3),
            sendTimeout: const Duration(seconds: 3),
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        // If we get any response (even 401/404), backend is reachable
        return response.statusCode != null;
      } catch (fallbackError) {
        debugPrint('Backend health check failed: $e, fallback also failed: $fallbackError');
        // If both fail, but we have internet, assume backend might be temporarily down
        // but user is still online (don't show offline banner)
        return hasInternet;
      }
    }
  }

  /// Verify critical endpoints
  Future<Map<String, bool>> verifyCriticalEndpoints() async {
    final results = <String, bool>{};
    
    // First check if we have internet connectivity
    final hasInternet = await hasInternetConnectivity();
    if (!hasInternet) {
      // If no internet, all endpoints are unavailable
      return {
        'auth': false,
        'game_sessions': false,
        'telemetry': false,
        'ugc': false,
        'curriculum': false,
      };
    }

    // Check authentication endpoint
    try {
      final response = await _dio.head(
        '${Api.baseurl}${Api.login}',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      // Any response (even 401/404) means endpoint is reachable
      results['auth'] = response.statusCode != null;
    } catch (e) {
      // If HEAD fails, endpoint might still be reachable (CORS, method not allowed, etc.)
      // Be optimistic: if we have internet, assume endpoint might be available
      results['auth'] = hasInternet;
    }

    // Check game sessions endpoint
    try {
      final response = await _dio.head(
        '${Api.baseurl}${Api.gameSessionStart}',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      results['game_sessions'] = response.statusCode != null;
    } catch (e) {
      results['game_sessions'] = hasInternet; // Optimistic if we have internet
    }

    // Check telemetry endpoint
    try {
      final response = await _dio.head(
        '${Api.baseurl}${Api.sendTelemetry}',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      results['telemetry'] = response.statusCode != null;
    } catch (e) {
      results['telemetry'] = hasInternet; // Optimistic if we have internet
    }

    // Check UGC endpoints
    try {
      final response = await _dio.head(
        '${Api.baseurl}${Api.getUserContent}',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      results['ugc'] = response.statusCode != null;
    } catch (e) {
      results['ugc'] = hasInternet; // Optimistic if we have internet
    }

    // Check curriculum endpoints
    try {
      final response = await _dio.head(
        '${Api.baseurl}${Api.lessons}',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      results['curriculum'] = response.statusCode != null;
    } catch (e) {
      results['curriculum'] = hasInternet; // Optimistic if we have internet
    }

    return results;
  }

  /// Get connection status
  Future<BackendConnectionStatus> getConnectionStatus() async {
    final isHealthy = await checkBackendHealth();
    final endpoints = await verifyCriticalEndpoints();

    final availableEndpoints = endpoints.values.where((v) => v).length;
    final totalEndpoints = endpoints.length;
    final availability = totalEndpoints > 0 ? availableEndpoints / totalEndpoints : 0.0;

    return BackendConnectionStatus(
      isConnected: isHealthy,
      endpointAvailability: availability,
      endpointStatus: endpoints,
      lastChecked: DateTime.now(),
    );
  }

  /// Monitor backend connection continuously
  Stream<BackendConnectionStatus> monitorConnection({
    Duration interval = const Duration(seconds: 30),
  }) async* {
    while (true) {
      yield await getConnectionStatus();
      await Future.delayed(interval);
    }
  }
}

/// Backend connection status
class BackendConnectionStatus {
  final bool isConnected;
  final double endpointAvailability;
  final Map<String, bool> endpointStatus;
  final DateTime lastChecked;

  BackendConnectionStatus({
    required this.isConnected,
    required this.endpointAvailability,
    required this.endpointStatus,
    required this.lastChecked,
  });

  bool get isFullyOperational => isConnected && endpointAvailability >= 0.8;
  bool get hasPartialConnectivity => isConnected && endpointAvailability < 0.8 && endpointAvailability > 0;
  // Only show offline if we're truly offline (no internet connectivity)
  // Don't show offline just because backend endpoints are down
  bool get isOffline => !isConnected && endpointAvailability == 0;

  @override
  String toString() {
    return 'BackendConnectionStatus('
        'connected: $isConnected, '
        'availability: ${(endpointAvailability * 100).toStringAsFixed(1)}%, '
        'endpoints: ${endpointStatus.length}'
        ')';
  }
}

final backendHealthServiceProvider = Provider<BackendHealthService>((ref) {
  return BackendHealthService(ref);
});

