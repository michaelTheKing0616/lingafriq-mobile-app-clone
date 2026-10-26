import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/lessons/handwriting_practice.dart';
import 'package:lingafriq/lessons/stroke_order_view.dart';

StrokeCatalog _fixtureCatalog() {
  return StrokeCatalog.fromJson({
    'card': 'P5-084-test',
    'glyphs': [
      {
        'character': '\uE010',
        'catalog_source_id': 'test_fixture:P5-084:stroke_order_test',
        'meaning': 'fixture glyph',
        'strokes': [
          {
            'source_id': 'test_fixture:P5-084:stroke1',
            'points': [
              [0.2, 0.2],
              [0.8, 0.2],
              [0.8, 0.8],
              [0.2, 0.8],
              [0.2, 0.2],
            ],
          },
        ],
      },
    ],
  });
}

List<Offset> _squareTrace() {
  return [
    const Offset(20, 20),
    const Offset(80, 20),
    const Offset(80, 80),
    const Offset(20, 80),
    const Offset(20, 20),
    const Offset(22, 22),
    const Offset(24, 24),
    const Offset(26, 26),
    const Offset(28, 28),
    const Offset(30, 30),
  ];
}

void main() {
  group('stroke data', () {
    test('catalog requires source_id on strokes', () {
      expect(
        () => StrokeCatalog.fromJson({
          'glyphs': [
            {
              'character': 'x',
              'catalog_source_id': 'src',
              'strokes': [
                {'points': [
                  [0, 0],
                  [1, 1],
                ]},
              ],
            },
          ],
        }),
        throwsFormatException,
      );
    });

    test('default catalog leaves Ge\'ez glyphs without stroke data', () {
      expect(kDefaultStrokeCatalog.dataFor('\u1200'), isNull);
      expect(
        resolveStrokeOrderState(
          character: '\u1200',
          catalog: kDefaultStrokeCatalog,
          animationPlaying: false,
        ),
        StrokeOrderUiState.unavailable,
      );
    });
  });

  group('handwriting recognition', () {
    final catalog = _fixtureCatalog();
    const glyph = '\uE010';

    test('matching trace is recognized', () {
      final result = recognizeHandwriting(
        attempt: HandwritingAttempt(points: _squareTrace()),
        character: glyph,
        catalog: catalog,
      );
      expect(result.state, HandwritingUiState.recognized);
    });

    test('far trace is mismatch', () {
      final result = recognizeHandwriting(
        attempt: HandwritingAttempt(
          points: List.generate(10, (i) => Offset(i * 12.0, 4)),
        ),
        character: glyph,
        catalog: catalog,
      );
      expect(result.state, HandwritingUiState.mismatch);
    });

    test('too few points is unsure', () {
      final result = recognizeHandwriting(
        attempt: HandwritingAttempt(points: const [Offset(1, 1)]),
        character: glyph,
        catalog: catalog,
      );
      expect(result.state, HandwritingUiState.unsure);
    });

    test('missing stroke data is unavailable', () {
      final result = recognizeHandwriting(
        attempt: HandwritingAttempt(points: _squareTrace()),
        character: '\u1200',
        catalog: catalog,
      );
      expect(result.state, HandwritingUiState.unavailable);
    });
  });

  testWidgets('stroke animation plays for sourced character', (tester) async {
    final catalog = _fixtureCatalog();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StrokeOrderView(
            character: '\uE010',
            catalog: catalog,
            romanization: 'fixture',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(StrokeOrderCopyKeys.defaultStrokeTitle), findsOneWidget);
    expect(find.text(StrokeOrderCopyKeys.unavailable), findsNothing);
  });

  testWidgets('missing stroke data shows unavailable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StrokeOrderView(character: '\u1200'),
        ),
      ),
    );
    expect(find.text(StrokeOrderCopyKeys.unavailable), findsOneWidget);
  });

  testWidgets('reduced motion shows completed strokes without animating',
      (tester) async {
    final catalog = _fixtureCatalog();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: StrokeOrderView(
              character: '\uE010',
              catalog: catalog,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(StrokeOrderCopyKeys.unavailable), findsNothing);
  });

  testWidgets('handwriting panel unavailable without stroke catalog', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HandwritingPracticePanel(character: '\u1200'),
        ),
      ),
    );
    expect(find.text(StrokeOrderCopyKeys.unavailable), findsOneWidget);
  });
}
