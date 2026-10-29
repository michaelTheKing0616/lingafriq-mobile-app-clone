import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/screens/lesson/models/lesson_content.dart';
import 'package:lingafriq/screens/lesson/widgets/quiz_section_widget.dart';

/// Mirrors the wrapping pattern used in quiz_section_flow_test.dart.
Widget _wrap(
  Widget child, {
  bool reducedMotion = false,
  TextDirection textDirection = TextDirection.ltr,
}) {
  // MaterialApp resolves Directionality from its `locale`, not from any
  // ambient Directionality above it -- so RTL must be requested via locale,
  // and 'ar' must be declared as supported or it silently falls back to en.
  final locale = textDirection == TextDirection.rtl ? const Locale('ar') : null;
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// Widens the test surface so content that assumes a real phone viewport
/// (e.g. empty states, stat cards) doesn't spuriously overflow the default
/// 800x600 test window.
Future<void> _setPhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 1600));
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
}

LessonContent _singleQuestionContent() {
  return LessonContent(
    id: 1,
    sectionId: 1,
    title: 'Quiz',
    type: LessonSectionType.instantQuiz,
    score: 10,
    isCompleted: false,
    questions: [
      QuizQuestion(
        id: 1,
        question: 'What is this?',
        hint: 'Think carefully',
        funFact: 'A fun fact appears after checking.',
        options: [
          QuizOption(id: 1, text: 'Correct', isCorrect: true),
          QuizOption(id: 2, text: 'Wrong', isCorrect: false),
        ],
      ),
    ],
  );
}

void main() {
  group('QuizSectionWidget states', () {
    testWidgets(
      'renders an empty state with no placeholder-y copy when there are no questions',
      (tester) async {
        await _setPhoneSurface(tester);
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());
        final content = LessonContent(
          id: 1,
          sectionId: 1,
          title: 'Quiz',
          type: LessonSectionType.instantQuiz,
          score: 10,
          isCompleted: false,
        );

        await tester.pumpWidget(
          _wrap(
            QuizSectionWidget(
              content: content,
              onAnswerSelected: (_, __) {},
              onCheckAnswer: (_, __) async {},
              onFinish: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Uses the shared design-system empty state, not a bare Text widget.
        expect(find.text("This part isn't ready yet"), findsOneWidget);
        expect(find.text('No questions available'), findsNothing);
      },
    );

    testWidgets(
      'shows warm correct-answer feedback and accessible option semantics',
      (tester) async {
        await _setPhoneSurface(tester);
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _wrap(
            QuizSectionWidget(
              content: _singleQuestionContent(),
              onAnswerSelected: (_, __) {},
              onCheckAnswer: (_, __) async {},
              onFinish: () {},
              isAnswerCorrect: (questionId, option) => option == 'Correct',
            ),
          ),
        );

        // Every option must expose a screen-reader-friendly label.
        expect(
          find.bySemanticsLabel(RegExp(r'^Answer option A: Correct\.')),
          findsOneWidget,
        );

        await tester.tap(find.text('Correct'));
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pumpAndSettle();

        // The verdict sits in a green banner with the next action inside it.
        expect(
          find.byKey(const Key('lesson-feedback-correct')),
          findsOneWidget,
        );
        expect(find.text('Nice work!'), findsOneWidget);
        expect(find.text('Please select an answer'), findsNothing);

        handle.dispose();
      },
    );

    testWidgets(
      'shows feedback for an incorrect answer and reveals the hint/fun-fact cards',
      (tester) async {
        await _setPhoneSurface(tester);
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());
        await tester.pumpWidget(
          _wrap(
            QuizSectionWidget(
              content: _singleQuestionContent(),
              onAnswerSelected: (_, __) {},
              onCheckAnswer: (_, __) async {},
              onFinish: () {},
              isAnswerCorrect: (questionId, option) => option == 'Correct',
            ),
          ),
        );

        // Hint is visible before checking.
        expect(find.textContaining('Think carefully'), findsOneWidget);

        await tester.tap(find.text('Wrong'));
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('lesson-feedback-incorrect')),
          findsOneWidget,
        );
        expect(find.text('Correct answer: Correct'), findsOneWidget);
        // Fun fact only appears once the answer has been checked.
        expect(
          find.textContaining('A fun fact appears after checking.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'does not crash and skips the shake delay when reduced motion is requested',
      (tester) async {
        await _setPhoneSurface(tester);
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());
        await tester.pumpWidget(
          _wrap(
            QuizSectionWidget(
              content: _singleQuestionContent(),
              onAnswerSelected: (_, __) {},
              onCheckAnswer: (_, __) async {},
              onFinish: () {},
              isAnswerCorrect: (questionId, option) => option == 'Correct',
            ),
            reducedMotion: true,
          ),
        );

        await tester.tap(find.text('Wrong'));
        await tester.pump();
        await tester.tap(find.text('Check'));

        // With reduced motion the 500ms shake delay is skipped entirely, so a
        // single short pump (well under 500ms) is enough to settle.
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('lesson-feedback-incorrect')),
          findsOneWidget,
        );
      },
    );

    testWidgets('mirrors the Next/Previous icons for RTL directionality', (
      tester,
    ) async {
      await _setPhoneSurface(tester);
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
      final content = LessonContent(
        id: 1,
        sectionId: 1,
        title: 'Quiz',
        type: LessonSectionType.instantQuiz,
        score: 10,
        isCompleted: false,
        questions: [
          QuizQuestion(
            id: 1,
            question: 'Q1',
            options: [
              QuizOption(id: 1, text: 'Yes', isCorrect: true),
              QuizOption(id: 2, text: 'No', isCorrect: false),
            ],
          ),
          QuizQuestion(
            id: 2,
            question: 'Q2',
            options: [
              QuizOption(id: 3, text: 'A', isCorrect: true),
              QuizOption(id: 4, text: 'B', isCorrect: false),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          QuizSectionWidget(
            content: content,
            onAnswerSelected: (_, __) {},
            onCheckAnswer: (_, __) async {},
            onFinish: () {},
            isAnswerCorrect: (qid, option) =>
                qid == 1 ? option == 'Yes' : option == 'A',
          ),
          textDirection: TextDirection.rtl,
        ),
      );

      await tester.tap(find.text('Yes'));
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      // In RTL, "Next" should point back (arrow_back_rounded) since forward
      // reading direction is reversed.
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });
  });
}
