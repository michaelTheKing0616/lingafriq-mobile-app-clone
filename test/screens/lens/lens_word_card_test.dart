import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/lens_word_card.dart';
import 'package:lingafriq/screens/lens/lens_word_card.dart';
import 'package:lingafriq/widgets/tone_contour_line.dart';

import '../../helpers/test_utils.dart';

LensWordCard _yoCard({LensWordCardAudioKind kind = LensWordCardAudioKind.nativeHuman}) {
  return LensWordCard(
    lexemeId: 'yo.lex.ọkọ.vehicle',
    language: 'yo',
    word: 'ọkọ̀',
    objectSetId: 'vehicle',
    audio: LensWordCardAudio(kind: kind, playUri: 'audio/yo/test.ogg'),
  );
}

Map<String, dynamic> _yoLemmaEntry() {
  final path = File('test/content/fixtures/lexeme_yo_oko.json').absolute.path;
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('lensLemmaToneFromEntry', () {
    test('reads tone_pattern and syllables from lemma JSON', () {
      final data = lensLemmaToneFromEntry(_yoLemmaEntry());
      expect(data.tonePattern, ['M', 'L']);
      expect(data.syllables, ['ọ', 'kọ̀']);
      expect(data.hasContour, isTrue);
    });
  });

  group('LensDetectionWordCard', () {
    testWidgets('tap flips from detection label to word card', (tester) async {
      final tone = lensLemmaToneFromEntry(_yoLemmaEntry());
      await pumpWidgetWithMaterial(
        tester,
        LensDetectionWordCard(
          card: _yoCard(),
          detectionLabel: 'car',
          tonePattern: tone.tonePattern,
          syllables: tone.syllables,
        ),
      );
      expect(find.text('car'), findsOneWidget);
      expect(find.text('ọkọ̀'), findsNothing);

      await tester.tap(find.text('car'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.text('ọkọ̀'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('word uses 28sp and mic meets 48dp touch target', (tester) async {
      final tone = lensLemmaToneFromEntry(_yoLemmaEntry());
      await pumpWidgetWithMaterial(
        tester,
        LensDetectionWordCard(
          card: _yoCard(),
          detectionLabel: 'car',
          tonePattern: tone.tonePattern,
          syllables: tone.syllables,
          initiallyFlipped: true,
        ),
      );

      final word = tester.widget<Text>(find.text('ọkọ̀'));
      expect(word.style?.fontSize, 28);

      final micBox = tester.getSize(find.byType(FilledButton));
      expect(micBox.width, greaterThanOrEqualTo(48));
      expect(micBox.height, greaterThanOrEqualTo(48));
    });

    testWidgets('reduced motion cross-fades instead of 3D flip', (tester) async {
      await pumpWidgetWithMaterial(
        tester,
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: LensDetectionWordCard(
            card: _yoCard(),
            detectionLabel: 'car',
          ),
        ),
      );
      await tester.tap(find.text('car'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));
      expect(find.text('ọkọ̀'), findsOneWidget);
    });

    testWidgets('no_audio state when recording missing', (tester) async {
      await pumpWidgetWithMaterial(
        tester,
        LensDetectionWordCard(
          card: _yoCard(kind: LensWordCardAudioKind.noRecordingYet),
          detectionLabel: 'car',
          initiallyFlipped: true,
        ),
      );
      expect(find.text('No recording yet'), findsOneWidget);
    });

    testWidgets('large text scale keeps diacritics visible', (tester) async {
      await pumpWidgetWithTheme(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: LensDetectionWordCard(
            card: _yoCard(),
            detectionLabel: 'car',
            initiallyFlipped: true,
          ),
        ),
      );
      expect(find.text('ọkọ̀'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
