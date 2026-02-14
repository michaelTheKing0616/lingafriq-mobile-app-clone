import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:lingafriq/lessons/models/section_lesson_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/providers/offline_download_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/services/offline/local_database_service.dart';
import 'package:lingafriq/services/sound_effects_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/widgets/gamification/combo_tracker.dart';
import 'models/lesson_content.dart';

/// State for lesson flow
class LessonFlowState {
  final List<LessonContent> sections;
  final int currentSectionIndex;
  final Map<int, Map<int, String?>> quizAnswers; // sectionId -> questionId -> answer
  final Map<int, List<String?>> wordQuizAnswers; // sectionId -> list of answers
  final bool isLoading;
  final String? error;
  final DateTime? startTime;
  final int totalXPEarned;
  final int comboBonus;
  final int correctAnswers;
  final int totalQuestions;

  LessonFlowState({
    required this.sections,
    this.currentSectionIndex = 0,
    this.quizAnswers = const {},
    this.wordQuizAnswers = const {},
    this.isLoading = false,
    this.error,
    this.startTime,
    this.totalXPEarned = 0,
    this.comboBonus = 0,
    this.correctAnswers = 0,
    this.totalQuestions = 0,
  });

  /// Computed accuracy percentage (0-100)
  double get accuracy => totalQuestions > 0 ? (correctAnswers / totalQuestions * 100) : 0;

  /// Computed time taken since lesson start
  Duration get timeTaken => startTime != null ? DateTime.now().difference(startTime!) : Duration.zero;

  LessonFlowState copyWith({
    List<LessonContent>? sections,
    int? currentSectionIndex,
    Map<int, Map<int, String?>>? quizAnswers,
    Map<int, List<String?>>? wordQuizAnswers,
    bool? isLoading,
    String? error,
    DateTime? startTime,
    int? totalXPEarned,
    int? comboBonus,
    int? correctAnswers,
    int? totalQuestions,
  }) {
    return LessonFlowState(
      sections: sections ?? this.sections,
      currentSectionIndex: currentSectionIndex ?? this.currentSectionIndex,
      quizAnswers: quizAnswers ?? this.quizAnswers,
      wordQuizAnswers: wordQuizAnswers ?? this.wordQuizAnswers,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
      totalXPEarned: totalXPEarned ?? this.totalXPEarned,
      comboBonus: comboBonus ?? this.comboBonus,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
    );
  }

  LessonContent? get currentSection {
    if (currentSectionIndex >= 0 && currentSectionIndex < sections.length) {
      return sections[currentSectionIndex];
    }
    return null;
  }

  bool get isLastSection => currentSectionIndex >= sections.length - 1;
  bool get hasMoreSections => currentSectionIndex < sections.length - 1;
  int get completedSections => sections.where((s) => s.isCompleted).length;
  double get progress => sections.isEmpty ? 0.0 : completedSections / sections.length;
}

/// Provider for lesson flow state management
class LessonFlowNotifier extends StateNotifier<LessonFlowState> {
  final Ref ref;
  final int lessonId;
  final ComboTracker comboTracker;
  final SoundEffectsService soundEffects;

  LessonFlowNotifier(
    this.ref,
    this.lessonId,
    this.comboTracker,
    this.soundEffects,
  ) : super(LessonFlowState(sections: []));

  /// Initialize lesson flow with section lessons.
  /// When sectionLessons is empty, if offline and lesson is downloaded, loads from local DB.
  Future<void> initialize(List<SectionLessonModel> sectionLessons) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      if (sectionLessons.isEmpty) {
        final isOnline = await ConnectivityService.hasInternet();
        final isDownloaded = ref.read(offlineDownloadProvider.notifier).isDownloaded(lessonId.toString());
        if (!isOnline && isDownloaded) {
          final local = LocalDatabaseService().getLesson(lessonId.toString());
          if (local != null) {
            final sectionId = int.tryParse(local.id) ?? lessonId;
            final content = LessonContent(
              id: sectionId,
              sectionId: sectionId,
              title: local.title,
              type: LessonSectionType.tutorial,
              score: 10,
              isCompleted: local.isComplete,
              dateTime: local.lastAccessedAt,
              text: local.content,
              audioUrl: local.audioPaths.isNotEmpty ? local.audioPaths.first : null,
              imageUrl: local.imagePaths.isNotEmpty ? local.imagePaths.first : null,
            );
            state = state.copyWith(
              sections: [content],
              isLoading: false,
              startTime: DateTime.now(),
            );
            return;
          }
        }
        state = state.copyWith(isLoading: false);
        return;
      }

