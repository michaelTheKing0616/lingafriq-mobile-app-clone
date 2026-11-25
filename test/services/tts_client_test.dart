import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/tts_client.dart';

void main() {
  group('P1-040 tts_client', () {
    test('503 audio_unavailable maps to unavailable surface', () {
      expect(
        ttsClientSurfaceForHttp(
          statusCode: 503,
          body: '{"code":"audio_unavailable"}',
        ),
        TtsClientSurfaceState.unavailable,
      );
    });

    test('503 translation_unavailable maps to unavailable surface', () {
      expect(
        ttsClientSurfaceForHttp(
          statusCode: 503,
          body: '{"code":"translation_unavailable"}',
        ),
        TtsClientSurfaceState.unavailable,
      );
    });

    test('503 voice_coming maps to voiceComing surface', () {
      expect(
        ttsClientSurfaceForHttp(
          statusCode: 503,
          body: '{"code":"voice_coming"}',
          language: 'xhosa',
        ),
        TtsClientSurfaceState.voiceComing,
      );
    });

    test('typed exception for audio_unavailable', () {
      final err = ttsClientUnavailableFromResponse(
        statusCode: 503,
        body: '{"code":"audio_unavailable"}',
      );
      expect(err, isNotNull);
      expect(err!.code, 'audio_unavailable');
      expect(err.retryable, isTrue);
    });
  });
}
