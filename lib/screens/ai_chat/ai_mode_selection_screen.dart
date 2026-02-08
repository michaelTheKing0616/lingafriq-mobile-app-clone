import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/services/sound_effects_service.dart';
import 'ai_chat_screen_new.dart';

/// AI Chat — Screen 2: How would you like to learn?
/// Radial-style mode selector; modes as journeys with poetic descriptions. "Surprise Me" path.
class AIModeSelectionScreen extends ConsumerWidget {
  final String language;
  final String languageName;

  const AIModeSelectionScreen({
    Key? key,
    required this.language,
    required this.languageName,
  }) : super(key: key);

  static const List<Map<String, dynamic>> modes = [
    {
      'id': 'tutor',
      'title': 'Tutor',
      'description': 'Personalized AI tutor for all your questions',
      'poem': 'Ask anything. Learn at your pace.',
      'icon': Icons.school,
      'color': 0xFF1B7340,
    },
    {
      'id': 'translate',
      'title': 'Translation',
      'description': 'Translate text with grammar notes',
      'poem': 'Meaning first, then the words.',
      'icon': Icons.translate,
      'color': 0xFF1CB0F6,
    },
    {
      'id': 'review',
      'title': 'Review',
      'description': 'Review and practice what you\'ve learned',
      'poem': 'Return to what you know; make it stick.',
      'icon': Icons.refresh,
      'color': 0xFF9B59B6,
    },
    {
      'id': 'explain',
      'title': 'Grammar',
      'description': 'Learn grammar rules and examples',
      'poem': 'See the bones of the sentence.',
      'icon': Icons.menu_book,
      'color': 0xFF16A085,
    },
    {
      'id': 'pronunciation',
      'title': 'Pronunciation',
      'description': 'Perfect your pronunciation',
      'poem': 'Your voice, refined.',
      'icon': Icons.record_voice_over,
      'color': 0xFFEB8937,
    },
    {
      'id': 'story',
      'title': 'Stories',
      'description': 'Cultural stories with vocabulary',
      'poem': 'Stories that carry the culture.',
      'icon': Icons.auto_stories,
      'color': 0xFFC4413A,
    },
    {
      'id': 'dialogue',
      'title': 'Dialogue',
      'description': 'Practice conversations',
      'poem': 'Speak as you would in the world.',
      'icon': Icons.chat_bubble_outline,
      'color': 0xFF3498DB,
    },
    {
      'id': 'assess',
      'title': 'Assessment',
      'description': 'Test your proficiency',
      'poem': 'Know where you stand; then rise.',
      'icon': Icons.assessment,
      'color': 0xFFF7CB46,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final soundEffects = ref.watch(soundEffectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageName,
          style: PolieTypography.label(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? PolieColors.textPrimary : PolieColors.textPrimaryLight,
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    PolieColors.primary,
                    PolieColors.primaryDark,
                    PolieColors.obsidian,
                  ]
                : [
                    PolieColors.primary.withOpacity(0.92),
                    PolieColors.primaryDark.withOpacity(0.88),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: PolieSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      'How would you like to learn?',
                      style: PolieTypography.h1(context).copyWith(
                        color: isDark
                            ? PolieColors.textPrimary
                            : PolieColors.textPrimaryLight,
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
                    SizedBox(height: PolieSpacing.xs),
                    Text(
                      'Choose a journey for $languageName',
                      style: PolieTypography.bodySmall(context).copyWith(
                        color: PolieColors.textSecondary,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                    SizedBox(height: PolieSpacing.md),
                    // Surprise Me
                    _SurpriseMeButton(
                      language: language,
                      languageName: languageName,
                      isDark: isDark,
                      soundEffects: soundEffects,
                    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.9, 0.9)),
                  ],
                ),
              ),
              SizedBox(height: PolieSpacing.lg),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md),
                  itemCount: modes.length,
                  itemBuilder: (context, index) {
                    final mode = modes[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: PolieSpacing.sm),
                      child: _ModeJourneyCard(
                        mode: mode,
                        language: language,
                        languageName: languageName,
                        isDark: isDark,
                      )
                          .animate(delay: (index * 50).ms)
                          .fadeIn(duration: 300.ms)
                          .slideX(begin: 0.05, end: 0),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeJourneyCard extends StatelessWidget {
  final Map<String, dynamic> mode;
  final String language;
  final String languageName;
  final bool isDark;

  const _ModeJourneyCard({
    required this.mode,
    required this.language,
    required this.languageName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(mode['color'] as int);
    final poem = mode['poem'] as String? ?? mode['description'] as String;

    return PolieGlassCard(
      hasGlow: true,
      glowColor: color,
      padding: EdgeInsets.symmetric(
        vertical: PolieSpacing.md,
        horizontal: PolieSpacing.lg,
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            SmoothPageRoute(
              child: AIChatScreen(
                language: language,
                languageName: languageName,
                mode: mode['id'] as String,
                modeName: mode['title'] as String,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(PolieSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                mode['icon'] as IconData,
                color: color,
                size: 28.sp,
              ),
            ),
            SizedBox(width: PolieSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mode['title'] as String,
                    style: PolieTypography.label(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.xs),
                  Text(
                    poem,
                    style: PolieTypography.bodySmall(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14.sp, color: color),
          ],
        ),
      ),
    );
  }
}

class _SurpriseMeButton extends StatelessWidget {
  final String language;
  final String languageName;
  final bool isDark;
  final SoundEffectsService soundEffects;

  const _SurpriseMeButton({
    required this.language,
    required this.languageName,
    required this.isDark,
    required this.soundEffects,
  });

  @override
  Widget build(BuildContext context) {
    return PolieGlassCard(
      hasGlow: true,
      glowColor: PolieColors.goldEmber,
      padding: EdgeInsets.symmetric(
        vertical: PolieSpacing.md,
        horizontal: PolieSpacing.lg,
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          try {
            soundEffects.play(SoundEffect.celebration);
          } catch (_) {}
          final random = Random();
          final mode = AIModeSelectionScreen.modes[
              random.nextInt(AIModeSelectionScreen.modes.length)];
          Navigator.push(
            context,
            SmoothPageRoute(
              child: AIChatScreen(
                language: language,
                languageName: languageName,
                mode: mode['id'] as String,
                modeName: mode['title'] as String,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              color: PolieColors.goldEmber,
              size: 24.sp,
            ),
            SizedBox(width: PolieSpacing.sm),
            Text(
              'Surprise Me',
              style: PolieTypography.label(context).copyWith(
                color: PolieColors.goldEmber,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}