import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';
import '../../models/badge_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/design_system.dart';
import '../../utils/utils.dart';

/// Material 3 compliant badge gallery widget
/// Displays all badges with unlocked badges highlighted
class BadgeGalleryWidget extends ConsumerWidget {
  final bool showLocked;
  final int crossAxisCount;
  final VoidCallback? onBadgeTap;

  const BadgeGalleryWidget({
    Key? key,
    this.showLocked = true,
    this.crossAxisCount = 3,
    this.onBadgeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider.notifier);
    final allBadges = gamification.allBadges;
    final unlockedBadges = gamification.unlockedBadges;
    final isDark = context.isDarkMode;

    final badgesToShow = showLocked 
        ? allBadges 
        : unlockedBadges;

    if (badgesToShow.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Text(
            showLocked 
                ? 'No badges available'
                : 'No badges unlocked yet. Keep learning!',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.adaptive54,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 3.h,
        childAspectRatio: 0.9,
      ),
      itemCount: badgesToShow.length,
      itemBuilder: (context, index) {
        final badge = badgesToShow[index];
        final isUnlocked = unlockedBadges.contains(badge);
        
        return _BadgeCard(
          badge: badge,
          isUnlocked: isUnlocked,
          isDark: isDark,
          onTap: () => onBadgeTap?.call(),
        );
      },
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Badge badge;
  final bool isUnlocked;
  final bool isDark;
  final VoidCallback? onTap;

  const _BadgeCard({
    required this.badge,
    required this.isUnlocked,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
              : (isDark ? Colors.grey[900] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
          border: Border.all(
            color: isUnlocked
                ? AppColors.accentGold
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked ? DesignSystem.shadowMedium : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Icon
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.accentGold.withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getBadgeIcon(badge.category),
                size: 32.sp,
                color: isUnlocked
                    ? AppColors.accentGold
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
            ),
            SizedBox(height: 1.h),
            // Badge Name
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: isUnlocked
                    ? context.adaptive
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isUnlocked) ...[
              SizedBox(height: 0.5.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                ),
                child: Text(
                  'Unlocked',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getBadgeIcon(String category) {
    switch (category.toLowerCase()) {
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'level':
        return Icons.star_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'learning':
        return Icons.school_rounded;
      case 'game':
        return Icons.sports_esports_rounded;
      default:
        return Icons.workspace_premium_rounded;
    }
  }
}

/// Badge detail dialog
class BadgeDetailDialog extends StatelessWidget {
  final Badge badge;
  final bool isUnlocked;

  const BadgeDetailDialog({
    Key? key,
    required this.badge,
    required this.isUnlocked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
      ),
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Icon
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.accentGold.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 64.sp,
                color: isUnlocked ? AppColors.accentGold : Colors.grey,
              ),
            ),
            SizedBox(height: 3.h),
            // Badge Name
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: context.adaptive,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            // Badge Description
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.adaptive54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            // Status
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.accentGold.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
              ),
              child: Text(
                isUnlocked ? 'Unlocked' : 'Locked',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? AppColors.accentGold : Colors.grey,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            // Close Button
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

