import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/customisation/unlock_client.dart';

void main() {
  group('AvatarUnlockClient', () {
    test('rejectLocalMasteryUnlockClaim blocks client-forged mastery ids', () {
      expect(
        () => AvatarUnlockClient.rejectLocalMasteryUnlockClaim({
          'unlockedMasteryIds': ['mastery:greetings_respect'],
        }),
        throwsA(
          isA<AvatarUnlockException>().having(
            (e) => e.code,
            'code',
            'CLIENT_MASTERY_UNLOCK_FORBIDDEN',
          ),
        ),
      );
    });

    test('fetchMasteryEntitlements parses server list', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, contains('/api/avatar/mastery-entitlements'));
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'unlocked_mastery_ids': [
                      'mastery:greetings_respect',
                      'mastery:tone_checkpoint',
                    ],
                  },
                },
              ),
            );
          },
        ),
      );
      final client = AvatarUnlockClient(dio, baseUrl: 'https://api.test');
      final entitlements = await client.fetchMasteryEntitlements();
      expect(
        entitlements.unlockedMasteryIds,
        containsAll(['mastery:greetings_respect', 'mastery:tone_checkpoint']),
      );
    });
  });
}
