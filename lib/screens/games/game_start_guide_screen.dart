import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';

class GameStartGuideScreen extends ConsumerWidget {
  const GameStartGuideScreen({
    super.key,
    required this.gameTitle,
    required this.gameDescription,
    required this.objectiveXp,
    required this.culturalTip,
    required this.steps,
    required this.characterName,
    required this.characterTitle,
    required this.onStart,
    this.onReviewVocab,
  });

  final String gameTitle;
  final String gameDescription;
  final int objectiveXp;
  final String culturalTip;
  final List<String> steps;
  final String characterName;
  final String characterTitle;
  final VoidCallback onStart;
  final VoidCallback? onReviewVocab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeroSection(context, cs),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      GriotBentoGrid(
                        gap: 12,
                        items: [
                          GriotBentoItem(span: 12, child: _buildObjectiveCard()),
                          GriotBentoItem(span: 12, child: _buildHowToPlayCard(cs)),
                          GriotBentoItem(span: 12, child: _buildCulturalTipStrip(cs)),
                        ],
                      ),
                      SizedBox(height: 32.h),
                      GriotGradientButton(
                        label: 'Start Mission',
                        icon: Icons.rocket_launch_rounded,
                        onPressed: onStart,
                      ),
                      SizedBox(height: 8.h),
                      GriotTertiaryButton(
                        label: 'Review Vocabulary',
                        icon: Icons.menu_book_rounded,
                        onPressed: onReviewVocab,
                      ),
                      SizedBox(height: safePadding.bottom + 16.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: safePadding.top + 8.h,
            left: 12.w,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: cs.surface.withAlpha(200),
                  shape: BoxShape.circle,
                  boxShadow: ModernGriotShadows.sm,
                ),
                child: Icon(Icons.arrow_back_rounded, size: 20.sp, color: cs.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ColorScheme cs) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: GriotSvgPatternBackground(
        pattern: GriotPattern.dots,
        opacity: 0.02,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ModernGriotColors.primaryContainer.withAlpha(60),
                ModernGriotColors.primary.withAlpha(30),
                cs.surface,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 48.h),
              Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ModernGriotGradients.signatureGradient,
                  boxShadow: ModernGriotShadows.glow(ModernGriotColors.primaryContainer),
                ),
                child: Icon(Icons.person_rounded, size: 56.sp, color: ModernGriotColors.onPrimary),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: GriotGlassPanel(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                  child: Column(
                    children: [
                      Text(
                        characterName,
                        style: ModernGriotTypography.titleLarge(context: context, color: cs.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        characterTitle,
                        style: ModernGriotTypography.bodySmall(context: context, color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                gameTitle,
                style: ModernGriotTypography.headlineMedium(context: context, color: cs.onSurface),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: ModernGriotColors.primary,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GriotBadgePill(
            label: '+$objectiveXp XP',
            icon: Icons.star_rounded,
            color: ModernGriotColors.primaryContainer,
            textColor: ModernGriotColors.onPrimaryContainer,
            bounce: true,
          ),
          SizedBox(height: 12.h),
          Text(
            'Mission Objective',
            style: ModernGriotTypography.titleMedium(color: ModernGriotColors.onPrimary),
          ),
          SizedBox(height: 4.h),
          Text(
            gameDescription,
            style: ModernGriotTypography.bodyMedium(color: ModernGriotColors.onPrimary.withAlpha(200)),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToPlayCard(ColorScheme cs) {
    final displaySteps = steps.take(3).toList();

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to Play', style: ModernGriotTypography.titleMedium(color: cs.onSurface)),
          SizedBox(height: 12.h),
          for (var i = 0; i < displaySteps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    gradient: ModernGriotGradients.signatureGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: ModernGriotColors.onPrimary),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(displaySteps[i], style: ModernGriotTypography.bodyMedium(color: cs.onSurface)),
                  ),
                ),
              ],
            ),
            if (i < displaySteps.length - 1) SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }

  Widget _buildCulturalTipStrip(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderLg,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 5.w,
            height: 72.h,
            decoration: BoxDecoration(
              gradient: ModernGriotGradients.sunsetWarm,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ModernGriotRadius.lg),
                bottomLeft: Radius.circular(ModernGriotRadius.lg),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 20.sp, color: ModernGriotColors.primaryContainer),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cultural Tip', style: ModernGriotTypography.labelMedium(color: cs.primary)),
                        SizedBox(height: 2.h),
                        Text(
                          culturalTip,
                          style: ModernGriotTypography.bodySmall(color: cs.onSurfaceVariant),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
