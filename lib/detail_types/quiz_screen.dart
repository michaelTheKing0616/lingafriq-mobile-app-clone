import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lingafriq/models/quiz_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/progress_integration.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

import '../widgets/points_and_profile_image_builder.dart';
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
  }) : super(key: key);

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
              return singleQuizIndicatorBuilder(isCorrect);
            }
            return multiQuizIndicatorBuilder();
          }),
        ),
        child: PopScope(
          canPop: true,
          onPopInvoked: (didPop) {
            if (!didPop) {
              ref.read(navigationProvider).pop();
            }
          },
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
              SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Consumer(
                      builder: ((context, ref, child) {
                        final index = ref.watch(quizIndexProvider);
                        return PrimaryButton(
                          width: 0.3.sw,
                          onTap: () async {
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
                                  final success = await ref.read(apiProvider.notifier).markAsComplete(endpointToHit);
                                  if (!success) {
                                    "Failed to mark quiz as complete".log("quiz_screen");
                                  } else {
                                    // Track progress
                                    await ProgressIntegration.onQuizCompleted(ref);
                                  }
                                }
                                if (context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              }
                              if (!correct && isTakeQuiz) {
                                if (context.mounted) {
                                  Navigator.of(context).pop(false);
                                }
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
                                  final success = await ref.read(apiProvider.notifier).markAsComplete(endpointToHit);
                                  if (!success) {
                                    "Failed to mark quiz as complete".log("quiz_screen");
                                  } else {
                                    // Track progress
                                    await ProgressIntegration.onQuizCompleted(ref);
                                  }
                                }
                                if (context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              }
                              if (!correct && isTakeQuiz) {
                                if (context.mounted) {
                                  Navigator.of(context).pop(false);
                                }
                              }
                              return;
                            }

                            if (index == quiz.length - 1) {
                              ref.read(navigationProvider).naviateTo(QuizAnswersScreen(
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              (quiz.length == (index + 1) ? "Submit" : "Next")
                                  .text
                                  .size(18.sp)
                                  .white
                                  .make(),
                              12.widthBox,
                              const Icon(
                                Icons.arrow_circle_right,
                                color: Colors.white,
                              )
                            ],
                          ),
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
      ),
    );
  }

  Widget singleQuizIndicatorBuilder(bool isCorrect) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(
            isCorrect ? Icons.done : Icons.close,
            size: 46.sp,
            color: isCorrect ? Colors.green : Colors.red,
          ),
        ),
        12.heightBox,
        () {
          if (isCorrect) {
            final score = quiz.first.score?.round().toString();
            return score == null ? 'Correct' : "+$score";
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
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            //   child: Icon(
            //     Icons.done,
            //     size: 46.sp,
            //     color: Colors.green,
            //   ),
            // ),
            // "Done!!!".text.xl3.medium.white.make().py16(),
            Container(
              width: 0.5.sw,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: AppColors.red,
              ),
              child: "${index + 1}/${quiz.length}".text.xl2.medium.white.makeCentered(),
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
    Key? key,
    required this.quiz,
  }) : super(key: key);

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
            color: selected ? AppColors.primaryOrange : context.adaptive26,
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
    Key? key,
    required this.quiz,
    required this.onSelect,
    this.initial,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selected = useState<String?>(null);
    quiz.answer.toString().log('Answer');
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: context.adaptive8),
          child: Text(
            quiz.question,
            style: TextStyle(fontSize: 26.sp),
          ),
        ),
        ...quiz.choices.map((e) {
          return RadioListTile<String?>(
            activeColor: initial == quiz.answer ? Colors.green : Colors.red,
            selectedTileColor: initial == quiz.answer ? Colors.green : Colors.red,
            visualDensity: VisualDensity.compact,
            title: e.text
                .color((() {
                  if (initial != e) return context.adaptive;
                  if (initial == quiz.answer) return Colors.green;
                  return Colors.red;
                }).call())
                .make(),
            value: e,
            groupValue: initial ?? selected.value,
            onChanged: (value) {
              if (initial != null) return;
              selected.value = value;
              onSelect.call(value!);
            },
          );
        }).toList(),
        Divider(
          height: 0,
          color: context.adaptive8,
          thickness: 4,
          endIndent: 12,
          indent: 16,
        ).py12(),
      ],
    ).scrollVertical();
  }
}
