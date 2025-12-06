import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/quiz_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/progress_integration.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:lingafriq/screens/loading/dynamic_loading_screen.dart';

import '../widgets/points_and_profile_image_builder.dart';
import 'quiz_screen.dart';

class QuizAnswersScreen extends ConsumerWidget {
  final List<QuizModel> quiz;
  final String title;
  final List<Map<String, String?>> selectedAnswers;
  final String endpointToHit;
  final bool isCompleted;
  const QuizAnswersScreen({
    Key? key,
    required this.quiz,
    required this.title,
    required this.selectedAnswers,
    required this.endpointToHit,
    this.isCompleted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correctAnswers = selectedAnswers.asMap().entries.where((e) {
      final currentQuiz = quiz.elementAt(e.key);
      return currentQuiz.answer == e.value[currentQuiz.question];
    });
    final allCorrect = quiz.length == correctAnswers.length;
    final isLoading = ref.watch(apiProvider.select((value) => value.isLoading));

    final content = Scaffold(
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
                    title.text.xl2.semiBold.maxLines(2).ellipsis.color(Colors.white).make().p16(),
                  ],
                ).expand(),
                PointsAndProfileImageBuilder(
                  size: Size(0.07.sh, 0.07.sh),
                ),
                16.widthBox,
              ],
            ),
          ),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              12.heightBox,
              if (allCorrect)
                "Congratulations!!!. "
                    .richText
                    .withTextSpanChildren([
                      "You have answered all questions correctly."
                          .textSpan
                          .color(Colors.green)
                          .make()
                    ])
                    .xl
                    .make()
                    .px24()
              else
                "You score ${correctAnswers.length} correct answers out of ${quiz.length}. See where you made a mistake to try again."
                    .text
                    .make()
                    .px24(),
              ...quiz.asMap().entries.map((e) {
                final index = e.key;
                final currentQuiz = quiz[index];
                final answer = selectedAnswers[index][currentQuiz.question];
                return QuizItem(
                  initial: answer,
                  quiz: currentQuiz,
                  onSelect: (_) {},
                );
              }).toList(),
              SafeArea(
                top: false,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PrimaryButton(
                      width: 0.6.sw,
                      onTap: () async {
                        if (allCorrect) {
                          if (!isCompleted) {
                            final success = await ref.read(apiProvider.notifier).markAsComplete(endpointToHit);
                            if (!success) {
                              "Failed to mark quiz as complete".log("quiz_answers_screen");
                            } else {
                              final pointsEarned = correctAnswers.length * 10;
                              await ProgressIntegration.onQuizCompleted(ref, wordsLearned: quiz.length, pointsEarned: pointsEarned);
                            }
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        } else {
                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        }
                      },
                      text: allCorrect ? "Continue" : "Try Again",
                    ).pOnly(bottom: 24, top: 16),
                  ],
                ),
              )
            ],
          ).expand(),
        ],
      ),
    );

    return Stack(
      children: [
        content,
        if (isLoading)
          const Positioned.fill(
            child: IgnorePointer(child: DynamicLoadingScreen()),
          ),
      ],
    );
  }
}
