import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/screens/tabs_view/home/take_quiz_screen.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';

import '../../../history/screens/history_list_screen.dart';
import '../../../mannerisms/screens/mannerism_list_screen.dart';
import '../../../providers/navigation_provider.dart';
import '../../../screens/learning/learning_path_screen.dart';
import '../../../widgets/responsive_safe_area.dart';

class LanguageDetailScreen extends ConsumerWidget {
  final Language language;
  const LanguageDetailScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? PanAfricanColors.surfaceDark
          : PanAfricanColors.surfaceLight,
      body: Column(
        children: [
          TopGradientBox(
            borderRadius: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BackButtonWithHaptic(isDark: isDark),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
                  child: Text(
                    language.name,
                    style: PanAfricanTypography.headlineMedium(context).copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
              ],
            ),
          ),
          Stack(
            children: [
              IgnorePointer(
                ignoring: true,
                child: Image.asset(
                  Images.courseBackground,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              ResponsiveSafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Padding(
                            padding: EdgeInsets.all(PanAfricanSpacing.md),
                            child: Stack(
                              children: [
                                IgnorePointer(
                                  ignoring: true,
                                  child: Image.asset(Images.map).offset(offset: Offset(0, -12.sp)),
                                ),
                                Positioned(
                                  left: constraints.maxWidth * 0.12,
                                  top: constraints.maxHeight * 0.075,
                                  child: _LessonTextBuilder(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(navigationProvider)
                                          .navigateTo(LearningPathScreen(language: language));
                                    },
                                  ),
                                ).animate(effects: kGradientTextEffects),
                                Positioned(
                                  left: constraints.maxWidth * 0.365,
                                  top: constraints.maxHeight * (context.isSmall ? 0.315 : 0.265),
                                  child: _MannerismTextBuilder(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(navigationProvider)
                                          .navigateTo(MannerismsListScreen(language: language));
                                    },
                                  ).animate(effects: kGradientTextEffects),
                                ),
                                Positioned(
                                  left: constraints.maxWidth * (context.isSmall ? 0.45 : 0.425),
                                  top: constraints.maxHeight * (context.isSmall ? 0.6 : 0.475),
                                  child: _HistoryTextBuilder(
                                    size: Size(18.sp, 18.sp),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(navigationProvider)
                                          .navigateTo(HistoryListScreen(language: language));
                                    },
                                  ).animate(effects: kGradientTextEffects),
                                ),
                              ],
                            ),
                          );
                        },
                      ).px16(),
                    ),
                    SizedBox(height: PanAfricanSpacing.lg),
                    _QuizButton(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ref.read(navigationProvider).navigateTo(TakeQuizScreen(language: language));
                      },
                    ),
                    SizedBox(height: PanAfricanSpacing.lg),
                  ],
                ),
              )
            ],
          ).expand()
        ],
      ),
    );
  }
}

class _BackButtonWithHaptic extends StatelessWidget {
  final bool isDark;

  const _BackButtonWithHaptic({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: PanAfricanSpacing.xs,
        top: PanAfricanSpacing.xs,
      ),
      child: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onPrimary),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
        tooltip: 'Back',
      ),
    );
  }
}

class _QuizButton extends StatelessWidget {
  final VoidCallback onTap;

  const _QuizButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.6.sw,
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.forest,
        borderRadius: PanAfricanRadius.roundBR,
        boxShadow: PanAfricanShadows.md,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: PanAfricanRadius.roundBR,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.lg,
              vertical: PanAfricanSpacing.md,
            ),
            child: Center(
              child: Text(
                'Take Quiz',
                style: PanAfricanTypography.titleMedium(context).copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonTextBuilder extends StatelessWidget {
  final VoidCallback onTap;
  const _LessonTextBuilder({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: PanAfricanRadius.smBR,
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ['l', 'e', 's', 's', 'o', 'n', 's'].map((e) {
              return Image.asset(
                "assets/alphabets/$e.png",
                width: 19.sp,
                height: 19.sp,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _MannerismTextBuilder extends StatelessWidget {
  final VoidCallback onTap;

  const _MannerismTextBuilder({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: PanAfricanRadius.smBR,
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ['m', 'a', 'n', 'n', 'e', 'r', 'i', 's', 'm', 's'].map((e) {
              return Image.asset(
                "assets/alphabets/$e.png",
                width: 18.sp,
                height: 18.sp,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _HistoryTextBuilder extends StatelessWidget {
  final VoidCallback onTap;

  final Size? size;
  const _HistoryTextBuilder({
    Key? key,
    required this.onTap,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: PanAfricanRadius.smBR,
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ['h', 'i', 's', 't', 'o', 'r', 'y'].map((e) {
              return Image.asset(
                "assets/alphabets/$e.png",
                width: size?.width ?? 19.sp,
                height: size?.height ?? 19.sp,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
