import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/game_ui/completion_modal.dart';

void main() {
  group('CompletionModal', () {
    testWidgets('renders stats and action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionModal(
              title: 'Round Complete',
              score: 12,
              xp: 25,
              accuracy: 0.9,
              streakDelta: 2,
              onTryAgain: () {},
              onExit: () {},
            ),
          ),
        ),
      );

      expect(find.text('Round Complete'), findsOneWidget);
      expect(find.textContaining('Score: 12'), findsOneWidget);
      expect(find.textContaining('XP: +25'), findsOneWidget);
      expect(find.textContaining('Accuracy: 90%'), findsOneWidget);
      expect(find.textContaining('Streak: +2'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('shows next round action when callback is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionModal(
              title: 'Round Complete',
              score: 10,
              xp: 20,
              accuracy: 0.8,
              streakDelta: 1,
              onTryAgain: () {},
              onExit: () {},
              onNextRound: () {},
            ),
          ),
        ),
      );

      expect(find.text('Next Round'), findsOneWidget);
    });
  });
}
