import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:sizer/sizer.dart';

/// Daily Challenges Screen - Based on Figma Make Design
class DailyChallengesScreen extends HookConsumerWidget {
  final VoidCallback? onBack;
  
  const DailyChallengesScreen({Key? key, this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyGoals = ref.watch(dailyGoalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate progress
    final completedCount = dailyGoals.goals.where((g) => g.isCompleted).length;
    final totalCount = dailyGoals.goals.length;
    final totalXP = dailyGoals.goals
        .where((g) => g.isCompleted)
        .fold(0, (sum, goal) => sum + (goal.xpReward ?? 0));
    
    return Scaffold(
      backgroundColor: isDark ? AfricanTheme.backgroundDark : AfricanTheme.backgroundLight,
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 25.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF007A3D), // Green
                  Color(0xFF00A8E8), // Blue
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    if (onBack != null)
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: onBack,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                    SizedBox(height: 2.h),
                    const Icon(
                      Icons.track_changes_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Daily Challenges',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Complete challenges to earn extra XP',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white.withOpacity(0.9),
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
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Progress Card
                  Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: isDark ? AfricanTheme.stitchCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                      boxShadow: DesignSystem.shadowLarge,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Progress',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              '$totalXP XP earned',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007A3D),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                          ),
                          child: Text(
                            '$completedCount/$totalCount',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),
                  // Challenges List
                  ...dailyGoals.goals.map((goal) {
                    final progress = goal.currentProgress / goal.targetProgress;
                    final isCompleted = goal.isCompleted;
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color: isDark ? AfricanTheme.stitchCardDark : Colors.white,
                        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                        boxShadow: DesignSystem.shadowMedium,
                        border: Border.all(
                          color: isCompleted
                              ? const Color(0xFF007A3D)
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
                                  ? const Color(0xFF007A3D)
                                  : (isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(DesignSystem.radiusL),
                            ),
                            child: Icon(
                              isCompleted ? Icons.check : Icons.track_changes_rounded,
                              color: isCompleted ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.title,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress.clamp(0.0, 1.0),
                                    backgroundColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFF007A3D),
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${goal.currentProgress}/${goal.targetProgress}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: isDark ? Colors.white70 : Colors.black54,
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
                                          '${goal.xpReward ?? 0} XP',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: isDark ? Colors.white70 : Colors.black54,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

