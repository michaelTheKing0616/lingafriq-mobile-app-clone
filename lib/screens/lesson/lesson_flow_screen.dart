import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:lingafriq/lessons/models/section_lesson_model.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/lingafriq_scaffold.dart';
import 'package:lingafriq/widgets/points_and_profile_image_builder.dart';
import 'package:lingafriq/widgets/portrait_video_player.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:lingafriq/widgets/gamification/combo_display_widget.dart';
import 'lesson_provider.dart';
import 'models/lesson_content.dart';
import 'widgets/lesson_progress_bar.dart';
import 'widgets/tutorial_section_widget.dart';
import 'widgets/quiz_section_widget.dart';
import 'widgets/word_quiz_section_widget.dart';
import 'widgets/lesson_complete_widget.dart';

/// Main lesson flow screen that orchestrates the entire lesson experience
class LessonFlowScreen extends HookConsumerWidget {
  final int lessonId;
  final List<SectionLessonModel> sectionLessons;
  final String lessonTitle;

  const LessonFlowScreen({
    super.key,
    required this.lessonId,
    required this.sectionLessons,
    required this.lessonTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController(initialPage: 0);
    final lessonFlow = ref.watch(lessonFlowProvider(lessonId).notifier);
    final lessonState = ref.watch(lessonFlowProvider(lessonId));
    final comboTracker = lessonFlow.comboTracker;

    void exitLesson() {
      final sections = ref.read(lessonFlowProvider(lessonId)).sections;
      _pauseAllSectionVideos(ref, sections);
      comboTracker.reset();
      ref.read(navigationProvider).pop();
    }

    // Stops any active BetterPlayer (iOS) if the screen is removed by any path.
    useEffect(() {
      return () {
        try {
          final sections = ref.read(lessonFlowProvider(lessonId)).sections;
          _pauseAllSectionVideos(ref, sections);
        } catch (_) {}
      };
    }, [lessonId]);

    // Initialize after build to avoid modifying provider during build (fixes widget tests).
    // Defer to post-frame + microtask so the state write runs outside the frame entirely.
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() {
          final state = ref.read(lessonFlowProvider(lessonId));
          if (state.sections.isEmpty) {
            ref
                .read(lessonFlowProvider(lessonId).notifier)
                .initialize(sectionLessons);
          }
        });
      });
      return null;
    }, []);

    // Sync page controller with state
    useEffect(() {
      if (pageController.hasClients) {
        final currentPage = pageController.page?.round() ?? 0;
        if (currentPage != lessonState.currentSectionIndex) {
          pageController.animateToPage(
            lessonState.currentSectionIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
      return null;
    }, [lessonState.currentSectionIndex]);

    // Show completion screen when all sections are done
    final allCompleted =
        lessonState.sections.isNotEmpty &&
        lessonState.sections.every((s) => s.isCompleted);
    final showCompletion =
        allCompleted &&
        lessonState.currentSectionIndex >= lessonState.sections.length;

    if (showCompletion) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) return;
          exitLesson();
        },
        child: LingafriqScaffold(
          body: LessonCompleteWidget(
            totalXP: lessonState.totalXPEarned,
            comboBonus: lessonState.comboBonus,
            accuracy: lessonState.accuracy,
            timeTaken: lessonState.timeTaken.inSeconds,
            bestCombo: comboTracker.maxCombo,
            onContinue: exitLesson,
            onShare: () {
              Share.share(
                'I just completed a lesson on LingAfriq! ${lessonState.totalXPEarned} XP earned.',
                subject: 'LingAfriq lesson complete',
              );
            },
          ),
        ),
      );
    }

    final currentSection = lessonState.currentSection;
    if (currentSection == null || lessonState.sections.isEmpty) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) return;
          ref.read(navigationProvider).pop();
        },
        child: LingafriqScaffold(
          body: Center(
            child: CircularProgressIndicator(color: PanAfricanColors.primary),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        exitLesson();
      },
      child: LoadingOverlayPro(
        isLoading: lessonState.isLoading,
        child: LingafriqScaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  // Header
                  TopGradientBox(
                    borderRadius: 0,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  label: 'Exit lesson',
                                  button: true,
                                  child: BackButton(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    onPressed: exitLesson,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: 16.w,
                                    bottom: 8.h,
                                  ),
                                  child: Text(
                                    lessonTitle,
                                    style:
                                        PanAfricanTypography.titleLarge(
                                          context,
                                        ).copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ).expand(),
                            PointsAndProfileImageBuilder(
                              size: Size(0.07.sh, 0.07.sh),
                            ),
                            SizedBox(width: 16.w),
                          ],
                        ),
                        // Progress bar
                        Semantics(
                          label:
                              'Lesson progress. Section ${lessonState.currentSectionIndex + 1} of ${lessonState.sections.length}. ${(lessonState.completedSections / lessonState.sections.length * 100).toInt()} percent complete.',
                          value:
                              '${lessonState.currentSectionIndex + 1} of ${lessonState.sections.length}',
                          child: LessonProgressBar(
                            sections: lessonState.sections,
                            currentIndex: lessonState.currentSectionIndex,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: PageView.builder(
                      controller: pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lessonState.sections.length,
                      itemBuilder: (context, index) {
                        final section = lessonState.sections[index];
                        final sectionLabel =
                            'Section ${index + 1} of ${lessonState.sections.length}';
                        return Semantics(
                          label: sectionLabel,
                          header: true,
                          child: _buildSectionContent(
                            context,
                            ref,
                            section,
                            lessonFlow,
                            lessonState,
                            pageController,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Combo display
              ComboDisplayWidget(comboTracker: comboTracker),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent(
    BuildContext context,
    WidgetRef ref,
    LessonContent section,
    LessonFlowNotifier lessonFlow,
    LessonFlowState lessonState,
    PageController pageController,
  ) {
    switch (section.type) {
      case LessonSectionType.tutorial:
        return TutorialSectionWidget(
          content: section,
          onContinue: () async {
            final success = await lessonFlow.completeSection(section.sectionId);
            if (success && lessonState.hasMoreSections) {
              final nextIndex = lessonState.currentSectionIndex + 1;
              lessonFlow.nextSection();
              if (pageController.hasClients) {
                pageController.animateToPage(
                  nextIndex,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            } else if (success) {
              // All sections complete - show completion screen
              ref.read(lessonFlowProvider(lessonId).notifier).nextSection();
            }
          },
        );

      case LessonSectionType.instantQuiz:
      case LessonSectionType.longQuiz:
        return QuizSectionWidget(
          content: section,
          onAnswerSelected: (questionId, answer) {
            lessonFlow.setQuizAnswer(section.sectionId, questionId, answer);
          },
          onFinish: () {
            Future<void> completeAndAdvance() async {
              await lessonFlow.completeSection(section.sectionId);
              if (!context.mounted) return;
              final st = ref.read(lessonFlowProvider(lessonId));
              if (st.hasMoreSections) {
                await Future.delayed(const Duration(milliseconds: 500));
                if (!context.mounted) return;
                final nextIndex = st.currentSectionIndex + 1;
                lessonFlow.nextSection();
                if (pageController.hasClients) {
                  pageController.animateToPage(
                    nextIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              } else {
                ref.read(lessonFlowProvider(lessonId).notifier).nextSection();
              }
            }

            completeAndAdvance();
          },
          onCheckAnswer: (questionId, answer) async {
            await lessonFlow.checkQuizAnswer(
              section.sectionId,
              questionId,
              answer,
            );
            // Multi-question sections: do NOT complete or advance here — only on
            // the last question via onFinish. Single-question sections also use
            // onFinish (Check → Finish) for one consistent code path.
          },
          isAnswerChecked: (questionId) {
            return lessonState.quizAnswers[section.sectionId]?[questionId] !=
                null;
          },
          isAnswerCorrect: (questionId, option) {
            final question = section.questions?.firstWhere(
              (q) => q.id == questionId,
            );
            if (question == null) return false;
            final correctOption = question.options.firstWhere(
              (o) => o.isCorrect,
            );
            return correctOption.text == option;
          },
        );

      case LessonSectionType.wordQuiz:
        return WordQuizSectionWidget(
          content: section,
          currentAnswers: lessonState.wordQuizAnswers[section.sectionId],
          onAnswerChanged: (blankIndex, answer) {
            lessonFlow.setWordQuizAnswer(section.sectionId, blankIndex, answer);
          },
          onCheck: () async {
            final allCorrect = await lessonFlow.checkWordQuizCompletion(
              section.sectionId,
            );
            if (allCorrect) {
              await lessonFlow.completeSection(section.sectionId);

              if (lessonState.hasMoreSections) {
                await Future.delayed(const Duration(milliseconds: 1500));
                if (context.mounted) {
                  final nextIndex = lessonState.currentSectionIndex + 1;
                  lessonFlow.nextSection();
                  if (pageController.hasClients) {
                    pageController.animateToPage(
                      nextIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              } else {
                // All sections complete - show completion screen
                ref.read(lessonFlowProvider(lessonId).notifier).nextSection();
              }
            }
          },
        );
    }
  }

  /// Pause all video players across all lesson sections before navigating away.
  static void _pauseAllSectionVideos(
    WidgetRef ref,
    List<LessonContent> sections,
  ) {
    for (final section in sections) {
      final videoUrl = section.videoUrl?.trim();
      if (videoUrl != null && videoUrl.isNotEmpty) {
        try {
          ref.read(betterPlayerController(videoUrl)).pause();
        } catch (_) {}
      }
      if (section.questions != null) {
        for (final q in section.questions!) {
          final qVideo = q.videoUrl?.trim();
          if (qVideo != null && qVideo.isNotEmpty) {
            try {
              ref.read(betterPlayerController(qVideo)).pause();
            } catch (_) {}
          }
        }
      }
    }
  }
}
