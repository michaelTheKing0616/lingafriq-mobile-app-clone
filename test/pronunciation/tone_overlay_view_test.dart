import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/pronunciation/tone_overlay_view.dart';

void main() {
  test('buildToneOverlayAccessibilitySummary describes each syllable', () {
    final summary = buildToneOverlayAccessibilitySummary([
      SyllableToneOverlayRow(
        label: 'ọ',
        expectedToneLabel: 'H',
        toneLabel: 'H',
        correct: true,
        nativeContour: [1],
        learnerContour: [1.1],
      ),
      SyllableToneOverlayRow(
        label: 'kọ',
        expectedToneLabel: 'L',
        correct: null,
        reason: 'unsure',
        nativeContour: [0],
        learnerContour: [0],
      ),
    ]);
    expect(summary, contains('ọ: correct'));
    expect(summary, contains('kọ:'));
    expect(summary, contains('Tone unclear'));
  });

  testWidgets('ToneOverlayView exposes semantics summary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToneOverlayView(
            status: ToneOverlayStatus.scored,
            syllables: [
              SyllableToneOverlayRow(
                label: 'a',
                expectedToneLabel: 'M',
                correct: false,
                toneLabel: 'L',
                nativeContour: [2, 3],
                learnerContour: [1, 2],
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('a: incorrect, expected M, heard L'),
      findsOneWidget,
    );
  });
}
