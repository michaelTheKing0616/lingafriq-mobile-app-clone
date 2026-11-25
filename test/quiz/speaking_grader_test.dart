import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/screens/quiz/items/speaking_item.dart';
import 'package:lingafriq/services/quiz/speaking_grader.dart';

Widget _host(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
  );
}

class _FakeRecorder implements SpeakingRecorder {
  _FakeRecorder(this.path);

  final String path;
  int starts = 0;
  int stops = 0;
  final List<String> discarded = [];

  @override
  Future<void> start() async {
    starts += 1;
  }

  @override
  Future<String> stop() async {
    stops += 1;
    return path;
  }

  @override
  Future<void> discard(String path) async {
    discarded.add(path);
  }
}

class _FakeScorer implements SpeakingScorer {
  _FakeScorer(this.payload);

  final ScorerPayload payload;
  int calls = 0;
  String? audioPath;
  String? referenceText;
  String? language;

  @override
  Future<ScorerPayload> score({
    required String audioPath,
    required String referenceText,
    required String language,
  }) async {
    calls += 1;
    this.audioPath = audioPath;
    this.referenceText = referenceText;
    this.language = language;
    return payload;
  }
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, Object?> body;
  RequestOptions? options;
  String wireBody = '';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(<int>[], (
        collected,
        chunk,
      ) {
        collected.addAll(chunk);
        return collected;
      });
      wireBody = utf8.decode(bytes);
    }
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

Future<ScorerPayload> _post(int statusCode, Map<String, Object?> body) async {
  const audioPath = '/tmp/speak-take.wav';
  const referenceText = 'Ẹ káàrọ̀';
  const language = 'yoruba';
  final adapter = _ScriptedAdapter(statusCode: statusCode, body: body);
  final dio = Dio()..httpClientAdapter = adapter;
  final payload = await HttpSpeakingScorer(dio).score(
    audioPath: audioPath,
    referenceText: referenceText,
    language: language,
  );
  final options = adapter.options;
  expect(options, isNotNull);
  expect(options!.method, 'POST');
  expect(options.uri.path, '/hybrid-polie/pronounce');
  expect(
    options.uri.toString(),
    '${ApiContract.baseUrl}/hybrid-polie/pronounce',
  );
  expect(options.contentType, contains('application/json'));
  final headerNames = options.headers.keys.map((key) => key.toLowerCase());
  expect(headerNames, isNot(contains('authorization')));
  expect(headerNames, isNot(contains('x-api-key')));
  final sent = jsonDecode(adapter.wireBody) as Map<String, dynamic>;
  expect(sent['audioUrl'], audioPath);
  expect(sent['referenceText'], referenceText);
  expect(sent['language'], language);
  return payload;
}

Future<void> _recordAndStop(WidgetTester tester) async {
  await tester.tap(find.text(SpeakingCopy.record));
  await tester.pump();
  expect(find.byKey(const ValueKey<String>('phase-recording')), findsOneWidget);
  await tester.tap(find.text(SpeakingCopy.stop));
  await tester.pump();
}

