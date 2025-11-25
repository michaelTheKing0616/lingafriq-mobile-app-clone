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
