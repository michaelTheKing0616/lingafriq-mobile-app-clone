import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Widget to Display Quality Badges on UGC Content
class UGCQualityBadgesWidget extends StatelessWidget {
  final List<String> badges;
  final bool isDark;

  const UGCQualityBadgesWidget({
    super.key,
    required this.badges,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return SizedBox.shrink();

    return Wrap(
      spacing: PanAfricanSpacing.xs,
      runSpacing: PanAfricanSpacing.xs,
      children: badges.map((badge) {
        return _QualityBadge(
          badge: badge,
          isDark: isDark,
        );
      }).toList(),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  final String badge;
  final bool isDark;

  const _QualityBadge({
    required this.badge,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final badgeData = _getBadgeData(badge);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm,
        vertical: PanAfricanSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: badgeData['color'].withOpacity(0.2),
        borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
        border: Border.all(
          color: badgeData['color'],
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeData['icon'] as IconData,
            size: 14.sp,
            color: badgeData['color'] as Color,
          ),
          SizedBox(width: PanAfricanSpacing.xxs),
          Text(
            badgeData['label'] as String,
            style: PanAfricanTypography.labelSmall(context).copyWith(
              color: badgeData['color'] as Color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getBadgeData(String badge) {
    switch (badge.toLowerCase()) {
      case 'native_speaker_verified':
        return {
          'label': 'Native Verified',
          'icon': Icons.verified_user,
          'color': PanAfricanColors.success,
        };
      case 'grammatically_perfect':
        return {
          'label': 'Grammar Perfect',
          'icon': Icons.check_circle,
          'color': PanAfricanColors.primary,
        };
      case 'culturally_authentic':
        return {
          'label': 'Culturally Authentic',
          'icon': Icons.public,
          'color': PanAfricanColors.kenteRed,
        };
      case 'canonical_form':
        return {
          'label': 'Canonical',
          'icon': Icons.book,
          'color': PanAfricanColors.kenteBlue,
        };
      case 'expert_reviewed':
        return {
          'label': 'Expert Reviewed',
          'icon': Icons.school,
          'color': PanAfricanColors.secondary,
        };
      case 'community_favorite':
        return {
          'label': 'Community Favorite',
          'icon': Icons.favorite,
          'color': PanAfricanColors.tertiary,
        };
      default:
        return {
          'label': badge,
          'icon': Icons.star,
          'color': PanAfricanColors.neutralMedium,
        };
    }
  }
}

/// Extension to easily add badges to content cards
extension UGCBadgeExtension on Widget {
  Widget withQualityBadges(List<String> badges, {bool isDark = false}) {
    return Stack(
      children: [
        this,
        if (badges.isNotEmpty)
          Positioned(
            top: PanAfricanSpacing.sm,
            right: PanAfricanSpacing.sm,
            child: UGCQualityBadgesWidget(
              badges: badges,
              isDark: isDark,
            ),
          ),
      ],
    );
  }
}

