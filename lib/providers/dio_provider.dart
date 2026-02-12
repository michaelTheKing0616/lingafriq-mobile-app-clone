import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/utils/structured_logger.dart';

import '../utils/api.dart';

/// Production API domains that require certificate pinning
/// Add your production API domain here when deploying
const _pinnedDomains = <String>[
  'api.lingafriq.com',
  'lingafriq.com',
];

/// Check if the URL is a production endpoint that requires pinning
bool _isPinnedDomain(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return _pinnedDomains.any((domain) => uri.host == domain || uri.host.endsWith('.$domain'));
}

final client = Provider<Dio>(
  (ref) {
    final options = BaseOptions(
      baseUrl: ApiContract.baseUrl,
      connectTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
    );
    final dio = Dio(options);
    
    // SECURITY: Configure SSL/TLS based on environment
    if (ApiContract.baseUrl.startsWith('http://')) {
      // Development mode: Allow HTTP and self-signed certificates
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          logger.debug('Allowing HTTP/self-signed certificate for local backend', context: {
            'host': host,
            'port': port,
            'backendUrl': ApiContract.baseUrl,
          });
          return true; // Allow all certificates for HTTP backends
        };
        return client;
      };
      logger.info('HTTP backend detected - SSL verification disabled', context: {
        'backendUrl': ApiContract.baseUrl,
      });
    } else if (_isPinnedDomain(ApiContract.baseUrl)) {
      // PRODUCTION: Enable certificate pinning for production domains
      // Note: For full certificate pinning, consider using packages like:
      // - dio_certificate_pinning
      // - ssl_pinning_plugin
      // The native Android network_security_config.xml also provides pinning
      logger.info('Production HTTPS backend detected - certificate pinning active', context: {
        'backendUrl': ApiContract.baseUrl,
      });
      
      // Strict SSL verification (default behavior - no override needed)
      // Certificate pinning is handled by native Android network_security_config.xml
    }
    
    dio.interceptors.add(_DioLogger(ref));
    return dio;
  },
);

class _DioLogger extends Interceptor {
  final Ref ref;
  _DioLogger(this.ref);

  /// Single-flight lock: only one token refresh at a time.
  /// Concurrent 401 handlers wait on the same Future.
  Completer<String?>? _refreshCompleter;
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log("Api call start ${options.path} \n ${options.data ?? ''} ");
    if (options.data is FormData) {
      _log("${options.data.fields}");
    }

    if ([Api.register, Api.login, Api.resetPassword].contains(options.path)) {
      _log("RETURNING EARLY");
      super.onRequest(options, handler);
      return;
    }

    // Exclude auth endpoints from token addition
    if (![Api.register, Api.login, Api.resetPassword, Api.refreshToken].contains(options.path)) {
      if (!options.headers.containsKey("Authorization")) {
        var token = ref.read(apiProvider.notifier).token;
        // Fallback to SharedPreferences if token is null (handles app restart scenarios)
        if (token == null) {
          try {
            final prefs = ref.read(sharedPreferencesProvider);
            token = prefs.getAccessToken();
            // Update api_provider token if found in SharedPreferences
            if (token != null) {
              ref.read(apiProvider.notifier).token = token;
            }
          } catch (e) {
            // Silently fail - no token available
          }
        }
        if (token != null) {
          options.headers.addAll({"Authorization": "Bearer $token"});
        }
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log("Api call stop ${response.requestOptions.path}");
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    _log(
      'Api call error\n${err.requestOptions.uri.toString()}\n${err.requestOptions.path}\n${err.response?.statusCode}\n${err.response?.statusMessage}\n${err.response?.data},',
    );
    
    // Handle 429 Rate Limit - Transform to user-friendly error before propagation
    if (err.response?.statusCode == 429) {
      final retryAfter = err.response?.headers.value('retry-after');
      final retrySeconds = retryAfter != null ? int.tryParse(retryAfter) : null;
      
      // Create user-friendly error that will be caught by error handlers
      final userFriendlyError = DioException(
        requestOptions: err.requestOptions,
        type: DioExceptionType.badResponse,
        response: err.response != null
            ? Response(
                requestOptions: err.requestOptions,
                statusCode: 429,
                statusMessage: retrySeconds != null
                    ? 'Please slow down. Try again in ${(retrySeconds / 60).ceil()} minute${(retrySeconds / 60).ceil() > 1 ? 's' : ''}.'
                    : 'You\'re making requests too quickly. Please wait a moment and try again.',
                data: {
                  'message': retrySeconds != null
                      ? 'Please slow down. Try again in ${(retrySeconds / 60).ceil()} minute${(retrySeconds / 60).ceil() > 1 ? 's' : ''}.'
                      : 'You\'re making requests too quickly. Please wait a moment and try again.',
                  'code': 429,
                  'retry_after': retrySeconds,
                },
                headers: err.response!.headers,
              )
            : null,
        error: 'Rate limit exceeded',
      );
      
      _log('Rate limit (429) detected - transformed to user-friendly message');
      return handler.reject(userFriendlyError);
    }
    
    // Handle 401 Unauthorized - attempt token refresh with single-flight lock
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.uri.path.contains('auth/jwt/refresh') &&
        err.requestOptions.path != Api.refreshToken) {
      final requestOptions = err.requestOptions;
      
      // Skip refresh if this request was already a retry
      if (!requestOptions.extra.containsKey('_retry')) {
        requestOptions.extra['_retry'] = true;
        
        try {
          String? newAccessToken;

          if (_refreshCompleter != null) {
            // Another request is already refreshing — wait for it
            _log('Waiting for in-flight token refresh...');
            newAccessToken = await _refreshCompleter!.future;
          } else {
            // We are the first — start the refresh
            _refreshCompleter = Completer<String?>();
            try {
              final apiProviderNotifier = ref.read(apiProvider.notifier);
              newAccessToken = await apiProviderNotifier.refreshAccessToken();
              _refreshCompleter!.complete(newAccessToken);
            } catch (e) {
              _refreshCompleter!.completeError(e);
              rethrow;
            } finally {
              _refreshCompleter = null;
            }
          }

          if (newAccessToken != null) {
            // Update token and retry the original request
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final response = await ref.read(client).fetch(requestOptions);
            return handler.resolve(response);
          }

          // Token refresh returned null — force full logout
          _forceLogout('Token refresh returned null');
        } catch (refreshError) {
          _log('Token refresh failed: $refreshError');
          _forceLogout('Token refresh threw: $refreshError');
        }
      }
    }
    
    super.onError(err, handler);
  }

  /// Force full sign-out when token refresh fails irreversibly.
  /// Clears tokens and triggers the auth state notifier so the UI
  /// redirects to the login/session-expired screen.
  void _forceLogout(String reason) {
    _log('Forcing logout: $reason');
    try {
      // Clear the API token immediately
      ref.read(apiProvider.notifier).clearToken();
      // Trigger full sign-out via auth provider — this clears SharedPreferences,
      // resets user state, and navigates to the login screen.
      ref.read(authProvider.notifier).signOut();
    } catch (e) {
      _log('Error during forced logout: $e');
      // Last resort: just clear the token
      try {
        ref.read(apiProvider.notifier).clearToken();
      } catch (_) {}
    }
    logger.warn('Session expired — user forcefully logged out', tag: 'auth', context: {'reason': reason});
  }

  _log(String message) => log(message, name: "Dio_Logger");
}
