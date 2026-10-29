import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_feedback.dart';

void main() {
  group('GameKitFeedbackBudget', () {
    test('tap budget is 160 ms and celebration cap is 1.5 s', () {
      expect(GameKitFeedbackBudget.tapToFeedbackP95Ms, 160);
      expect(GameKitFeedbackBudget.celebrationMaxMs, 1500);
    });
  });

  group('local verification', () {
    test('MCQ with known key is locally verifiable', () {
      expect(
        gameKitIsLocallyVerifiable(
          selectedAnswer: 'a',
          correctAnswer: 'a',
          requiresServerScoring: false,
        ),
        isTrue,
      );
      expect(
        gameKitIsLocallyVerifiable(
          selectedAnswer: 'a',
          correctAnswer: 'b',
          requiresServerScoring: false,
        ),
        isTrue,
      );
    });

    test('typed answers require server scoring path', () {
      expect(
        gameKitIsLocallyVerifiable(
          selectedAnswer: null,
          correctAnswer: 'x',
          requiresServerScoring: true,
        ),
        isFalse,
      );
    });

    test('local verdict trims whitespace', () {
      expect(
        gameKitLocalVerdict(selectedAnswer: ' hello ', correctAnswer: 'hello'),
        isTrue,
      );
    });
  });

  group('GameKitFeedbackTiming', () {
    test('pending only after budget for non-local paths', () {
      final timing = GameKitFeedbackTiming(
        tappedAt: DateTime.fromMillisecondsSinceEpoch(0),
        locallyVerifiable: false,
      );
      expect(
        timing.shouldShowPending(DateTime.fromMillisecondsSinceEpoch(159)),
        isFalse,
      );
      expect(
        timing.shouldShowPending(DateTime.fromMillisecondsSinceEpoch(160)),
        isTrue,
      );
    });
  });

  group('celebration milestones', () {
    test('fires on 3, 5, 10', () {
      expect(gameKitShouldTriggerCelebration(2), isFalse);
      expect(gameKitShouldTriggerCelebration(3), isTrue);
      expect(gameKitShouldTriggerCelebration(10), isTrue);
    });
  });

  group('GameKitVerdictSlot widget', () {
    testWidgets('pending and final share fixed height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GameKitVerdictSlot(
                  phase: GameKitFeedbackPhase.pending,
                  isCorrect: false,
                  correctLabel: 'Correct',
                  wrongLabel: 'Wrong',
                  pendingLabel: 'Checking',
                ),
                GameKitVerdictSlot(
                  phase: GameKitFeedbackPhase.finalVerdict,
                  isCorrect: true,
                  correctLabel: 'Correct',
                  wrongLabel: 'Wrong',
                  pendingLabel: 'Checking',
                ),
              ],
            ),
          ),
        ),
      );

      // Both phases render the exact same slot height: no layout shift.
      final slots = find.byType(GameKitVerdictSlot);
      expect(slots, findsNWidgets(2));
      for (final e in slots.evaluate()) {
        expect(
          tester.getSize(find.byWidget(e.widget)).height,
          GameKitFeedbackBudget.verdictSlotHeight,
        );
      }
      expect(tester.takeException(), isNull);
    });
  });
}
