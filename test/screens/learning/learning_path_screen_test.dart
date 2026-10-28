import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/learning_path_provider.dart';
import 'package:lingafriq/screens/learning/learning_path_screen.dart';

/// Widget tests for [LearningPathScreen] covering the states the strict UI
/// quality gate pass requires: locked/current/mastered nodes, a brand-new
/// learner's empty path, offline (Drift-cached) data, a load error, and a
/// reduced-motion render. Mirrors the provider-override pattern used by
/// `test/games/game_mastery_map_screen_test.dart`.
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

  /// Builds the screen inside a `ProviderScope` with `pathLessonsProvider`
  /// stubbed for one of three scenarios: resolved [lessons] data, a
  /// [pendingFuture] that never resolves (loading), or a [throwError]
  /// (error state). Exactly one of these should be supplied per test.
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

  // The "current" node runs a deliberately endless `..repeat(reverse: true)`
  // pulse `AnimationController` (see `PathNodeWidget`), and `ScreenUtilInit`
  // needs one extra frame after the first to swap in its real `builder`
  // output. Together that means a plain `pumpAndSettle()` either times out
  // (endless pulse) or fires too early (ScreenUtil bootstrap frame). A
  // bounded pump sequence sidesteps both without weakening the assertions.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  // `flutter_screenutil` reads the device size straight from
  // `View.maybeOf(context).physicalSize` / `.devicePixelRatio` (see
  // `ScreenUtilInit._newData()`), not from `tester.binding.setSurfaceSize`'s
  // `_surfaceSize` field. Using `setSurfaceSize` alone silently leaves the
  // test view at its default 800x600-logical size, so every `.w`/`.h`/`.sp`
  // value comes out ~2x too large against our 390x844 design size and
  // overflows the header `Row`. Setting `tester.view` directly (the API the
  // framework's own `setSurfaceSize` docs now recommend) is what actually
  // drives ScreenUtil's scale factor to 1.0 here.
  void setPhoneSurface(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('LearningPathScreen states', () {
    testWidgets('loading state shows a friendly, non-technical message', (tester) async {
      setPhoneSurface(tester);
      final neverCompletes = Completer<PathLessonsSnapshot>();
      await tester.pumpWidget(harness(pendingFuture: neverCompletes.future));
      await settle(tester);

      expect(find.text('Loading your path…'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets('empty path (brand-new learner) shows warm copy and a way forward',
        (tester) async {
      setPhoneSurface(tester);
      await tester.pumpWidget(harness(lessons: const []));
      await settle(tester);

      expect(find.textContaining("weaving your Yoruba path"), findsOneWidget);
      expect(find.text('Open lesson list'), findsOneWidget);
      // Warm, human copy — not a bare placeholder like "No data".
      expect(find.text('No data available'), findsNothing);
    });

    testWidgets('offline (Drift-cached) snapshot shows a dedicated Offline badge',
        (tester) async {
      setPhoneSurface(tester);
      final lessons = [
        lesson(id: 1, name: 'Greetings', count: 5, completed: 0),
      ];
      await tester.pumpWidget(
        harness(lessons: lessons, source: PathLessonSource.drift),
      );
      await settle(tester);

      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('load error shows a retry affordance without leaking raw exception text',
        (tester) async {
      setPhoneSurface(tester);
      await tester.pumpWidget(
        harness(throwError: Exception('socket timeout 10.0.0.1:443')),
      );
      await settle(tester);

      expect(find.text('Try again'), findsOneWidget);
      expect(find.textContaining("couldn't load your path"), findsOneWidget);
      // The raw exception string must never reach the learner.
      expect(find.textContaining('socket timeout'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets(
        'locked, current, and mastered nodes each announce distinct accessibility semantics',
        (tester) async {
      final handle = tester.ensureSemantics();
      setPhoneSurface(tester);
      final lessons = [
        lesson(id: 1, name: 'Greetings', count: 5, completed: 5), // mastered/done
        lesson(id: 2, name: 'Numbers', count: 5, completed: 0), // current
        lesson(id: 3, name: 'Colors', count: 5, completed: 0), // locked
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
        lesson(id: 1, name: 'Greetings', count: 5, completed: 0), // current
        lesson(id: 2, name: 'Numbers', count: 5, completed: 0), // locked
      ];
      await tester.pumpWidget(harness(lessons: lessons));
      await settle(tester);

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

      // Tapping the locked node must not open the lesson preview sheet
      // (which would render the lesson's name as its title).
      await tester.tap(find.byIcon(Icons.lock_rounded));
      await settle(tester);

      expect(find.text('Numbers'), findsNothing);
    });

    testWidgets('reduced motion renders the path statically without throwing',
        (tester) async {
      setPhoneSurface(tester);
      final lessons = [
        lesson(id: 1, name: 'Greetings', count: 5, completed: 0), // current
        lesson(id: 2, name: 'Numbers', count: 5, completed: 0), // locked
      ];
      await tester.pumpWidget(harness(lessons: lessons, reducedMotion: true));
      await settle(tester);
      // Pump a few more frames; if a pulse AnimationController had been
      // created despite reduced motion, `pumpAndSettle` would time out, so
      // we assert directly that no frame is scheduled instead.
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.binding.hasScheduledFrame, isFalse);

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets(
        'header (title, section count, Offline + percent badges) does not overflow at 2.0x text scale',
        (tester) async {
      setPhoneSurface(tester);
      final lessons = [
        lesson(id: 1, name: 'Greetings', count: 5, completed: 5),
        lesson(id: 2, name: 'Numbers', count: 5, completed: 0),
      ];
      await tester.pumpWidget(
        harness(
          lessons: lessons,
          source: PathLessonSource.drift, // also renders the Offline pill
          textScale: 2.0,
        ),
      );
      await settle(tester);

      // A RenderFlex overflow throws during layout/paint and would surface
      // here as a caught FlutterError; asserting no exception is the direct
      // regression check for `GriotBadgePill`'s unbounded width at large
      // text-scale factors (see `Flexible`/`FittedBox` wrapping in `_header`).
      expect(tester.takeException(), isNull);
      expect(find.text('Learning Path'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });
  });
}
