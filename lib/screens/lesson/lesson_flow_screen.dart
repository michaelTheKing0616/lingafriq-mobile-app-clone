import 'package:lingafriq/providers/age_policy_provider.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/widgets/bidi_text.dart';
import 'package:lingafriq/screens/lesson/widgets/lesson_skeleton.dart';
import 'package:lingafriq/lessons/models/section_lesson_model.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/content/lingafriq_ux_voice.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/lingafriq_scaffold.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
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
/// Lesson header gradient: deep kente red to deep ochre, so the white
/// title, ✕ and points keep >=4.5:1 at every stop (see contrast test).
const List<Color> kLessonHeaderGradient = [
  Color(0xFFA3322B),
  Color(0xFF8C5A00),
];

/// Connectivity for the completion screen's offline note (overridable in
/// tests). Never blocks: progress is already saved locally.
final lessonOnlineProvider = FutureProvider.autoDispose<bool>(
  (ref) => ConnectivityService.hasInternet(),
);

class LessonFlowScreen extends HookConsumerWidget {
  final int lessonId;
  final List<SectionLessonModel> sectionLessons;
  final String lessonTitle;
  final String? audioLanguage;

  const LessonFlowScreen({
    super.key,
    required this.lessonId,
    required this.sectionLessons,
    required this.lessonTitle,
    this.audioLanguage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      LessonSystemTextScale(child: _LessonFlowBody(this));
}

/// Restores the learner's system text size inside the lesson (clamped to
/// 200%). The app shell pins [TextScaler] to 1.0, which would otherwise make
/// large-text settings do nothing on the screen people spend the most time in.
class LessonSystemTextScale extends StatelessWidget {
  const LessonSystemTextScale({super.key, required this.child});
  final Widget child;

  static const maxScale = 2.0;

  @override
  Widget build(BuildContext context) {
    final system = MediaQueryData.fromView(
      View.of(context),
    ).textScaler.clamp(maxScaleFactor: maxScale);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: system),
      child: child,
    );
  }
}

