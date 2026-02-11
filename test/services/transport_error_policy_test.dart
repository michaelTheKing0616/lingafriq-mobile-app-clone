import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';

void main() {
  group('TransportErrorPolicy', () {
    test('maps backend down (connection refused) separately from internet down', () {
      final backendDown = DioException(
        requestOptions: RequestOptions(path: '/auth/jwt/create/'),
        type: DioExceptionType.connectionError,
        message: 'SocketException: Connection refused',
      );

      final internetDown = DioException(
        requestOptions: RequestOptions(path: '/auth/jwt/create/'),
        type: DioExceptionType.connectionError,
        message: 'SocketException: Failed host lookup',
      );

      expect(TransportErrorPolicy.isBackendIssue(backendDown), isTrue);
      expect(TransportErrorPolicy.isNetworkIssue(backendDown), isFalse);
      expect(TransportErrorPolicy.toUserMessage(backendDown), contains('Cannot connect to server'));

      expect(TransportErrorPolicy.isBackendIssue(internetDown), isFalse);
      expect(TransportErrorPolicy.isNetworkIssue(internetDown), isTrue);
      expect(TransportErrorPolicy.toUserMessage(internetDown), contains('No internet connection'));
    });

    test('maps /accounts/auth/users/search 404 to user-safe message', () {
      final notFound = DioException(
        requestOptions: RequestOptions(path: '/accounts/auth/users/search'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/accounts/auth/users/search'),
          statusCode: 404,
          data: <String, dynamic>{'error': 'Not Found'},
        ),
      );

      expect(TransportErrorPolicy.toUserMessage(notFound), equals('The requested resource was not found.'));
    });
  });
}
