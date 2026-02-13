import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/lesson/models/lesson_content.dart';

void main() {
  group('LessonSectionType', () {
    test('should parse from string correctly', () {
      expect(LessonSectionType.fromString('Tutorial'), LessonSectionType.tutorial);
      expect(LessonSectionType.fromString('Instant Quiz'), LessonSectionType.instantQuiz);
      expect(LessonSectionType.fromString('Word Quiz'), LessonSectionType.wordQuiz);
      expect(LessonSectionType.fromString('Long Quiz'), LessonSectionType.longQuiz);
      expect(LessonSectionType.fromString('tutorial'), LessonSectionType.tutorial);
      expect(LessonSectionType.fromString('INSTANT QUIZ'), LessonSectionType.instantQuiz);
    });

    test('should default to tutorial for null or unknown types', () {
      expect(LessonSectionType.fromString(null), LessonSectionType.tutorial);
      expect(LessonSectionType.fromString(''), LessonSectionType.tutorial);
      expect(LessonSectionType.fromString('Unknown Type'), LessonSectionType.tutorial);
    });

    test('should convert to backend string format', () {
      expect(LessonSectionType.tutorial.toBackendString(), 'Tutorial');
      expect(LessonSectionType.instantQuiz.toBackendString(), 'Instant Quiz');
      expect(LessonSectionType.wordQuiz.toBackendString(), 'Word Quiz');
      expect(LessonSectionType.longQuiz.toBackendString(), 'Long Quiz');
    });

    test('should identify quiz types correctly', () {
      expect(LessonSectionType.tutorial.isQuiz, false);
      expect(LessonSectionType.instantQuiz.isQuiz, true);
      expect(LessonSectionType.longQuiz.isQuiz, true);
      expect(LessonSectionType.wordQuiz.isQuiz, false);
    });

    test('should identify word quiz correctly', () {
      expect(LessonSectionType.wordQuiz.isWordQuiz, true);
      expect(LessonSectionType.tutorial.isWordQuiz, false);
      expect(LessonSectionType.instantQuiz.isWordQuiz, false);
    });
  });

  group('LessonContent.fromSectionLesson', () {
    test('should parse tutorial section correctly', () {
      final content = LessonContent.fromSectionLesson(
        id: 1,
        sectionId: 101,
        title: 'Test Tutorial',
        types: 'Tutorial',
        score: 10,
        isCompleted: false,
        otherData: {
          'text': 'Tutorial content',
          'audio': 'https://example.com/audio.mp3',
          'video': 'https://example.com/video.mp4',
          'image': 'https://example.com/image.jpg',
        },
      );

      expect(content.id, 1);
      expect(content.sectionId, 101);
      expect(content.title, 'Test Tutorial');
      expect(content.type, LessonSectionType.tutorial);
      expect(content.score, 10);
      expect(content.isCompleted, false);
      expect(content.text, 'Tutorial content');
      expect(content.audioUrl, 'https://example.com/audio.mp3');
      expect(content.videoUrl, 'https://example.com/video.mp4');
      expect(content.imageUrl, 'https://example.com/image.jpg');
      expect(content.questions, isNull);
      expect(content.wordQuestions, isNull);
    });

    test('should parse instant quiz section correctly', () {
      final content = LessonContent.fromSectionLesson(
        id: 2,
        sectionId: 102,
        title: 'Test Quiz',
        types: 'Instant Quiz',
        score: 20,
        isCompleted: false,
        otherData: {
          'quiz_type': 'multiple_choice',
          'question': [
            {
              'id': 1,
              'question': {
                'question': 'What is this?',
                'text': 'Question text',
                'hint': 'Think carefully',
                'fun_fact': 'Interesting fact',
                'image': 'https://example.com/q1.jpg',
                'audio': 'https://example.com/q1.mp3',
              },
              'choices': [
                {'text': 'Option A', 'correct_answer': true},
                {'text': 'Option B', 'correct_answer': false},
                {'text': 'Option C', 'correct_answer': false},
              ],
            },
          ],
        },
      );

      expect(content.type, LessonSectionType.instantQuiz);
      expect(content.questions, isNotNull);
      expect(content.questions!.length, 1);
      expect(content.questions![0].question, 'What is this?');
      expect(content.questions![0].options.length, 3);
      expect(content.questions![0].options[0].isCorrect, true);
      expect(content.questions![0].options[1].isCorrect, false);
    });

    test('should parse word quiz section correctly', () {
      final content = LessonContent.fromSectionLesson(
        id: 3,
        sectionId: 103,
        title: 'Word Quiz',
        types: 'Word Quiz',
        score: 15,
        isCompleted: false,
        otherData: {
          'word_question': [
            [
              {
                'text': 'Hello [world/monde]',
              },
            ],
          ],
        },
      );

      expect(content.type, LessonSectionType.wordQuiz);
      expect(content.wordQuestions, isNotNull);
      expect(content.wordQuestions!.length, greaterThan(0));
    });

    test('should handle missing fields gracefully', () {
      final content = LessonContent.fromSectionLesson(
        id: 4,
        sectionId: 104,
        title: 'Minimal Section',
        types: 'Tutorial',
        score: 5,
        isCompleted: false,
        otherData: {},
      );

      expect(content.text, isNull);
      expect(content.audioUrl, isNull);
      expect(content.videoUrl, isNull);
      expect(content.imageUrl, isNull);
      expect(content.questions, isNull);
      expect(content.wordQuestions, isNull);
    });

    test('should handle null otherData', () {
      final content = LessonContent.fromSectionLesson(
        id: 5,
        sectionId: 105,
        title: 'Null Data Section',
        types: 'Tutorial',
        score: 5,
        isCompleted: false,
        otherData: null,
      );

      expect(content.text, isNull);
      expect(content.questions, isNull);
    });

    test('should use title as fallback for text', () {
      final content = LessonContent.fromSectionLesson(
        id: 6,
        sectionId: 106,
        title: 'Fallback Title',
        types: 'Tutorial',
        score: 5,
        isCompleted: false,
        otherData: {
          'title': 'Other Title',
        },
      );

      expect(content.text, 'Other Title');
    });

    test('should handle empty question arrays', () {
      final content = LessonContent.fromSectionLesson(
        id: 7,
        sectionId: 107,
        title: 'Empty Quiz',
        types: 'Instant Quiz',
        score: 0,
        isCompleted: false,
        otherData: {
          'question': [],
        },
      );

      expect(content.questions, isNull);
    });

    test('should filter out invalid quiz questions', () {
      final content = LessonContent.fromSectionLesson(
        id: 8,
        sectionId: 108,
        title: 'Invalid Quiz',
        types: 'Instant Quiz',
        score: 0,
        isCompleted: false,
        otherData: {
          'question': [
            {
              'id': 1,
              'question': {'question': 'Valid question'},
              'choices': [
                {'text': 'Option A', 'correct_answer': true},
              ],
            },
            {
              'id': 2,
              // Missing question or choices
            },
            null,
          ],
        },
      );

      expect(content.questions, isNotNull);
      expect(content.questions!.length, 1);
    });

    test('should handle dateTime correctly', () {
      final dateTime = DateTime.now();
      final content = LessonContent.fromSectionLesson(
        id: 9,
        sectionId: 109,
        title: 'Dated Section',
        types: 'Tutorial',
        score: 10,
        isCompleted: false,
        dateTime: dateTime,
        otherData: {},
      );

      expect(content.dateTime, dateTime);
    });
  });

  group('QuizQuestion', () {
    test('should create quiz question with all fields', () {
      final question = QuizQuestion(
        id: 1,
        question: 'What is this?',
        text: 'Additional text',
        hint: 'Think carefully',
        funFact: 'Interesting fact',
        imageUrl: 'https://example.com/image.jpg',
        audioUrl: 'https://example.com/audio.mp3',
        videoUrl: 'https://example.com/video.mp4',
        options: [
          QuizOption(id: 0, text: 'Option A', isCorrect: true),
          QuizOption(id: 1, text: 'Option B', isCorrect: false),
        ],
      );

      expect(question.id, 1);
      expect(question.question, 'What is this?');
      expect(question.text, 'Additional text');
      expect(question.hint, 'Think carefully');
      expect(question.funFact, 'Interesting fact');
      expect(question.options.length, 2);
    });

    test('should use copyWith correctly', () {
      final question = QuizQuestion(
        id: 1,
        question: 'Original',
        options: [
          QuizOption(id: 0, text: 'A', isCorrect: true),
        ],
      );

      final updated = question.copyWith(
        question: 'Updated',
        hint: 'New hint',
      );

      expect(updated.question, 'Updated');
      expect(updated.hint, 'New hint');
      expect(updated.id, 1); // Unchanged
    });
  });

  group('WordQuizQuestion', () {
    test('should create word quiz question', () {
      final question = WordQuizQuestion(
        id: 1,
        question: 'What is [hello/bonjour]?',
        content: 'Hello',
        hint: 'Greeting',
      );

      expect(question.id, 1);
      expect(question.question, 'What is [hello/bonjour]?');
      expect(question.content, 'Hello');
      expect(question.hint, 'Greeting');
    });

    test('should use copyWith correctly', () {
      final question = WordQuizQuestion(
        id: 1,
        question: 'Original',
        content: 'Content',
      );

      final updated = question.copyWith(
        question: 'Updated',
        hint: 'New hint',
      );

      expect(updated.question, 'Updated');
      expect(updated.hint, 'New hint');
      expect(updated.content, 'Content'); // Unchanged
    });
  });

  group('LessonContent edge cases', () {
    test('should handle empty string fields', () {
      final content = LessonContent.fromSectionLesson(
        id: 10,
        sectionId: 110,
        title: 'Empty Strings',
        types: 'Tutorial',
        score: 0,
        isCompleted: false,
        otherData: {
          'text': '',
          'audio': '',
          'video': '',
          'image': '',
        },
      );

      expect(content.text, isNull);
      expect(content.audioUrl, isNull);
      expect(content.videoUrl, isNull);
      expect(content.imageUrl, isNull);
    });

    test('should handle whitespace-only fields', () {
      final content = LessonContent.fromSectionLesson(
        id: 11,
        sectionId: 111,
        title: 'Whitespace',
        types: 'Tutorial',
        score: 0,
        isCompleted: false,
        otherData: {
          'text': '   ',
        },
      );

      expect(content.text, isNull);
    });

    test('should handle non-map otherData', () {
      final content = LessonContent.fromSectionLesson(
        id: 12,
        sectionId: 112,
        title: 'Non-map Data',
        types: 'Tutorial',
        score: 0,
        isCompleted: false,
        otherData: 'not a map',
      );

      expect(content.text, isNull);
      expect(content.questions, isNull);
    });

    test('should handle quiz with no correct answers', () {
      final content = LessonContent.fromSectionLesson(
        id: 13,
        sectionId: 113,
        title: 'No Correct Answers',
        types: 'Instant Quiz',
        score: 0,
        isCompleted: false,
        otherData: {
          'question': [
            {
              'id': 1,
              'question': {'question': 'Question'},
              'choices': [
                {'text': 'Option A', 'correct_answer': false},
                {'text': 'Option B', 'correct_answer': false},
              ],
            },
          ],
        },
      );

      // Should filter out questions with no correct answers
      expect(content.questions, isNull);
    });
  });
}
