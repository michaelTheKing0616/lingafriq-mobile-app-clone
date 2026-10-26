import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/tts/yo_tts.dart';

const _marked = '\u00e0\u00e1r\u1ecd\u0300 \u1eb9\u0301';

void main() {
  group('assertYoFullyToneMarked', () {
    test('accepts NFC Yoruba with tone marks', () {
      expect(() => assertYoFullyToneMarked(_marked), returnsNormally);
    });

    test('throws ToneMarksMissing for plain baba', () {
      expect(
        () => assertYoFullyToneMarked('baba'),
        throwsA(isA<ToneMarksMissing>()),
      );
    });
  });

  group('YoTtsService fallback', () {
    test('uses Spitch when Intron returns 503', () async {
      var calls = 0;
      final service = YoTtsService(
        baseUrl: 'https://api.example',
        authToken: 't',
        post: (url, {headers, body}) async {
          calls += 1;
          if (url.path.contains('intron')) {
            return YoTtsHttpResponse(
              statusCode: 503,
              bodyBytes: Uint8List(0),
              bodyText: '{"code":"intron_not_configured"}',
            );
          }
          expect(url.path, contains('synthesize'));
          expect(headers?['X-Tts-Provider'], 'spitch');
          return YoTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([1, 2, 3]),
            headers: {'content-type': 'audio/wav'},
          );
        },
      );

      final result = await service.synthesize(text: _marked);
      expect(calls, 2);
      expect(result.provider, 'spitch');
      expect(result.bytes, [1, 2, 3]);
    });

    test('uses Intron when JSON returns audioUrl', () async {
      final service = YoTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          return YoTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List(0),
            bodyText: jsonEncode({'audioUrl': 'https://cdn.example/a.wav'}),
          );
        },
        get: (url, {headers}) async {
          return YoTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([9, 8]),
          );
        },
      );

      final result = await service.synthesize(text: _marked);
      expect(result.provider, 'intron');
      expect(result.bytes, [9, 8]);
    });

    test('rejects unmarked text before any HTTP call', () async {
      var calls = 0;
      final service = YoTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          calls += 1;
          return YoTtsHttpResponse(statusCode: 200, bodyBytes: Uint8List(0));
        },
      );

      await expectLater(
        service.synthesize(text: 'oko'),
        throwsA(isA<ToneMarksMissing>()),
      );
      expect(calls, 0);
    });
  });
}
