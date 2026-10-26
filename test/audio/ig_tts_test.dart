import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/tts/ig_tts.dart';

const _igSample = '\u1ecb b\u1ee5\u1e63\u1ecd';

void main() {
  group('assertIgTtsInput', () {
    test('accepts NFC Igbo surface text', () {
      expect(() => assertIgTtsInput(_igSample), returnsNormally);
    });

    test('throws IgTtsInputEmpty for whitespace', () {
      expect(
        () => assertIgTtsInput('   '),
        throwsA(isA<IgTtsInputEmpty>()),
      );
    });
  });

  group('IgTtsService fallback', () {
    test('uses Spitch when Intron returns 503', () async {
      var calls = 0;
      final service = IgTtsService(
        baseUrl: 'https://api.example',
        authToken: 't',
        post: (url, {headers, body}) async {
          calls += 1;
          if (url.path.contains('intron')) {
            return IgTtsHttpResponse(
              statusCode: 503,
              bodyBytes: Uint8List(0),
              bodyText: '{"code":"intron_not_configured"}',
            );
          }
          expect(url.path, contains('synthesize'));
          expect(headers?['X-Tts-Provider'], 'spitch');
          return IgTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([4, 5, 6]),
            headers: {'content-type': 'audio/wav'},
          );
        },
      );

      final result = await service.synthesize(text: _igSample);
      expect(calls, 2);
      expect(result.provider, 'spitch');
      expect(result.bytes, [4, 5, 6]);
    });

    test('uses Intron when JSON returns audioUrl', () async {
      final service = IgTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          return IgTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List(0),
            bodyText: jsonEncode({'audioUrl': 'https://cdn.example/ig.wav'}),
          );
        },
        get: (url, {headers}) async {
          return IgTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([7, 6]),
          );
        },
      );

      final result = await service.synthesize(text: _igSample);
      expect(result.provider, 'intron');
      expect(result.bytes, [7, 6]);
    });

    test('rejects empty text before any HTTP call', () async {
      var calls = 0;
      final service = IgTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          calls += 1;
          return IgTtsHttpResponse(statusCode: 200, bodyBytes: Uint8List(0));
        },
      );

      await expectLater(
        service.synthesize(text: '  '),
        throwsA(isA<IgTtsInputEmpty>()),
      );
      expect(calls, 0);
    });
  });
}
