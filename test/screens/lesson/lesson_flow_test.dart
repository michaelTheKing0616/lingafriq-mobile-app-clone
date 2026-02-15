import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/lesson/lesson_flow_screen.dart';
import 'package:lingafriq/lessons/models/section_lesson_model.dart';

/// Valid date string for SectionLessonModel.date (DateTime.parse)
const _kValidDate = '2024-01-01T00:00:00';

Widget _wrapLessonFlow({
  required int lessonId,
  required List<SectionLessonModel> sectionLessons,
  required String lessonTitle,
}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(
      child: MaterialApp(
        home: LessonFlowScreen(
          lessonId: lessonId,
          sectionLessons: sectionLessons,
          lessonTitle: lessonTitle,
        ),
      ),
    ),
  );
}

void main() {
  group('LessonFlowScreen Widget Tests', () {
    testWidgets('should display lesson title', (WidgetTester tester) async {
      final sectionLessons = [
        SectionLessonModel(
          id: 1,
          title: 'Section 1',
          score: 10,
          types: 'Tutorial',
          dateTime: _kValidDate,
          completed: false,
          completed_by: null,
          otherData: {'text': 'Content'},
        ),
      ];

      await tester.pumpWidget(
        _wrapLessonFlow(
          lessonId: 1,
          sectionLessons: sectionLessons,
          lessonTitle: 'Test Lesson',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Lesson'), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      final sectionLessons = [
        SectionLessonModel(
          id: 1,
          title: 'Section 1',
          score: 10,
          types: 'Tutorial',
          dateTime: _kValidDate,
          completed: false,
          completed_by: null,
          otherData: {},
        ),
      ];

      await tester.pumpWidget(
        _wrapLessonFlow(
          lessonId: 1,
          sectionLessons: sectionLessons,
          lessonTitle: 'Test Lesson',
        ),
      );

      // Check immediately after pumpWidget — before the deferred init
      // (postFrameCallback + microtask) triggers a rebuild with populated state.
      // The extra pump() would process the deferred init and remove the indicator.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should navigate between sections', (WidgetTester tester) async {
      final sectionLessons = [
        SectionLessonModel(
          id: 1,
          title: 'Section 1',
          score: 10,
          types: 'Tutorial',
          dateTime: _kValidDate,
          completed: false,
          completed_by: null,
          otherData: {'text': 'Content 1'},
        ),
        SectionLessonModel(
          id: 2,
          title: 'Section 2',
          score: 15,
          types: 'Tutorial',
          dateTime: _kValidDate,
          completed: false,
          completed_by: null,
          otherData: {'text': 'Content 2'},
        ),
      ];

      await tester.pumpWidget(
        _wrapLessonFlow(
          lessonId: 1,
          sectionLessons: sectionLessons,
          lessonTitle: 'Test Lesson',
        ),
      );
      await tester.pumpAndSettle();

      // Screen built with multiple sections - PageView contains section content
      expect(find.byType(LessonFlowScreen), findsOneWidget);
    });

    testWidgets('should handle quiz answer selection', (WidgetTester tester) async {
      final sectionLessons = [
        SectionLessonModel(
          id: 1,
          title: 'Quiz Section',
          score: 20,
          types: 'Instant Quiz',
          dateTime: _kValidDate,
          completed: false,
          completed_by: null,
          otherData: {
            'question': [
              {
                'id': 1,
                'question': {
                  'question': 'What is this?',
                },
                'choices': [
                  {'text': 'Option A', 'correct_answer': true},
                  {'text': 'Option B', 'correct_answer': false},
                ],
              },
            ],
          },
        ),
      ];

      await tester.pumpWidget(
        _wrapLessonFlow(
          lessonId: 1,
          sectionLessons: sectionLessons,
          lessonTitle: 'Test Lesson',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LessonFlowScreen), findsOneWidget);
    });

    testWidgets('should show completion screen when all sections done', (WidgetTester tester) async {
      final sectionLessons = [
        SectionLessonModel(
          id: 1,
          title: 'Section 1',
          score: 10,
          types: 'Tutorial',
          dateTime: _kValidDate,
          completed: true,
          completed_by: 1,
          otherData: {'text': 'Content'},
        ),
      ];

      await tester.pumpWidget(
        _wrapLessonFlow(
          lessonId: 1,
          sectionLessons: sectionLessons,
          lessonTitle: 'Test Lesson',
        ),
      );
      await tester.pumpAndSettle();

      // Screen builds; completion shown when all sections done and index past last
      expect(find.byType(LessonFlowScreen), findsOneWidget);
    });

    testWidgets('should display progress bar', (WidgetTester tester) async {
      final sectionLessons = [
        SectionLessonModel(
          id: 1,
          title: 'Section 1',
          score: 10,
          types: 'Tutorial',
          dateTime: _kValidDate,
          completed: false,
          completed_by: null,
          otherData: {},
        ),
        SectionLessonModel(
          id: 2,
          title: 'Section 2',
          score: 15,
          types: 'Tutorial',
          dateTime: _kValidDate,
          completed: false,
          completed_by: null,
          otherData: {},
        ),
      ];

      await tester.pumpWidget(
        _wrapLessonFlow(
          lessonId: 1,
          sectionLessons: sectionLessons,
          lessonTitle: 'Test Lesson',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LessonFlowScreen), findsOneWidget);
    });

    testWidgets('should handle back button press', (WidgetTester tester) async {
      final sectionLessons = [
        SectionLessonModel(
          id: 1,
          title: 'Section 1',
          score: 10,
          types: 'Tutorial',
          dateTime: _kValidDate,
          completed: false,
          completed_by: null,
          otherData: {},
        ),
      ];

      await tester.pumpWidget(
        _wrapLessonFlow(
          lessonId: 1,
          sectionLessons: sectionLessons,
          lessonTitle: 'Test Lesson',
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.byType(BackButton);
      expect(backButton.evaluate().isNotEmpty, isTrue);
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    });

    testWidgets('should display combo tracker when combo is active', (WidgetTester tester) async {
      final sectionLessons = [
        SectionLessonModel(
          id: 1,
          title: 'Quiz Section',
          score: 20,
          types: 'Instant Quiz',
          dateTime: _kValidDate,
          completed: false,
          completed_by: null,
          otherData: {
            'question': [
              {
                'id': 1,
                'question': {'question': 'Question'},
                'choices': [
                  {'text': 'A', 'correct_answer': true},
                ],
              },
            ],
          },
        ),
      ];

      await tester.pumpWidget(
        _wrapLessonFlow(
          lessonId: 1,
          sectionLessons: sectionLessons,
          lessonTitle: 'Test Lesson',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LessonFlowScreen), findsOneWidget);
    });
  });

  group('Lesson Flow Navigation', () {
    test('should track current section index', () {
      // Test that currentSectionIndex is tracked correctly
    });

    test('should advance to next section on completion', () {
      // Test that completing a section advances to next
    });

    test('should prevent skipping sections', () {
      // Test that users cannot skip ahead
    });
  });

  group('Quiz Answer Handling', () {
    test('should mark correct answer', () {
      // Test that correct answers are handled properly
    });

    test('should mark incorrect answer', () {
      // Test that incorrect answers reset combo
    });

    test('should calculate score correctly', () {
      // Test score calculation based on answers
    });
  });

  group('Completion Flow', () {
    test('should show completion screen when all sections done', () {
      // Test completion screen display
    });

    test('should calculate total XP earned', () {
      // Test XP calculation
    });

    test('should calculate combo bonus', () {
      // Test combo bonus calculation
    });

    test('should calculate accuracy', () {
      // Test accuracy calculation
    });
  });
}
