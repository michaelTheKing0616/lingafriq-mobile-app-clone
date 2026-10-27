import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_feedback.dart';

void main() {
  testWidgets('gamekit_feedback_playing golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 200));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameKitVerdictSlot(
            phase: GameKitFeedbackPhase.idle,
            isCorrect: false,
            correctLabel: 'Nice one!',
            wrongLabel: 'Not quite',
            pendingLabel: 'Checking…',
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/gamekit_feedback_playing.png'),
    );
  });

  testWidgets('gamekit_feedback_why_wrong golden (pending)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 200));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameKitVerdictSlot(
            phase: GameKitFeedbackPhase.pending,
            isCorrect: false,
            correctLabel: 'Nice one!',
            wrongLabel: 'Not quite',
            pendingLabel: 'Checking your answer…',
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/gamekit_feedback_why_wrong.png'),
    );
  });

  testWidgets('gamekit_feedback_results golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 200));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameKitVerdictSlot(
            phase: GameKitFeedbackPhase.finalVerdict,
            isCorrect: true,
            correctLabel: 'Nice one!',
            wrongLabel: 'Not quite',
            pendingLabel: 'Checking…',
            detailMessage: 'Excellent! Perfect score!',
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/gamekit_feedback_results.png'),
    );
  });
}
