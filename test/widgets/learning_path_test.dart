import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/widgets/learning_path/path_node_state.dart';
import 'package:lingafriq/widgets/learning_path/path_node_widget.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';

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

  void setPhoneSurface(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('PathNodeWidget', () {
    testWidgets('paints locked state with lock icon', (WidgetTester tester) async {
      setPhoneSurface(tester);
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeVisualState.locked,
          index: 0,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('paints current state with number, play icon, and Start bubble',
        (WidgetTester tester) async {
      setPhoneSurface(tester);
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeVisualState.current,
          index: 0,
          playNowFallback: 'Start',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.text('START'), findsOneWidget);
    });

    testWidgets('paints done state with check icon', (WidgetTester tester) async {
      setPhoneSurface(tester);
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeVisualState.done,
          index: 0,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('checkpoint done paints trophy chrome', (WidgetTester tester) async {
      setPhoneSurface(tester);
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeVisualState.done,
          index: 4,
          isCheckpoint: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });

    testWidgets('offline tick appears when savedOffline', (WidgetTester tester) async {
      setPhoneSurface(tester);
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeVisualState.current,
          index: 0,
          savedOffline: true,
          reducedMotion: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('tap on current node triggers onTap when provided',
        (WidgetTester tester) async {
      setPhoneSurface(tester);
      var tapped = false;
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeVisualState.current,
          index: 0,
          reducedMotion: true,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('tap on locked node does not trigger onTap',
        (WidgetTester tester) async {
      setPhoneSurface(tester);
      var tapped = false;
      await tester.pumpWidget(wrap(
        PathNodeWidget(
          lesson: testLesson,
          state: PathNodeVisualState.locked,
          index: 0,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PathNodeWidget));
      await tester.pumpAndSettle();

      expect(tapped, false);
    });

    testWidgets('sine checkpoint helper marks every 5th lesson', (_) async {
      expect(PathLayout.isCheckpoint(4), isTrue);
      expect(PathLayout.isCheckpoint(0), isFalse);
      expect(PathLayout.horizontalOffsetForIndex(2), 72);
    });
  });
}
