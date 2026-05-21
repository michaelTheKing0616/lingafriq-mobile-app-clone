import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/lessons/models/lesson_response.dart';
import 'package:lingafriq/lessons/screens/section_lessons_list.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/lessons/models/section_lesson_model.dart';
import 'package:lingafriq/screens/content/native_content_review_screen.dart';
import 'package:lingafriq/screens/curriculum/authentic_curriculum_entry_screen.dart';
import 'package:lingafriq/screens/lesson/lesson_flow_screen.dart';
import 'package:lingafriq/screens/lessons/lessons_map_entry_screen.dart';
import 'package:lingafriq/screens/learning/learning_path_screen.dart';
import 'package:lingafriq/screens/magazine/culture_magazine_screen_enhanced.dart';
import 'package:lingafriq/utils/curriculum_languages.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

/// Central navigation for the two lesson systems and bundled content tools.
///
/// - **API lessons:** map → path → sections (classic per-section OR unified [LessonFlowScreen])
/// - **Authentic Path:** bundled A1–C1 curriculum (separate from API lesson map)
class LearningExperienceNavigation {
  LearningExperienceNavigation._();

  static String? languageKeyFor(Language language) =>
      CurriculumLanguages.keyForApiLanguage(language);

  static Future<void> openLessonsMap(BuildContext context) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      SmoothPageRoute.platform(child: const LessonsMapEntryScreen()),
    );
  }

  static Future<void> openAuthenticPath(
    BuildContext context, {
    String? initialLanguage,
    String? initialLevel,
  }) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      SmoothPageRoute.platform(
        child: AuthenticCurriculumEntryScreen(
          initialLanguage: initialLanguage,
          initialLevel: initialLevel,
        ),
      ),
    );
  }

  static Future<void> openNativeContentReview(BuildContext context) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      SmoothPageRoute.platform(child: const NativeContentReviewScreen()),
    );
  }

  static Future<void> openMagazine(
    BuildContext context, {
    String? languageKey,
  }) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      SmoothPageRoute.platform(
        child: CultureMagazineScreenEnhanced(
          initialFilterLanguage: languageKey,
        ),
      ),
    );
  }

  static Future<void> openLearningPath(
    BuildContext context,
    Language language,
  ) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      SmoothPageRoute.platform(
        child: LearningPathScreen(language: language),
      ),
    );
  }

  /// Unified in-app lesson flow (tutorial → quiz → word quiz) with audio + UX voice.
  static Future<void> openUnifiedLessonFlow(
    BuildContext context, {
    required int lessonId,
    required String lessonTitle,
    required List<SectionLessonModel> sectionLessons,
    String? audioLanguage,
  }) {
    if (sectionLessons.isEmpty) return Future.value();
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      SmoothPageRoute.platform(
        child: LessonFlowScreen(
          lessonId: lessonId,
          sectionLessons: sectionLessons,
          lessonTitle: lessonTitle,
          audioLanguage: audioLanguage,
        ),
      ),
    );
  }

  static Future<void> openLessonSections(
    BuildContext context, {
    required Lesson lesson,
    String? studyLanguageKey,
  }) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push(
      SmoothPageRoute.platform(
        child: LessonSectionsListScreen(
          lesson: lesson,
          studyLanguageKey: studyLanguageKey,
        ),
      ),
    );
  }
}
