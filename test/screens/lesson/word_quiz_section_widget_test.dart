import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/screens/lesson/models/lesson_content.dart';
import 'package:lingafriq/screens/lesson/widgets/word_quiz_section_widget.dart';

Widget _wrap(Widget child, {bool reducedMotion = false}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
  );
}

Future<void> _setPhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 1600));
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
}

LessonContent _blankContent() {
  return LessonContent(
    id: 1,
    sectionId: 1,
    title: 'Word Quiz',
    type: LessonSectionType.wordQuiz,
    score: 10,
    isCompleted: false,
    wordQuestions: [
      WordQuizQuestion(id: 0, question: 'hello/bonjour', content: 'Hello'),
    ],
  );
}

void main() {
  group('WordQuizSectionWidget states', () {
    testWidgets('renders a warm empty state (not a bare placeholder) with no questions', (
      tester,
    ) async {
      await _setPhoneSurface(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      final content = LessonContent(
        id: 1,
        sectionId: 1,
        title: 'Word Quiz',
        type: LessonSectionType.wordQuiz,
        score: 10,
        isCompleted: false,
      );

      await tester.pumpWidget(
        _wrap(
          WordQuizSectionWidget(
            content: content,
            onAnswerChanged: (_, __) {},
            onCheck: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing to fill in yet'), findsOneWidget);
      expect(find.text('No word quiz questions available'), findsNothing);
    });

    testWidgets('exposes accessible semantics on the fill-in-the-blank target', (tester) async {
      await _setPhoneSurface(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _wrap(
          WordQuizSectionWidget(
            content: _blankContent(),
            onAnswerChanged: (_, __) {},
            onCheck: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp(r'^Empty blank 1\.')),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('shows warm copy (not robotic copy) when blanks are left empty', (tester) async {
      await _setPhoneSurface(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        _wrap(
          WordQuizSectionWidget(
            content: _blankContent(),
            onAnswerChanged: (_, __) {},
            onCheck: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill the only blank, then tap it again to clear it -- this leaves
      // the blank explicitly unanswered (the "all filled" guard only trips
      // once a blank has been touched and cleared).
      await tester.tap(find.text('bonjour'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('bonjour'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Please fill in all blanks'), findsNothing);
    });

    testWidgets('filling the blank correctly and checking does not crash with reduced motion', (
      tester,
    ) async {
      await _setPhoneSurface(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      var checked = false;
      await tester.pumpWidget(
        _wrap(
          WordQuizSectionWidget(
            content: _blankContent(),
            onAnswerChanged: (_, __) {},
            onCheck: () => checked = true,
          ),
          reducedMotion: true,
        ),
      );
      await tester.pumpAndSettle();

      // Tap the word-bank choice to fill the only blank.
      await tester.tap(find.text('bonjour'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(checked, isTrue);
    });
  });
}
