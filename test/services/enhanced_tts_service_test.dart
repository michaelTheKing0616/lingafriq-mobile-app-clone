import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lingafriq/services/enhanced_tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnhancedTTSService P6-047', () {
    test('human recording wins without gateway TTS', () async {
      var gatewayCalls = 0;
      final client = MockClient((request) async {
        if (request.url.path.contains('/api/ai/tts/')) {
          gatewayCalls++;
        }
        return http.Response('', 503);
      });

      final svc = EnhancedTTSService(httpClient: client);
      final plan = await svc.resolvePlayback(
        const EnhancedTtsSpeakRequest(
          text: 'ọkọ',
          language: 'yo',
          turnKind: EnhancedTtsTurnKind.curriculumRecorded,
          humanAudioUrl: 'https://cdn.example/native.mp3',
        ),
      );

      expect(plan.kind, EnhancedTtsPlaybackKind.playingHuman);
      expect(plan.gatewayTtsRequested, isFalse);
      expect(gatewayCalls, 0);
    });

    test('yo dynamic failure surfaces no-voice state', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'code': 'voice_not_gated'}),
          503,
        );
      });

      final svc = EnhancedTTSService(httpClient: client);
      final plan = await svc.resolvePlayback(
        const EnhancedTtsSpeakRequest(
          text: 'ẹ kú',
          language: 'yo',
          turnKind: EnhancedTtsTurnKind.dynamicAi,
        ),
      );

      expect(plan.kind, EnhancedTtsPlaybackKind.noVoice);
      expect(plan.showNoVoiceState, isTrue);
      expect(plan.gatewayTtsRequested, isTrue);
    });

    test('dynamic licensed bytes when gateway returns audio', () async {
      final client = MockClient((request) async {
        return http.Response.bytes(
          Uint8List.fromList([1, 2, 3]),
          200,
          headers: {'content-type': 'audio/wav'},
        );
      });

      final svc = EnhancedTTSService(httpClient: client);
      final plan = await svc.resolvePlayback(
        const EnhancedTtsSpeakRequest(
          text: 'habari',
          language: 'sw',
          turnKind: EnhancedTtsTurnKind.dynamicAi,
        ),
      );

      expect(plan.kind, EnhancedTtsPlaybackKind.playingLicensed);
      expect(plan.licensedAudioBytes, isNotNull);
    });

    test('no-voice semantics label is exposed for a11y', () {
      expect(
        EnhancedTTSService.noVoiceSemanticsLabel('Yoruba'),
        contains('No licensed voice'),
      );
    });
  });
}
