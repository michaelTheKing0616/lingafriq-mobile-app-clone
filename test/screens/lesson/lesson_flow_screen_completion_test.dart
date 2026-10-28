import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/models/section_lesson_model.dart';
import 'package:lingafriq/screens/lesson/lesson_flow_screen.dart';
import 'package:lingafriq/screens/lesson/lesson_provider.dart';
import 'package:lingafriq/screens/lesson/models/lesson_content.dart';
import 'package:lingafriq/services/sound_effects_service.dart';
import 'package:lingafriq/widgets/gamification/combo_tracker.dart';

/// Behaves exactly like the real [LessonFlowNotifier] -- including real
/// `setWordQuizAnswer()` logic -- except:
///   1. `initialize()` loads pre-built [LessonContent] fixtures directly,
///      bypassing the raw-otherData parsing format (already covered by
///      lesson_content_test.dart) so this test stays focused on the
///      screen's completion-gating behavior.
///   2. `completeSection()` always reports failure, simulating a transient
///      network error when a learner finishes a section.
///   3. `checkQuizAnswer()`/`checkWordQuizCompletion()` reproduce only the
///      real correctness-checking logic, skipping the real
///      `soundEffects.playCorrect()` call -- that awaits the `audioplayers`
///      plugin's method channel, which has no mock handler under
///      flutter_test and never resolves, hanging anything that awaits it.
class _FailingLessonFlowNotifier extends LessonFlowNotifier {
  _FailingLessonFlowNotifier(Ref ref, int lessonId, this._fixtureSections)
      : super(ref, lessonId, ComboTracker(), ref.read(soundEffectsProvider));

  final List<LessonContent> _fixtureSections;
  int completeSectionCallCount = 0;

  @override
  Future<void> initialize(List<SectionLessonModel> sectionLessons) async {
    state = state.copyWith(sections: _fixtureSections, isLoading: false);
  }

  @override
  Future<bool> completeSection(int sectionId) async {
    completeSectionCallCount++;
    return false;
  }

  @override
  Future<bool> checkQuizAnswer(
    int sectionId,
    int questionId,
    String selectedAnswer,
  ) async {
    final section = state.sections.firstWhere((s) => s.sectionId == sectionId);
    final question = section.questions?.firstWhere((q) => q.id == questionId);
    if (question == null) return false;
    final correctOption = question.options.firstWhere((o) => o.isCorrect);
    return correctOption.text == selectedAnswer;
  }

  @override
  Future<bool> checkWordQuizCompletion(int sectionId) async {
    final section = state.sections.firstWhere((s) => s.sectionId == sectionId);
    final answers = state.wordQuizAnswers[sectionId] ?? [];
    final questions = section.wordQuestions ?? [];
    if (answers.length != questions.length) return false;
    if (answers.any((a) => a == null || a.isEmpty)) return false;
    for (int i = 0; i < questions.length; i++) {
      final parts = questions[i].question.split('/');
      final expected = parts.length > 1
          ? parts.last.trim().toLowerCase()
          : questions[i].question.trim().toLowerCase();
      final actual = answers[i]?.trim().toLowerCase() ?? '';
      if (actual != expected) return false;
    }
    return true;
  }
}

Widget _wrapWithFailingCompletion({
  required int lessonId,
  required List<LessonContent> fixtureSections,
}) {
  // sectionLessons is only consumed by the real initialize(), which we
  // override above, so an empty list is fine here.
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(
      overrides: [
        lessonFlowProvider(lessonId).overrideWith(
          (ref) => _FailingLessonFlowNotifier(ref, lessonId, fixtureSections),
        ),
      ],
      child: MaterialApp(
        home: LessonFlowScreen(
          lessonId: lessonId,
          sectionLessons: const [],
          lessonTitle: 'Test Lesson',
        ),
      ),
    ),
  );
}

