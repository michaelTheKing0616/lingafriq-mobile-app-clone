import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/models/roleplay_progress_model.dart';
import 'package:lingafriq/services/roleplay_progress_service.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/ai_chat/roleplay_scenario_selection_screen.dart';

/// Roleplay Completion Summary Screen
/// Shows performance metrics, XP earned, and recommendations after completing a scenario
class RoleplayCompletionSummaryScreen extends HookConsumerWidget {
  final RoleplaySessionResult result;
  final String language;
  final String languageName;
  final VoidCallback? onContinue;

  const RoleplayCompletionSummaryScreen({
    Key? key,
    required this.result,
    required this.language,
    required this.languageName,
    this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressService = ref.read(roleplayProgressServiceProvider);
    final gamification = ref.read(gamificationProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final xpEarned = useState<int>(0);
    final isLoading = useState(false);

    // Calculate XP based on performance
    useEffect(() {
      _calculateAndAwardXP(context, ref, progressService, gamification, xpEarned, isLoading);
      return null;
    }, []);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Scenario Complete! 🎉',
                  style: PanAfricanTypography.headlineMedium(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: PanAfricanColors.primary,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.2),
                SizedBox(height: PanAfricanSpacing.lg),

                // Score Card
                _ScoreCard(
                  score: result.score,
                  accuracy: result.accuracy,
                  fluency: result.fluency,
                  isDark: isDark,
                )
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2),
                SizedBox(height: PanAfricanSpacing.lg),

                // XP Earned
                if (xpEarned.value > 0)
                  Card(
                    color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                    child: Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: PanAfricanColors.accent, size: 32.sp),
                          SizedBox(width: PanAfricanSpacing.md),
                          Column(
                            children: [
                              Text(
                                '+${xpEarned.value} XP',
                                style: PanAfricanTypography.headlineSmall(context)?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: PanAfricanColors.accent,
                                ),
                              ),
                              Text(
                                'Earned!',
                                style: PanAfricanTypography.bodySmall(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 300.ms)
                      .scale(begin: Offset(0.8, 0.8)),
                SizedBox(height: PanAfricanSpacing.lg),

                // Performance Metrics
                _PerformanceMetrics(
                  result: result,
                  isDark: isDark,
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.1),

                SizedBox(height: PanAfricanSpacing.lg),

                // Vocabulary Learned
                if (result.vocabularyLearned.isNotEmpty)
                  _VocabularySection(
                    vocabulary: result.vocabularyLearned,
                    isDark: isDark,
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.1),

                SizedBox(height: PanAfricanSpacing.lg),

                // Grammar Points
                if (result.grammarPoints.isNotEmpty)
                  _GrammarSection(
                    grammarPoints: result.grammarPoints,
                    isDark: isDark,
                  )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.1),

                SizedBox(height: PanAfricanSpacing.xl),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
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
                        icon: Icon(Icons.refresh),
                        label: Text('Try Another'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading.value
                            ? null
                            : () {
                                if (onContinue != null) {
                                  onContinue!();
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                        icon: isLoading.value
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.check),
                        label: Text('Continue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PanAfricanColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _calculateAndAwardXP(
    BuildContext context,
    WidgetRef ref,
    RoleplayProgressService progressService,
    dynamic gamification,
    ValueNotifier<int> xpEarned,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    try {
      // Calculate XP: base 50 + accuracy bonus + fluency bonus + score bonus
      final baseXP = 50;
      final accuracyBonus = (result.accuracy * 30).round();
      final fluencyBonus = (result.fluency * 20).round();
      final scoreBonus = (result.score / 10).round();
      final totalXP = baseXP + accuracyBonus + fluencyBonus + scoreBonus;

      xpEarned.value = totalXP;

      // Award XP
      await gamification.awardXP(totalXP, reason: 'roleplay_completion');

      // Record session
      await progressService.recordSession(result);

      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Error calculating XP: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final double accuracy;
  final double fluency;
  final bool isDark;

  const _ScoreCard({
    required this.score,
    required this.accuracy,
    required this.fluency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          children: [
            // Score
            Text(
              '$score',
              style: PanAfricanTypography.displaySmall(context)?.copyWith(
                fontWeight: FontWeight.bold,
                color: PanAfricanColors.primary,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              'Points',
              style: PanAfricanTypography.bodyMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Divider(),
            SizedBox(height: PanAfricanSpacing.lg),
            // Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricItem(
                  label: 'Accuracy',
                  value: '${(accuracy * 100).toStringAsFixed(0)}%',
                  icon: Icons.flag,
                  color: PanAfricanColors.success,
                ),
                _MetricItem(
                  label: 'Fluency',
                  value: '${(fluency * 100).toStringAsFixed(0)}%',
                  icon: Icons.speed,
                  color: PanAfricanColors.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32.sp),
        SizedBox(height: PanAfricanSpacing.xs),
        Text(
          value,
          style: PanAfricanTypography.titleMedium(context)?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xxs),
        Text(
          label,
          style: PanAfricanTypography.bodySmall(context),
        ),
      ],
    );
  }
}

class _PerformanceMetrics extends StatelessWidget {
  final RoleplaySessionResult result;
  final bool isDark;

  const _PerformanceMetrics({
    required this.result,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: PanAfricanTypography.titleMedium(context)?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            _MetricRow(
              label: 'Turns',
              value: '${result.turnCount}',
              icon: Icons.chat_bubble_outline,
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            _MetricRow(
              label: 'Time Spent',
              value: '${(result.timeSpent / 60).toStringAsFixed(1)} min',
              icon: Icons.timer,
            ),
            if (result.branchesTaken.isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.sm),
              _MetricRow(
                label: 'Branches Explored',
                value: '${result.branchesTaken.length}',
                icon: Icons.account_tree,
              ),
            ],
            if (result.corrections.isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.sm),
              _MetricRow(
                label: 'Corrections',
                value: '${result.corrections.length}',
                icon: Icons.edit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: PanAfricanColors.neutralMedium),
        SizedBox(width: PanAfricanSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: PanAfricanTypography.bodyMedium(context),
          ),
        ),
        Text(
          value,
          style: PanAfricanTypography.bodyMedium(context)?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _VocabularySection extends StatelessWidget {
  final List<String> vocabulary;
  final bool isDark;

  const _VocabularySection({
    required this.vocabulary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.book, color: PanAfricanColors.primary),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Vocabulary Learned',
                  style: PanAfricanTypography.titleMedium(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Wrap(
              spacing: PanAfricanSpacing.sm,
              runSpacing: PanAfricanSpacing.sm,
              children: vocabulary.map((word) {
                return Chip(
                  label: Text(word),
                  backgroundColor: PanAfricanColors.primary.withOpacity(0.1),
                  labelStyle: PanAfricanTypography.bodySmall(context)?.copyWith(
                    color: PanAfricanColors.primary,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrammarSection extends StatelessWidget {
  final List<String> grammarPoints;
  final bool isDark;

  const _GrammarSection({
    required this.grammarPoints,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: PanAfricanColors.secondary),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Grammar Points',
                  style: PanAfricanTypography.titleMedium(context)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            ...grammarPoints.map((point) {
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16.sp, color: PanAfricanColors.success),
                    SizedBox(width: PanAfricanSpacing.xs),
                    Expanded(
                      child: Text(
                        point,
                        style: PanAfricanTypography.bodyMedium(context),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

