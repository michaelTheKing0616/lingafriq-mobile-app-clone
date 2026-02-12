import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Beautiful Material 3 Badge Collection Screen
class BadgeCollectionScreenMaterial3 extends HookConsumerWidget {
  const BadgeCollectionScreenMaterial3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = useState<String?>(null);
    final selectedRarity = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mock data - replace with actual provider
    final allBadges = useState<List<Map<String, dynamic>>>([]);
    final unlockedBadges = useState<Set<String>>({});

    final categories = ['All', 'Learning', 'Streak', 'Community', 'Achievement'];
    final rarities = ['All', 'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Badge Collection',
          style: PanAfricanTypography.headlineMedium(context),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: PanAfricanSpacing.md),
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.sm,
              vertical: PanAfricanSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: PanAfricanColors.secondary.withOpacity(0.2),
              borderRadius: PanAfricanRadius.roundBR,
            ),
            child: Center(
              child: Text(
                '${unlockedBadges.value.length}/${allBadges.value.length}',
                style: PanAfricanTypography.titleMedium(context, color: PanAfricanColors.secondary),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
              child: Row(
                children: [
                  ...categories.map((category) {
                    final isSelected = selectedCategory.value == category ||
                        (category == 'All' && selectedCategory.value == null);
                    return Padding(
                      padding: EdgeInsets.only(right: PanAfricanSpacing.xs),
                      child: FilterChip(
                        label: Text(
                          category,
                          style: PanAfricanTypography.labelMedium(context),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          HapticFeedback.lightImpact();
                          selectedCategory.value = selected && category != 'All' ? category : null;
                        },
                        selectedColor: PanAfricanColors.primaryContainer,
                        checkmarkColor: PanAfricanColors.primary,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Badge Grid
          Expanded(
            child: allBadges.value.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              color: PanAfricanColors.secondary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.workspace_premium_outlined,
                              size: 48.sp,
                              color: PanAfricanColors.secondary,
                            ),
                          ),
                          SizedBox(height: PanAfricanSpacing.md),
                          Text(
                            'No badges yet',
                            style: PanAfricanTypography.titleMedium(context),
                          ),
                          SizedBox(height: PanAfricanSpacing.xs),
                          Text(
                            'Complete lessons and challenges to earn badges!',
                            style: PanAfricanTypography.bodySmall(context),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : OptimizedListView.builder(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: PanAfricanSpacing.md,
                      mainAxisSpacing: PanAfricanSpacing.md,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: allBadges.value.length,
                    itemBuilder: (context, index) {
                      final badge = allBadges.value[index];
                      final isUnlocked = unlockedBadges.value.contains(badge['id']);

                      return _BadgeCard(
                        badge: badge,
                        isUnlocked: isUnlocked,
                        isDark: isDark,
                      )
                          .animate(delay: (index * 50).ms)
                          .fadeIn(duration: 300.ms)
                          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Map<String, dynamic> badge;
  final bool isUnlocked;
  final bool isDark;

  const _BadgeCard({
    required this.badge,
    required this.isUnlocked,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rarity = badge['rarity'] ?? 'common';
    final color = _getRarityColor(rarity);
    final icon = badge['icon'] ?? '🏆';
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Show badge details
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.lgBR,
          border: Border.all(
            color: isUnlocked
                ? color
                : (isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked ? PanAfricanShadows.md : PanAfricanShadows.sm,
        ),
        child: Stack(
          children: [
            // Glow effect for legendary badges
            if (isUnlocked && rarity.toLowerCase() == 'legendary')
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: PanAfricanRadius.lgBR,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        PanAfricanColors.secondary.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge icon
                  Container(
                    width: 64.w,
                    height: 64.w,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? color.withOpacity(0.15)
                          : (isDark
                              ? PanAfricanColors.surfaceContainerHighDark
                              : PanAfricanColors.surfaceContainerHighLight),
                      shape: BoxShape.circle,
                      boxShadow: isUnlocked ? PanAfricanShadows.glow(color) : null,
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: TextStyle(fontSize: 32.sp),
                      ),
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  // Badge name
                  Text(
                    badge['name'] ?? 'Badge',
                    style: PanAfricanTypography.titleSmall(
                      context,
                      color: isUnlocked ? null : PanAfricanColors.neutralMedium,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  // Rarity chip
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: PanAfricanSpacing.xs,
                      vertical: PanAfricanSpacing.xxxs,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: PanAfricanRadius.roundBR,
                    ),
                    child: Text(
                      rarity.toUpperCase(),
                      style: PanAfricanTypography.labelSmall(context, color: color),
                    ),
                  ),
                ],
              ),
            ),
            // Lock overlay
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? Theme.of(context).colorScheme.scrim : colorScheme.surface).withOpacity(0.6),
                    borderRadius: PanAfricanRadius.lgBR,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock_rounded,
                      color: PanAfricanColors.neutralMedium,
                      size: 28.sp,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return PanAfricanColors.secondary;
      case 'epic':
        return PanAfricanColors.ankaraPurple;
      case 'rare':
        return PanAfricanColors.kenteBlue;
      case 'uncommon':
        return PanAfricanColors.primary;
      default:
        return PanAfricanColors.neutralMedium;
    }
  }
}

