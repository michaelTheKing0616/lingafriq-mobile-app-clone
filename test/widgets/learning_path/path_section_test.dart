import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/providers/learning_path_provider.dart';
import 'package:lingafriq/widgets/learning_path/lesson_preview_sheet.dart';
import 'package:lingafriq/widgets/learning_path/path_section_banner.dart';

void main() {
  group('buildPathScrollItems', () {
    test('inserts banner at each unit boundary', () {
      final lessons = List.generate(
        4,
        (i) => Lesson(
          id: i,
          score: 0,
          count: 3,
          completed: 0,
          name: 'Section $i',
          congrats: '',
          lessons_language: 1,
        ),
      );
      const units = [
        PathUnitBannerData(
          unitKey: 'yoruba-A1-u1',
          unitName: 'Unit 1',
          cefrLevel: 'A1',
          canDoStatement: 'I can greet.',
          firstLessonIndex: 0,
        ),
        PathUnitBannerData(
          unitKey: 'yoruba-A1-u2',
          unitName: 'Unit 2',
          cefrLevel: 'A1',
          canDoStatement: 'I can introduce myself.',
          firstLessonIndex: 2,
        ),
      ];
      final items = buildPathScrollItems(lessons: lessons, units: units);
      expect(items.whereType<PathScrollBannerItem>().length, 2);
      expect(items.whereType<PathScrollNodeItem>().length, 4);
    });
  });

  group('path scroll helpers', () {
    test('maps lesson index to scroll index', () {
      final lessons = [
        Lesson(
          id: 1,
          score: 0,
          count: 1,
          completed: 0,
          name: 'A',
          congrats: '',
          lessons_language: 1,
        ),
        Lesson(
          id: 2,
          score: 0,
          count: 1,
          completed: 0,
          name: 'B',
          congrats: '',
          lessons_language: 1,
        ),
      ];
      const units = [
        PathUnitBannerData(
          unitKey: 'u1',
          unitName: 'Unit 1',
          cefrLevel: 'A1',
          canDoStatement: 'Can do',
          firstLessonIndex: 0,
        ),
      ];
      final items = buildPathScrollItems(lessons: lessons, units: units);
      expect(pathScrollIndexForLesson(items, 1), 2);
    });
  });

  group('PathSectionBanner', () {
    testWidgets('shows unit name, CEFR, and can-do', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: Scaffold(
              body: PathSectionBanner(
                unitName: 'Unit 3',
                cefrLevel: 'A1',
                canDoStatement: 'I can ask prices.',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Unit 3'), findsOneWidget);
      expect(find.text('A1'), findsOneWidget);
      expect(find.text('I can ask prices.'), findsOneWidget);
    });
  });

  group('lesson preview helpers', () {
    test('estimates minutes and XP from activity count', () {
      final lesson = Lesson(
        id: 1,
        score: 0,
        count: 4,
        completed: 0,
        name: 'Market',
        congrats: 'Practice bargaining',
        lessons_language: 1,
      );
      expect(estimatePathLessonMinutes(lesson), 12);
      expect(estimatePathLessonXp(lesson), 40);
      expect(pathLessonGoal(lesson), 'Practice bargaining');
    });
  });

  group('PathFrameBudgetSampler', () {
    test('flags median above 16.7 ms', () {
      final sampler = PathFrameBudgetSampler();
      sampler.reset();
      for (var i = 0; i < 5; i++) {
        sampler.recordFrameMs(20);
      }
      expect(sampler.exceedsBudget(), isTrue);
    });
  });
}
