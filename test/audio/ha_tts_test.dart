import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/tts/ha_tts.dart';
import 'package:lingafriq/services/tts/yo_tts.dart';

/// Hausa teaching form with tone mark (same gate as Yoruba).
const _markedHa = '\u00e0\u00e1r\u1ecd\u0300';

void main() {
  group('haTtsProviderFallbackOrder', () {
    test('matches EXT-01 Hausa routing', () {
      expect(haTtsProviderFallbackOrder, [
        'intron',
        'spitch',
        'elevenlabs_v3',
      ]);
    });
  });

  group('HaTtsService tone gate', () {
    test('rejects unmarked text before HTTP', () async {
      var calls = 0;
      final service = HaTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          calls += 1;
          return HaTtsHttpResponse(statusCode: 200, bodyBytes: Uint8List(0));
        },
      );

      await expectLater(
        service.synthesize(text: 'sannu'),
        throwsA(isA<ToneMarksMissing>()),
      );
      expect(calls, 0);
    });
  });

  group('HaTtsService fallback order', () {
    test('Intron then Spitch then ElevenLabs v3', () async {
      final providers = <String>[];
      final service = HaTtsService(
        baseUrl: 'https://api.example',
        authToken: 't',
        post: (url, {headers, body}) async {
          if (url.path.contains('intron')) {
            providers.add('intron');
            return HaTtsHttpResponse(
              statusCode: 503,
              bodyBytes: Uint8List(0),
              bodyText: '{"code":"intron_not_configured"}',
            );
          }
          final header = headers?['X-Tts-Provider'] ?? '';
          providers.add(header);
          if (header == 'spitch') {
            return HaTtsHttpResponse(
              statusCode: 503,
              bodyBytes: Uint8List(0),
              bodyText: '{"code":"audio_unavailable"}',
            );
          }
          expect(header, 'elevenlabs_v3');
          return HaTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([1, 2, 3]),
            headers: {'content-type': 'audio/wav'},
          );
        },
      );

      final result = await service.synthesize(text: _markedHa);
      expect(providers, ['intron', 'spitch', 'elevenlabs_v3']);
      expect(result.provider, 'elevenlabs_v3');
      expect(result.bytes, [1, 2, 3]);
    });

    test('uses Intron when JSON returns audioUrl', () async {
      final service = HaTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          return HaTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List(0),
            bodyText: jsonEncode({'audioUrl': 'https://cdn.example/ha.wav'}),
          );
        },
        get: (url, {headers}) async {
          return HaTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([9, 1]),
          );
        },
      );

      final result = await service.synthesize(text: _markedHa);
      expect(result.provider, 'intron');
      expect(result.bytes, [9, 1]);
    });

    test('uses Spitch when Intron returns 503 only', () async {
      var calls = 0;
      final service = HaTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          calls += 1;
          if (url.path.contains('intron')) {
            return HaTtsHttpResponse(
              statusCode: 503,
              bodyBytes: Uint8List(0),
              bodyText: '{"code":"intron_not_configured"}',
            );
          }
          expect(headers?['X-Tts-Provider'], 'spitch');
          return HaTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([4, 5]),
            headers: {'content-type': 'audio/wav'},
          );
        },
      );

      final result = await service.synthesize(text: _markedHa);
      expect(calls, 2);
      expect(result.provider, 'spitch');
    });
  });
}
