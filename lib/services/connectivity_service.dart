import 'dart:io';

import 'package:dio/dio.dart';
import 'package:lingafriq/config/url_constants.dart';
import 'package:lingafriq/services/env_config.dart';

/// Single connectivity domain service used across app layers.
class ConnectivityService {
  ConnectivityService._();

  static DateTime? _lastInternetCheckAt;
  static bool? _lastInternetResult;
  static const Duration _internetCacheTtl = Duration(seconds: 5);

  static String get _backendHost {
    final uri = Uri.tryParse(EnvConfig.backendBaseUrl);
    return uri?.host ?? 'admin.lingafriq.com';
  }

  static Future<bool> hasInternet({Dio? dio}) async {
    final now = DateTime.now();
    if (_lastInternetResult != null &&
        _lastInternetCheckAt != null &&
        now.difference(_lastInternetCheckAt!) < _internetCacheTtl) {
      return _lastInternetResult!;
    }

    // Fast DNS probe first.
    try {
      final result = await InternetAddress.lookup(_backendHost)
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        _lastInternetResult = true;
        _lastInternetCheckAt = now;
        return true;
      }
    } catch (_) {}

    // HTTP probe fallback for networks where DNS succeeds but requests are restricted.
    final client = dio ?? Dio();
    final probes = <String>[
      UrlConstants.connectivityProbe,
      'https://cloudflare.com',
    ];
    for (final probe in probes) {
      try {
        final response = await client.head(
          probe,
          options: Options(
            receiveTimeout: const Duration(seconds: 5),
            sendTimeout: const Duration(seconds: 5),
            followRedirects: false,
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        if (response.statusCode != null) {
          _lastInternetResult = true;
          _lastInternetCheckAt = now;
          return true;
        }
      } catch (_) {}
    }

    _lastInternetResult = false;
    _lastInternetCheckAt = now;
    return false;
  }

  static Future<bool> hasBackend({
    Dio? dio,
    String? healthPath,
  }) async {
    if (!await hasInternet(dio: dio)) return false;
    final client = dio ?? Dio();
    final baseUrl = EnvConfig.backendBaseUrl.replaceAll(RegExp(r'/$'), '');
    final candidatePaths = <String>[
      if (healthPath != null && healthPath.isNotEmpty) healthPath,
      '/healthcheck',
      '/api/health',
      '/health',
    ];

    for (final path in candidatePaths) {
      try {
        final response = await client.get(
          '$baseUrl$path',
          options: Options(
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        final status = response.statusCode ?? 0;
        // Any non-5xx status means backend is reachable, even if this
        // specific endpoint is protected or not found in this environment.
        if (status > 0 && status < 500) return true;
      } catch (_) {
        // Continue trying other health paths.
      }
    }
    return false;
  }
}
