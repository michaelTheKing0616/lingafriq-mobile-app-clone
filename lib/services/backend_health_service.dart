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

  /// Check if backend is reachable
  Future<bool> checkBackendHealth() async {
    try {
      final response = await _dio.get(
        '${Api.baseurl}health/',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend health check failed: $e');
      return false;
    }
  }

  /// Verify critical endpoints
  Future<Map<String, bool>> verifyCriticalEndpoints() async {
    final results = <String, bool>{};

    // Check authentication endpoint
    try {
      final response = await _dio.head(
        '${Api.baseurl}${Api.login}',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      results['auth'] = response.statusCode != null && response.statusCode! < 500;
    } catch (e) {
      results['auth'] = false;
    }

    // Check game sessions endpoint
    try {
      final response = await _dio.head(
        '${Api.baseurl}${Api.gameSessionStart}',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      results['game_sessions'] = response.statusCode != null && response.statusCode! < 500;
    } catch (e) {
      results['game_sessions'] = false;
    }

    // Check telemetry endpoint
    try {
      final response = await _dio.head(
        '${Api.baseurl}${Api.sendTelemetry}',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      results['telemetry'] = response.statusCode != null && response.statusCode! < 500;
    } catch (e) {
      results['telemetry'] = false;
    }

    // Check UGC endpoints
    try {
      final response = await _dio.head(
        '${Api.baseurl}${Api.getUserContent}',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      results['ugc'] = response.statusCode != null && response.statusCode! < 500;
    } catch (e) {
      results['ugc'] = false;
    }

    // Check curriculum endpoints
    try {
      final response = await _dio.head(
        '${Api.baseurl}${Api.lessons}',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      results['curriculum'] = response.statusCode != null && response.statusCode! < 500;
    } catch (e) {
      results['curriculum'] = false;
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
  bool get hasPartialConnectivity => isConnected && endpointAvailability < 0.8;
  bool get isOffline => !isConnected;

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

