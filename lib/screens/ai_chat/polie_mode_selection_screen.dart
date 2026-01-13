import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_language_setup_screen.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Polie Mode Selection Screen
/// Shows all 6 Polie modes: Translation, Tutor, Roleplay, Conversation, Vocab, Review
class PolieModeSelectionScreen extends HookConsumerWidget {
  final VoidCallback? onBack;
  
  const PolieModeSelectionScreen({Key? key, this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundary(
      errorMessage: 'Mode selection is temporarily unavailable',
      onRetry: () {},
      child: _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
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
                        // Back button
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: onBack ?? () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        const Icon(
                          Icons.psychology_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Choose Your Learning Mode',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Select how you want to practice with Polie',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
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
                children: [
                  SizedBox(height: 2.h),
                  // Translation Mode
                  _ModeCard(
                    title: 'Translation',
                    description: 'Instant translations between English and African languages. Perfect for quick lookups.',
                    icon: Icons.translate_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007A3D), Color(0xFF00A8E8)],
                    ),
                    badge: 'Quick & Easy',
                    mode: PolieMode.translation,
                    onTap: () => _navigateToLanguageSelection(context, ref, PolieMode.translation),
                    isDark: isDark,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: 2.h),
                  // Tutor Mode
                  _ModeCard(
                    title: 'Tutor',
                    description: 'Practice conversations with your AI tutor. Get feedback, corrections, and explanations.',
                    icon: Icons.school_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCE1126), Color(0xFFFF6B35)],
                    ),
                    badge: 'Interactive Learning',
                    mode: PolieMode.tutor,
                    onTap: () => _navigateToLanguageSelection(context, ref, PolieMode.tutor),
                    isDark: isDark,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: 2.h),
                  // Roleplay Mode
                  _ModeCard(
                    title: 'Roleplay',
                    description: 'Practice real-world scenarios. Order food, ask for directions, have conversations.',
                    icon: Icons.theater_comedy_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9B59B6), Color(0xFFE74C3C)],
                    ),
                    badge: 'Real Scenarios',
                    mode: PolieMode.roleplay,
                    onTap: () => _navigateToLanguageSelection(context, ref, PolieMode.roleplay),
                    isDark: isDark,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: 2.h),
                  // Conversation Mode
                  _ModeCard(
                    title: 'Conversation',
                    description: 'Free-flowing conversations in your target language. Practice natural dialogue.',
                    icon: Icons.chat_bubble_outline_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3498DB), Color(0xFF2ECC71)],
                    ),
                    badge: 'Natural Dialogue',
                    mode: PolieMode.conversation,
                    onTap: () => _navigateToLanguageSelection(context, ref, PolieMode.conversation),
                    isDark: isDark,
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: 2.h),
                  // Vocab Mode
                  _ModeCard(
                    title: 'Vocabulary',
                    description: 'Learn new words, their meanings, usage, and practice with spaced repetition.',
                    icon: Icons.book_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
                    ),
                    badge: 'Word Mastery',
                    mode: PolieMode.vocab,
                    onTap: () => _navigateToLanguageSelection(context, ref, PolieMode.vocab),
                    isDark: isDark,
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: 2.h),
                  // Review Mode
                  _ModeCard(
                    title: 'Review',
                    description: 'Review previously learned words and phrases. Strengthen your memory.',
                    icon: Icons.refresh_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16A085), Color(0xFF1ABC9C)],
                    ),
                    badge: 'Memory Boost',
                    mode: PolieMode.review,
                    onTap: () => _navigateToLanguageSelection(context, ref, PolieMode.review),
                    isDark: isDark,
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLanguageSelection(BuildContext context, WidgetRef ref, PolieMode mode) async {
    // Set the mode first (this will save current chat history and load new mode's history)
    await ref.read(groqChatProvider.notifier).setMode(mode);
    
    // Navigate to language selection
    // After language is selected, it will load the scoped chat history (mode × language)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiChatLanguageSetupScreen(initialMode: mode),
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
  final PolieMode mode;
  final VoidCallback onTap;
  final bool isDark;
  
  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.badge,
    required this.mode,
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
              Icon(
                Icons.arrow_forward_ios,
                color: isDark ? Colors.white54 : Colors.black45,
                size: 16,
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

