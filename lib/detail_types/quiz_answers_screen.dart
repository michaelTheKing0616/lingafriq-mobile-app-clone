import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/quiz_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

import '../widgets/points_and_profile_image_builder.dart';
import 'quiz_screen.dart';

class QuizAnswersScreen extends ConsumerWidget {
  final List<QuizModel> quiz;
  final String title;
  final List<Map<String, String?>> selectedAnswers;
  final String endpointToHit;
  final bool isCompleted;
  const QuizAnswersScreen({
    super.key,
    required this.quiz,
    required this.title,
    required this.selectedAnswers,
    required this.endpointToHit,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correctAnswers = selectedAnswers.asMap().entries.where((e) {
      final currentQuiz = quiz.elementAt(e.key);
      return currentQuiz.answer == e.value[currentQuiz.question];
    });
    final allCorrect = quiz.length == correctAnswers.length;
    final isLoading = ref.watch(apiProvider.select((value) => value.isLoading));
    return LoadingOverlayPro(
      isLoading: isLoading,
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
              padding: EdgeInsets.symmetric(vertical: 12.h),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: PanAfricanCard(
                    hasGradientBorder: true,
                    gradientStart: allCorrect
                        ? PanAfricanColors.success
                        : PanAfricanColors.secondary,
                    gradientEnd: PanAfricanColors.tertiary,
                    padding: EdgeInsets.all(PanAfricanSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allCorrect ? 'Excellent work!' : 'Quiz summary',
                          style: PanAfricanTypography.titleLarge(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.xs),
                        Text(
                          allCorrect
                              ? 'You answered every question correctly.'
                              : 'You scored ${correctAnswers.length} correct answers out of ${quiz.length}. Review the questions below.',
                          style: PanAfricanTypography.bodyMedium(context).copyWith(
                            color: PanAfricanColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: PanAfricanSpacing.md),
                        PanAfricanBadge(
                          label: '${correctAnswers.length}/${quiz.length} correct',
                          color: allCorrect
                              ? PanAfricanColors.success
                              : PanAfricanColors.secondary,
                          icon: allCorrect
                              ? Icons.celebration_rounded
                              : Icons.analytics_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                ...quiz.asMap().entries.map((e) {
                  final index = e.key;
                  final currentQuiz = quiz[index];
                  final answer = selectedAnswers[index][currentQuiz.question];
                  return QuizItem(
                    initial: answer,
                    quiz: currentQuiz,
                    onSelect: (_) {},
                  );
                }),
                SafeArea(
                  top: false,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PanAfricanButton(
                        width: 0.6.sw,
                        onPressed: () async {
                          if (allCorrect) {
                            if (!isCompleted) {
                              await ref.read(apiProvider.notifier).markAsComplete(endpointToHit);
                            }
                            Navigator.of(context).pop(true);
                          }
                          Navigator.of(context).pop(true);
                        },
                        label: allCorrect ? "Continue" : "Try Again",
                        backgroundColor: allCorrect
                            ? PanAfricanColors.success
                            : PanAfricanColors.primary,
                        foregroundColor: Colors.white,
                      ).pOnly(bottom: 24, top: 16),
                    ],
                  ),
                )
              ],
            ).expand(),
          ],
        ),
      ),
    );
  }
}
