import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/adaptive_learning_service.dart';
import '../../models/adaptive_learning_summary.dart';
import '../../services/localization_service.dart';
import '../../utils/pan_african_design_system.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/adaptive_learning_provider.dart';
import '../../screens/ai_chat/ai_chat_language_setup_screen.dart';
import '../../screens/games/language_games_screen.dart';
import '../../screens/progress/progress_dashboard_screen.dart';
import '../../providers/experiments_provider.dart';

/// Pan-African adaptive learning panel for the dashboard/home.
/// Shows CEFR, SRS status, and smart recommendations powered by Polie + gamification.
class AdaptiveLearningPanel extends ConsumerWidget {
  const AdaptiveLearningPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(adaptiveLearningProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = ref.watch(localizationProvider);
    final experiments = ref.watch(experimentsProvider);

    final isDashboardVariantV2 =
        experiments.variants['polie_dashboard_variant'] == 'v2';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [PanAfricanColors.surfaceDark, PanAfricanColors.surfaceContainerDark]
              : [PanAfricanColors.primary, PanAfricanColors.kenteBlue],
        ),
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        boxShadow: PanAfricanShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<String>(
            future: loc.t(
              key: 'adaptive.title',
              english: isDashboardVariantV2
                  ? 'Polie’s Smart Journey'
                  : 'Smart Path with Polie',
            ),
            builder: (context, snapshot) {
              final title = snapshot.data ??
                  (isDashboardVariantV2
                      ? 'Polie’s Smart Journey'
                      : 'Smart Path with Polie');
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.sm,
                          vertical: PanAfricanSpacing.xxxs,
                        ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.scrim.withOpacity(0.25),
                      borderRadius:
                          BorderRadius.circular(PanAfricanRadius.round),
                    ),
                    child: Text(
                      isDashboardVariantV2
                          ? 'Level ${summary.cefrLevel} · ${summary.cefrScore.toStringAsFixed(0)}% ready'
                          : 'CEFR ${summary.cefrLevel} · ${summary.cefrScore.toStringAsFixed(0)}%',
                      style: PanAfricanTypography.labelSmall(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _AdaptiveStatChip(
                  label: 'Words to review',
                  value: '${summary.dueSrsItems}',
                ),
              ),
              SizedBox(width: PanAfricanSpacing.xs),
              Expanded(
                child: _AdaptiveStatChip(
                  label: 'Streak',
                  value: '${summary.dailyStreak} days',
                ),
              ),
              SizedBox(width: PanAfricanSpacing.xs),
              Expanded(
                child: _AdaptiveStatChip(
                  label: 'Total XP',
                  value: '${summary.totalXp}',
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Column(
            children: summary.recommendations
                .map((rec) => _AdaptiveRecommendationTile(
                      recommendation: rec,
                      isDark: isDark,
                      onTap: () => _handleAction(context, ref, rec.actionType),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    AdaptiveActionType actionType,
  ) {
    final nav = ref.read(navigationProvider);
    switch (actionType) {
      case AdaptiveActionType.reviewWords:
      case AdaptiveActionType.continuePolieTutor:
        nav.navigateTo(const AiChatLanguageSetupScreen());
        break;
      case AdaptiveActionType.playGame:
        nav.navigateTo(const LanguageGamesScreen());
        break;
      case AdaptiveActionType.completeLesson:
        nav.navigateTo(const ProgressDashboardScreen());
        break;
      case AdaptiveActionType.joinChat:
        // Can be wired to global chat screen when appropriate
        break;
      case AdaptiveActionType.readMagazine:
        // Can be wired to culture magazine screen
        break;
    }
  }
}

class _AdaptiveStatChip extends StatelessWidget {
  final String label;
  final String value;

  const _AdaptiveStatChip({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm,
        vertical: PanAfricanSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.scrim.withOpacity(0.25),
        borderRadius: BorderRadius.circular(PanAfricanRadius.round),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: PanAfricanTypography.labelSmall(context).copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.xxxs),
          Text(
            value,
            style: PanAfricanTypography.labelLarge(context).copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveRecommendationTile extends StatelessWidget {
  final AdaptiveRecommendation recommendation;
  final bool isDark;
  final VoidCallback onTap;

  const _AdaptiveRecommendationTile({
    Key? key,
    required this.recommendation,
    required this.isDark,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color:
            isDark ? PanAfricanColors.cardDark : Theme.of(context).colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        boxShadow: PanAfricanShadows.sm,
        border: Border.all(
          color: isDark
              ? PanAfricanColors.borderDark
              : PanAfricanColors.borderLight,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.sm,
        ),
        title: Text(
          recommendation.title,
          style: PanAfricanTypography.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? PanAfricanColors.textPrimaryDark
                : PanAfricanColors.textPrimaryLight,
          ),
        ),
        subtitle: Text(
          recommendation.description,
          style: PanAfricanTypography.bodySmall(context).copyWith(
            color: isDark
                ? PanAfricanColors.textSecondaryDark
                : PanAfricanColors.textSecondaryLight,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16.sp,
          color: isDark
              ? PanAfricanColors.textSecondaryDark
              : PanAfricanColors.textSecondaryLight,
        ),
      ),
    );
  }
}


