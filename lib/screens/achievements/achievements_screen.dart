import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/achievements_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsNotifier = ref.watch(achievementsProvider.notifier);
    final achievements = ref.watch(achievementsProvider.notifier).achievements;
    final totalXP = ref.watch(achievementsProvider.notifier).totalXP;
    final level = ref.watch(achievementsProvider.notifier).level;
    final unlockedCount = ref.watch(achievementsProvider.notifier).unlockedCount;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // XP and Level Card
            _buildXPLevelCard(context, totalXP, level, unlockedCount, achievements.length, isDark),
            SizedBox(height: 24.sp),
            
            // Achievements Grid
            Text(
              'All Achievements',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16.sp),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.sp,
                mainAxisSpacing: 12.sp,
                childAspectRatio: 0.85,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                return _buildAchievementCard(context, achievements[index], isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPLevelCard(
    BuildContext context,
    int totalXP,
    int level,
    int unlockedCount,
    int totalCount,
    bool isDark,
  ) {
    final progress = (totalXP % 100) / 100.0;
    final nextLevelXP = (level * 100);
    final currentLevelXP = ((level - 1) * 100);
    final progressToNext = totalXP - currentLevelXP;
    final progressNeeded = nextLevelXP - currentLevelXP;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryOrange,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.sp),
                    Text(
                      '$totalXP XP',
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(16.sp),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '⭐',
                    style: TextStyle(fontSize: 32.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.sp),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressNeeded > 0 ? progressToNext / progressNeeded : 1.0,
                minHeight: 12,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              '$progressToNext / $progressNeeded XP to Level ${level + 1}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            SizedBox(height: 16.sp),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('$unlockedCount', 'Unlocked', Colors.white),
                _buildStatItem('$totalCount', 'Total', Colors.white),
                _buildStatItem('${((unlockedCount / totalCount) * 100).toInt()}%', 'Complete', Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.sp),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context, achievement, bool isDark) {
    final rarityColor = _getRarityColor(achievement.rarity, isDark);
    final isUnlocked = achievement.isUnlocked;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? rarityColor : (isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5)),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: rarityColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(12.sp),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? rarityColor.withOpacity(0.2)
                    : (isDark ? const Color(0xFF2A4A35) : Colors.grey[100]),
                shape: BoxShape.circle,
              ),
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 32.sp,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
            SizedBox(height: 12.sp),
            // Name
            Text(
              achievement.name,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isUnlocked
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.sp),
            // Description
            Text(
              achievement.description,
              style: TextStyle(
                fontSize: 11.sp,
                color: isUnlocked
                    ? (isDark ? Colors.grey[400] : Colors.grey[600])
                    : (isDark ? Colors.grey[700] : Colors.grey[500]),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.sp),
            // XP Reward
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
              decoration: BoxDecoration(
                color: isUnlocked ? rarityColor.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${achievement.xpReward} XP',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? rarityColor : (isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
              ),
            ),
            if (isUnlocked && achievement.unlockedAt != null) ...[
              SizedBox(height: 4.sp),
              Text(
                'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(rarity, bool isDark) {
    switch (rarity) {
      case AchievementRarity.common:
        return isDark ? Colors.grey[400]! : Colors.grey[600]!;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return AppColors.primaryOrange;
      default:
        return AppColors.primaryGreen;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
}

