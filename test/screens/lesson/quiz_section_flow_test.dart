import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/screens/lesson/models/lesson_content.dart';
import 'package:lingafriq/screens/lesson/widgets/quiz_section_widget.dart';

void main() {
  group('QuizSectionWidget multi-question', () {
    testWidgets('onFinish runs after last question only; two questions', (tester) async {
      var finishCalls = 0;
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
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 800,
                child: QuizSectionWidget(
                  content: content,
                  onAnswerSelected: (_, __) {},
                  onCheckAnswer: (_, __) async {},
                  onFinish: () => finishCalls++,
                  isAnswerCorrect: (qid, option) {
                    if (qid == 1) return option == 'Yes';
                    if (qid == 2) return option == 'A';
                    return false;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Q1: select correct, check, next
      await tester.tap(find.text('Yes'));
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Q2: select correct, check, finish
      // "A" exists twice (option label + option text). Tapping either is fine,
      // but `tap()` requires an unambiguous target.
      await tester.tap(find.text('A').first);
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish'));
      await tester.pump();

      expect(finishCalls, 1);
    });
  });
}
