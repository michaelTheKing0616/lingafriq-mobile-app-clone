import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_language_setup_screen.dart';
import 'package:lingafriq/screens/ai_chat/roleplay_scenario_selection_screen.dart';
import 'package:lingafriq/screens/personalities/personality_selection_screen.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

/// Polie Tutor — vertical mode carousel. Afro-futurist, cinematic.
/// Each mode opens into a full-bleed immersive workspace.
class PolieModeSelectionScreen extends ConsumerWidget {
  final VoidCallback? onBack;

  const PolieModeSelectionScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundary(
      errorMessage: 'Unable to load mode selection. Please try again.',
      onRetry: () {},
      child: _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? PolieColors.textPrimary : PolieColors.textPrimaryLight;
    final textSecondary =
        isDark ? PolieColors.textSecondary : PolieColors.textSecondaryLight;

    final modes = [
      _ModeData(
        title: 'Translation',
        description: 'Meaning-first, culturally fluent. Or literal word-by-word.',
        icon: Icons.translate_rounded,
        accentColor: PolieColors.electricTeal,
        mode: PolieMode.translation,
      ),
      _ModeData(
        title: 'Tutor',
        description: 'Adaptive lessons, grammar, and exercises with feedback.',
        icon: Icons.school_rounded,
        accentColor: PolieColors.goldEmber,
        mode: PolieMode.tutor,
      ),
      _ModeData(
        title: 'Roleplay',
        description: 'Real scenarios: market, taxi, elder. Practice with character.',
        icon: Icons.theater_comedy_rounded,
        accentColor: PolieColors.royalAmethyst,
        mode: PolieMode.roleplay,
      ),
      _ModeData(
        title: 'Conversation',
        description: 'Free-flowing dialogue. Natural practice with gentle correction.',
        icon: Icons.chat_bubble_outline_rounded,
        accentColor: PolieColors.electricTealLight,
        mode: PolieMode.conversation,
      ),
      _ModeData(
        title: 'Vocabulary',
        description: 'New words, usage, and spaced repetition.',
        icon: Icons.book_rounded,
        accentColor: PolieColors.goldEmberLight,
        mode: PolieMode.vocab,
      ),
      _ModeData(
        title: 'Review',
        description: 'Strengthen memory. Review learned words and phrases.',
        icon: Icons.refresh_rounded,
        accentColor: PolieColors.success,
        mode: PolieMode.review,
      ),
      _ModeData(
        title: 'Pronunciation',
        description: 'Master sounds, tones, and phonetics. Practice speaking clearly.',
        icon: Icons.record_voice_over_rounded,
        accentColor: PolieColors.electricTeal,
        mode: PolieMode.pronunciation,
      ),
      _ModeData(
        title: 'Grammar',
        description: 'Sentence patterns, rules, and practice exercises.',
        icon: Icons.account_tree_rounded,
        accentColor: PolieColors.royalAmethyst,
        mode: PolieMode.grammar,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? PolieColors.obsidian : PolieColors.surfaceContainerLight,
      body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md, vertical: PolieSpacing.sm),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (onBack != null) {
                          onBack!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Polie AI',
                        style: PolieTypography.h2(context).copyWith(color: textPrimary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md),
                child: PolieGlassCard(
                  padding: EdgeInsets.all(PolieSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? PolieColors.royalAmethyst : PolieColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: PolieElevation.level1(context),
                        ),
                        child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.onPrimary, size: 28),
                      ),
                      SizedBox(width: PolieSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose your learning mode',
                              style: PolieTypography.h2(context).copyWith(
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: PolieSpacing.xs),
                            Text(
                              'Translate, practice, roleplay, or review with Polie.',
                              style: PolieTypography.bodySmall(context).copyWith(
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: PolieSpacing.lg),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md),
                  itemCount: modes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == modes.length) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: PolieSpacing.md),
                        child: PolieGlassCard(
                          padding: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.push(
                                context,
                                SmoothPageRoute(child: const PersonalitySelectionScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(PolieRadius.lg),
                            child: Padding(
                              padding: EdgeInsets.all(PolieSpacing.lg),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(PolieSpacing.md),
                                    decoration: BoxDecoration(
                                      color: PolieColors.goldEmber.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(PolieRadius.md),
                                    ),
                                    child: Icon(Icons.people_alt_rounded, color: PolieColors.goldEmber, size: 28),
                                  ),
                                  SizedBox(width: PolieSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Historical Personas',
                                          style: PolieTypography.h2(context).copyWith(color: textPrimary),
                                        ),
                                        SizedBox(height: PolieSpacing.xs),
                                        Text(
                                          'Chat with African historical figures. Learn through their eyes.',
                                          style: PolieTypography.bodySmall(context).copyWith(color: textSecondary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.05, end: 0, duration: 300.ms);
                    }
                    final data = modes[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: PolieSpacing.md),
                      child: PolieGlassCard(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _navigateToMode(context, ref, data.mode);
                          },
                          borderRadius: BorderRadius.circular(PolieRadius.lg),
                          child: Padding(
                            padding: EdgeInsets.all(PolieSpacing.lg),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(PolieSpacing.md),
                                  decoration: BoxDecoration(
                                    color: data.accentColor.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(PolieRadius.md),
                                  ),
                                  child: Icon(data.icon, color: data.accentColor, size: 28),
                                ),
                                SizedBox(width: PolieSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.title,
                                        style: PolieTypography.h2(context).copyWith(
                                          color: textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: PolieSpacing.xs),
                                      Text(
                                        data.description,
                                        style: PolieTypography.bodySmall(context).copyWith(
                                          color: textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.05, end: 0, duration: 300.ms);
                  },
                ),
              ),
            ],
          ),
      ),
    );
  }

  void _navigateToMode(BuildContext context, WidgetRef ref, PolieMode mode) {
    // NOTE: Do NOT call setMode() here. The language setup screen will call
    // setModeAndLanguage() atomically once the user picks a language.
    // Calling setMode() prematurely triggers save/load with (new mode × old language),
    // which is the wrong history key and causes unnecessary state churn.

    if (mode == PolieMode.roleplay) {
      Navigator.push(
        context,
        SmoothPageRoute(
          child: AiChatLanguageSetupScreen(
            initialMode: mode,
            onLanguageSelected: (language, languageName) {
              Navigator.pushReplacement(
                context,
                SmoothPageRoute(
                  child: RoleplayScenarioSelectionScreen(
                    language: language,
                    languageName: languageName,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        SmoothPageRoute(
          child: AiChatLanguageSetupScreen(initialMode: mode),
        ),
      );
    }
  }
}

class _ModeData {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final PolieMode mode;

  _ModeData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.mode,
  });
}
