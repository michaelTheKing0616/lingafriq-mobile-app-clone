import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/screens/lesson/models/lesson_content.dart';
import 'package:lingafriq/screens/lesson/widgets/lesson_progress_bar.dart';

Widget _wrap(Widget child, {bool reducedMotion = false, double width = 320}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

List<LessonContent> _sections(int count, {int completedCount = 0}) {
  return List.generate(
    count,
    (i) => LessonContent(
      id: i,
      sectionId: i,
      title: 'Section $i',
      type: LessonSectionType.tutorial,
      score: 10,
      isCompleted: i < completedCount,
    ),
  );
}

void main() {
  group('LessonProgressBar', () {
    testWidgets('exposes an accessible progress label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(LessonProgressBar(sections: _sections(4, completedCount: 1), currentIndex: 1)),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp(r'Section 2 of 4\. 50 percent complete\.')),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('never overflows, even with a large section count on a narrow phone', (
      tester,
    ) async {
      // Regression guard: the old dot-row implementation could overflow
      // horizontally once a lesson had enough sections. Expanded segments
      // must always fit regardless of count or screen width.
      await tester.pumpWidget(
        _wrap(
          LessonProgressBar(sections: _sections(30, completedCount: 10), currentIndex: 10),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('uses an instant (zero-duration) transition when reduced motion is on', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LessonProgressBar(sections: _sections(3), currentIndex: 0),
          reducedMotion: true,
        ),
      );
      await tester.pumpAndSettle();

      final containers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(containers, isNotEmpty);
      for (final c in containers) {
        expect(c.duration, Duration.zero);
      }
    });

    testWidgets('uses an animated transition when reduced motion is off', (tester) async {
      await tester.pumpWidget(
        _wrap(LessonProgressBar(sections: _sections(3), currentIndex: 0)),
      );
      await tester.pumpAndSettle();

      final containers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(containers, isNotEmpty);
      for (final c in containers) {
        expect(c.duration, const Duration(milliseconds: 300));
      }
    });
  });
}
