import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/connectivity_service.dart';
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
    return ConnectivityService.hasInternet(dio: _dio);
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
    if (await ConnectivityService.hasBackend(dio: _dio, healthPath: '/healthcheck')) {
      return true;
    }

    // If health endpoint fails, try a lightweight auth endpoint as fallback.
    try {
      final response = await _dio.head(
        ApiContract.url(ApiContract.login),
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode != null;
    } catch (e) {
      debugPrint('Backend health check failed: $e');
      // If backend is unavailable but internet exists, return false so UI can
      // distinguish backend outage from full offline mode.
      return false;
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
        ApiContract.url(ApiContract.login),
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
        // Use a safe, side-effect-free endpoint. Telemetry is POST-only.
        '${Api.baseurl}healthcheck',
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
        '${Api.baseurl}${Api.userContent}',
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

