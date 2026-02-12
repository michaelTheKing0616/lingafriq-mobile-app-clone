import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import '../../utils/error_handler.dart';
import '../../utils/integration_helpers.dart';
import '../../utils/performance_utils.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/gamification_services_provider.dart';
import '../../providers/socket_provider.dart';
import '../../models/badge_model.dart';
import '../../services/gamification/badges_service.dart';
import '../../widgets/error_boundary.dart';
import '../../widgets/empty_state_widget.dart';

/// Screen displaying all badges with unlock status
class BadgeCollectionScreen extends ConsumerStatefulWidget {
  const BadgeCollectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BadgeCollectionScreen> createState() => _BadgeCollectionScreenState();
}

class _BadgeCollectionScreenState extends ConsumerState<BadgeCollectionScreen> {
  BadgeCategory? _selectedCategory;
  BadgeRarity? _selectedRarity;

  @override
  Widget build(BuildContext context) {
    final gamification = ref.watch(gamificationProvider.notifier);
    final allBadges = gamification.allBadges;
    final unlockedBadges = gamification.unlockedBadges;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter badges
    var filteredBadges = allBadges;
    if (_selectedCategory != null) {
      filteredBadges = filteredBadges.where((b) => b.category == _selectedCategory).toList();
    }
    if (_selectedRarity != null) {
      filteredBadges = filteredBadges.where((b) => b.rarity == _selectedRarity).toList();
    }

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
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.sm,
              vertical: PanAfricanSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: PanAfricanColors.secondary.withOpacity(0.2),
              borderRadius: PanAfricanRadius.roundBR,
            ),
            child: Text(
              '${unlockedBadges.length}/${allBadges.length}',
              style: PanAfricanTypography.titleMedium(context, color: PanAfricanColors.secondary),
            ),
          ),
          SizedBox(width: PanAfricanSpacing.md),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'All',
                  selected: _selectedCategory == null && _selectedRarity == null,
                  onSelected: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedCategory = null;
                      _selectedRarity = null;
                    });
                  },
                ),
                SizedBox(width: PanAfricanSpacing.xs),
                ...BadgeCategory.values.map((category) => Padding(
                      padding: EdgeInsets.only(right: PanAfricanSpacing.xs),
                      child: _buildFilterChip(
                        context,
                        label: category.name.toUpperCase(),
                        selected: _selectedCategory == category,
                        onSelected: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedCategory = category;
                            _selectedRarity = null;
                          });
                        },
                      ),
                    )),
                SizedBox(width: PanAfricanSpacing.xs),
                ...BadgeRarity.values.map((rarity) => Padding(
                      padding: EdgeInsets.only(right: PanAfricanSpacing.xs),
                      child: _buildFilterChip(
                        context,
                        label: rarity.name.toUpperCase(),
                        selected: _selectedRarity == rarity,
                        onSelected: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedRarity = rarity;
                            _selectedCategory = null;
                          });
                        },
                      ),
                    )),
              ],
            ),
          ),
          // Badge grid
          Expanded(
            child: filteredBadges.isEmpty
                ? AppEmptyState(
                    icon: Icons.emoji_events_rounded,
                    title: 'No badges yet',
                    subtitle: 'Complete lessons and challenges to earn badges',
                  )
                : OptimizedListView.builder(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: PanAfricanSpacing.md,
                mainAxisSpacing: PanAfricanSpacing.md,
                childAspectRatio: 0.85,
              ),
              itemCount: filteredBadges.length,
              itemBuilder: (context, index) {
                final badge = filteredBadges[index];
                final isUnlocked = unlockedBadges.contains(badge);
                return _BadgeCard(
                  badge: badge,
                  isUnlocked: isUnlocked,
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: PanAfricanTypography.labelMedium(context),
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: PanAfricanColors.primaryContainer,
      checkmarkColor: PanAfricanColors.primary,
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Badge badge;
  final bool isUnlocked;
  final bool isDark;

  const _BadgeCard({
    required this.badge,
    required this.isUnlocked,
    required this.isDark,
  });

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return PanAfricanColors.neutralMedium;
      case BadgeRarity.uncommon:
        return PanAfricanColors.primary;
      case BadgeRarity.rare:
        return PanAfricanColors.kenteBlue;
      case BadgeRarity.epic:
        return PanAfricanColors.ankaraPurple;
      case BadgeRarity.legendary:
        return PanAfricanColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor(badge.rarity);
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
            color: isUnlocked ? rarityColor : (isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked ? PanAfricanShadows.md : PanAfricanShadows.sm,
        ),
        child: Stack(
          children: [
            if (isUnlocked && badge.rarity == BadgeRarity.legendary)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: PanAfricanRadius.lgBR,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        PanAfricanColors.secondary.withOpacity(0.1),
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
                          ? rarityColor.withOpacity(0.15)
                          : (isDark ? PanAfricanColors.surfaceContainerHighDark : PanAfricanColors.surfaceContainerHighLight),
                      shape: BoxShape.circle,
                      boxShadow: isUnlocked ? PanAfricanShadows.glow(rarityColor) : null,
                    ),
                    child: Center(
                      child: Text(
                        badge.icon,
                        style: TextStyle(fontSize: 32.sp),
                      ),
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  // Badge name
                  Text(
                    badge.name,
                    style: PanAfricanTypography.titleSmall(
                      context,
                      color: isUnlocked ? null : PanAfricanColors.neutralMedium,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  // Rarity indicator
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: PanAfricanSpacing.xs,
                      vertical: PanAfricanSpacing.xxxs,
                    ),
                    decoration: BoxDecoration(
                      color: rarityColor.withOpacity(0.2),
                      borderRadius: PanAfricanRadius.roundBR,
                    ),
                    child: Text(
                      badge.rarity.name.toUpperCase(),
                      style: PanAfricanTypography.labelSmall(context, color: rarityColor),
                    ),
                  ),
                ],
              ),
            ),
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
}

