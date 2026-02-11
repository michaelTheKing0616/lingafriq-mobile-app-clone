import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';

/// Lightweight connectivity check without additional dependencies.
/// Uses a DNS lookup to verify actual internet access (not just Wi-Fi connected).
class ConnectivityHelper {
  ConnectivityHelper._();

  /// Delegates to ConnectivityService.hasInternet to keep one policy.
  static Future<bool> hasConnection() async {
    return ConnectivityService.hasInternet();
  }

  /// Execute an async action with offline fallback.
  static Future<T> executeOrFallback<T>({
    required Future<T> Function() onlineAction,
    required T Function() offlineFallback,
  }) async {
    if (await hasConnection()) {
      return onlineAction();
    }
    logger.info('Offline — using fallback', tag: 'connectivity');
    return offlineFallback();
  }
}
