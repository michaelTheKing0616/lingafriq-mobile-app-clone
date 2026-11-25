import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/lessons/tone_production_drill.dart';
import 'package:lingafriq/learning/pronunciation/tone_models.dart';

const _drillPath = 'lib/lessons/tone_production_drill.dart';

String _codeWithoutComments(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue);
  return file
      .readAsStringSync()
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
}

class _FakeToneScorer implements ToneProductionScorer {
  _FakeToneScorer(this.payload);

  final ToneScorerPayload payload;
  int calls = 0;

  @override
  Future<ToneScorerPayload> score({
    required String audioPath,
    required String expectedText,
    required String languageCode,
  }) async {
    calls += 1;
    return payload;
  }
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, Object?> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('buildActionableFeedback', () {
    test('maps first syllable error to ordinal coaching (AC1)', () {
      const errors = [
        ToneProductionError(
          syllable: 'ọkọ',
          position: 1,
          expected: 'L',
          actual: 'H',
          issue: 'pitch should be lower',
        ),
      ];
      final text = buildActionableFeedback(errors: errors);
      expect(text, contains('second syllable'));
      expect(text, contains('pitch should be lower'));
      expect(text, contains('ọkọ'));
    });
  });

  group('gradeToneProduction', () {
    test('low confidence yields unsure without accuracy shown (AC2)', () {
      const payload = ToneScorerPayload(
        available: true,
        accuracy: 0.92,
        confidence: 0.5,
        errors: const [],
        summaryFeedback: 'Good',
      );
      final grade = gradeToneProduction(payload);
      expect(grade.phase, ToneProductionPhase.unsure);
      expect(grade.accuracy, isNull);
    });

    test('confident payload yields feedback phase with hint', () {
      const payload = ToneScorerPayload(
        available: true,
        accuracy: 0.8,
        confidence: 0.85,
        errors: [
          ToneProductionError(
            syllable: 'ba',
            position: 0,
            expected: 'H',
            actual: 'L',
            issue: 'raise the pitch more',
          ),
        ],
        summaryFeedback: 'Keep practicing',
      );
      final grade = gradeToneProduction(payload);
      expect(grade.phase, ToneProductionPhase.feedback);
      expect(grade.accuracy, 0.8);
      expect(grade.actionableFeedback, contains('first syllable'));
    });
  });

  group('parseToneAnalyzeBody', () {
    test('parses voice-service tone analyzer shape', () {
      final payload = parseToneAnalyzeBody({
        'accuracy': 0.75,
        'errors': [
          {
            'syllable': 'mi',
            'position': 0,
            'expected': 'H',
            'actual': 'L',
            'issue': 'raise the pitch more',
          },
        ],
        'feedback': 'Good tones!',
        'actual_pattern': {'confidence': 0.9},
      });
      expect(payload.available, isTrue);
      expect(payload.accuracy, 0.75);
      expect(payload.confidence, 0.9);
      expect(payload.errors, hasLength(1));
    });
  });

  group('HttpToneProductionScorer', () {
    test('posts multipart to tone endpoint', () async {
      final audioFile = File(
        '${Directory.systemTemp.path}/tone_production_test.wav',
      );
      await audioFile.writeAsBytes(const [0, 1, 2, 3]);

      final dio = Dio();
      final adapter = _ScriptedAdapter(
        statusCode: 200,
        body: {
          'accuracy': 0.7,
          'feedback': 'ok',
          'actual_pattern': {'confidence': 0.8},
          'errors': [],
        },
      );
      dio.httpClientAdapter = adapter;
      final scorer = HttpToneProductionScorer(dio);
      final payload = await scorer.score(
        audioPath: audioFile.path,
        expectedText: 'ọkọ̀',
        languageCode: 'yo',
      );
      expect(payload.available, isTrue);
      expect(payload.confidence, 0.8);
    });
  });

  group('tone model gate', () {
    test('throws when language model missing', () {
      final catalog = parseToneModelsCatalog({
        'card': 'P5-027',
        'languages': {
          'sw': {'tonal': false, 'source_id': 'x'},
        },
      });
      expect(
        () => assertToneProductionAllowed(catalog, 'sw'),
        throwsA(isA<ToneModelMissing>()),
      );
    });
  });

  group('RandomScoreForbidden (AC3)', () {
    test('production drill has no RNG-fed score', () {
      final statements = _codeWithoutComments(_drillPath).split(';');
      final offenders = statements.where((s) {
        final usesRng = RegExp(r'\bRandom\s*\(').hasMatch(s);
        return usesRng && RegExp('score', caseSensitive: false).hasMatch(s);
      }).toList();
      expect(offenders, isEmpty);
    });

    test('unsure phase does not show accuracy percent', () {
      final code = _codeWithoutComments(_drillPath);
      final unsureBlock = code.split('ToneProductionPhase.unsure').last;
      expect(
        RegExp(r'accuracy').hasMatch(unsureBlock.split('recording').first),
        isFalse,
      );
    });
  });

  testWidgets('unsure UI offers retry without score', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToneProductionDrillScreen(
            spec: const ToneProductionSpec(
              id: 'yo.test',
              languageCode: 'yo',
              targetForm: 'ọkọ̀',
              promptGlossEn: 'Say vehicle',
            ),
            scorer: _FakeToneScorer(
              const ToneScorerPayload(
                available: true,
                accuracy: 0.9,
                confidence: 0.2,
                errors: const [],
                summaryFeedback: null,
              ),
            ),
            audioPath: '/tmp/fake.wav',
          ),
        ),
      ),
    );
    await tester.tap(find.text(ToneProductionCopyKeys.record));
    await tester.pump();
    await tester.pump();
    expect(find.text(ToneProductionCopyKeys.defaultUnsure), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text(ToneProductionCopyKeys.retry), findsOneWidget);
  });
}