void main() {
  test('a usable payload grades scored and keeps both numbers', () {
    final grade = gradeSpeaking(
      const ScorerPayload(score: 0.8, confidence: 0.9, available: true),
    );
    expect(grade.phase, 'scored');
    expect(grade.score, 0.8);
    expect(grade.confidence, 0.9);
  });

  test('confidence at 0.6 still grades scored', () {
    final grade = gradeSpeaking(
      const ScorerPayload(score: 0.8, confidence: 0.6, available: true),
    );
    expect(grade.phase, 'scored');
    expect(grade.score, 0.8);
    expect(grade.confidence, 0.6);
  });

  test('a zero score with high confidence is still a score', () {
    final grade = gradeSpeaking(
      const ScorerPayload(score: 0, confidence: 0.95, available: true),
    );
    expect(grade.phase, 'scored');
    expect(grade.score, 0);
    expect(grade.confidence, 0.95);
  });

  test('confidence 0.4 grades unsure and the score is null', () {
    final grade = gradeSpeaking(
      const ScorerPayload(score: 0.8, confidence: 0.4, available: true),
    );
    expect(grade.phase, 'unsure');
    expect(grade.score, isNull);
    expect(grade.confidence, 0.4);
  });

  test('available false grades unavailable and the score is null', () {
    final grade = gradeSpeaking(
      const ScorerPayload(score: 0.8, confidence: 0.9, available: false),
    );
    expect(grade.phase, 'unavailable');
    expect(grade.score, isNull);
    expect(grade.confidence, isNull);
  });

  test('a score outside 0 to 1 grades unavailable and the score is null', () {
    final grade = gradeSpeaking(
      const ScorerPayload(score: 1.2, confidence: 0.9, available: true),
    );
    expect(grade.phase, 'unavailable');
    expect(grade.score, isNull);
    expect(grade.confidence, isNull);
  });

  test('a non-finite score grades unavailable and the score is null', () {
    final grade = gradeSpeaking(
      const ScorerPayload(score: double.nan, confidence: 0.9, available: true),
    );
    expect(grade.phase, 'unavailable');
    expect(grade.score, isNull);
    expect(grade.confidence, isNull);
  });

  testWidgets(
    'a recorded take shows the real score and confidence, then discards audio',
    (tester) async {
      const path = '/tmp/speak-take.wav';
      final recorder = _FakeRecorder(path);
      final scorer = _FakeScorer(
        const ScorerPayload(score: 0.8, confidence: 0.9, available: true),
      );
      await tester.pumpWidget(
        _host(
          SpeakingItem(
            prompt: 'Greet an elder',
            referenceText: 'Ẹ káàrọ̀',
            language: 'yoruba',
            scorer: scorer,
            recorder: recorder,
          ),
        ),
      );
      final root = tester.widget<Semantics>(
        find.byKey(const ValueKey<String>('phase-idle')),
      );
      expect(root.explicitChildNodes, isTrue);
      expect(root.container, isTrue);
      expect(find.text(SpeakingCopy.speak), findsOneWidget);
      expect(find.text('Greet an elder'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'item.speak' &&
              widget.properties.button == true,
        ),
        findsOneWidget,
      );

      await tester.tap(find.text(SpeakingCopy.record));
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('phase-recording')),
        findsOneWidget,
      );
      expect(scorer.calls, 0);
      expect(recorder.starts, 1);

      await tester.tap(find.text(SpeakingCopy.stop));
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('phase-scored')),
        findsOneWidget,
      );
      expect(find.text('0.8'), findsOneWidget);
      expect(find.text('0.9'), findsOneWidget);
      expect(find.text(SpeakingCopy.unsure), findsNothing);
      expect(find.text(SpeakingCopy.unavailable), findsNothing);
      expect(scorer.calls, 1);
      expect(scorer.audioPath, path);
      expect(scorer.referenceText, 'Ẹ káàrọ̀');
      expect(scorer.language, 'yoruba');
      expect(recorder.stops, 1);
      expect(recorder.discarded, [path]);
    },
  );

  testWidgets('low confidence shows unsure, no digits, and discards audio', (
    tester,
  ) async {
    const path = '/tmp/speak-take.wav';
    final recorder = _FakeRecorder(path);
    final scorer = _FakeScorer(
      const ScorerPayload(score: 0.8, confidence: 0.4, available: true),
    );
    await tester.pumpWidget(
      _host(
        SpeakingItem(
          prompt: 'Greet an elder',
          referenceText: 'Ẹ káàrọ̀',
          language: 'yoruba',
          scorer: scorer,
          recorder: recorder,
        ),
      ),
    );
    await _recordAndStop(tester);

    expect(find.byKey(const ValueKey<String>('phase-unsure')), findsOneWidget);
    expect(find.text(SpeakingCopy.unsure), findsOneWidget);
    expect(find.text('0.8'), findsNothing);
    expect(find.text('0.4'), findsNothing);
    expect(find.textContaining(RegExp(r'[0-9]')), findsNothing);
    expect(recorder.discarded, [path]);
  });

  testWidgets('an unavailable scorer shows no score and discards audio', (
    tester,
  ) async {
    const path = '/tmp/speak-take.wav';
    final recorder = _FakeRecorder(path);
    final scorer = _FakeScorer(
      const ScorerPayload(score: 0.8, confidence: 0.9, available: false),
    );
    await tester.pumpWidget(
      _host(
        SpeakingItem(
          prompt: 'Greet an elder',
          referenceText: 'Ẹ káàrọ̀',
          language: 'yoruba',
          scorer: scorer,
          recorder: recorder,
        ),
      ),
    );
    await _recordAndStop(tester);

    expect(
      find.byKey(const ValueKey<String>('phase-unavailable')),
      findsOneWidget,
    );
    expect(find.text(SpeakingCopy.unavailable), findsOneWidget);
    expect(find.text('0.8'), findsNothing);
    expect(find.text('0.9'), findsNothing);
    expect(find.textContaining(RegExp(r'[0-9]')), findsNothing);
    expect(recorder.discarded, [path]);
  });

  testWidgets('storeAudio true keeps the recording', (tester) async {
    const path = '/tmp/speak-take.wav';
    final recorder = _FakeRecorder(path);
    final scorer = _FakeScorer(
      const ScorerPayload(score: 0.8, confidence: 0.9, available: true),
    );
    await tester.pumpWidget(
      _host(
        SpeakingItem(
          prompt: 'Greet an elder',
          referenceText: 'Ẹ káàrọ̀',
          language: 'yoruba',
          scorer: scorer,
          recorder: recorder,
          storeAudio: true,
        ),
      ),
    );
    await _recordAndStop(tester);

    expect(find.byKey(const ValueKey<String>('phase-scored')), findsOneWidget);
    expect(find.text('0.8'), findsOneWidget);
    expect(find.text('0.9'), findsOneWidget);
    expect(recorder.discarded, isEmpty);
  });

  test('a 200 pronounce body with score and confidence is available', () async {
    final payload = await _post(200, {'score': 0.7, 'confidence': 0.8});
    expect(payload.available, isTrue);
    expect(payload.score, 0.7);
    expect(payload.confidence, 0.8);
  });

  test('a 503 pronunciation_unavailable response is not a score', () async {
    final payload = await _post(503, {
      'code': 'pronunciation_unavailable',
      'score': 0.7,
      'confidence': 0.8,
    });
    expect(payload.available, isFalse);
    expect(payload.score, isNull);
    expect(payload.confidence, isNull);
  });

  test('a 200 body without confidence does not invent one', () async {
    final payload = await _post(200, {'score': 0.7});
    expect(payload.available, isFalse);
    expect(payload.score, isNull);
    expect(payload.confidence, isNull);
  });

  test('a 200 body without a score does not invent one', () async {
    final payload = await _post(200, {'confidence': 0.8});
    expect(payload.available, isFalse);
    expect(payload.score, isNull);
    expect(payload.confidence, isNull);
  });

  test(
    'a fallback model is unavailable even when it includes numbers',
    () async {
      final payload = await _post(200, {
        'model': 'fallback',
        'score': 0.7,
        'confidence': 0.8,
      });
      expect(payload.available, isFalse);
      expect(payload.score, isNull);
      expect(payload.confidence, isNull);
    },
  );

  test('pronunciation_unavailable on a 200 body is not a score', () async {
    final payload = await _post(200, {
      'code': 'pronunciation_unavailable',
      'score': 0.7,
      'confidence': 0.8,
    });
    expect(payload.available, isFalse);
    expect(payload.score, isNull);
    expect(payload.confidence, isNull);
  });

  test(
    'an out-of-range number is not clamped and grades unavailable',
    () async {
      final payload = await _post(200, {'score': 1.5, 'confidence': 0.9});
      expect(payload.available, isTrue);
      expect(payload.score, 1.5);
      expect(payload.confidence, 0.9);
      final grade = gradeSpeaking(payload);
      expect(grade.phase, 'unavailable');
      expect(grade.score, isNull);
      expect(grade.confidence, isNull);
    },
  );

  test(
    'the speaking scorer does not use the MFA substitute or a client key',
    () {
      final grader = File(
        'lib/services/quiz/speaking_grader.dart',
      ).readAsStringSync();
      final item = File(
        'lib/screens/quiz/items/speaking_item.dart',
      ).readAsStringSync();
      for (final source in [grader, item]) {
        expect(source.contains('_scoreMFA'), isFalse);
        expect(source.contains('PronunciationScoringService'), isFalse);
        expect(source.contains('apiKey'), isFalse);
        expect(source.contains('Authorization'), isFalse);
        expect(source.contains('0.5'), isFalse);
      }
    },
  );
}
