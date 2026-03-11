import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/pan_african_design_system.dart';

class GameOnboardingOverlay extends StatelessWidget {
  final String gameType;
  final String title;
  final List<String> rules;
  final VoidCallback onDismiss;

  const GameOnboardingOverlay({
    super.key,
    required this.gameType,
    required this.title,
    required this.rules,
    required this.onDismiss,
  });

  static String _prefKey(String gameType) => 'game_onboarding_${gameType}_seen';

  static Future<bool> shouldShow(String gameType) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefKey(gameType)) ?? false);
  }

  static Future<void> markSeen(String gameType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(gameType), true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xl),
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            borderRadius: PanAfricanRadius.lgBR,
            boxShadow: PanAfricanShadows.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_esports_rounded,
                size: 40.sp,
                color: PanAfricanColors.primary,
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                title,
                style: PanAfricanTypography.titleLarge(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: PanAfricanSpacing.md),
              ...rules.map((rule) => Padding(
                    padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ',
                            style: PanAfricanTypography.bodyMedium(context,
                                color: PanAfricanColors.primary)),
                        Expanded(
                          child: Text(
                            rule,
                            style: PanAfricanTypography.bodyMedium(context),
                          ),
                        ),
                      ],
                    ),
                  )),
              SizedBox(height: PanAfricanSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    markSeen(gameType);
                    onDismiss();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: PanAfricanColors.primary,
                    padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: PanAfricanRadius.mdBR,
                    ),
                  ),
                  child: Text(
                    'Got it!',
                    style: PanAfricanTypography.labelLarge(context,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
