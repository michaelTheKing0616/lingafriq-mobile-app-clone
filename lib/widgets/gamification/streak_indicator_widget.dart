import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/design_system.dart';
import '../../utils/utils.dart';

/// Material 3 compliant streak indicator widget
/// Shows daily streak with fire animation
class StreakIndicatorWidget extends ConsumerWidget {
  final bool compact;
  final bool showLabel;

  const StreakIndicatorWidget({
    Key? key,
    this.compact = false,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider.notifier).gamification;
    final streak = gamification.dailyStreak;
    final isDark = context.isDarkMode;

    if (compact) {
      return _buildCompact(context, streak, isDark);
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentOrange.withOpacity(0.3),
            AppColors.accentGold.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        border: Border.all(
          color: AppColors.accentOrange.withOpacity(0.5),
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
                  color: AppColors.accentOrange,
                  size: 32.sp,
                ),
              );
            },
          ),
          SizedBox(width: 3.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLabel)
                Text(
                  'Daily Streak',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: context.adaptive54,
                  ),
                ),
              Text(
                '$streak day${streak != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentOrange,
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
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.accentOrange,
            size: 18.sp,
          ),
          SizedBox(width: 2.w),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.accentOrange,
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
  const StreakMilestoneWidget({Key? key}) : super(key: key);

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
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        border: Border.all(
          color: isDark ? AppColors.stitchBorderDark : AppColors.stitchBorderLight,
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
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: context.adaptive,
                ),
              ),
              Text(
                '$nextMilestone days',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8.h,
              backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '${(nextMilestone - streak)} days to go',
            style: TextStyle(
              fontSize: 11.sp,
              color: context.adaptive54,
            ),
          ),
        ],
      ),
    );
  }
}

