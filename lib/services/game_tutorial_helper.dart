import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/game/game_session_model.dart';
import '../screens/games/game_catalog.dart';
import '../utils/pan_african_design_system.dart';

/// One-time per [GameType] tutorial overlay driven by [GameCatalog] rules.
class GameTutorialHelper {
  GameTutorialHelper._();

  static const _prefsPrefix = 'game_tutorial_v1_';

  static Future<void> maybeShowForGame(
    BuildContext context,
    GameType gameType,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefsPrefix${gameType.name}';
    if (prefs.getBool(key) == true) return;

    final catalogEntry = GameCatalog.byType[gameType];
    if (catalogEntry == null) return;

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.lgBR),
          backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          title: Row(
            children: [
              Icon(Icons.school_rounded, color: PanAfricanColors.primary, size: 28),
              SizedBox(width: PanAfricanSpacing.sm),
              Expanded(
                child: Text(
                  l10n.gameTutorialHowToPlay,
                  style: PanAfricanTypography.titleLarge(ctx),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  catalogEntry.name,
                  style: PanAfricanTypography.titleMedium(ctx).copyWith(
                    color: PanAfricanColors.primary,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  catalogEntry.description,
                  style: PanAfricanTypography.bodyMedium(ctx),
                ),
                if (catalogEntry.rules.isNotEmpty) ...[
                  SizedBox(height: PanAfricanSpacing.md),
                  ...catalogEntry.rules.map(
                    (r) => Padding(
                      padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: PanAfricanTypography.bodyLarge(ctx)),
                          Expanded(
                            child: Text(
                              r,
                              style: PanAfricanTypography.bodyMedium(ctx),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.gameTutorialGotIt),
            ),
          ],
        );
      },
    );

    await prefs.setBool(key, true);
  }
}
