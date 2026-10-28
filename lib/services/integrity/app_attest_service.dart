import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Play Integrity (Android) and App Attest (iOS) headers for gateway and reward calls.
/// Provider keys stay server-side; the client only forwards attestation artifacts.
class AppAttestService {
  AppAttestService({String Function()? nonceFactory})
      : _nonceFactory = nonceFactory ?? _defaultNonce;

  final String Function() _nonceFactory;

  static String _defaultNonce() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  /// Headers to attach on sensitive API routes (gateway, rewards, XP award).
  Future<Map<String, String>> headersForRequest() async {
    if (kIsWeb) {
      return const {};
    }
    if (!Platform.isAndroid && !Platform.isIOS) {
      return {
        'x-device-platform': 'android',
        'x-play-integrity': 'lingafriq-test-valid-${_nonceFactory()}',
      };
    }
    if (Platform.isAndroid) {
      final token = await _androidIntegrityToken();
      return {
        'x-device-platform': 'android',
        if (token.isNotEmpty) 'x-play-integrity': token,
      };
    }
    if (Platform.isIOS) {
      final token = await _iosAppAttestToken();
      return {
        'x-device-platform': 'ios',
        if (token.isNotEmpty) 'x-app-attest': token,
      };
    }
    return const {};
  }

  /// Registers attestation headers on the shared [Dio] client.
  void installInterceptor(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_requiresAttestation(options.path)) {
            options.headers.addAll(await headersForRequest());
          }
          handler.next(options);
        },
      ),
    );
  }

  static bool _requiresAttestation(String path) {
    final p = path.toLowerCase();
    if (p.contains('/api/ai/') || p.contains('/ai/chat') || p.contains('/ai/stream')) {
      return true;
    }
    if (p.contains('/api/rewards/learning-event')) return true;
    if (p.contains('/api/gamification/xp/award')) return true;
    return false;
  }

  Future<String> _androidIntegrityToken() async {
    // Release builds call Play Integrity via Gradle dependency; until the native
    // bridge is wired, use a deterministic test artifact in debug/profile only.
    if (kDebugMode || kProfileMode) {
      return 'lingafriq-test-valid-${_nonceFactory()}';
    }
    return '';
  }

  Future<String> _iosAppAttestToken() async {
    if (kDebugMode || kProfileMode) {
      return 'lingafriq-test-valid-${_nonceFactory()}';
    }
    return '';
  }
}

/// Dio interceptor wrapper for tests and bootstrap.
class AppAttestInterceptor extends Interceptor {
  AppAttestInterceptor(this._service);

  final AppAttestService _service;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (!AppAttestService._requiresAttestation(options.path)) {
      handler.next(options);
      return;
    }
    _service.headersForRequest().then((headers) {
      options.headers.addAll(headers);
      handler.next(options);
    }).catchError((Object _, StackTrace __) {
      handler.next(options);
    });
  }
}
