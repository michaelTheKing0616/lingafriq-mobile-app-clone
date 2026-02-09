import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen.dart';
import 'package:lingafriq/screens/ai_chat/polie_mode_selection_screen.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AI Chat Select Screen - Entry point for Polie
/// Navigates to mode selection screen with all 6 modes
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
          color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(PolieRadius.xl)),
          boxShadow: PolieElevation.level3(context),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(PolieSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [PolieColors.royalAmethyst, PolieColors.goldEmber],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(PolieRadius.xl)),
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
                            style: PolieTypography.h2(context).copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: PolieSpacing.xl), // Balance the back button
                      ],
                    ),
                    SizedBox(height: PolieSpacing.xs),
                    Text(
                      mode == PolieMode.translation
                          ? 'Choose the language you want to translate to/from'
                          : 'Choose the language you want to practice',
                      style: PolieTypography.bodySmall(context).copyWith(
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
                padding: EdgeInsets.all(PolieSpacing.lg),
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: PolieSpacing.sm),
                    decoration: BoxDecoration(
                      color: isDark ? PolieColors.surfaceGlassDark : PolieColors.surfaceGlass,
                      borderRadius: BorderRadius.circular(PolieRadius.lg),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.06),
                      ),
                      boxShadow: PolieElevation.level1(context),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: PolieSpacing.md,
                        vertical: PolieSpacing.sm,
                      ),
                      leading: Text(
                        lang['flag']!,
                        style: TextStyle(fontSize: 32.sp),
                      ),
                      title: Text(
                        lang['name']!,
                        style: PolieTypography.body(context).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        mode == PolieMode.translation
                            ? 'English ↔ ${lang['name']}'
                            : 'Learn ${lang['name']} with Polie',
                        style: PolieTypography.bodySmall(context),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: isDark ? PolieColors.textSecondary : PolieColors.textSecondaryLight,
                        size: 16,
                      ),
                      onTap: () async {
                        // Atomically set mode + language for correct history key scoping
                        await ref.read(groqChatProvider.notifier).setModeAndLanguage(
                          mode: mode,
                          targetLanguage: lang['name']!,
                          sourceLanguage: 'English',
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context); // Close language selector
                        Navigator.push(
                          context,
                          SmoothPageRoute(
                            child: const AiChatScreen(),
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
    // Simply navigate to the mode selection screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(
          child: PolieModeSelectionScreen(onBack: onBack),
        ),
      );
    });
    
    // Show loading while transitioning
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? PolieColors.obsidian 
          : PolieColors.surfaceContainerLight,
      body: const Center(
        child: CircularProgressIndicator(),
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
        borderRadius: BorderRadius.circular(PolieRadius.xl),
        child: Container(
          padding: EdgeInsets.all(PolieSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
            borderRadius: BorderRadius.circular(PolieRadius.xl),
            boxShadow: PolieElevation.level2(context),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(PolieSpacing.md),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(PolieRadius.lg),
                  boxShadow: PolieElevation.level1(context),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              SizedBox(width: PolieSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: PolieTypography.h2(context),
                    ),
                    SizedBox(height: PolieSpacing.xs),
                    Text(
                      description,
                      style: PolieTypography.bodySmall(context),
                    ),
                    SizedBox(height: PolieSpacing.xs),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: PolieSpacing.sm,
                        vertical: PolieSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: gradient.colors.first.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(PolieRadius.pill),
                      ),
                      child: Text(
                        badge,
                        style: PolieTypography.label(context).copyWith(
                          color: gradient.colors.first,
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

