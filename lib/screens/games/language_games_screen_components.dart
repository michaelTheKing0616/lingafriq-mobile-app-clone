import 'package:flutter/material.dart';
import '../../models/game/game_session_model.dart';
import '../../utils/games_prefetch_language.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/pan_african_components.dart';
import 'game_catalog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Language Selector Widget
class LanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final Function(String) onLanguageChanged;

  const LanguageSelector({super.key, 
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        border: Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Language',
            style: PanAfricanTypography.titleSmall(context),
          ),
          SizedBox(height: PanAfricanSpacing.xs),
          Wrap(
            spacing: PanAfricanSpacing.xs,
            runSpacing: PanAfricanSpacing.xs,
            children: kGamesHubLanguageSlugs.map((lang) {
              final isSelected = selectedLanguage == lang;
              return PanAfricanChip(
                label: lang.toUpperCase(),
                selected: isSelected,
                onSelected: () => onLanguageChanged(lang),
                backgroundColor: isSelected
                    ? PanAfricanColors.primaryContainer
                    : (isDark
                        ? PanAfricanColors.surfaceContainerHighDark
                        : PanAfricanColors.surfaceContainerHighLight),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Game Section Widget
class GameSection extends StatelessWidget {
  final String title;
  final List<GameType> games;
  final Function(GameType) onGameSelected;

  const GameSection({super.key, 
    required this.title,
    required this.games,
    required this.onGameSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
          child: Text(
            title,
            style: PanAfricanTypography.titleLarge(context),
          ),
        ),
        ...games.map((game) => Padding(
              padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
              child: _GameCard(
                title: game.displayName,
                description: _getGameDescription(game),
                icon: _getGameIcon(game),
                gradient: _getGameGradient(game),
                onTap: () => onGameSelected(game),
                isAvailable: _isGameReady(game),
              ),
            )),
      ],
    );
  }

  String _getGameDescription(GameType game) {
    return GameCatalog.byType[game]?.description ?? 'Language game mode';
  }

  IconData _getGameIcon(GameType game) {
    return GameCatalog.byType[game]?.icon ?? Icons.sports_esports_rounded;
  }

  LinearGradient _getGameGradient(GameType game) {
    // Generate gradients based on game type
    final gradients = [
      const LinearGradient(colors: [Color(0xFFCE1126), Color(0xFFFF6B35)]),
      const LinearGradient(colors: [Color(0xFF007A3D), Color(0xFF00A8E8)]),
      const LinearGradient(colors: [Color(0xFFFCD116), Color(0xFFFF6B35)]),
      const LinearGradient(colors: [Color(0xFF7B2CBF), Color(0xFFCE1126)]),
      const LinearGradient(colors: [Color(0xFF00A8E8), Color(0xFF007A3D)]),
    ];
    return gradients[game.index % gradients.length];
  }

  bool _isGameReady(GameType game) {
    // All games listed are routable via `game_router.dart`.
    // If a game isn't available at runtime (assets/network/etc.), it should fail with a user-friendly
    // in-game error state instead of being hidden/disabled at the catalog level.
    return true;
  }
}

/// Extended Game Card with availability indicator
class _GameCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool isAvailable;

  const _GameCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.isAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight;
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.6,
      child: PanAfricanCard(
        onTap: isAvailable ? onTap : null,
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        backgroundColor:
            isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        hasHoverEffect: true,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.sm),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                boxShadow: PanAfricanShadows.sm,
                border: Border.all(color: borderColor.withOpacity(0.2)),
              ),
              child: Icon(icon, color: colorScheme.onPrimary, size: 28.sp),
            ),
            SizedBox(width: PanAfricanSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: PanAfricanTypography.titleMedium(context),
                        ),
                      ),
                      PanAfricanBadge(
                        label: isAvailable ? 'READY' : 'SOON',
                        color: isAvailable
                            ? PanAfricanColors.success
                            : PanAfricanColors.warning,
                        icon: isAvailable
                            ? Icons.bolt_rounded
                            : Icons.hourglass_bottom_rounded,
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    description,
                    style: PanAfricanTypography.bodySmall(context).copyWith(
                      color: isDark
                          ? PanAfricanColors.textSecondaryDark
                          : PanAfricanColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: PanAfricanSpacing.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.sp,
              color: isDark
                  ? PanAfricanColors.textSecondaryDark
                  : PanAfricanColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

