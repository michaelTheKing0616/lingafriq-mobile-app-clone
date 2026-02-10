import 'dart:io';

import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/utils/structured_logger.dart';

/// Lightweight connectivity check without additional dependencies.
/// Uses a DNS lookup to verify actual internet access (not just Wi-Fi connected).
class ConnectivityHelper {
  ConnectivityHelper._();

  static DateTime? _lastCheck;
  static bool? _lastResult;
  static const _cacheDuration = Duration(seconds: 5);

  /// Host to probe for connectivity (derived from backend URL)
  static String get _connectivityHost {
    final uri = Uri.tryParse(EnvConfig.backendBaseUrl);
    return uri?.host ?? 'api.lingafriq.com';
  }

  /// Quick connectivity check with 5-second caching to avoid excessive lookups.
  static Future<bool> hasConnection() async {
    final now = DateTime.now();
    if (_lastResult != null &&
        _lastCheck != null &&
        now.difference(_lastCheck!) < _cacheDuration) {
      return _lastResult!;
    }
    try {
      final result = await InternetAddress.lookup(_connectivityHost)
          .timeout(const Duration(seconds: 3));
      _lastResult = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _lastResult = false;
    } on Exception catch (_) {
      _lastResult = false;
    }
    _lastCheck = now;
    return _lastResult!;
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