      final user = ref.read(userProvider);
      final userId = user?.id;

      final contents = sectionLessons.map((section) {
        return LessonContent.fromSectionLesson(
          id: section.id,
          sectionId: section.id,
          title: section.title,
          types: section.types,
          score: section.score,
          isCompleted: section.completed_by == userId,
          dateTime: section.date,
          otherData: section.otherData,
        );
      }).toList();

      state = state.copyWith(
        sections: contents,
        isLoading: false,
        startTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Set quiz answer
  void setQuizAnswer(int sectionId, int questionId, String answer) {
    final currentAnswers = Map<int, Map<int, String?>>.from(state.quizAnswers);
    if (!currentAnswers.containsKey(sectionId)) {
      currentAnswers[sectionId] = {};
    }
    currentAnswers[sectionId]![questionId] = answer;
    state = state.copyWith(quizAnswers: currentAnswers);
  }

  /// Set word quiz answer
  void setWordQuizAnswer(int sectionId, int blankIndex, String? answer) {
    final currentAnswers = Map<int, List<String?>>.from(state.wordQuizAnswers);
    if (!currentAnswers.containsKey(sectionId)) {
      final section = state.sections.firstWhere((s) => s.sectionId == sectionId);
      currentAnswers[sectionId] = List.filled(
        section.wordQuestions?.length ?? 0,
        null,
      );
    }
    final answers = List<String?>.from(currentAnswers[sectionId]!);
    if (blankIndex >= 0 && blankIndex < answers.length) {
      answers[blankIndex] = answer;
      currentAnswers[sectionId] = answers;
      state = state.copyWith(wordQuizAnswers: currentAnswers);
    }
  }

  /// Check quiz answer and award XP
  Future<bool> checkQuizAnswer(int sectionId, int questionId, String selectedAnswer) async {
    final section = state.sections.firstWhere((s) => s.sectionId == sectionId);
    final question = section.questions?.firstWhere((q) => q.id == questionId);
    if (question == null) return false;

    final correctOption = question.options.firstWhere((o) => o.isCorrect);
    final isCorrect = correctOption.text == selectedAnswer;

    // Update total questions count
    final sectionForCount = state.sections.firstWhere((s) => s.sectionId == sectionId);
    final newTotalQuestions = state.totalQuestions + 
        (sectionForCount.questions?.length ?? sectionForCount.wordQuestions?.length ?? 0);

    if (isCorrect) {
      await soundEffects.playCorrect();
      comboTracker.recordCorrect();
      
      // Award XP with combo multiplier
      final multiplier = comboTracker.currentMultiplier;
      final xpGain = await ref.read(gamificationProvider.notifier).awardXP(
        'quiz_answer',
        multiplier: multiplier,
        sourceId: 'quiz_${sectionId}_$questionId',
      );

      state = state.copyWith(
        correctAnswers: state.correctAnswers + 1,
        totalXPEarned: state.totalXPEarned + xpGain,
        comboBonus: (multiplier > 1.0 ? xpGain : 0).round(),
        totalQuestions: newTotalQuestions,
      );
    } else {
      await soundEffects.playIncorrect();
      comboTracker.recordIncorrect();
      state = state.copyWith(
        totalQuestions: newTotalQuestions,
      );
    }

    return isCorrect;
  }

  /// Check word quiz completion
  Future<bool> checkWordQuizCompletion(int sectionId) async {
    final section = state.sections.firstWhere((s) => s.sectionId == sectionId);
    final answers = state.wordQuizAnswers[sectionId] ?? [];
    final questions = section.wordQuestions ?? [];

    if (answers.length != questions.length) return false;
    if (answers.any((a) => a == null || a.isEmpty)) return false;

    bool allCorrect = true;
    for (int i = 0; i < questions.length; i++) {
      // Extract correct answer from question format: "question/answer"
      final questionParts = questions[i].question.split('/');
      final expectedAnswer = questionParts.length > 1 
          ? questionParts.last.trim().toLowerCase()
          : questions[i].question.trim().toLowerCase();
      final userAnswer = answers[i]?.trim().toLowerCase() ?? '';
      
      if (userAnswer != expectedAnswer) {
        allCorrect = false;
        break;
      }
    }

    // Update total questions count
    final newTotalQuestions = state.totalQuestions + questions.length;

    if (allCorrect) {
      await soundEffects.playCorrect();
      comboTracker.recordCorrect();

      final multiplier = comboTracker.currentMultiplier;
      final xpGain = await ref.read(gamificationProvider.notifier).awardXP(
        'word_quiz_complete',
        multiplier: multiplier,
        sourceId: 'word_quiz_$sectionId',
      );

      state = state.copyWith(
        correctAnswers: state.correctAnswers + questions.length,
        totalXPEarned: state.totalXPEarned + xpGain,
        comboBonus: (multiplier > 1.0 ? xpGain : 0).round(),
        totalQuestions: newTotalQuestions,
      );
    } else {
      await soundEffects.playIncorrect();
      comboTracker.recordIncorrect();
      state = state.copyWith(
        totalQuestions: newTotalQuestions,
      );
    }

    return allCorrect;
  }

  /// Complete a section (tutorial or quiz)
  Future<bool> completeSection(int sectionId) async {
    try {
      state = state.copyWith(isLoading: true);

      final section = state.sections.firstWhere((s) => s.sectionId == sectionId);
      final endpoint = section.type.isTutorial
          ? Api.completeLessonTutorial(lessonId, sectionId)
          : Api.completeLessonQuiz(lessonId, sectionId);

      final success = await ref.read(apiProvider.notifier).markAsComplete(endpoint);

      if (success) {
        final updatedSections = state.sections.map((s) {
          if (s.sectionId == sectionId) {
            return s.copyWith(isCompleted: true);
          }
          return s;
        }).toList();

        state = state.copyWith(
          sections: updatedSections,
          isLoading: false,
        );

        // Award XP for section completion
        final multiplier = comboTracker.currentMultiplier;
        final xpGain = await ref.read(gamificationProvider.notifier).awardXP(
          section.type.isTutorial ? 'tutorial_complete' : 'quiz_complete',
          multiplier: multiplier,
          sourceId: 'section_$sectionId',
        );

        state = state.copyWith(
          totalXPEarned: state.totalXPEarned + xpGain,
          comboBonus: (multiplier > 1.0 ? xpGain : 0).round(),
        );

        return true;
      } else {
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Move to next section
  void nextSection() {
    if (state.hasMoreSections) {
      state = state.copyWith(currentSectionIndex: state.currentSectionIndex + 1);
    }
  }

  /// Move to previous section
  void previousSection() {
    if (state.currentSectionIndex > 0) {
      state = state.copyWith(currentSectionIndex: state.currentSectionIndex - 1);
    }
  }

  /// Get accuracy percentage
  double get accuracy {
    if (state.totalQuestions == 0) return 0.0;
    return (state.correctAnswers / state.totalQuestions) * 100;
  }

  /// Get time taken in seconds
  int get timeTaken {
    if (state.startTime == null) return 0;
    return DateTime.now().difference(state.startTime!).inSeconds;
  }
}

/// Provider for lesson flow
final lessonFlowProvider = StateNotifierProvider.autoDispose
    .family<LessonFlowNotifier, LessonFlowState, int>((ref, lessonId) {
  final comboTracker = ComboTracker();
  final soundEffects = ref.read(soundEffectsProvider);
  return LessonFlowNotifier(ref, lessonId, comboTracker, soundEffects);
});
