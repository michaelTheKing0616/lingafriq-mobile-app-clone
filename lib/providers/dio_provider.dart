import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/services/secure_storage_service.dart';

import '../utils/api.dart';

final client = Provider<Dio>(
  (ref) {
    final options = BaseOptions(
      baseUrl: Api.baseurl,
      connectTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
    );
    final dio = Dio(options);
    dio.interceptors.add(_DioLogger(ref));
    dio.interceptors.add(_AuthInterceptor(ref));
    return dio;
  },
);

class _DioLogger extends Interceptor {
  final Ref ref;
  _DioLogger(this.ref);
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

    if (!options.headers.containsKey("Authorization")) {
      final token = ref.read(apiProvider.notifier).token;
      if (token != null) {
        options.headers.addAll({"Authorization": "JWT $token"});
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
  void onError(DioError err, ErrorInterceptorHandler handler) {
    _log(
      'Api call error\n${err.requestOptions.uri.toString()}\n${err.requestOptions.path}\n${err.response?.statusCode}\n${err.response?.statusMessage}\n${err.response?.data},',
    );
    super.onError(err, handler);
  }

  _log(String message) => log(message, name: "Dio_Logger");
}

/// Auth Interceptor - Handles JWT token refresh on 401 errors
class _AuthInterceptor extends Interceptor {
  final Ref ref;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  _AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Skip auth for login/register endpoints
    if ([Api.register, Api.login, Api.resetPassword].contains(options.path)) {
      super.onRequest(options, handler);
      return;
    }

    // Add token if not already present
    if (!options.headers.containsKey("Authorization")) {
      final token = ref.read(apiProvider.notifier).token;
      if (token != null) {
        options.headers.addAll({"Authorization": "JWT $token"});
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - token expired or invalid
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;

      // Don't retry login/register endpoints
      if ([Api.register, Api.login, Api.resetPassword].contains(requestOptions.path)) {
        super.onError(err, handler);
        return;
      }

      // If already refreshing, queue this request
      if (_isRefreshing) {
        final completer = Completer<Response>();
        _pendingRequests.add(_PendingRequest(requestOptions, completer));
        try {
          final response = await completer.future;
          handler.resolve(response);
        } catch (e) {
          handler.reject(err);
        }
        return;
      }

      // Try to refresh token
      _isRefreshing = true;
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the original request with new token
          final token = ref.read(apiProvider.notifier).token;
          if (token != null) {
            requestOptions.headers["Authorization"] = "JWT $token";
          }

          // Retry the request
          final dio = Dio();
          final response = await dio.request(
            requestOptions.path,
            data: requestOptions.data,
            queryParameters: requestOptions.queryParameters,
            options: Options(
              method: requestOptions.method,
              headers: requestOptions.headers,
            ),
          );

          // Resolve pending requests
          _resolvePendingRequests(response);

          handler.resolve(response);
        } else {
          // Refresh failed, reject all requests
          _rejectPendingRequests(err);
          handler.reject(err);
        }
      } catch (e) {
        // Refresh failed, reject all requests
        _rejectPendingRequests(err);
        handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      super.onError(err, handler);
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final secureStorage = SecureStorageService();
      
      // Check if we have valid refresh token
      final hasValidRefresh = await secureStorage.hasValidRefreshToken();
      if (!hasValidRefresh) {
        log('No valid refresh token available', name: "AuthInterceptor");
        return false;
      }

      // Get stored credentials
      final emailAndPassword = ref.read(sharedPreferencesProvider).requestEmailAndPass;
      if (emailAndPassword == null) {
        log('No stored credentials for token refresh', name: "AuthInterceptor");
        return false;
      }

      final email = emailAndPassword['email']!;
      final password = emailAndPassword['password']!;

      // Attempt silent refresh
      final authProvider = ref.read(authProvider.notifier);
      final user = await authProvider.login(
        email: email,
        password: password,
        silentRefresh: true,
      );

      if (user != null) {
        log('Token refreshed successfully', name: "AuthInterceptor");
        return true;
      }

      return false;
    } catch (e) {
      log('Token refresh failed: $e', name: "AuthInterceptor");
      return false;
    }
  }

  void _resolvePendingRequests(Response response) {
    for (final pending in _pendingRequests) {
      pending.completer.complete(response);
    }
    _pendingRequests.clear();
  }

  void _rejectPendingRequests(DioError error) {
    for (final pending in _pendingRequests) {
      pending.completer.completeError(error);
    }
    _pendingRequests.clear();
  }
}

class _PendingRequest {
  final RequestOptions requestOptions;
  final Completer<Response> completer;

  _PendingRequest(this.requestOptions, this.completer);
}
