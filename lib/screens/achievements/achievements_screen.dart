import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/achievement_model.dart';
import 'package:lingafriq/providers/achievements_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/screens/ai_chat/polie_mode_selection_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundary(
      errorMessage: 'Unable to load achievements. Please check your connection and try again.',
      onRetry: () {
        ref.invalidate(achievementsProvider);
      },
      child: _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    
    // Safely access achievements provider with error handling
    try {
      final achievementsNotifier = ref.watch(achievementsProvider.notifier);
      final achievements = achievementsNotifier.achievements;
      final totalXP = achievementsNotifier.totalXP;
      final level = achievementsNotifier.level;
      final unlockedCount = achievementsNotifier.unlockedCount;
      
      return _buildAchievementsContent(
        context: context,
        isDark: isDark,
        achievements: achievements,
        totalXP: totalXP,
        level: level,
        unlockedCount: unlockedCount,
      );
    } catch (e) {
      // Handle errors gracefully
      if (context.mounted) {
        ErrorHandler.showError(context, e);
      }
      return _buildErrorState(context, isDark);
    }
  }

  Widget _buildAchievementsContent({
    required BuildContext context,
    required bool isDark,
    required List<Achievement> achievements,
    required int totalXP,
    required int level,
    required int unlockedCount,
  }) {

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
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
                  Color(0xFFFCD116), // Gold
                  Color(0xFFFF6B35), // Orange
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Achievements',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Your rewards & badges',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white.withValues(alpha: 0.9),
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
            child: ResponsiveSafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tabs
                  DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F3527) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            tabs: const [
                              Tab(text: 'Badges'),
                              Tab(text: 'Streaks'),
                              Tab(text: 'XP'),
                            ],
                            labelColor: isDark ? Colors.white : Colors.black87,
                            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                            indicatorColor: const Color(0xFFFCD116),
                            indicatorSize: TabBarIndicatorSize.tab,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        SizedBox(
                          height: 50.h,
                          child: TabBarView(
                            children: [
                              // Badges Tab
                              _buildBadgesTab(context, achievements, isDark),
                              // Streaks Tab
                              _buildStreaksTab(context, isDark),
                              // XP Tab
                              _buildXPTab(context, totalXP, level, isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
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
            PanAfricanColors.primary,
            PanAfricanColors.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: PanAfricanColors.primary.withValues(alpha: 0.3),
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
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(16.sp),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
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
                backgroundColor: Colors.white.withValues(alpha: 0.3),
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
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context, achievement, bool isDark) {
    final rarityColor = _getRarityColor(achievement.rarity, isDark);
    final isUnlocked = achievement.isUnlocked;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showAchievementDetail(context, achievement, isDark);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
                  color: rarityColor.withValues(alpha: 0.3),
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
                    ? rarityColor.withValues(alpha: 0.2)
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
                color: isUnlocked ? rarityColor.withValues(alpha: 0.2) : Colors.transparent,
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
      ),
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement, bool isDark) {
    final rarityColor = _getRarityColor(achievement.rarity, isDark);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
        title: Row(
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 28)),
            SizedBox(width: PanAfricanSpacing.sm),
            Expanded(
              child: Text(
                achievement.name,
                style: PanAfricanTypography.titleMedium(context),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.description,
                style: PanAfricanTypography.bodyMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Text('+${achievement.xpReward} XP', style: TextStyle(color: rarityColor, fontWeight: FontWeight.bold)),
              if (achievement.isUnlocked && achievement.unlockedAt != null)
                Padding(
                  padding: EdgeInsets.only(top: PanAfricanSpacing.sm),
                  child: Text(
                    'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          PanAfricanButton(
            label: 'Practice with Polie',
            onPressed: () {
              Navigator.pop(ctx);
              if (context.mounted) {
                Navigator.push(
                  context,
                  SmoothPageRoute(child: PolieModeSelectionScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity, bool isDark) {
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
        return PanAfricanColors.tertiary;
      default:
        return PanAfricanColors.primary;
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

  Widget _buildBadgesTab(BuildContext context, List achievements, bool isDark) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64.sp,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            SizedBox(height: 16.sp),
            Text(
              'No achievements yet',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              'Complete goals to unlock achievements!',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 3.w,
        childAspectRatio: 0.9,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
            boxShadow: achievement.isUnlocked ? PanAfricanShadows.md : [],
            border: achievement.isUnlocked
                ? Border.all(color: _getRarityColor(achievement.rarity, isDark).withValues(alpha: 0.2), width: 2)
                : Border.all(
                    color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                    width: 1,
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: achievement.isUnlocked ? 1.0 : 0.4,
                child: Text(
                  achievement.icon,
                  style: TextStyle(fontSize: 32.sp),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                achievement.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: achievement.isUnlocked
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.grey[600] : Colors.grey[500]),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (achievement.isUnlocked && achievement.unlockedAt != null)
                Text(
                  '${achievement.unlockedAt!.month}/${achievement.unlockedAt!.day}',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreaksTab(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        boxShadow: PanAfricanShadows.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 64,
            color: const Color(0xFFFF6B35),
          ),
          SizedBox(height: 2.h),
          Text(
            '12 Days',
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Current Streak',
            style: TextStyle(
              fontSize: 16.sp,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 3.h),
          Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              return Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: index < 5
                      ? const Color(0xFFFF6B35)
                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: isDark
          ? PanAfricanColors.surfaceDark
          : PanAfricanColors.surfaceLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            SizedBox(height: 16.sp),
            Text(
              'Unable to load achievements',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              'Please try again later',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPTab(BuildContext context, int totalXP, int level, bool isDark) {
    final progress = (totalXP % 100) / 100.0;
    final xpToNext = 100 - (totalXP % 100);
    
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        boxShadow: PanAfricanShadows.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 64,
            color: PanAfricanColors.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            totalXP.toString(),
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Total XP',
            style: TextStyle(
              fontSize: 16.sp,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 3.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
              minHeight: 12,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '$xpToNext XP to Level ${level + 1}',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

