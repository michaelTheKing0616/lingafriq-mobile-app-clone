import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/grammar/grammar_exercise_screen.dart';
import 'package:lingafriq/widgets/gamification/combo_tracker.dart';

void main() {
  group('GrammarExercise model', () {
    test('fromJson parses fill_in_the_blank type', () {
      final json = {
        'id': 'ex1',
        'type': 'fill_in_the_blank',
        'question': 'Mo ___ ilé.',
        'options': ['wá', 'wọ'],
        'correctAnswer': 'wá',
        'explanation': 'Correct form is wá',
      };
      final ex = GrammarExercise.fromJson(json);
      expect(ex.id, 'ex1');
      expect(ex.type, ExerciseType.fillInTheBlank);
      expect(ex.question, 'Mo ___ ilé.');
      expect(ex.options, ['wá', 'wọ']);
      expect(ex.correctAnswer, 'wá');
      expect(ex.explanation, 'Correct form is wá');
    });

    test('fromJson parses word_order type', () {
      final json = {
        '_id': 'ex2',
        'type': 'word_order',
        'question': 'Rearrange.',
        'options': ['Mo', 'wá', 'ilé'],
        'correct_answer': 'Mo wá ilé',
        'explanation': 'Correct order.',
      };
      final ex = GrammarExercise.fromJson(json);
      expect(ex.type, ExerciseType.wordOrder);
      expect(ex.correctAnswer, 'Mo wá ilé');
    });

    test('fromJson parses conjugation type', () {
      final json = {
        'id': 'ex3',
        'type': 'conjugation',
        'question': 'Select conjugation.',
        'options': ['wá', 'wáà'],
        'correctAnswer': 'wá',
        'explanation': 'Base form.',
      };
      final ex = GrammarExercise.fromJson(json);
      expect(ex.type, ExerciseType.conjugation);
    });

    test('fromJson parses error_detection type', () {
      final json = {
        'id': 'ex4',
        'type': 'error_detection',
        'question': 'Find the error.',
        'options': ['Mo', 'wáà', 'ilé'],
        'correctAnswer': 'wáà',
        'explanation': 'Should be wá.',
      };
      final ex = GrammarExercise.fromJson(json);
      expect(ex.type, ExerciseType.errorDetection);
    });

    test('fromJson defaults to fillInTheBlank for unknown type', () {
      final ex = GrammarExercise.fromJson({
        'id': 'x',
        'type': 'unknown',
        'question': 'Q',
        'options': [],
        'correctAnswer': 'A',
        'explanation': 'E',
      });
      expect(ex.type, ExerciseType.fillInTheBlank);
    });
  });

  group('GrammarExerciseScreen scoring and combo', () {
    testWidgets('screen builds and shows loading then content or error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => ProviderScope(
            child: MaterialApp(
              home: GrammarExerciseScreen(
                topicId: 'test-topic',
                topicName: 'Test Topic',
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(GrammarExerciseScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Allow async _loadExercises to complete (no pumpAndSettle - screen has ongoing animations)
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GrammarExerciseScreen), findsOneWidget);
    });
  });

  group('ComboTracker in grammar context', () {
    test('recordCorrect increases consecutiveCorrect and maxCombo', () {
      final tracker = ComboTracker();
      tracker.recordCorrect();
      tracker.recordCorrect();
      expect(tracker.consecutiveCorrect, 2);
      expect(tracker.maxCombo, 2);
    });

    test('recordIncorrect resets consecutiveCorrect but keeps maxCombo', () {
      final tracker = ComboTracker();
      tracker.recordCorrect();
      tracker.recordCorrect();
      tracker.recordCorrect();
      tracker.recordIncorrect();
      expect(tracker.consecutiveCorrect, 0);
      expect(tracker.maxCombo, 3);
    });

    test('combo multiplier increases at 2 and 4 correct', () {
      final tracker = ComboTracker();
      expect(tracker.currentMultiplier, 1.0);
      tracker.recordCorrect();
      expect(tracker.currentMultiplier, 1.0);
      tracker.recordCorrect();
      expect(tracker.currentMultiplier, 1.5);
      tracker.recordCorrect();
      tracker.recordCorrect();
      expect(tracker.currentMultiplier, 2.0);
    });
  });
}
