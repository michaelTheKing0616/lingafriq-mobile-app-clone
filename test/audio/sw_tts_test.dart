import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/tts/ig_tts.dart';
import 'package:lingafriq/services/tts/sw_tts.dart';

const _swPhrase = 'Habari yako?';

SwListenSample _listenSample(int index, bool? passed) {
  return SwListenSample(
    sampleId: 'sw-$index',
    sourceText: _swPhrase,
    audioRef: 'audio/sw/$index.wav',
    linguistPass: passed,
  );
}

void main() {
  group('swTts routing constants', () {
    test('documented order matches P5-065 artefact', () async {
      final raw = await File('assets/data/audio/sw_tts_decision.json')
          .readAsString();
      final decision = jsonDecode(raw) as Map<String, dynamic>;
      final parsed = parseSwTtsRouting(decision);

      expect(swTtsPrimaryProvider, 'google_chirp3_hd_sw_ke');
      expect(swTtsProviderFallbackOrder, ['intron', 'azure_sw_ke']);
      expect(swTtsSynthesisProviderOrder, parsed.synthesisOrder);
      expect(parsed.primary, decision['routing_for_p5_066']['primary_provider']);
    });
  });

  group('licensed human — own sentences only', () {
    const cvPool = {
      'pool_id': 'common-voice-sw-clips',
      'language': 'sw',
      'provider': 'common_voice',
      'text_scope': 'own_sentences_only',
    };

    const fleursPool = {
      'pool_id': 'fleurs-sw',
      'language': 'sw',
      'provider': 'fleurs',
      'text_scope': 'own_sentences_only',
    };

    test('accepts exact transcript match', () {
      for (final pool in [cvPool, fleursPool]) {
        expect(
          () => assertSwLicensedClipOwnSentence(
            pool: pool,
            clipTranscript: _swPhrase,
            requestedText: _swPhrase,
          ),
          returnsNormally,
        );
      }
    });

    test('rejects curriculum text on foreign clip', () {
      expect(
        () => assertSwLicensedClipOwnSentence(
          pool: cvPool,
          clipTranscript: 'Ninakupenda.',
          requestedText: _swPhrase,
        ),
        throwsA(isA<SwLicensedClipMismatch>()),
      );
    });

    test('registry helper tolerates missing sw pools', () async {
      final raw = await File('assets/data/audio/licensed_human.json')
          .readAsString();
      final registry = jsonDecode(raw) as Map<String, dynamic>;
      expect(swLicensedHumanPoolsFromRegistry(registry), isEmpty);
    });
  });

  group('assertSwAsrRoundTrip', () {
    test('accepts NFC-normalised match', () {
      expect(
        () => assertSwAsrRoundTrip(
          sourceText: '  Habari   yako? ',
          transcript: 'Habari yako?',
        ),
        returnsNormally,
      );
    });

    test('rejects mismatch', () {
      expect(
        () => assertSwAsrRoundTrip(
          sourceText: _swPhrase,
          transcript: 'Nzuri sana.',
        ),
        throwsA(isA<SwAsrRoundTripFailure>()),
      );
    });
  });

  group('sw listen batch', () {
    test('requires 100 linguist passes', () {
      expect(swRequiredListenSamples, 100);
      final short = List.generate(99, (i) => _listenSample(i, true));
      expect(swListenBatchApproved(short), isFalse);
      final full = List.generate(100, (i) => _listenSample(i, true));
      expect(swListenBatchApproved(full), isTrue);
      assertSwListenBatchApproved(full);
    });
  });

  group('SwTtsService', () {
    test('rejects empty text before HTTP', () async {
      var calls = 0;
      final service = SwTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          calls += 1;
          return SwTtsHttpResponse(statusCode: 200, bodyBytes: Uint8List(0));
        },
      );

      await expectLater(
        service.synthesize(text: '   '),
        throwsA(isA<SwTtsInputEmpty>()),
      );
      expect(calls, 0);
    });

    test('Chirp then Intron then Azure fallback', () async {
      final providers = <String>[];
      final service = SwTtsService(
        baseUrl: 'https://api.example',
        authToken: 't',
        post: (url, {headers, body}) async {
          if (url.path.contains('intron')) {
            providers.add('intron');
            return SwTtsHttpResponse(
              statusCode: 503,
              bodyBytes: Uint8List(0),
              bodyText: '{"code":"intron_not_configured"}',
            );
          }
          final header = headers?['X-Tts-Provider'] ?? '';
          providers.add(header);
          if (header == swTtsPrimaryProvider) {
            return SwTtsHttpResponse(
              statusCode: 503,
              bodyBytes: Uint8List(0),
              bodyText: '{"code":"audio_unavailable"}',
            );
          }
          expect(header, 'azure_sw_ke');
          return SwTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([7, 8, 9]),
            headers: {'content-type': 'audio/wav'},
          );
        },
      );

      final result = await service.synthesize(text: _swPhrase);
      expect(providers, [
        swTtsPrimaryProvider,
        'intron',
        'azure_sw_ke',
      ]);
      expect(result.provider, 'azure_sw_ke');
      expect(result.bytes, [7, 8, 9]);
    });

    test('uses Chirp when cloud synthesize succeeds', () async {
      final service = SwTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          expect(headers?['X-Tts-Provider'], swTtsPrimaryProvider);
          return SwTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([1, 3, 5]),
            headers: {'content-type': 'audio/wav'},
          );
        },
      );

      final result = await service.synthesize(text: _swPhrase);
      expect(result.provider, swTtsPrimaryProvider);
      expect(result.bytes, [1, 3, 5]);
    });

    test('uses Intron when Chirp fails and Intron returns audioUrl', () async {
      final service = SwTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          if (url.path.contains('intron')) {
            return SwTtsHttpResponse(
              statusCode: 200,
              bodyBytes: Uint8List(0),
              bodyText: jsonEncode({'audioUrl': 'https://cdn.example/sw.wav'}),
            );
          }
          return SwTtsHttpResponse(
            statusCode: 503,
            bodyBytes: Uint8List(0),
            bodyText: '{"code":"audio_unavailable"}',
          );
        },
        get: (url, {headers}) async {
          return SwTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([2, 0]),
          );
        },
      );

      final result = await service.synthesize(text: _swPhrase);
      expect(result.provider, 'intron');
      expect(result.bytes, [2, 0]);
    });
  });
}
