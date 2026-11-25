import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/api/generated/api_client.dart';
import 'package:lingafriq/api/generated/api_error.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/services/api_retry_service.dart';
import 'package:lingafriq/services/env_config.dart';

ProfileModel _profile(String? avatar) {
  return ProfileModel(
    id: 1,
    email: 'ada@example.com',
    username: 'ada',
    first_name: 'Ada',
    last_name: 'Okoye',
    is_current_user: true,
    rank: 1,
    nationality: 'NG',
    agree_to_privacy_terms: true,
    avatar: avatar,
    completed_point: 0,
  );
}

void main() {
  test('the generated client matches the spec version and one login route', () {
    expect(openApiSpecVersion, '1.0.0');
    expect(apiOperations['POST /auth/login']?.path, '/auth/login');
    expect(apiOperations.length, greaterThan(900));
  });

  test('the app has one backend base URL and lib contains no raw http IP', () {
    expect(EnvConfig.backendBaseUrl, 'https://admin.lingafriq.com');
    final pattern = RegExp(r'http://\d+\.\d+\.\d+\.\d+');
    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (pattern.hasMatch(entity.readAsStringSync())) hits.add(entity.path);
    }
    expect(hits, isEmpty);
    final personalities = File('lib/services/ai/historical_personality_service.dart').readAsStringSync();
    expect(personalities.contains('Fallback'), isFalse);
    expect(personalities.contains("'/api/historical-personalities'"), isFalse);
  });

  test('an http avatar moves onto the current API host', () {
    final url = _profile('http://203.0.113.10:8000/media/a.png').avatarUrl;
    expect(url, 'https://admin.lingafriq.com/media/a.png');
    expect(url.contains('203.0.113.10'), isFalse);
  });

  test('a failed call uses one path and throws ApiError', () async {
    final hits = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      hits.add('${request.method} ${request.uri.path}');
      request.response.statusCode = 503;
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    final api = LingAfriqApi(
      baseUrl: 'http://127.0.0.1:${server.port}',
      dio: Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}')),
    );
    await expectLater(
      api.send('POST /auth/login'),
      throwsA(
        isA<ApiError>().having((error) => error.path, 'path', '/auth/login').having(
              (error) => error.statusCode,
              'statusCode',
              503,
            ),
      ),
    );
    expect(hits, ['POST /auth/login']);
  });

  test('a retry that cannot continue surfaces ApiError', () async {
    final service = ApiRetryService(config: const RetryConfig(maxRetries: 0));
    await expectLater(
      service.execute<void>(() async {
        throw DioException(
          requestOptions: RequestOptions(path: '/auth/login', method: 'GET'),
          type: DioExceptionType.connectionError,
        );
      }),
      throwsA(isA<ApiError>().having((error) => error.path, 'path', '/auth/login')),
    );
  });
}
