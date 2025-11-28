import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AI Chat Select Screen - Based on Figma Make Design
/// Allows users to choose between Translator Mode and Tutor Mode
class AiChatSelectScreen extends HookConsumerWidget {
  final VoidCallback? onBack;
  
  const AiChatSelectScreen({Key? key, this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AfricanTheme.backgroundDark : AfricanTheme.backgroundLight,
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 30.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7B2CBF), // Purple
                  Color(0xFFCE1126), // Red
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
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'AI Language Assistant',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Choose how you\'d like to practice',
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
          // Mode Selection Cards
          Positioned(
            top: 25.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 2.h),
                  // Translator Mode Card
                  _ModeCard(
                    title: 'Translator Mode',
                    description: 'Instant translations between English and Swahili. Perfect for quick lookups and understanding phrases.',
                    icon: Icons.translate_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007A3D), Color(0xFF00A8E8)],
                    ),
                    badge: 'Quick & Easy',
                    onTap: () {
                      // Set translator mode and navigate
                      ref.read(groqChatProvider.notifier).setMode(PolieMode.translation);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AiChatScreen(),
                        ),
                      );
                    },
                    isDark: isDark,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: 3.h),
                  // Tutor Mode Card
                  _ModeCard(
                    title: 'Tutor Mode',
                    description: 'Practice conversations with your AI tutor. Get feedback, corrections, and explanations to improve your skills.',
                    icon: Icons.school_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCE1126), Color(0xFFFF6B35)],
                    ),
                    badge: 'Interactive Learning',
                    onTap: () {
                      // Set tutor mode and navigate
                      ref.read(groqChatProvider.notifier).setMode(PolieMode.tutor);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AiChatScreen(),
                        ),
                      );
                    },
                    isDark: isDark,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final String badge;
  final VoidCallback onTap;
  final bool isDark;
  
  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.badge,
    required this.onTap,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        child: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: isDark ? AfricanTheme.stitchCardDark : Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
            boxShadow: DesignSystem.shadowLarge,
            border: Border.all(
              color: isDark ? AfricanTheme.stitchBorderDark : Colors.transparent,
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
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: gradient.colors.first.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: gradient.colors.first,
                          fontWeight: FontWeight.w600,
                        ),
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

