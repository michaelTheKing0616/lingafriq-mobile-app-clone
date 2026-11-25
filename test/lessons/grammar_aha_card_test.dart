import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/lessons/grammar_aha_card.dart';

const _yoProgressive = {
  'id': 'yo.pat.progressive',
  'description_l1': 'Preverbal ń marks an action in progress (progressive aspect)',
  'form': 'Subject + ń + verb phrase',
  'examples': [
    'Mo ń kọ́ èdè Yorùbá',
    'Mo ń ṣe dáadáa',
  ],
  'contrasts': [
    'Mo ti kọ́ èdè Yorùbá (completed)',
    'Mo máa kọ́ èdè Yorùbá (future)',
  ],
  'common_errors': [
    'Dropping ń and using only the bare verb for ongoing actions',
  ],
  'cefr': 'A1',
  'label': 'expert_reviewed',
};

void main() {
  setUp(clearGrammarAhaGapLog);

  group('buildGrammarAhaCard', () {
    test('pairs examples with contrasts then practice prompt', () {
      final entry = GrammarPatternEntry.fromJson(_yoProgressive);
      final model = buildGrammarAhaCard(entry);

      expect(model.patternId, 'yo.pat.progressive');
      expect(model.contrastRows, hasLength(2));
      expect(model.contrastRows.first.example, contains('ń'));
      expect(model.contrastRows.first.contrast, contains('ti'));
      expect(model.practicePrompt, contains('bare verb'));
      assertGrammarAhaCardCiClean(model);
    });

    test('missing contrasts logs PatternContrastMissing and returns null', () {
      final entry = GrammarPatternEntry.fromJson({
        ..._yoProgressive,
        'contrasts': <String>[],
      });

      expect(tryBuildGrammarAhaCard(entry), isNull);
      expect(grammarAhaGapLog, hasLength(1));
      expect(grammarAhaGapLog.single.code, GrammarAhaCodes.patternContrastMissing);
      expect(
        () => buildGrammarAhaCard(entry),
        throwsA(isA<PatternContrastMissing>()),
      );
    });

    test('rejects legacy generic grammar templates', () {
      final entry = GrammarPatternEntry.fromJson({
        ..._yoProgressive,
        'description_l1': 'Listen for the verb stem; affixes carry tense and person.',
      });

      expect(
        () => buildGrammarAhaCard(entry),
        throwsA(isA<GenericGrammarInAhaCard>()),
      );
    });

    test('containsBannedGenericGrammar catches SVO template', () {
      expect(
        containsBannedGenericGrammar('Pattern: subject → verb → object'),
        isTrue,
      );
      expect(containsBannedGenericGrammar('Mo ń lọ'), isFalse);
    });
  });

  group('GrammarAhaCard widget', () {
    testWidgets('announces contrast pairs and advances to practice', (tester) async {
      final entry = GrammarPatternEntry.fromJson(_yoProgressive);
      final model = buildGrammarAhaCard(entry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GrammarAhaCard(model: model)),
        ),
      );

      expect(find.textContaining('Mo ń kọ́'), findsOneWidget);
      expect(find.textContaining('Mo ti kọ́'), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(GrammarAhaCard));
      expect(semantics.label, contains('contrast pairs'));

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('bare verb'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
