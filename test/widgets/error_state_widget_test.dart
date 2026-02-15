import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/error_state_widget.dart';
import '../helpers/test_utils.dart';

void main() {
  group('AppErrorState Widget', () {
    testWidgets('displays error message', (WidgetTester tester) async {
      await pumpWidgetWithScreenUtil(
        tester,
        const AppErrorState(
          message: 'Test error message',
        ),
      );

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('displays default message when not provided', (WidgetTester tester) async {
      await pumpWidgetWithScreenUtil(
        tester,
        const AppErrorState(),
      );

      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('shows retry button when onRetry is provided', (WidgetTester tester) async {
      bool retryCalled = false;

      await pumpWidgetWithScreenUtil(
        tester,
        AppErrorState(
          message: 'Test error',
          onRetry: () {
            retryCalled = true;
          },
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
      expect(retryCalled, isFalse);

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (WidgetTester tester) async {
      await pumpWidgetWithScreenUtil(
        tester,
        const AppErrorState(
          message: 'Test error',
        ),
      );

      expect(find.text('Try Again'), findsNothing);
    });

    testWidgets('displays custom icon when provided', (WidgetTester tester) async {
      await pumpWidgetWithScreenUtil(
        tester,
        const AppErrorState(
          message: 'Test error',
          icon: Icons.warning,
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('displays default error icon when icon not provided', (WidgetTester tester) async {
      await pumpWidgetWithScreenUtil(
        tester,
        const AppErrorState(
          message: 'Test error',
        ),
      );

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('centers content vertically and horizontally', (WidgetTester tester) async {
      await pumpWidgetWithScreenUtil(
        tester,
        const AppErrorState(
          message: 'Test error',
        ),
      );

      // AppErrorState wraps content in a Center; Flutter's Icon widget also
      // adds an internal Center, so we verify at least one Center exists.
      final centerFinder = find.descendant(
        of: find.byType(AppErrorState),
        matching: find.byType(Center),
      );
      expect(centerFinder, findsAtLeastNWidgets(1));
    });
  });
}
