import 'package:flutter/foundation.dart';
import '../services/backend_connectivity_test.dart';
import '../utils/api.dart';
import '../services/env_config.dart';

/// Connectivity Verification Utility
/// Provides easy-to-use functions to verify frontend-backend connectivity
class ConnectivityVerification {
  static final BackendConnectivityTest _test = BackendConnectivityTest();

  /// Quick connectivity check - returns true if backend is reachable
  static Future<bool> isBackendReachable() async {
    try {
      final result = await _test.testBackendHealth();
      return result.isConnected;
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      return false;
    }
  }

  /// Get detailed connectivity status
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      return await _test.getConnectivityReport();
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Print connectivity status to console (for debugging)
  static Future<void> printStatus() async {
    debugPrint('=== Backend Connectivity Status ===');
    debugPrint('Backend URL: ${Api.baseurl}');
    debugPrint('URL Source: EnvConfig.backendBaseUrl');
    debugPrint('Configured URL: ${EnvConfig.backendBaseUrl}');
    
    final status = await getStatus();
    debugPrint('Has Internet: ${status['has_internet']}');
    debugPrint('Backend Connected: ${status['backend_health']?['connected']}');
    debugPrint('Backend Status Code: ${status['backend_health']?['status_code']}');
    debugPrint('Response Time: ${status['backend_health']?['response_time_ms']}ms');
    
    if (status['critical_endpoints'] != null) {
      debugPrint('\nCritical Endpoints:');
      (status['critical_endpoints'] as Map).forEach((key, value) {
        debugPrint('  $key: ${value['connected'] ? '✓' : '✗'} (${value['status_code'] ?? 'N/A'})');
      });
    }
    
    debugPrint('\nSummary:');
    debugPrint('  All Connected: ${status['summary']?['all_connected']}');
    debugPrint('  Any Connected: ${status['summary']?['any_connected']}');
    debugPrint('  Successful: ${status['summary']?['successful']}/${status['summary']?['total_tested']}');
    debugPrint('===================================');
  }

  /// Test specific endpoint
  static Future<bool> testEndpoint(String endpoint) async {
    try {
      final result = await _test.testEndpoint(endpoint);
      return result.isConnected;
    } catch (e) {
      debugPrint('Endpoint test failed: $e');
      return false;
    }
  }

  /// Get user-friendly connectivity message
  static Future<String> getConnectivityMessage() async {
    final status = await getStatus();
    
    if (status['error'] != null) {
      return 'Unable to check connectivity: ${status['error']}';
    }
    
    final hasInternet = status['has_internet'] as bool? ?? false;
    final backendConnected = status['backend_health']?['connected'] as bool? ?? false;
    
    if (!hasInternet) {
      return 'No internet connection detected.';
    }
    
    if (!backendConnected) {
      final error = status['backend_health']?['error'] as String?;
      if (error != null) {
        return 'Backend unreachable: $error';
      }
      return 'Backend server is not responding.';
    }
    
    return 'Backend is connected and responding.';
  }
}
