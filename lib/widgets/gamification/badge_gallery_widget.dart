import 'package:flutter/material.dart' hide Badge;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';
import '../../models/badge_model.dart' show Badge;
import '../../utils/pan_african_design_system.dart';
import '../../widgets/pan_african_components.dart';
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
          padding: EdgeInsets.all(PanAfricanSpacing.sm),
          child: Text(
            showLocked 
                ? 'No badges available'
                : 'No badges unlocked yet. Keep learning!',
            style: PanAfricanTypography.bodySmall(context).copyWith(
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
        crossAxisSpacing: PanAfricanSpacing.xs,
        mainAxisSpacing: PanAfricanSpacing.xs,
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
              ? (isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight)
              : (isDark ? Colors.grey[900] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
          border: Border.all(
            color: isUnlocked
                ? PanAfricanColors.secondary
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked ? PanAfricanShadows.md : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Icon
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.xs),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? PanAfricanColors.secondary.withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getBadgeIcon(badge.category.name),
                size: 32.sp,
                color: isUnlocked
                    ? PanAfricanColors.secondary
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xxs),
            // Badge Name
            Text(
              badge.name,
              style: PanAfricanTypography.labelSmall(context).copyWith(
                color: isUnlocked
                    ? context.adaptive
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isUnlocked) ...[
              SizedBox(height: PanAfricanSpacing.xxxs),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: PanAfricanSpacing.xs,
                  vertical: PanAfricanSpacing.xxxs,
                ),
                decoration: BoxDecoration(
                  color: PanAfricanColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(PanAfricanRadius.round),
                ),
                child: Text(
                  'Unlocked',
                  style: PanAfricanTypography.labelSmall(context).copyWith(
                    color: PanAfricanColors.secondary,
                    fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
      ),
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
          borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Icon
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? PanAfricanColors.secondary.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 64.sp,
                color: isUnlocked ? PanAfricanColors.secondary : Colors.grey,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            // Badge Name
            Text(
              badge.name,
              style: PanAfricanTypography.headlineSmall(context).copyWith(
                color: context.adaptive,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            // Badge Description
            Text(
              badge.description,
              style: PanAfricanTypography.bodySmall(context).copyWith(
                color: context.adaptive54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            // Status
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.md,
                vertical: PanAfricanSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? PanAfricanColors.secondary.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(PanAfricanRadius.round),
              ),
              child: Text(
                isUnlocked ? 'Unlocked' : 'Locked',
                style: PanAfricanTypography.labelLarge(context).copyWith(
                  color: isUnlocked ? PanAfricanColors.secondary : Colors.grey,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            // Close Button
            PanAfricanButton(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: PanAfricanColors.onSecondaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}

