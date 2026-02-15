import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/widgets/learning_path/path_node_widget.dart';

void main() {
  late Lesson testLesson;

  setUpAll(() {
    testLesson = Lesson(
      id: 101,
      score: 0,
      count: 5,
      completed: 0,
      name: 'Greetings',
      congrats: 'Well done!',
      lessons_language: 1,
    );
  });

  Widget wrap(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  group('PathNodeWidget', () {
    testWidgets('paints locked state with lock icon', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeState.locked,
          index: 0,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('paints current state with number and play icon', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeState.current,
          index: 0,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled_rounded), findsOneWidget);
    });

    testWidgets('paints completed state with check icon', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeState.completed,
          index: 0,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('paints crowned state with check and premium icon', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeState.crowned,
          index: 0,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });

    testWidgets('tap on current node triggers onTap when provided', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeState.current,
          index: 0,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('1'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('tap on locked node does not trigger onTap', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeState.locked,
          index: 0,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PathNodeWidget));
      await tester.pumpAndSettle();

      expect(tapped, false);
    });

    testWidgets('displays correct index number for current state', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeState.current,
          index: 2,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3'), findsOneWidget);
    });
  });
}
