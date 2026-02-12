import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../utils/error_handler.dart';
import '../../utils/integration_helpers.dart';
import '../../utils/performance_utils.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// Daily Challenges Screen - Based on Figma Make Design
class DailyChallengesScreen extends HookConsumerWidget {
  final VoidCallback? onBack;

  const DailyChallengesScreen({Key? key, this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyGoals = ref.read(dailyGoalsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate progress
    final completedCount = dailyGoals.goals.where((g) => g.completed).length;
    final totalCount = dailyGoals.goals.length;
    final totalXP = dailyGoals.goals
        .where((g) => g.completed)
        .fold(0, (sum, goal) => sum + _getXpReward(goal.type));

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 25.h,
            decoration: BoxDecoration(
              gradient: PanAfricanGradients.forest,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(PanAfricanRadius.xxl),
                bottomRight: Radius.circular(PanAfricanRadius.xxl),
              ),
              boxShadow: PanAfricanShadows.lg,
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Column(
                  children: [
                    if (onBack != null)
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: onBack,
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                    SizedBox(height: 2.h),
                    Icon(
                      Icons.track_changes_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 64,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Daily Challenges',
                      style: PanAfricanTypography.headlineLarge(context).copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Complete challenges to earn extra XP',
                      style: PanAfricanTypography.bodyMedium(context).copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            top: 22.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                children: [
                  if (dailyGoals.goals.isEmpty)
                    const PanAfricanEmptyState(
                      icon: Icons.track_changes_rounded,
                      title: 'No challenges yet',
                      description: 'Check back later for your daily goals.',
                    )
                  else ...[
                  // Progress Card
                  Container(
                    padding: EdgeInsets.all(PanAfricanSpacing.lg),
                    decoration: BoxDecoration(
                      color:
                          isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                      borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
                      boxShadow: PanAfricanShadows.lg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Progress',
                              style: PanAfricanTypography.titleMedium(context).copyWith(
                                color: isDark
                                    ? PanAfricanColors.textPrimaryDark
                                    : PanAfricanColors.textPrimaryLight,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              '$totalXP XP earned',
                              style: PanAfricanTypography.bodySmall(context).copyWith(
                                color: isDark
                                    ? PanAfricanColors.textSecondaryDark
                                    : PanAfricanColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: PanAfricanSpacing.md,
                            vertical: PanAfricanSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: PanAfricanColors.primary,
                            borderRadius: BorderRadius.circular(PanAfricanRadius.round),
                          ),
                          child: Text(
                            '$completedCount/$totalCount',
                            style: PanAfricanTypography.labelLarge(context).copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),
                  // Challenges List
                  ...dailyGoals.goals.map((goal) {
                    final progress = goal.target > 0 ? (goal.current / goal.target).clamp(0.0, 1.0) : 0.0;
                    final isCompleted = goal.completed;

                    return Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      padding: EdgeInsets.all(PanAfricanSpacing.lg),
                      decoration: BoxDecoration(
                        color:
                            isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
                        boxShadow: PanAfricanShadows.md,
                        border: Border.all(
                          color: isCompleted
                              ? PanAfricanColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? PanAfricanColors.primary
                                  : (isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                            ),
                            child: Icon(
                              isCompleted ? Icons.check : Icons.track_changes_rounded,
                              color: isCompleted
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              size: 20,
                            ),
                          ),
                          SizedBox(width: PanAfricanSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGoalTitle(goal.type),
                                  style: PanAfricanTypography.bodyLarge(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? PanAfricanColors.textPrimaryDark
                                        : PanAfricanColors.textPrimaryLight,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(PanAfricanRadius.xs),
                                  child: LinearProgressIndicator(
                                    value: progress.clamp(0.0, 1.0),
                                    backgroundColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isCompleted
                                          ? PanAfricanColors.primary
                                          : PanAfricanColors.secondary,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${goal.current}/${goal.target}',
                                      style: PanAfricanTypography.labelSmall(context).copyWith(
                                        color: isDark
                                            ? PanAfricanColors.textSecondaryDark
                                            : PanAfricanColors.textSecondaryLight,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFFCD116),
                                          size: 16,
                                        ),
                                        SizedBox(width: 0.5.w),
                                        Text(
                                          '${_getXpReward(goal.type)} XP',
                                          style: PanAfricanTypography.labelSmall(context).copyWith(
                                            color: isDark
                                                ? PanAfricanColors.textSecondaryDark
                                                : PanAfricanColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGoalTitle(String type) {
    switch (type) {
      case 'lessons':
        return 'Complete Lessons';
      case 'quizzes':
        return 'Take Quizzes';
      case 'games':
        return 'Play Games';
      case 'chat_minutes':
        return 'Chat with Native Speakers';
      case 'words_learned':
        return 'Learn New Words';
      default:
        return type.replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  int _getXpReward(String type) {
    // Default XP rewards based on goal type
    switch (type) {
      case 'lessons':
        return 50;
      case 'quizzes':
        return 30;
      case 'games':
        return 40;
      case 'chat_minutes':
        return 25;
      case 'words_learned':
        return 20;
      default:
        return 10;
    }
  }
}
