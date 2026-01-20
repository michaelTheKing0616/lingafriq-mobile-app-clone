import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';

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
    
    // Handle 401 Unauthorized - attempt token refresh
    if (err.response?.statusCode == 401 && err.requestOptions.path != Api.refreshToken) {
      final requestOptions = err.requestOptions;
      
      // Skip refresh if already retried
      if (!requestOptions.extra.containsKey('_retry')) {
        requestOptions.extra['_retry'] = true;
        
        try {
          // Attempt to refresh token
          final apiProviderNotifier = ref.read(apiProvider.notifier);
          final newAccessToken = await apiProviderNotifier.refreshAccessToken();
          
          if (newAccessToken != null) {
            // Update token and retry request
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final response = await ref.read(client).fetch(requestOptions);
            return handler.resolve(response);
          }
        } catch (refreshError) {
          _log('Token refresh failed: $refreshError');
          // If refresh fails, clear token and let error propagate
          ref.read(apiProvider.notifier).clearToken();
        }
      }
    }
    
    super.onError(err, handler);
  }

  _log(String message) => log(message, name: "Dio_Logger");
}
