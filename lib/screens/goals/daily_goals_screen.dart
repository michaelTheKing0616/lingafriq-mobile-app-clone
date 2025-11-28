import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DailyGoalsScreen extends ConsumerWidget {
  const DailyGoalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsNotifier = ref.watch(dailyGoalsProvider.notifier);
    final goals = ref.watch(dailyGoalsProvider.notifier).goals;
    final streak = ref.watch(dailyGoalsProvider.notifier).currentStreak;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Daily Goals'),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak Card - Material 3 Design
            _buildStreakCard(context, streak, isDark),
            SizedBox(height: 24.sp),
            
            // Daily Goals Title
            Text(
              'Today\'s Goals',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16.sp),
            
            // Goals List
            ...goals.map((goal) => _buildGoalCard(context, goal, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, int streak, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Row(
          children: [
            // Fire Icon
            Container(
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 32.sp),
              ),
            ),
            SizedBox(width: 16.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak Day Streak',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    streak > 0 
                        ? 'Keep it up! You\'re on fire! 🔥'
                        : 'Start your learning journey today!',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, goal, bool isDark) {
    final icon = _getGoalIcon(goal.type);
    final title = _getGoalTitle(goal.type);
    final progress = goal.progress;
    final isCompleted = goal.completed;

    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon Container
                Container(
                  padding: EdgeInsets.all(12.sp),
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? AppColors.primaryGreen.withOpacity(0.2)
                        : (isDark ? const Color(0xFF2A4A35) : Colors.grey[100]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    icon,
                    style: TextStyle(fontSize: 24.sp),
                  ),
                ),
                SizedBox(width: 16.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.sp),
                      Text(
                        '${goal.current} / ${goal.target}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '✓ Done',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.sp),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: isDark ? const Color(0xFF2A4A35) : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppColors.primaryGreen : AppColors.primaryOrange,
                ),
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              '${(progress * 100).toInt()}% complete',
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGoalIcon(String type) {
    switch (type) {
      case 'lessons':
        return '📚';
      case 'quizzes':
        return '🎯';
      case 'games':
        return '🎮';
      case 'chat_minutes':
        return '💬';
      case 'words_learned':
        return '📝';
      default:
        return '✅';
    }
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
        return 'Chat with Polie';
      case 'words_learned':
        return 'Learn Words';
      default:
        return 'Goal';
    }
  }
}

