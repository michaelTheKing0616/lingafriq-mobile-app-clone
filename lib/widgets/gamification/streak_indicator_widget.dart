import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';
import '../../utils/pan_african_design_system.dart';
import '../../utils/utils.dart';

/// Material 3 compliant streak indicator widget
/// Shows daily streak with fire animation
class StreakIndicatorWidget extends ConsumerWidget {
  final bool compact;
  final bool showLabel;

  const StreakIndicatorWidget({
    super.key,
    this.compact = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider.notifier).gamification;
    final streak = gamification.dailyStreak;
    final isDark = context.isDarkMode;

    if (compact) {
      return _buildCompact(context, streak, isDark);
    }

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.xs),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PanAfricanColors.tertiary.withOpacity(0.3),
            PanAfricanColors.secondary.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        border: Border.all(
          color: PanAfricanColors.tertiary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fire Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: PanAfricanColors.tertiary,
                  size: 32.sp,
                ),
              );
            },
          ),
          SizedBox(width: PanAfricanSpacing.xxs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLabel)
                Text(
                  'Daily Streak',
                  style: PanAfricanTypography.labelSmall(context).copyWith(
                    color: context.adaptive54,
                  ),
                ),
              Text(
                '$streak day${streak != 1 ? 's' : ''}',
                style: PanAfricanTypography.titleMedium(context).copyWith(
                  color: PanAfricanColors.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context, int streak, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.xs,
        vertical: PanAfricanSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: PanAfricanColors.tertiary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(PanAfricanRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: PanAfricanColors.tertiary,
            size: 18.sp,
          ),
          SizedBox(width: PanAfricanSpacing.xxxs),
          Text(
            '$streak',
            style: PanAfricanTypography.labelLarge(context).copyWith(
              color: PanAfricanColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Streak milestone widget
/// Shows progress towards streak milestones
class StreakMilestoneWidget extends ConsumerWidget {
  const StreakMilestoneWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider.notifier).gamification;
    final streak = gamification.dailyStreak;
    final isDark = context.isDarkMode;

    // Milestones: 7, 30, 100, 365 days
    final milestones = [7, 30, 100, 365];
    final nextMilestone = milestones.firstWhere(
      (m) => m > streak,
      orElse: () => milestones.last,
    );
    final progress = streak / nextMilestone;

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        border: Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Milestone',
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.adaptive,
                ),
              ),
              Text(
                '$nextMilestone days',
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: PanAfricanColors.tertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.xxxs),
          ClipRRect(
            borderRadius: BorderRadius.circular(PanAfricanRadius.round),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8.h,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.tertiary),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.xxxs),
          Text(
            '${(nextMilestone - streak)} days to go',
            style: PanAfricanTypography.labelSmall(context).copyWith(
              color: context.adaptive54,
            ),
          ),
        ],
      ),
    );
  }
}

