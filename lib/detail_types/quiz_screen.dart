import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lingafriq/models/quiz_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

import '../widgets/points_and_profile_image_builder.dart';
import '../widgets/responsive_safe_area.dart';
import 'quiz_answers_screen.dart';

class QuizIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int value) {
    state = value;
  }
}

final quizIndexProvider =
    NotifierProvider.autoDispose<QuizIndexNotifier, int>(() {
  return QuizIndexNotifier();
});

class QuizScreen extends HookConsumerWidget {
  final String title;
  final List<QuizModel> quiz;
  final String endpointToHit;
  final bool isTakeQuiz;
  final bool isCompleted;
  const QuizScreen({
    Key? key,
    required this.title,
    required this.quiz,
    required this.endpointToHit,
    this.isTakeQuiz = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    "QUIZ SCORE: ${quiz.first.score}".log('QuizScreen');

    final pageController = usePageController();
    final selectedAnswer = quiz.map((e) {
      return useState<Map<String, String?>>({e.question: null});
    }).toList();
    final showIndicator = useState({"isLoading": false, "isCorrect": true});
    final isLoading = ref.watch(apiProvider.select((value) => value.isLoading));
    return LoadingOverlayPro(
      isLoading: isLoading,
      child: LoadingOverlayPro(
        isLoading: showIndicator.value['isLoading'] as bool,
        progressIndicator: Material(
          color: Colors.transparent,
          child: Builder(builder: (context) {
            if (quiz.length == 1 || isTakeQuiz) {
              final isCorrect = showIndicator.value['isCorrect'] as bool;
              return singleQuizIndicatorBuilder(context, isCorrect);
            }
            return multiQuizIndicatorBuilder();
          }),
        ),
        child: Scaffold(
          body: Column(
            children: [
              TopGradientBox(
                borderRadius: 0,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BackButton(color: Colors.white),
                        title.text.xl2.semiBold
                            .maxLines(2)
                            .ellipsis
                            .color(Colors.white)
                            .make()
                            .p16(),
                      ],
                    ).expand(),
                    PointsAndProfileImageBuilder(
                      size: Size(0.07.sh, 0.07.sh),
                    ),
                    16.widthBox,
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: pageController,
                  children: quiz.asMap().entries.map((e) {
                    return QuizItem(
                      quiz: e.value,
                      onSelect: (value) {
                        selectedAnswer[e.key].value = {e.value.question: value};
                      },
                    );
                  }).toList(),
                ),
              ),
              if (quiz.length != 1) _DotIndicator(quiz: quiz).pOnly(top: 4),
              if (quiz.length > 1)
                Consumer(
                  builder: (context, ref, child) {
                    final index = ref.watch(quizIndexProvider);
                    final progress = ((index + 1) / quiz.length).clamp(0.0, 1.0);
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 8.h,
                      ),
                      child: PanAfricanProgressBar(
                        progress: progress,
                        color: PanAfricanColors.primary,
                        height: 6.h,
                      ),
                    );
                  },
                ),
              ResponsiveSafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Consumer(
                      builder: ((context, ref, child) {
                        final index = ref.watch(quizIndexProvider);
                        return PanAfricanButton(
                          width: 0.36.sw,
                          onPressed: () async {
                            if (quiz.length == 1) {
                              final currenlySelectedAnswer =
                                  selectedAnswer.first.value[quiz.first.question];
                              if (currenlySelectedAnswer == null) {
                                VxToast.show(context, msg: "Please select an option");
                                return;
                              }
                              final correct = quiz.first.answer == currenlySelectedAnswer;
                              showIndicator.value = {"isLoading": true, "isCorrect": correct};
                              await Future.delayed(const Duration(milliseconds: 700));
                              showIndicator.value = {
                                "isLoading": false,
                              };
                              if (correct) {
                                if (!isCompleted) {
                                  await ref.read(apiProvider.notifier).markAsComplete(endpointToHit);
                                }
                                Navigator.of(context).pop(true);
                              }
                              if (!correct && isTakeQuiz) {
                                Navigator.of(context).pop(false);
                              }
                              return;
                            }
                            final currentlySelectedAnswer =
                                selectedAnswer[index].value[quiz[index].question];
                            if (currentlySelectedAnswer == null) {
                              VxToast.show(context, msg: "Please select an option");
                              return;
                            }
                            final correct = quiz[index].answer == currentlySelectedAnswer;
                            showIndicator.value = {"isLoading": true, "isCorrect": correct};
                            await Future.delayed(const Duration(milliseconds: 700));
                            showIndicator.value = {"isLoading": false, "isCorrect": correct};
                            if (isTakeQuiz && index == quiz.length - 1) {
                              final correctAnswers = selectedAnswer.asMap().entries.where((e) {
                                final currentQuiz = quiz.elementAt(e.key);
                                return currentQuiz.answer == e.value.value[currentQuiz.question];
                              });
                              final correct = quiz.length == correctAnswers.length;
                              ref.read(quizIndexProvider.notifier).setIndex(0);
                              if (correct) {
                                if (!isCompleted) {
                                  await ref.read(apiProvider.notifier).markAsComplete(endpointToHit);
                                }
                                Navigator.of(context).pop(true);
                              }
                              if (!correct && isTakeQuiz) {
                                Navigator.of(context).pop(false);
                              }
                              return;
                            }

                            if (index == quiz.length - 1) {
                              ref.read(navigationProvider).navigateTo(QuizAnswersScreen(
                                    quiz: quiz,
                                    title: title,
                                    selectedAnswers: selectedAnswer.map((e) => e.value).toList(),
                                    endpointToHit: endpointToHit,
                                    isCompleted: isCompleted,
                                  ));
                              ref.read(quizIndexProvider.notifier).setIndex(0);
                              pageController.animateToPage(
                                0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.fastLinearToSlowEaseIn,
                              );
                              return;
                            }
                            ref.read(quizIndexProvider.notifier).setIndex(index + 1);
                            pageController.animateToPage(
                              index + 1,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.fastLinearToSlowEaseIn,
                            );
                          },
                          label: quiz.length == (index + 1) ? "Submit" : "Next",
                          icon: Icons.arrow_circle_right,
                          isLoading: isLoading,
                          backgroundColor: PanAfricanColors.primary,
                          foregroundColor: Colors.white,
                        );
                      }),
                    ),
                  ],
                ).p16(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget singleQuizIndicatorBuilder(BuildContext context, bool isCorrect) {
    final accent = isCorrect ? PanAfricanColors.success : PanAfricanColors.error;
    return Column(
      children: [
        PanAfricanCard(
          padding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 14.h,
          ),
          hasGlow: true,
          glowColor: accent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  size: 28.sp,
                  color: accent,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                isCorrect ? 'Correct' : (isTakeQuiz ? 'Try again' : 'Not quite'),
                style: PanAfricanTypography.titleMedium(context).copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        12.heightBox,
        () {
          if (isCorrect) {
            final score = quiz.first.score?.round().toString();
            return score == null ? 'Well done' : "+$score points";
          }
          if (isTakeQuiz) return '';
          return "Try Again";
        }.call().text.xl3.medium.white.make(),
      ],
    );
  }

  Widget multiQuizIndicatorBuilder() {
    return Consumer(
      builder: (context, ref, child) {
        final index = ref.watch(quizIndexProvider);
        return Column(
          children: [
            PanAfricanCard(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Column(
                children: [
                  Text(
                    'Question ${index + 1} of ${quiz.length}',
                    style: PanAfricanTypography.labelLarge(context).copyWith(
                      color: PanAfricanColors.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  PanAfricanProgressBar(
                    progress: ((index + 1) / quiz.length).clamp(0.0, 1.0),
                    color: PanAfricanColors.primary,
                    height: 6.h,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DotIndicator extends ConsumerWidget {
  final List<QuizModel> quiz;
  const _DotIndicator({
    super.key,
    required this.quiz,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(quizIndexProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(quiz.length, (e) {
        final selected = e == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastLinearToSlowEaseIn,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? PanAfricanColors.tertiary : context.adaptive26,
          ),
        );
      }).toList(),
    );
  }
}

class QuizItem extends HookWidget {
  final String? initial;
  final QuizModel quiz;
  final ValueChanged<String> onSelect;
  const QuizItem({
    super.key,
    required this.quiz,
    required this.onSelect,
    this.initial,
  });

  @override
  Widget build(BuildContext context) {
    final selected = useState<String?>(null);
    quiz.answer.toString().log('Answer');
    final isReview = initial != null;
    final selectedValue = initial ?? selected.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight;

    Color _optionBorder(String option) {
      if (isReview && option == quiz.answer) return PanAfricanColors.success;
      if (isReview && selectedValue == option && option != quiz.answer) {
        return PanAfricanColors.error;
      }
      if (!isReview && selectedValue == option) return PanAfricanColors.primary;
      return isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight;
    }

    Color _optionBackground(String option) {
      if (isReview && option == quiz.answer) {
        return PanAfricanColors.success.withOpacity(0.12);
      }
      if (isReview && selectedValue == option && option != quiz.answer) {
        return PanAfricanColors.error.withOpacity(0.12);
      }
      if (!isReview && selectedValue == option) {
        return PanAfricanColors.primary.withOpacity(0.12);
      }
      return surfaceColor;
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: PanAfricanCard(
            hasGradientBorder: true,
            gradientStart: PanAfricanColors.secondary,
            gradientEnd: PanAfricanColors.tertiary,
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Text(
              quiz.question,
              style: PanAfricanTypography.headlineSmall(context),
            ),
          ),
        ),
        ...quiz.choices.map((option) {
          final isSelected = selectedValue == option;
          final isCorrect = option == quiz.answer;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
            child: PanAfricanCard(
              onTap: isReview
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      selected.value = option;
                      onSelect.call(option);
                    },
              backgroundColor: _optionBackground(option),
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.md,
                vertical: PanAfricanSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _optionBorder(option), width: 2),
                      color: isSelected || (isReview && isCorrect)
                          ? _optionBorder(option).withOpacity(0.15)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      isReview && isCorrect
                          ? Icons.check_rounded
                          : (isReview && isSelected && !isCorrect)
                              ? Icons.close_rounded
                              : (isSelected ? Icons.circle : Icons.circle_outlined),
                      color: _optionBorder(option),
                      size: 16.sp,
                    ),
                  ),
                  SizedBox(width: PanAfricanSpacing.md),
                  Expanded(
                    child: Text(
                      option,
                      style: PanAfricanTypography.bodyLarge(context).copyWith(
                        color: isReview && isCorrect
                            ? PanAfricanColors.success
                            : isReview && isSelected && !isCorrect
                                ? PanAfricanColors.error
                                : null,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isReview && isCorrect)
                    PanAfricanBadge(
                      label: 'Correct',
                      color: PanAfricanColors.success,
                      icon: Icons.check_circle_rounded,
                    ),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: 8.h),
      ],
    ).scrollVertical();
  }
}
