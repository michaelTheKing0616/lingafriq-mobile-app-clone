import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/tts/ig_tts.dart';
import 'package:lingafriq/services/tts/zu_tts.dart';

const _zuPhrase = 'Sawubona.';
const _zuClickPhrase = 'Qaphela.';

ZuListenSample _listenSample(
  int index,
  bool? passed, {
  String text = _zuPhrase,
  String? asrTranscript,
  String asrProvider = 'intron',
}) {
  return ZuListenSample(
    sampleId: 'zu-$index',
    sourceText: text,
    audioRef: 'audio/zu/$index.wav',
    linguistPass: passed,
    asrTranscript: asrTranscript,
    asrProvider: asrProvider,
  );
}

void main() {
  group('zu Azure voices', () {
    test('Thando and Themba neural names are documented', () {
      expect(zuAzureVoiceThandoNeural, 'zu-ZA-ThandoNeural');
      expect(zuAzureVoiceThembaNeural, 'zu-ZA-ThembaNeural');
      expect(zuTtsSynthesisProviderOrder, [
        zuTtsProviderThando,
        zuTtsProviderThemba,
      ]);
    });
  });

  group('licensed human — FLEURS and WAXAL', () {
    const fleursPool = {
      'pool_id': 'fleurs-zu',
      'language': 'zu',
      'provider': 'fleurs',
      'licence_id': 'fleurs',
      'text_scope': 'own_sentences_only',
    };

    const waxalPool = {
      'pool_id': 'waxal-zu',
      'language': 'zu',
      'provider': 'waxal',
      'register_id': 'waxal-other',
      'subset_licence_verified': true,
      'text_scope': 'own_sentences_only',
    };

    test('accepts own-sentence match', () {
      for (final pool in [fleursPool, waxalPool]) {
        expect(
          () => assertZuLicensedClipOwnSentence(
            pool: pool,
            clipTranscript: _zuPhrase,
            requestedText: _zuPhrase,
          ),
          returnsNormally,
        );
      }
    });

    test('rejects WAXAL without subset verification', () {
      expect(
        () => assertZuLicensedClipOwnSentence(
          pool: {
            ...waxalPool,
            'subset_licence_verified': false,
          },
          clipTranscript: _zuPhrase,
          requestedText: _zuPhrase,
        ),
        throwsA(isA<ZuLicensedClipMismatch>()),
      );
    });

    test('registry helper tolerates missing zu pools', () async {
      final raw = await File('assets/data/audio/licensed_human.json')
          .readAsString();
      final registry = jsonDecode(raw) as Map<String, dynamic>;
      expect(zuLicensedHumanPoolsFromRegistry(registry), isEmpty);
    });
  });

  group('assertZuAsrRoundTrip', () {
    test('accepts intron match', () {
      expect(
        () => assertZuAsrRoundTrip(
          sourceText: '  Sawubona. ',
          transcript: 'Sawubona.',
          asrProvider: 'intron',
        ),
        returnsNormally,
      );
    });

    test('rejects forbidden ASR vendor', () {
      expect(
        () => assertZuAsrRoundTrip(
          sourceText: _zuPhrase,
          transcript: _zuPhrase,
          asrProvider: 'whisper',
        ),
        throwsA(isA<ZuAsrRoundTripFailure>()),
      );
    });

    test('lelapa allowed and enforces click inventory', () {
      expect(
        () => assertZuAsrRoundTrip(
          sourceText: _zuClickPhrase,
          transcript: 'Qaphela.',
          asrProvider: 'lelapa',
        ),
        returnsNormally,
      );
      expect(
        () => assertZuAsrRoundTrip(
          sourceText: _zuClickPhrase,
          transcript: 'Kaphela.',
          asrProvider: 'lelapa',
        ),
        throwsA(isA<ZuAsrRoundTripFailure>()),
      );
      expect(
        () => assertZuClickInventoryMatches(
          sourceText: _zuClickPhrase,
          transcript: 'Caphila.',
        ),
        throwsA(isA<ZuClickCheckFailure>()),
      );
    });
  });

  group('zu listen batch', () {
    test('requires 100 linguist passes and click ASR when needed', () {
      final short = List.generate(99, (i) => _listenSample(i, true));
      expect(zuListenBatchApproved(short), isFalse);

      final full = List.generate(
        100,
        (i) => _listenSample(
          i,
          true,
          asrTranscript: _zuPhrase,
        ),
      );
      expect(zuListenBatchApproved(full), isTrue);
      assertZuListenBatchApproved(full);

      final clickNoAsr = List.generate(
        100,
        (i) => _listenSample(i, true, text: _zuClickPhrase),
      );
      expect(zuListenBatchApproved(clickNoAsr), isFalse);
    });
  });

  group('ZuTtsService', () {
    test('rejects empty text before HTTP', () async {
      var calls = 0;
      final service = ZuTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          calls += 1;
          return ZuTtsHttpResponse(statusCode: 200, bodyBytes: Uint8List(0));
        },
      );

      await expectLater(
        service.synthesize(text: '   '),
        throwsA(isA<ZuTtsInputEmpty>()),
      );
      expect(calls, 0);
    });

    test('Thando then Themba fallback', () async {
      final providers = <String>[];
      final voices = <String>[];
      final service = ZuTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          final header = headers?['X-Tts-Provider'] ?? '';
          providers.add(header);
          final decoded = jsonDecode(body as String) as Map<String, dynamic>;
          voices.add(decoded['voiceName'] as String);
          if (header == zuTtsProviderThando) {
            return ZuTtsHttpResponse(
              statusCode: 503,
              bodyBytes: Uint8List(0),
              bodyText: '{"code":"audio_unavailable"}',
            );
          }
          expect(header, zuTtsProviderThemba);
          return ZuTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([4, 5, 6]),
            headers: {'content-type': 'audio/wav'},
          );
        },
      );

      final result = await service.synthesize(text: _zuPhrase);
      expect(providers, [zuTtsProviderThando, zuTtsProviderThemba]);
      expect(voices, [zuAzureVoiceThandoNeural, zuAzureVoiceThembaNeural]);
      expect(result.provider, zuTtsProviderThemba);
      expect(result.bytes, [4, 5, 6]);
    });

    test('uses Thando when Azure succeeds', () async {
      final service = ZuTtsService(
        baseUrl: 'https://api.example',
        post: (url, {headers, body}) async {
          expect(headers?['X-Tts-Provider'], zuTtsProviderThando);
          final decoded = jsonDecode(body as String) as Map<String, dynamic>;
          expect(decoded['locale'], zuTtsLocale);
          expect(decoded['voiceName'], zuAzureVoiceThandoNeural);
          return ZuTtsHttpResponse(
            statusCode: 200,
            bodyBytes: Uint8List.fromList([1, 2]),
            headers: {'content-type': 'audio/wav'},
          );
        },
      );

      final result = await service.synthesize(text: _zuPhrase);
      expect(result.provider, zuTtsProviderThando);
      expect(result.voiceName, zuAzureVoiceThandoNeural);
    });
  });
}
