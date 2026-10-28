import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/integrity/app_attest_service.dart';

void main() {
  test('adds play integrity header for AI routes', () async {
    final service = AppAttestService(nonceFactory: () => 'unit-test-nonce');
    final headers = await service.headersForRequest();
    expect(headers['x-device-platform'], isNotNull);
    expect(headers.containsKey('x-play-integrity') || headers.containsKey('x-app-attest'), isTrue);
  });

  test('interceptor attaches headers on reward path', () async {
    final service = AppAttestService(nonceFactory: () => 'reward-nonce');
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
    dio.interceptors.add(AppAttestInterceptor(service));

    late RequestOptions captured;
    dio.httpClientAdapter = _CaptureAdapter((options) {
      captured = options;
    });

    await dio.post('/api/rewards/learning-event', data: {'rule_id': 'x', 'evidence_id': 'y'});
    expect(captured.headers['x-play-integrity'] ?? captured.headers['x-app-attest'], isNotNull);
  });
}

class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter(this._onFetch);

  final void Function(RequestOptions options) _onFetch;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _onFetch(options);
    return ResponseBody.fromString('{}', 200, headers: {});
  }
}
