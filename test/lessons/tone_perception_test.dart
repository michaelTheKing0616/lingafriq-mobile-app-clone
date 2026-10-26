import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/lessons/tone_perception_drill.dart';

String _fixtureJson() {
  final path = File(
    'assets/data/tone/minimal_pairs.json',
  );
  return path.readAsStringSync();
}

void main() {
  group('parseTonePerceptionCatalog', () {
    test('loads Yoruba ọkọ́ / ọkọ̀ pair with recorded sources (AC1)', () {
      final catalog = loadTonePerceptionCatalogFromJson(_fixtureJson());
      expect(catalog.cardId, 'P5-026');

      final yo = drillsForLanguage(catalog, 'yo');
      expect(yo, hasLength(1));
      final drill = yo.single;
      expect(drill.correctOptionId, 'yo.lex.ọkọ.vehicle');
      expect(
        drill.options.map((o) => o.form),
        containsAll(['ọkọ́', 'ọkọ̀']),
      );
      expect(drill.pairSourceId, isNotEmpty);
    });

    test('records FSI references for yo, ig, ha (AC2)', () {
      final catalog = loadTonePerceptionCatalogFromJson(_fixtureJson());
      for (final code in ['yo', 'ig', 'ha']) {
        final ref = catalog.packs[code]!.fsiReference!;
        expect(ref.licence, isNotEmpty);
        expect(ref.uriOrCitation, contains('register:fsi-'));
        expect(ref.use, 'reference_only');
      }
    });

    test('unsourced option fails TonePairUnsourced (AC3)', () {
      expect(
        () => parseTonePerceptionCatalog({
          'card': 'P5-026',
          'languages': {
            'yo': {
              'drills': [
                {
                  'id': 'bad',
                  'prompt_gloss_en': 'x',
                  'correct_option_id': 'a',
                  'pair_source_id': 'src',
                  'options': [
                    {'id': 'a', 'form': 'a', 'gloss_en': 'a', 'source_id': ''},
                  ],
                },
              ],
            },
          },
        }),
        throwsA(isA<TonePairUnsourced>()),
      );
    });

    test('gradePerceptionChoice is correct/incorrect only (AC4)', () {
      final catalog = loadTonePerceptionCatalogFromJson(_fixtureJson());
      final drill = drillsForLanguage(catalog, 'yo').single;
      final ok = gradePerceptionChoice(
        drill: drill,
        selectedOptionId: drill.correctOptionId,
      );
      expect(ok.correct, isTrue);

      final wrongId = drill.options
          .map((o) => o.id)
          .firstWhere((id) => id != drill.correctOptionId);
      final bad = gradePerceptionChoice(
        drill: drill,
        selectedOptionId: wrongId,
      );
      expect(bad.correct, isFalse);
    });
  });

  group('TonePerceptionDrillScreen', () {
    testWidgets('choose phase shows options and result without score', (tester) async {
      final catalog = loadTonePerceptionCatalogFromJson(_fixtureJson());
      final drill = drillsForLanguage(catalog, 'yo').single;
      TonePerceptionAnswer? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: TonePerceptionDrillScreen(
            drill: drill,
            onComplete: (a) => captured = a,
          ),
        ),
      );

      await tester.tap(find.text(TonePerceptionCopyKeys.listen));
      await tester.pump();
      await tester.tap(find.text(TonePerceptionCopyKeys.pick));
      await tester.pump();

      await tester.tap(find.textContaining('ọkọ̀'));
      await tester.pump();

      expect(find.text('Correct'), findsOneWidget);
      expect(captured?.correct, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
