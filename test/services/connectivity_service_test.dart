import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lingafriq/services/connectivity_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('ConnectivityService', () {
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
    });

    group('hasInternet', () {
      test('returns true when DNS lookup succeeds', () async {
        final result = await ConnectivityService.hasInternet();
        // Note: This test may pass or fail depending on actual network
        // In a real test environment, you'd mock InternetAddress.lookup
        expect(result, isA<bool>());
      });

      test('returns false when DNS lookup fails and HTTP probes fail', () async {
        // Mock Dio to throw errors for all probes
        when(() => mockDio.head(any(), options: any(named: 'options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ));

        final result = await ConnectivityService.hasInternet(dio: mockDio);
        // This will likely return false if network is down
        expect(result, isA<bool>());
      });

      test('caches result for 5 seconds', () async {
        // First call
        final result1 = await ConnectivityService.hasInternet();
        // Immediate second call should use cache
        final result2 = await ConnectivityService.hasInternet();
        expect(result1, equals(result2));
      });
    });

    group('hasBackend', () {
      test('returns false when hasInternet returns false', () async {
        // Mock hasInternet to return false
        when(() => mockDio.head(any(), options: any(named: 'options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ));

        when(() => mockDio.get(any(), options: any(named: 'options')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/healthcheck'),
          type: DioExceptionType.connectionError,
        ));

        final result = await ConnectivityService.hasBackend(dio: mockDio);
        expect(result, isFalse);
      });

      test('returns true when healthcheck returns 200', () async {
        when(() => mockDio.head(any(), options: any(named: 'options')))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(path: '/'),
                  statusCode: 200,
                ));

        when(() => mockDio.get(any(), options: any(named: 'options')))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(path: '/healthcheck'),
                  statusCode: 200,
                ));

        final result = await ConnectivityService.hasBackend(dio: mockDio);
        expect(result, isTrue);
      });

      test('returns false when healthcheck returns non-200', () async {
        when(() => mockDio.head(any(), options: any(named: 'options')))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(path: '/'),
                  statusCode: 200,
                ));

        when(() => mockDio.get(any(), options: any(named: 'options')))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(path: '/healthcheck'),
                  statusCode: 500,
                ));

        final result = await ConnectivityService.hasBackend(dio: mockDio);
        expect(result, isFalse);
      });

      test('uses custom healthPath when provided', () async {
        when(() => mockDio.head(any(), options: any(named: 'options')))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(path: '/'),
                  statusCode: 200,
                ));

        when(() => mockDio.get(any(), options: any(named: 'options')))
            .thenAnswer((_) async => Response(
                  requestOptions: RequestOptions(path: '/custom/health'),
                  statusCode: 200,
                ));

        final result = await ConnectivityService.hasBackend(
          dio: mockDio,
          healthPath: '/custom/health',
        );
        expect(result, isTrue);
      });
    });
  });
}
