import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/curriculum_model.dart';
import 'package:lingafriq/screens/lesson/lesson_flow_stages.dart';

void main() {
  test('buildLessonMcqs prefers unit_quiz items', () {
    final lesson = CurriculumLesson(
      id: 'test-l1',
      title: 'Greetings',
      vocab: const [],
      exercises: const [],
    );
    final unitQuiz = [
      CurriculumMcqItem(
        id: 'q1',
        question: 'Pick greeting',
        options: ['A', 'B', 'Mo ń kọ́'],
        answer: 'Mo ń kọ́',
      ),
    ];
    final mcqs = buildLessonMcqs(lesson, unitQuiz: unitQuiz);
    expect(mcqs.length, 1);
    expect(mcqs.first.prompt, 'Pick greeting');
    expect(mcqs.first.correct, 'Mo ń kọ́');
  });

  test('buildLessonMcqs parses flashcard lines', () {
    final lesson = CurriculumLesson(
      id: 'test-l1',
      title: 'Greetings',
      durationMin: 10,
      vocab: [
        CurriculumVocab(word: 'Bawo', meaning: 'Hello'),
        CurriculumVocab(word: 'E kaaro', meaning: 'Good morning'),
      ],
      exercises: [
        CurriculumExercise(
          type: 'flashcards',
          items: ['Bawo — Hello', 'E kaaro — Good morning'],
        ),
      ],
    );
    final mcqs = buildLessonMcqs(lesson);
    expect(mcqs.length, greaterThanOrEqualTo(1));
    expect(mcqs.first.correct, 'Hello');
    expect(mcqs.first.options, contains('Hello'));
  });
}