_FailingLessonFlowNotifier _notifierFor(WidgetTester tester, int lessonId) {
  final element = tester.element(find.byType(LessonFlowScreen));
  final container = ProviderScope.containerOf(element);
  return container.read(lessonFlowProvider(lessonId).notifier)
      as _FailingLessonFlowNotifier;
}

void main() {
  group('LessonFlowScreen completion-failure handling', () {
    testWidgets(
      'quiz: does not advance to lesson-complete and offers a retry when completeSection fails',
      (tester) async {
        final section = LessonContent(
          id: 1,
          sectionId: 1,
          title: 'Quiz Section',
          type: LessonSectionType.instantQuiz,
          score: 10,
          isCompleted: false,
          questions: [
            QuizQuestion(
              id: 1,
              question: 'What is this?',
              options: [
                QuizOption(id: 1, text: 'Option A', isCorrect: true),
                QuizOption(id: 2, text: 'Option B', isCorrect: false),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          _wrapWithFailingCompletion(lessonId: 1, fixtureSections: [section]),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Option A'));
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pump(); // show the correct-answer feedback SnackBar

        // Dismiss that first SnackBar deterministically instead of racing
        // its 3-second auto-dismiss timer -- otherwise it can still be
        // mid-exit-animation when we try to show the retry SnackBar next,
        // which would queue (and delay) it behind the first one.
        ScaffoldMessenger.of(
          tester.element(find.byType(LessonFlowScreen)),
        ).clearSnackBars();
        await tester.pump(const Duration(milliseconds: 300));

        // Single-question quiz: the Check button becomes "Finish".
        // NOTE: deliberately avoid pumpAndSettle() past this point -- the
        // retry SnackBar has a finite but non-trivial auto-dismiss timer,
        // and pumpAndSettle() fast-forwards through it, making the
        // SnackBar vanish before we can assert on it.
        await tester.tap(find.text('Finish'));
        await tester.pump(); // flush completeAndAdvance()'s awaited call
        await tester.pump(const Duration(milliseconds: 300)); // SnackBar entrance

        // completeSection failed -- the learner must NOT be silently
        // advanced to the lesson-complete screen.
        expect(_notifierFor(tester, 1).completeSectionCallCount, 1);
        expect(find.byType(LessonFlowScreen), findsOneWidget);
        expect(find.textContaining('Lesson Complete'), findsNothing);

        // A retry affordance must be surfaced instead of a silent failure.
        expect(find.text('Retry'), findsOneWidget);

        // Tapping Retry re-attempts completion (deterministically fails
        // again here), rather than being a dead end.
        await tester.tap(find.text('Retry'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(_notifierFor(tester, 1).completeSectionCallCount, 2);
        expect(find.textContaining('Lesson Complete'), findsNothing);
      },
    );

    testWidgets(
      'word quiz: does not advance to lesson-complete and offers a retry when completeSection fails',
      (tester) async {
        final section = LessonContent(
          id: 1,
          sectionId: 1,
          title: 'Word Quiz Section',
          type: LessonSectionType.wordQuiz,
          score: 10,
          isCompleted: false,
          wordQuestions: [
            // "word/answer" format; _initializeChoices() needs the slash to
            // populate the tappable word bank with "Hello".
            WordQuizQuestion(id: 0, question: 'Hello/Hello', content: 'Say ___.'),
          ],
        );

        await tester.pumpWidget(
          _wrapWithFailingCompletion(lessonId: 1, fixtureSections: [section]),
        );
        await tester.pumpAndSettle();

        // Fill in the single blank with the only word-bank choice, then check.
        // See the quiz test above for why pumpAndSettle() is avoided here.
        await tester.tap(find.text('Hello').first);
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(_notifierFor(tester, 1).completeSectionCallCount, 1);
        expect(find.byType(LessonFlowScreen), findsOneWidget);
        expect(find.textContaining('Lesson Complete'), findsNothing);
        expect(find.text('Retry'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(_notifierFor(tester, 1).completeSectionCallCount, 2);
        expect(find.textContaining('Lesson Complete'), findsNothing);
      },
    );
  });
}
