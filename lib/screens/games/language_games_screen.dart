import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/games/lazy_game_list.dart';
import 'game_router.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// Modern Language Games Screen - Based on Figma Make Design
class LanguageGamesScreen extends HookConsumerWidget {
  final VoidCallback? onBack;
  
  const LanguageGamesScreen({Key? key, this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = useState<GameType?>(null);
    final selectedLanguage = useState<String>('yoruba');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(userProvider);
    final backAction = onBack ??
        (Navigator.of(context).canPop() ? () => Navigator.of(context).pop() : null);
    
    if (selectedGame.value != null) {
      return buildGameScreen(
        gameType: selectedGame.value!,
        language: selectedLanguage.value,
        level: user?.level?.toString() ?? 'A0',
        onBack: () => selectedGame.value = null,
        ref: ref,
      );
    }
    
    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      body: Stack(
        children: [
          // Gradient Header with vibrant Pan-African colors
          Container(
            height: 30.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PanAfricanColors.ankaraPurple,
                  PanAfricanColors.kenteRed,
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(PanAfricanRadius.xxl),
                bottomRight: Radius.circular(PanAfricanRadius.xxl),
              ),
              boxShadow: PanAfricanShadows.lg,
            ),
            child: Stack(
              children: [
                // Pattern overlay for visual interest
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PatternPainter(
                      color: colorScheme.onPrimary.withOpacity(0.1),
                    ),
                  ),
                ),
                ResponsiveSafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Column(
                      children: [
                        if (backAction != null)
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back_rounded,
                              color: colorScheme.onPrimary,
                                size: 24.sp,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                backAction();
                              },
                              style: IconButton.styleFrom(
                              backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
                                shape: const CircleBorder(),
                              ),
                            ),
                          ),
                        SizedBox(height: PanAfricanSpacing.sm),
                        Container(
                          padding: EdgeInsets.all(PanAfricanSpacing.md),
                          decoration: BoxDecoration(
                            gradient: PanAfricanGradients.savannaGold,
                            shape: BoxShape.circle,
                            boxShadow: PanAfricanShadows.glowGold(0.6),
                          ),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: PanAfricanColors.neutralDarkest,
                            size: 48.sp,
                          ),
                        ),
                        SizedBox(height: PanAfricanSpacing.sm),
                        Text(
                          'Language Games',
                          style: PanAfricanTypography.headlineMedium(context, color: colorScheme.onPrimary),
                        ),
                        SizedBox(height: PanAfricanSpacing.xs),
                        Text(
                          'Learn while having fun!',
                          style: PanAfricanTypography.bodyMedium(context, color: colorScheme.onPrimary.withOpacity(0.9)),
                        ),
                        SizedBox(height: PanAfricanSpacing.sm),
                        Wrap(
                          spacing: PanAfricanSpacing.xs,
                          runSpacing: PanAfricanSpacing.xs,
                          alignment: WrapAlignment.center,
                          children: [
                            PanAfricanBadge(
                              label: '37 games',
                              color: PanAfricanColors.secondary,
                              icon: Icons.extension_rounded,
                            ),
                            PanAfricanBadge(
                              label: 'Daily XP',
                              color: PanAfricanColors.tertiary,
                              icon: Icons.local_fire_department_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Games List with Lazy Loading
          Positioned(
            top: 25.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: LazyGameList(
              selectedLanguage: selectedLanguage.value,
              onLanguageChanged: (lang) => selectedLanguage.value = lang,
              onGameSelected: (game) {
                HapticFeedback.lightImpact();
                selectedGame.value = game;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  
  _PatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    const spacing = 35.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

