/// Lesson Content Manager
/// 
/// This system allows easy addition of new lessons to the curriculum.
/// Lessons can be added here and will be available in the app.
/// 
/// To add a new lesson:
/// 1. Add a new LessonContent entry below
/// 2. Specify the language ID it belongs to
/// 3. Add lesson sections with content
/// 4. The lesson will appear in the app automatically

import 'package:lingafriq/models/language_response.dart';

class LessonContent {
  final int languageId;
  final String languageName;
  final String lessonName;
  final String description;
  final int score;
  final List<LessonSection> sections;

  LessonContent({
    required this.languageId,
    required this.languageName,
    required this.lessonName,
    required this.description,
    required this.score,
    required this.sections,
  });
}

class LessonSection {
  final String title;
  final String content;
  final String? audioUrl;
  final List<QuizQuestion>? quiz;

  LessonSection({
    required this.title,
    required this.content,
    this.audioUrl,
    this.quiz,
  });
}

class QuizQuestion {
  final String question;
  final String correctAnswer;
  final List<String> options;
  final int score;

  QuizQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
    this.score = 10,
  });
}

/// Lesson Content Database
/// Add your lessons here
class LessonContentManager {
  static List<LessonContent> getAllLessons() {
    return [
      // Example: Hausa Lessons
      LessonContent(
        languageId: 1, // Replace with actual language ID
        languageName: 'Hausa',
        lessonName: 'Basic Greetings',
        description: 'Learn essential Hausa greetings',
        score: 50,
        sections: [
          LessonSection(
            title: 'Introduction',
            content: 'In this lesson, you will learn basic Hausa greetings.',
          ),
          LessonSection(
            title: 'Common Greetings',
            content: '''
            - Sannu (Hello)
            - Ina kwana? (How are you?)
            - Lafiya lau (I'm fine)
            - Na gode (Thank you)
            ''',
          ),
          LessonSection(
            title: 'Practice Quiz',
            content: 'Test your knowledge',
            quiz: [
              QuizQuestion(
                question: 'How do you say "Hello" in Hausa?',
                correctAnswer: 'Sannu',
                options: ['Sannu', 'Na gode', 'Ina kwana?', 'Lafiya'],
                score: 10,
              ),
            ],
          ),
        ],
      ),

      // Example: Yoruba Lessons
      LessonContent(
        languageId: 2, // Replace with actual language ID
        languageName: 'Yoruba',
        lessonName: 'Family Members',
        description: 'Learn Yoruba family vocabulary',
        score: 50,
        sections: [
          LessonSection(
            title: 'Introduction',
            content: 'Learn how to talk about family in Yoruba.',
          ),
          LessonSection(
            title: 'Family Vocabulary',
            content: '''
            - Iya (Mother)
            - Baba (Father)
            - Omo (Child)
            - Egbon (Sibling)
            ''',
          ),
        ],
      ),

      // Add more lessons here following the same pattern
      // Example template:
      /*
      LessonContent(
        languageId: YOUR_LANGUAGE_ID,
        languageName: 'Language Name',
        lessonName: 'Lesson Title',
        description: 'Brief description',
        score: 50,
        sections: [
          LessonSection(
            title: 'Section Title',
            content: 'Section content here...',
            quiz: [
              QuizQuestion(
                question: 'Question text?',
                correctAnswer: 'Correct answer',
                options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
                score: 10,
              ),
            ],
          ),
        ],
      ),
      */
    ];
  }

  /// Get lessons for a specific language
  static List<LessonContent> getLessonsForLanguage(int languageId) {
    return getAllLessons().where((lesson) => lesson.languageId == languageId).toList();
  }

  /// Get lessons for a specific language by name
  static List<LessonContent> getLessonsForLanguageName(String languageName) {
    return getAllLessons()
        .where((lesson) => lesson.languageName.toLowerCase() == languageName.toLowerCase())
        .toList();
  }

  /// Add a new lesson programmatically
  static void addLesson(LessonContent lesson) {
    // In a real implementation, this would save to a database
    // For now, lessons are defined statically in getAllLessons()
    // To add a lesson, simply add it to the list in getAllLessons()
  }
}

/// Instructions for adding lessons:
/// 
/// 1. OPEN this file: lib/data/lesson_content_manager.dart
/// 
/// 2. FIND the getAllLessons() method
/// 
/// 3. ADD a new LessonContent object to the list:
/// 
///    LessonContent(
///      languageId: 1,  // The ID of the language (check API or language list)
///      languageName: 'Hausa',  // Name must match exactly
///      lessonName: 'Your Lesson Title',
///      description: 'Brief description of the lesson',
///      score: 50,  // Points awarded for completing
///      sections: [
///        LessonSection(
///          title: 'Section 1',
///          content: 'Your content here...',
///        ),
///        LessonSection(
///          title: 'Section 2',
///          content: 'More content...',
///          quiz: [
///            QuizQuestion(
///              question: 'What is...?',
///              correctAnswer: 'Correct answer',
///              options: ['A', 'B', 'C', 'D'],
///            ),
///          ],
///        ),
///      ],
///    ),
/// 
/// 4. SAVE the file
/// 
/// 5. The lesson will appear in the app after the next build
/// 
/// NOTE: For production, consider:
/// - Storing lessons in a database
/// - Using a CMS (Content Management System)
/// - Creating an admin panel for lesson management
/// - Syncing lessons from a backend API

