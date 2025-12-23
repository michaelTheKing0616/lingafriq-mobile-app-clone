import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
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
        title: Text('Badge Collection'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: PanAfricanSpacing.md),
            child: Center(
              child: Text(
                '${unlockedBadges.value.length}/${allBadges.value.length}',
                style: PanAfricanTypography.titleMedium(context),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: Column(
          children: [
            // Filters
            Container(
              padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
                child: Row(
                  children: [
                    ...categories.map((category) {
                      final isSelected = selectedCategory.value == category ||
                          (category == 'All' && selectedCategory.value == null);
                      return Padding(
                        padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            selectedCategory.value = selected && category != 'All' ? category : null;
                            HapticFeedback.lightImpact();
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            size: 64.sp,
                            color: PanAfricanColors.neutralMedium,
                          ),
                          SizedBox(height: PanAfricanSpacing.md),
                          Text(
                            'No badges yet',
                            style: PanAfricanTypography.bodyLarge(context),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(PanAfricanSpacing.lg),
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
                            .scale(begin: Offset(0.9, 0.9), end: Offset(1, 1));
                      },
                    ),
            ),
          ],
        ),
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

    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      elevation: isUnlocked ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        side: isUnlocked
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? color.withOpacity(0.1)
                      : PanAfricanColors.neutralLight.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUnlocked ? Icons.workspace_premium : Icons.lock,
                  size: 48.sp,
                  color: isUnlocked ? color : PanAfricanColors.neutralMedium,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                badge['name'] ?? 'Badge',
                style: PanAfricanTypography.titleSmall(context),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isUnlocked) ...[
                SizedBox(height: PanAfricanSpacing.xs),
                Chip(
                  label: Text(
                    rarity.toUpperCase(),
                    style: PanAfricanTypography.labelSmall(context),
                  ),
                  backgroundColor: color.withOpacity(0.2),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),
          if (!isUnlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                ),
                child: Center(
                  child: Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 32.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return PanAfricanColors.secondary;
      case 'epic':
        return PanAfricanColors.kenteRed;
      case 'rare':
        return PanAfricanColors.kenteBlue;
      case 'uncommon':
        return PanAfricanColors.primary;
      default:
        return PanAfricanColors.neutralMedium;
    }
  }
}

