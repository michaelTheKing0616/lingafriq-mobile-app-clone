import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';

void main() {
  group('TransportErrorPolicy', () {
    group('isNetworkIssue', () {
      test('returns true for failed host lookup', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
          message: 'SocketException: Failed host lookup',
        );
        expect(TransportErrorPolicy.isNetworkIssue(error), isTrue);
      });

      test('returns true for name resolution errors', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
          message: 'Name resolution failed',
        );
        expect(TransportErrorPolicy.isNetworkIssue(error), isTrue);
      });

      test('returns true for network unreachable', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
          message: 'Network is unreachable',
        );
        expect(TransportErrorPolicy.isNetworkIssue(error), isTrue);
      });

      test('returns false for connection refused', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
          message: 'Connection refused',
        );
        expect(TransportErrorPolicy.isNetworkIssue(error), isFalse);
      });

      test('returns false for non-connection errors', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 404,
          ),
        );
        expect(TransportErrorPolicy.isNetworkIssue(error), isFalse);
      });
    });

    group('isBackendIssue', () {
      test('returns true for connection timeout', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );
        expect(TransportErrorPolicy.isBackendIssue(error), isTrue);
      });

      test('returns true for send timeout', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.sendTimeout,
        );
        expect(TransportErrorPolicy.isBackendIssue(error), isTrue);
      });

      test('returns true for receive timeout', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
        );
        expect(TransportErrorPolicy.isBackendIssue(error), isTrue);
      });

      test('returns true for 5xx status codes', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          ),
        );
        expect(TransportErrorPolicy.isBackendIssue(error), isTrue);
      });

      test('returns true for connection refused', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
          message: 'Connection refused',
        );
        expect(TransportErrorPolicy.isBackendIssue(error), isTrue);
      });

      test('returns false for 4xx status codes', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 404,
          ),
        );
        expect(TransportErrorPolicy.isBackendIssue(error), isFalse);
      });
    });

    group('isRetryable', () {
      test('returns true for network issues', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
          message: 'Failed host lookup',
        );
        expect(TransportErrorPolicy.isRetryable(error), isTrue);
      });

      test('returns true for backend issues', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );
        expect(TransportErrorPolicy.isRetryable(error), isTrue);
      });

      test('returns true for 429 status code', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 429,
          ),
        );
        expect(TransportErrorPolicy.isRetryable(error), isTrue);
      });

      test('returns true for unknown errors', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.unknown,
        );
        expect(TransportErrorPolicy.isRetryable(error), isTrue);
      });

      test('returns false for 4xx client errors', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
          ),
        );
        expect(TransportErrorPolicy.isRetryable(error), isFalse);
      });
    });

    group('toUserMessage', () {
      test('returns server unavailable message for backend issues', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          ),
        );
        final message = TransportErrorPolicy.toUserMessage(error);
        expect(message, contains('temporarily unavailable'));
      });

      test('returns no internet message for network issues', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
          message: 'Failed host lookup',
        );
        final message = TransportErrorPolicy.toUserMessage(error);
        expect(message, contains('No internet connection'));
      });

      test('returns authentication message for 401', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 401,
          ),
        );
        final message = TransportErrorPolicy.toUserMessage(error);
        expect(message, contains('Authentication failed'));
      });

      test('returns permission message for 403', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 403,
          ),
        );
        final message = TransportErrorPolicy.toUserMessage(error);
        expect(message, contains('permission'));
      });

      test('returns not found message for 404', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 404,
          ),
        );
        final message = TransportErrorPolicy.toUserMessage(error);
        expect(message, contains('not found'));
      });

      test('returns rate limit message for 429 with retry-after', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['120'],
            }),
          ),
        );
        final message = TransportErrorPolicy.toUserMessage(error);
        expect(message, contains('Try again in'));
      });

      test('returns cancelled message for cancelled requests', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.cancel,
        );
        final message = TransportErrorPolicy.toUserMessage(error);
        expect(message, contains('cancelled'));
      });

      test('returns certificate error message for bad certificate', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badCertificate,
        );
        final message = TransportErrorPolicy.toUserMessage(error);
        expect(message, contains('security certificate'));
      });
    });
  });
}
