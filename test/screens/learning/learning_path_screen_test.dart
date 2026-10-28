import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/learning_path_provider.dart';
import 'package:lingafriq/screens/learning/learning_path_screen.dart';
import 'package:lingafriq/widgets/learning_path/path_checkpoint_card.dart';
import 'package:lingafriq/widgets/learning_path/path_sticky_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final language = Language(
    id: 7,
    total_score: 0,
    total_count: 0,
    completed: 0,
    name: 'Yoruba',
    background: '',
    Inrtoduction: '',
    is_published: true,
    is_featured: false,
    level_language: 'A1',
  );

  Lesson lesson({
    required int id,
    required String name,
    required int count,
    required int completed,
  }) {
    return Lesson(
      id: id,
      score: 0,
      count: count,
      completed: completed,
      name: name,
      congrats: 'Well done!',
      lessons_language: 7,
    );
  }

  Widget harness({
    List<Lesson>? lessons,
    PathLessonSource source = PathLessonSource.network,
    bool reducedMotion = false,
    Object? throwError,
    Future<PathLessonsSnapshot>? pendingFuture,
    double textScale = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        pathLessonsProvider.overrideWith((ref, _) {
          if (pendingFuture != null) return pendingFuture;
          if (throwError != null) throw throwError;
          return Future.value(
            PathLessonsSnapshot(lessons: lessons ?? const [], source: source),
          );
        }),
        pathUnitsProvider.overrideWith((ref, _) async => const <PathUnitBannerData>[]),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reducedMotion,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: LearningPathScreen(language: language),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  void setPhoneSurface(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('LearningPathScreen states', () {
    testWidgets('loading state shows a friendly, non-technical message',
        (tester) async {
      setPhoneSurface(tester);
      final neverCompletes = Completer<PathLessonsSnapshot>();
      await tester.pumpWidget(harness(pendingFuture: neverCompletes.future));
      await settle(tester);

      expect(find.text('Loading your path…'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets(
        'empty path (brand-new learner) shows warm copy and a way forward',
        (tester) async {
      setPhoneSurface(tester);
      await tester.pumpWidget(harness(lessons: const []));
      await settle(tester);

      expect(find.textContaining("weaving your Yoruba path"), findsOneWidget);
      expect(find.text('Open lesson list'), findsOneWidget);
      expect(find.text('No data available'), findsNothing);
    });

    testWidgets(
        'offline (Drift-cached) snapshot shows Offline badge in sticky header',
        (tester) async {
      setPhoneSurface(tester);
      final lessons = [
        lesson(id: 1, name: 'Greetings', count: 5, completed: 0),
      ];
      await tester.pumpWidget(
        harness(lessons: lessons, source: PathLessonSource.drift),
      );
      await settle(tester);

      expect(find.byType(PathStickyHeader), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Yoruba'), findsWidgets);
    });

    testWidgets(
        'load error shows a retry affordance without leaking raw exception text',
        (tester) async {
      setPhoneSurface(tester);
      await tester.pumpWidget(
        harness(throwError: Exception('socket timeout 10.0.0.1:443')),
      );
      await settle(tester);

      expect(find.text('Try again'), findsOneWidget);
      expect(find.textContaining("couldn't load your path"), findsOneWidget);
      expect(find.textContaining('socket timeout'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets(
        'locked, current, and mastered nodes each announce distinct accessibility semantics',
        (tester) async {
      final handle = tester.ensureSemantics();
      setPhoneSurface(tester);
      final lessons = [
        lesson(id: 1, name: 'Greetings', count: 5, completed: 5),
        lesson(id: 2, name: 'Numbers', count: 5, completed: 0),
        lesson(id: 3, name: 'Colors', count: 5, completed: 0),
      ];
      await tester.pumpWidget(harness(lessons: lessons));
      await settle(tester);

      expect(
        find.bySemanticsLabel(RegExp(r'Greetings\. Completed\.$')),
        findsOneWidget,
        reason: 'mastered node should announce completion',
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Numbers\. Current lesson')),
        findsOneWidget,
        reason: 'the active node should announce it is the current lesson',
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Colors\. Locked')),
        findsOneWidget,
        reason: 'a node the learner has not reached yet should announce locked',
      );

      handle.dispose();
    });

    testWidgets('locked node cannot be tapped into a lesson', (tester) async {
      setPhoneSurface(tester);
      final lessons = [
        lesson(id: 1, name: 'Greetings', count: 5, completed: 0),
        lesson(id: 2, name: 'Numbers', count: 5, completed: 0),
      ];
      await tester.pumpWidget(harness(lessons: lessons));
      await settle(tester);

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.lock_rounded));
      await settle(tester);

      expect(find.text('Numbers'), findsNothing);
    });

    testWidgets('reduced motion renders the path statically without throwing',
        (tester) async {
      setPhoneSurface(tester);
      final lessons = [
        lesson(id: 1, name: 'Greetings', count: 5, completed: 0),
        lesson(id: 2, name: 'Numbers', count: 5, completed: 0),
      ];
      await tester.pumpWidget(harness(lessons: lessons, reducedMotion: true));
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.binding.hasScheduledFrame, isFalse);

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets(
        'sticky header with Offline does not overflow at 2.0x text scale',
        (tester) async {
      setPhoneSurface(tester);
      final lessons = [
        lesson(id: 1, name: 'Greetings', count: 5, completed: 5),
        lesson(id: 2, name: 'Numbers', count: 5, completed: 0),
      ];
      await tester.pumpWidget(
        harness(
          lessons: lessons,
          source: PathLessonSource.drift,
          textScale: 2.0,
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(PathStickyHeader), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('list-view toggle shows accessible lesson rows', (tester) async {
      setPhoneSurface(tester);
      final lessons = [
        lesson(id: 1, name: 'Greetings', count: 5, completed: 0),
        lesson(id: 2, name: 'Numbers', count: 5, completed: 0),
      ];
      await tester.pumpWidget(harness(lessons: lessons, reducedMotion: true));
      await settle(tester);

      expect(find.byTooltip('List view'), findsOneWidget);
      await tester.tap(find.byTooltip('List view'));
      await settle(tester);

      expect(find.text('Greetings'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
      expect(find.byTooltip('Path view'), findsOneWidget);
    });

    testWidgets('fifth lesson renders Busuu-style checkpoint card',
        (tester) async {
      setPhoneSurface(tester);
      final lessons = List.generate(
        5,
        (i) => lesson(
          id: i + 1,
          name: 'Lesson ${i + 1}',
          count: 5,
          completed: i == 0 ? 0 : 0,
        ),
      );
      // Unlock through lesson 5 as current path stretch.
      lessons[0] = lesson(id: 1, name: 'Lesson 1', count: 5, completed: 5);
      lessons[1] = lesson(id: 2, name: 'Lesson 2', count: 5, completed: 5);
      lessons[2] = lesson(id: 3, name: 'Lesson 3', count: 5, completed: 5);
      lessons[3] = lesson(id: 4, name: 'Lesson 4', count: 5, completed: 5);
      lessons[4] = lesson(id: 5, name: 'Lesson 5', count: 5, completed: 0);

      await tester.pumpWidget(harness(lessons: lessons, reducedMotion: true));
      await settle(tester);

      expect(find.byType(PathCheckpointCard), findsOneWidget);
      expect(find.textContaining('gate'), findsOneWidget);
      expect(find.textContaining('Lesson 5'), findsWidgets);
    });

    testWidgets('sticky unit banner shows Unit N · Title pattern',
        (tester) async {
      setPhoneSurface(tester);
      final lessons = [
        lesson(id: 1, name: 'Greetings', count: 5, completed: 0),
      ];
      await tester.pumpWidget(harness(lessons: lessons, reducedMotion: true));
      await settle(tester);

      expect(find.textContaining('Unit 1'), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsWidgets);
    });
  });
}
