import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AI Chat Select Screen - Based on Figma Make Design
/// Allows users to choose between Translator Mode and Tutor Mode
class AiChatSelectScreen extends HookConsumerWidget {
  final VoidCallback? onBack;
  
  const AiChatSelectScreen({Key? key, this.onBack}) : super(key: key);

  void _showLanguageSelector(BuildContext context, WidgetRef ref, PolieMode mode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Supported African languages for AI chat
    final languages = [
      {'name': 'Yoruba', 'flag': '🇳🇬', 'code': 'yo'},
      {'name': 'Hausa', 'flag': '🇳🇬', 'code': 'ha'},
      {'name': 'Igbo', 'flag': '🇳🇬', 'code': 'ig'},
      {'name': 'Swahili', 'flag': '🇰🇪', 'code': 'sw'},
      {'name': 'Zulu', 'flag': '🇿🇦', 'code': 'zu'},
      {'name': 'Xhosa', 'flag': '🇿🇦', 'code': 'xh'},
      {'name': 'Amharic', 'flag': '🇪🇹', 'code': 'am'},
      {'name': 'Twi', 'flag': '🇬🇭', 'code': 'tw'},
      {'name': 'Afrikaans', 'flag': '🇿🇦', 'code': 'af'},
      {'name': 'Nigerian Pidgin', 'flag': '🇳🇬', 'code': 'pcm'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F3527) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B2CBF), Color(0xFFCE1126)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            mode == PolieMode.translation 
                                ? 'Select Language to Translate'
                                : 'Select Language to Learn',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      mode == PolieMode.translation
                          ? 'Choose the language you want to translate to/from'
                          : 'Choose the language you want to practice',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // Language List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(4.w),
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 2.h),
                    color: isDark ? const Color(0xFF2A4034) : Colors.white,
                    elevation: 2,
                    child: ListTile(
                      leading: Text(
                        lang['flag']!,
                        style: TextStyle(fontSize: 32.sp),
                      ),
                      title: Text(
                        lang['name']!,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        mode == PolieMode.translation
                            ? 'English ↔ ${lang['name']}'
                            : 'Learn ${lang['name']} with Polie',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isDark ? Colors.white54 : Colors.black45,
                        size: 16,
                      ),
                      onTap: () {
                        // Set language and navigate to chat
                        ref.read(groqChatProvider.notifier).setLanguageDirection(
                          'English',
                          lang['name']!,
                        );
                        Navigator.pop(context); // Close language selector
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiChatScreen(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                        // Always show back button
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
                      // Set translator mode and show language selector
                      ref.read(groqChatProvider.notifier).setMode(PolieMode.translation);
                      _showLanguageSelector(context, ref, PolieMode.translation);
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
                      // Set tutor mode and show language selector
                      ref.read(groqChatProvider.notifier).setMode(PolieMode.tutor);
                      _showLanguageSelector(context, ref, PolieMode.tutor);
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

