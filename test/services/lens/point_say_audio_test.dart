import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lingafriq/services/lens/point_say_audio.dart';
import 'package:lingafriq/services/voice/tts_service.dart';

void main() {
  group('PointSayAudio', () {
    test('human audio wins and licensed TTS is not requested', () async {
      var ttsCalls = 0;
      final tts = TtsService(
        baseUrl: 'https://api.example',
        post: (_, {headers, body}) async {
          ttsCalls++;
          return http.Response('', 200);
        },
      );
      final resolver = PointSayAudio(ttsService: tts);

      final plan = await resolver.resolve(
        const PointSayDictionaryHit(
          word: 'ọkọ',
          language: 'yo',
          humanAudioUrl: 'https://cdn.example/native/oko.mp3',
        ),
      );

      expect(plan.kind, PointSayPlaybackKind.playingHuman);
      expect(plan.licensedTtsRequested, isFalse);
      expect(ttsCalls, 0);
    });

    test('licensed route is called when human audio is missing', () async {
      var ttsCalls = 0;
      final tts = TtsService(
        baseUrl: 'https://api.example',
        post: (_, {headers, body}) async {
          ttsCalls++;
          return http.Response.bytes(
            Uint8List.fromList([9, 9, 9]),
            200,
            headers: {'content-type': 'audio/mpeg'},
          );
        },
      );
      final resolver = PointSayAudio(ttsService: tts);

      final plan = await resolver.resolve(
        const PointSayDictionaryHit(word: 'sannu', language: 'ha'),
      );

      expect(plan.kind, PointSayPlaybackKind.playingLicensed);
      expect(plan.licensedTtsRequested, isTrue);
      expect(plan.licensedAudioBytes, isNotNull);
      expect(ttsCalls, 1);
    });

    test('503 voice_coming does not imply device fallback path', () async {
      final tts = TtsService(
        baseUrl: 'https://api.example',
        post: (_, {headers, body}) async {
          return http.Response(
            jsonEncode({'code': 'voice_coming'}),
            503,
          );
        },
      );
      final resolver = PointSayAudio(ttsService: tts);

      final plan = await resolver.resolve(
        const PointSayDictionaryHit(word: 'molo', language: 'xh'),
      );

      expect(plan.kind, PointSayPlaybackKind.voiceComing);
      expect(plan.unavailableCode, 'voice_coming');
      expect(plan.licensedAudioBytes, isNull);
    });

    test('503 audio_unavailable surfaces unavailable state', () async {
      final tts = TtsService(
        baseUrl: 'https://api.example',
        post: (_, {headers, body}) async {
          return http.Response(
            jsonEncode({'code': 'audio_unavailable'}),
            503,
          );
        },
      );
      final resolver = PointSayAudio(ttsService: tts);

      final plan = await resolver.resolve(
        const PointSayDictionaryHit(word: 'test', language: 'yo'),
      );

      expect(plan.kind, PointSayPlaybackKind.audioUnavailable);
      expect(plan.unavailableCode, 'audio_unavailable');
    });

    test('play button label includes the word', () {
      expect(
        PointSayAudio.playButtonLabel('ọkọ'),
        'Play ọkọ',
      );
    });
  });
}