/// Bottom sheet asking before a learner abandons a lesson mid-way. Shows
/// exactly how close they are ([done] of [total] sections) so the choice is
/// concrete. Returns true only when they choose to end it.
Future<bool> confirmLessonQuit(
  BuildContext context, {
  required int done,
  required int total,
}) async {
  final left = (total - done).clamp(0, total);
  final l = l10nOf(context);
  final scheme = Theme.of(context).colorScheme;
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Copy scrolls at large text sizes; the two choices below
                // stay pinned so "Keep learning" is never pushed off-screen.
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            l.lessonQuitTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LessonQuitSteps(done: done, total: total),
                        const SizedBox(height: 8),
                        Text(
                          l.lessonQuitRemaining(left),
                          key: const Key('lesson-quit-remaining'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.lessonQuitBody,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('lesson-keep-learning'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  child: Text(
                    l.lessonKeepLearning,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('lesson-end-session'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: scheme.error,
                  ),
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  child: Text(l.lessonEndSession, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// A row of section pills: gold for finished, outlined for still to do.
/// Reads in the text direction, so it fills from the right in Arabic.
class LessonQuitSteps extends StatelessWidget {
  const LessonQuitSteps({super.key, required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 40),
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i < done ? PanAfricanColors.accent : null,
                  border: Border.all(
                    color: i < done
                        ? PanAfricanColors.secondaryDark
                        : scheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonFlowBody extends HookConsumerWidget {
  const _LessonFlowBody(this.w);
  final LessonFlowScreen w;

  int get lessonId => w.lessonId;
  List<SectionLessonModel> get sectionLessons => w.sectionLessons;
  String get lessonTitle => w.lessonTitle;
  String? get audioLanguage => w.audioLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = l10nOf(context);
    final pageController = usePageController(initialPage: 0);
    final lessonFlow = ref.watch(lessonFlowProvider(lessonId).notifier);
    final lessonState = ref.watch(lessonFlowProvider(lessonId));
    final comboTracker = lessonFlow.comboTracker;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final pageTransitionDuration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 300);

    void exitLesson() {
      final sections = ref.read(lessonFlowProvider(lessonId)).sections;
      _pauseAllSectionVideos(ref, sections);
      comboTracker.reset();
      ref.read(navigationProvider).pop();
    }

    Future<void> askToExit() async {
      final st = ref.read(lessonFlowProvider(lessonId));
      final ok = await confirmLessonQuit(
        context,
        done: st.completedSections,
        total: st.sections.length,
      );
      if (ok) exitLesson();
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
            duration: pageTransitionDuration,
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
            totalQuestions: lessonState.totalQuestions,
            online: ref.watch(lessonOnlineProvider).value ?? true,
            childMode:
                ref.watch(agePolicyProvider).value?.socialSurfacesBlocked ??
                false,
            onContinue: exitLesson,
            onShare: () {
              Share.share(
                LingAfriqUxVoice.lessonShareText(lessonState.totalXPEarned),
                subject: 'LingAfriq lesson complete',
              );
            },
          ),
        ),
      );
    }

    final currentSection = lessonState.currentSection;

    // Lesson failed to load entirely (no cached/offline copy either) — give
    // the learner a warm, actionable way forward instead of a silent gap.
    if (lessonState.sections.isEmpty &&
        lessonState.error != null &&
        !lessonState.isLoading) {
      void retryLoad() {
        ref
            .read(lessonFlowProvider(lessonId).notifier)
            .initialize(sectionLessons);
      }

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) return;
          ref.read(navigationProvider).pop();
        },
        child: LingafriqScaffold(
          body: Column(
            children: [
              TopGradientBox(
                borderRadius: 0,
                colors: kLessonHeaderGradient,
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('lesson-error-close'),
                      tooltip: l.lessonExit,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => ref.read(navigationProvider).pop(),
                    ),
                    Expanded(
                      child: BidiText(
                        lessonTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PanAfricanTypography.titleLarge(context)
                            .copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                  ],
                ).pOnly(bottom: 8),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  label:
                      "${l.lessonLoadFailedTitle}. ${l.lessonLoadFailedBody}",
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Center(
                          child: PanAfricanErrorState(
                            title: l.lessonLoadFailedTitle,
                            description: l.lessonLoadFailedBody,
                            onRetry: retryLoad,
                            retryLabel: l.lessonRetry,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (currentSection == null || lessonState.sections.isEmpty) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) return;
          ref.read(navigationProvider).pop();
        },
        child: LingafriqScaffold(
          body: LessonSkeleton(caption: l.lessonPreparing),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        askToExit();
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
                    colors: kLessonHeaderGradient,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconButton(
                                  key: const Key('lesson-close'),
                                  tooltip: l.lessonExit,
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: askToExit,
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    start: 16.w,
                                    bottom: 8.h,
                                  ),
                                  child: BidiText(
                                    lessonTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        PanAfricanTypography.titleLarge(
                                          context,
                                        ).copyWith(
                                          color: Colors.white,
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
                          label: l.lessonProgressLabel(
                            lessonState.currentSectionIndex + 1,
                            lessonState.sections.length,
                            (lessonState.completedSections /
                                    lessonState.sections.length *
                                    100)
                                .toInt(),
                          ),
                          value: l.lessonSectionLabel(
                            lessonState.currentSectionIndex + 1,
                            lessonState.sections.length,
                          ),
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
                        final sectionLabel = l.lessonSectionLabel(
                          index + 1,
                          lessonState.sections.length,
                        );
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
                            pageTransitionDuration,
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

  /// Shows a warm, AA-safe retry affordance when a section fails to save its
  /// completion (e.g. a transient network error) instead of silently
  /// advancing the learner or leaving them stuck with no feedback at all.
  void _showRetrySnackBar(BuildContext context, VoidCallback onRetry) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LingAfriqUxVoice.connectionError,
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
        backgroundColor: colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: l10nOf(context).lessonRetry,
          textColor: colorScheme.onErrorContainer,
          onPressed: onRetry,
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
    Duration pageTransitionDuration,
  ) {
    switch (section.type) {
      case LessonSectionType.tutorial:
        return TutorialSectionWidget(
          content: section,
          vocabAudioLanguage: audioLanguage,
          vocabAudioText: section.title,
          onContinue: () async {
            Future<void> completeAndAdvance() async {
              final success = await lessonFlow.completeSection(
                section.sectionId,
              );
              if (!context.mounted) return;
              if (!success) {
                _showRetrySnackBar(context, completeAndAdvance);
                return;
              }
              final st = ref.read(lessonFlowProvider(lessonId));
              if (st.hasMoreSections) {
                final nextIndex = st.currentSectionIndex + 1;
                lessonFlow.nextSection();
                if (pageController.hasClients) {
                  pageController.animateToPage(
                    nextIndex,
                    duration: pageTransitionDuration,
                    curve: Curves.easeInOut,
                  );
                }
              } else {
                // All sections complete - show completion screen
                ref.read(lessonFlowProvider(lessonId).notifier).nextSection();
              }
            }

            await completeAndAdvance();
          },
        );

      case LessonSectionType.instantQuiz:
      case LessonSectionType.longQuiz:
        return QuizSectionWidget(
          content: section,
          vocabAudioLanguage: audioLanguage,
          vocabAudioText: section.questions?.isNotEmpty == true
              ? section.questions!.first.question
              : null,
          onAnswerSelected: (questionId, answer) {
            lessonFlow.setQuizAnswer(section.sectionId, questionId, answer);
          },
          onFinish: () {
            Future<void> completeAndAdvance() async {
              final success = await lessonFlow.completeSection(
                section.sectionId,
              );
              if (!context.mounted) return;
              if (!success) {
                _showRetrySnackBar(context, completeAndAdvance);
                return;
              }
              final st = ref.read(lessonFlowProvider(lessonId));
              if (st.hasMoreSections) {
                await Future.delayed(const Duration(milliseconds: 500));
                if (!context.mounted) return;
                final nextIndex = st.currentSectionIndex + 1;
                lessonFlow.nextSection();
                if (pageController.hasClients) {
                  pageController.animateToPage(
                    nextIndex,
                    duration: pageTransitionDuration,
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
          audioLanguage: audioLanguage,
          currentAnswers: lessonState.wordQuizAnswers[section.sectionId],
          onAnswerChanged: (blankIndex, answer) {
            lessonFlow.setWordQuizAnswer(section.sectionId, blankIndex, answer);
          },
          onCheck: () async {
            final allCorrect = await lessonFlow.checkWordQuizCompletion(
              section.sectionId,
            );
            if (!allCorrect) return;

            Future<void> completeAndAdvance() async {
              final success = await lessonFlow.completeSection(
                section.sectionId,
              );
              if (!context.mounted) return;
              if (!success) {
                _showRetrySnackBar(context, completeAndAdvance);
                return;
              }

              final st = ref.read(lessonFlowProvider(lessonId));
              if (st.hasMoreSections) {
                await Future.delayed(const Duration(milliseconds: 1500));
                if (!context.mounted) return;
                final nextIndex = st.currentSectionIndex + 1;
                lessonFlow.nextSection();
                if (pageController.hasClients) {
                  pageController.animateToPage(
                    nextIndex,
                    duration: pageTransitionDuration,
                    curve: Curves.easeInOut,
                  );
                }
              } else {
                // All sections complete - show completion screen
                ref.read(lessonFlowProvider(lessonId).notifier).nextSection();
              }
            }

            await completeAndAdvance();
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
