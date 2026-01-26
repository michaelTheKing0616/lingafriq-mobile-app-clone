import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/screens/games/word_match_audio_game.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/services/lazy_game_loader.dart';
import 'package:lingafriq/screens/games/lazy_game_list.dart';
import 'language_games_screen_components.dart';
import 'game_router.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Modern Language Games Screen - Based on Figma Make Design
class LanguageGamesScreen extends HookConsumerWidget {
  final VoidCallback? onBack;
  
  const LanguageGamesScreen({Key? key, this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = useState<GameType?>(null);
    final selectedLanguage = useState<String>('yoruba');
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: isDark ? AfricanTheme.backgroundDark : AfricanTheme.backgroundLight,
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 30.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF7B2CBF), // Purple
                  const Color(0xFFCE1126), // Red
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Pattern overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PatternPainter(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        if (backAction != null)
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: backAction,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                shape: const CircleBorder(),
                              ),
                            ),
                          ),
                        SizedBox(height: 2.h),
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Language Games',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Learn while having fun!',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
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
              onGameSelected: (game) => selectedGame.value = game,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  
  const _GameCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        child: Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: isDark ? AfricanTheme.backgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
            boxShadow: DesignSystem.shadowLarge,
            border: Border.all(
              color: isDark ? AfricanTheme.stitchBorderDark : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusL),
                  boxShadow: DesignSystem.shadowMedium,
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

