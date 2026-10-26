import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/tts/ig_tts.dart';
import 'package:lingafriq/services/tts/pcm_tts.dart';

const _pcmPhrase = 'How you dey?';

PcmListenSample _listenSample(int index, bool? passed) {
  return PcmListenSample(
    sampleId: 'pcm-$index',
    sourceText: _pcmPhrase,
    audioRef: 'audio/pcm/$index.wav',
    linguistPass: passed,
  );
}

void main() {
  group('pcmTtsProviderFallbackOrder', () {
    test('matches EXT-01 Pidgin routing', () {
      expect(pcmTtsProviderFallbackOrder, ['intron', 'spitch']);
    });
  });

  group('licensed human registry', () {
    test('registry documents n/a for Pidgin pools', () async {
      expect(pcmLicensedHumanAudioUsableNow, 'n/a');
      final path = 'assets/data/audio/licensed_human.json';
      final raw = await File(path).readAsString();
      final registry = jsonDecode(raw) as Map<String, dynamic>;
      expect(pcmLicensedHumanPoolsFromRegistry(registry), isEmpty);
    });
  });

  group('assertPcmAsrRoundTrip', () {
    test('accepts NFC-normalised match', () {
      expect(
        () => assertPcmAsrRoundTrip(
          sourceText: '  How   you dey? ',
          transcript: 'How you dey?',
        ),
        returnsNormally,
      );
    });

    test('rejects mismatch', () {
      expect(
        () => assertPcmAsrRoundTrip(
          sourceText: _pcmPhrase,
          transcript: 'Wetin dey happen?',
        ),
        throwsA(isA<PcmAsrRoundTripFailure>()),
      );
    });
  });

  group('pcm listen batch', () {
    test('requires 100 linguist passes', () {
      expect(pcmRequiredListenSamples, 100);
      final short = List.generate(99, (i) => _listenSample(i, true));
      expect(pcmListenBatchApproved(short), isFalse);
      final full = List.generate(100, (i) => _listenSample(i, true));
      expect(pcmListenBatchApproved(full), isTrue);
      assertPcmListenBatchApproved(full);
    });

    test('assertPcmListenBatchApproved fails on any rejection', () {
      final rows = List.generate(100, (i) => _listenSample(i, i != 50));
      expect(
        () => assertPcmListenBatchApproved(rows),
        throwsA(
          predicate<PcmListenCheckFailure>((e) => e.code == 'LISTEN_CHECK_FAILED'),
        ),
      );
    });
  });

  group('PcmTtsService', () {
    test('rejects empty text before HTTP', () async {
      var calls = 0;
      final service = PcmTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          calls += 1;
          return PcmTtsHttpResponse(statusCode: 200, bodyBytes: Uint8List(0));
        },
      );

      await expectLater(
        service.synthesize(text: '   '),
        throwsA(isA<PcmTtsInputEmpty>()),
      );
      expect(calls, 0);
    });

    test('Intron then Spitch fallback', () async {
      final providers = <String>[];
      final service = PcmTtsService(
        baseUrl: 'https://api.example',
        authToken: 't',
        post: (url, {headers, body}) async {
          if (url.path.contains('intron')) {
            providers.add('intron');
            return PcmTtsHttpResponse(
              statusCode: 503,
              bodyBytes: Uint8List(0),
              bodyText: '{"code":"intron_not_configured"}',
            );
          }
          expect(headers?['X-Tts-Provider'], 'spitch');
          providers.add('spitch');
          return PcmTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([2, 4, 6]),
            headers: {'content-type': 'audio/wav'},
          );
        },
      );

      final result = await service.synthesize(text: _pcmPhrase);
      expect(providers, ['intron', 'spitch']);
      expect(result.provider, 'spitch');
      expect(result.bytes, [2, 4, 6]);
    });

    test('uses Intron when JSON returns audioUrl', () async {
      final service = PcmTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          return PcmTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List(0),
            bodyText: jsonEncode({'audioUrl': 'https://cdn.example/pcm.wav'}),
          );
        },
        get: (url, {headers}) async {
          return PcmTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([8, 0]),
          );
        },
      );

      final result = await service.synthesize(text: _pcmPhrase);
      expect(result.provider, 'intron');
      expect(result.bytes, [8, 0]);
    });

    test('Spitch failure surfaces IntronTtsFailure', () async {
      final service = PcmTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          return PcmTtsHttpResponse(
            statusCode: 503,
            bodyBytes: Uint8List(0),
            bodyText: '{"code":"audio_unavailable"}',
          );
        },
      );

      await expectLater(
        service.synthesize(text: _pcmPhrase),
        throwsA(isA<IntronTtsFailure>()),
      );
    });
  });
}
