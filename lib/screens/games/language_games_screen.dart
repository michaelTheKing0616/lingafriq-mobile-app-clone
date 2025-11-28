import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/screens/games/word_match_game.dart';
import 'package:lingafriq/screens/games/pronunciation_game.dart';
import 'package:lingafriq/screens/games/speed_challenge_game.dart';
import 'package:sizer/sizer.dart';

/// Modern Language Games Screen - Based on Figma Make Design
class LanguageGamesScreen extends HookConsumerWidget {
  final VoidCallback? onBack;
  
  const LanguageGamesScreen({Key? key, this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = useState<String?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (selectedGame.value == 'word-match') {
      return WordMatchGame(onBack: () => selectedGame.value = null);
    }
    if (selectedGame.value == 'pronunciation') {
      return PronunciationGame(onBack: () => selectedGame.value = null);
    }
    if (selectedGame.value == 'speed-quiz') {
      return SpeedChallengeGame(onBack: () => selectedGame.value = null);
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
                        if (onBack != null)
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: onBack,
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
          // Games List
          Positioned(
            top: 25.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  _GameCard(
                    title: 'Word Match',
                    description: 'Match English words with their Swahili translations',
                    icon: Icons.track_changes_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCE1126), Color(0xFFFF6B35)],
                    ),
                    onTap: () => selectedGame.value = 'word-match',
                  ),
                  SizedBox(height: 2.h),
                  _GameCard(
                    title: 'Pronunciation Practice',
                    description: 'Listen and repeat words correctly',
                    icon: Icons.volume_up_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007A3D), Color(0xFF00A8E8)],
                    ),
                    onTap: () => selectedGame.value = 'pronunciation',
                  ),
                  SizedBox(height: 2.h),
                  _GameCard(
                    title: 'Speed Quiz',
                    description: 'Answer as many questions as possible in 60 seconds',
                    icon: Icons.bolt_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFCD116), Color(0xFFFF6B35)],
                    ),
                    onTap: () => selectedGame.value = 'speed-quiz',
                  ),
                ],
              ),
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

