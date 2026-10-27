import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/realtime_voice_client.dart';

void main() {
  group('RealtimeVoiceClient', () {
    test('cascade phase order matches gateway agent', () {
      expect(RealtimeVoiceClient.cascadePhases, ['vad', 'stt', 'llm', 'tts']);
    });

    test('quota_exceeded maps to user message', () {
      final msg = RealtimeVoiceClient.userMessageFor(
        DioException(
          requestOptions: RequestOptions(path: RealtimeVoiceClient.sessionPath),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 429,
            data: {'error': 'quota_exceeded'},
          ),
        ),
      );
      expect(msg.toLowerCase(), contains('limit'));
    });

    test('startSession parses gateway token payload', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'livekit_token': 'jwt-fixture',
                  'livekit_url': 'wss://example.livekit.cloud',
                  'room_name': 'ai-realtime::u1::yo::sess',
                },
              ),
            );
          },
        ),
      );
      final client = RealtimeVoiceClient(dio);
      final creds = await client.startSession(language: 'yo', mode: 'conversation');
      expect(creds.livekitToken, 'jwt-fixture');
      expect(creds.roomName, contains('ai-realtime::'));
    });
  });
}
