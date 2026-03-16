import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/game/game_content_failure.dart';
import 'package:lingafriq/providers/game_provider.dart';

void main() {
  group('Game content failure typing', () {
    test('maps 401 to authFailure', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/games/game-content'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/games/game-content'),
          statusCode: 401,
        ),
      );

      final failure = GameProvider.classifyGameContentFailure(
        error,
        defaultType: GameContentFailureType.serviceUnavailable,
        defaultMessage: 'fallback',
      );

      expect(failure.type, GameContentFailureType.authFailure);
    });

    test('maps 422 to parseFailure', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/games/cards'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/games/cards'),
          statusCode: 422,
        ),
      );

      final failure = GameProvider.classifyGameContentFailure(
        error,
        defaultType: GameContentFailureType.serviceUnavailable,
        defaultMessage: 'fallback',
      );

      expect(failure.type, GameContentFailureType.parseFailure);
    });

    test('keeps default type for unknown errors', () {
      final failure = GameProvider.classifyGameContentFailure(
        Exception('network down'),
        defaultType: GameContentFailureType.serviceUnavailable,
        defaultMessage: 'default service failure',
      );

      expect(failure.type, GameContentFailureType.serviceUnavailable);
      expect(failure.message, 'default service failure');
    });
  });
}
