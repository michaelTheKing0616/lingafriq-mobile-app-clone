import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';

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
    dio.interceptors.add(_DioLogger(ref, dio));
    return dio;
  },
);

class _DioLogger extends Interceptor {
  final Ref ref;
  final Dio dio;
  _DioLogger(this.ref, this.dio);
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
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    _log(
      'Api call error\n${err.requestOptions.uri.toString()}\n${err.requestOptions.path}\n${err.response?.statusCode}\n${err.response?.statusMessage}\n${err.response?.data},',
    );

    // Auto-refresh session on 401 once, then retry the original request.
    // Skips auth endpoints and multipart bodies (FormData) since those aren't safely replayable.
    final status = err.response?.statusCode;
    final req = err.requestOptions;
    final isAuthEndpoint = [Api.register, Api.login, Api.resetPassword, Api.tokenRefresh, Api.tokenVerify]
        .contains(req.path);
    final alreadyRetried = req.extra['retry_401'] == true;

    if (status == 401 && !alreadyRetried && !isAuthEndpoint && req.data is! FormData) {
      try {
        final api = ref.read(apiProvider.notifier);
        final refreshed = await api.refreshSession();
        final token = api.token;

        if (refreshed && token != null && token.isNotEmpty) {
          req.extra['retry_401'] = true;
          req.headers['Authorization'] = 'JWT $token';

          final response = await dio.fetch(req);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        // Fall through to original error handling.
      }
    }

    super.onError(err, handler);
  }

  _log(String message) => log(message, name: "Dio_Logger");
}
