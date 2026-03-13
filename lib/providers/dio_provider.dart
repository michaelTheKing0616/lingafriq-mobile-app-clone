import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/screens/auth/world_class_login_screen.dart';
import 'package:lingafriq/utils/structured_logger.dart';

import '../utils/api.dart';

/// Production API domains that require certificate pinning
/// Add your production API domain here when deploying
const _pinnedDomains = <String>[
  'admin.lingafriq.com',
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
    // CRITICAL: baseUrl MUST end with '/' for Dio to correctly resolve
    // relative paths (e.g. "auth/jwt/create/"). Without a trailing slash,
    // Dio concatenates directly: "https://host.com" + "auth/..." produces
    // "https://host.comauth/..." — a broken URL whose DNS lookup fails,
    // surfacing as a misleading "no Internet connection" error.
    final rawBase = ApiContract.baseUrl;
    final normalizedBase = rawBase.endsWith('/') ? rawBase : '$rawBase/';
    final options = BaseOptions(
      baseUrl: normalizedBase,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );
    final dio = Dio(options);
    
    // SECURITY: Configure SSL/TLS based on environment
    if (ApiContract.baseUrl.startsWith('http://')) {
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          logger.debug('Allowing HTTP/self-signed certificate for local backend', context: {
            'host': host,
            'port': port,
            'backendUrl': ApiContract.baseUrl,
          });
          return true;
        };
        return client;
      };
      logger.info('HTTP backend detected - SSL verification disabled', context: {
        'backendUrl': ApiContract.baseUrl,
      });
    } else if (_isPinnedDomain(ApiContract.baseUrl)) {
      logger.info('Production HTTPS backend detected', context: {
        'backendUrl': ApiContract.baseUrl,
      });
    }
    
    // Retry interceptor for transient DNS / connection failures.
    // Must be added BEFORE the logger so retries are transparent.
    dio.interceptors.add(_DnsRetryInterceptor());
    dio.interceptors.add(_DioLogger(ref));
    return dio;
  },
);

/// Retries requests that fail due to DNS resolution (host lookup) errors.
/// DNS failures are often transient — a single retry after a short delay
/// frequently succeeds when the first attempt hit a stale cache or
/// a momentary resolver hiccup.
class _DnsRetryInterceptor extends Interceptor {
  static const _maxRetries = 2;
  static const _retryDelay = Duration(seconds: 2);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isDnsFailure = err.type == DioExceptionType.connectionError &&
        (err.message ?? err.error?.toString() ?? '')
            .toLowerCase()
            .contains('failed host lookup');

    final retryCount = err.requestOptions.extra['_dnsRetry'] as int? ?? 0;

    if (isDnsFailure && retryCount < _maxRetries) {
      logger.warn('DNS lookup failed — retrying (${retryCount + 1}/$_maxRetries)', context: {
        'url': err.requestOptions.uri.toString(),
      });
      await Future.delayed(_retryDelay);
      err.requestOptions.extra['_dnsRetry'] = retryCount + 1;
      try {
        final dio = Dio(BaseOptions(
          connectTimeout: err.requestOptions.connectTimeout,
          sendTimeout: err.requestOptions.sendTimeout,
          receiveTimeout: err.requestOptions.receiveTimeout,
        ));
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return super.onError(retryErr, handler);
      }
    }

    super.onError(err, handler);
  }
}

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
          await _forceLogout('Token refresh returned null');
        } catch (refreshError) {
          _log('Token refresh failed: $refreshError');
          await _forceLogout('Token refresh threw: $refreshError');
        }
      }
    }
    
    super.onError(err, handler);
  }

  /// Force full sign-out when token refresh fails irreversibly.
  /// Clears tokens and triggers the auth state notifier so the UI
  /// redirects to the login/session-expired screen.
  Future<void> _forceLogout(String reason) async {
    _log('Forcing logout: $reason');
    try {
      // Clear the API token immediately
      ref.read(apiProvider.notifier).clearToken();
      // Trigger full sign-out via auth provider — this clears SharedPreferences,
      // resets user state, and navigates to the login screen.
      await ref.read(authProvider.notifier).signOut();
      // Fallback route in case signOut navigation fails in interceptor context.
      await ref.read(navigationProvider).navigateOffAll(const WorldClassLoginScreen());
    } catch (e) {
      _log('Error during forced logout: $e');
      // Last resort: just clear the token
      try {
        ref.read(apiProvider.notifier).clearToken();
      } catch (_) {}
      try {
        await ref.read(navigationProvider).navigateOffAll(const WorldClassLoginScreen());
      } catch (_) {}
    }
    logger.warn('Session expired — user forcefully logged out', tag: 'auth', context: {'reason': reason});
  }

  _log(String message) => log(message, name: "Dio_Logger");
}
