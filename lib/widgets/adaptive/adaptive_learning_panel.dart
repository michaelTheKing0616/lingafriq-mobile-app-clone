import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/adaptive_learning_service.dart';
import '../../models/adaptive_learning_summary.dart';
import '../../services/localization_service.dart';
import '../../utils/african_theme.dart';
import '../../utils/design_system.dart';
import '../../providers/navigation_provider.dart';
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
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0D1B1A), Color(0xFF123C3A)]
              : const [Color(0xFF007A3D), Color(0xFF00A8E8)],
        ),
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        boxShadow: DesignSystem.shadowLarge,
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
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius:
                          BorderRadius.circular(DesignSystem.radiusRound),
                    ),
                    child: Text(
                      isDashboardVariantV2
                          ? 'Level ${summary.cefrLevel} · ${summary.cefrScore.toStringAsFixed(0)}% ready'
                          : 'CEFR ${summary.cefrLevel} · ${summary.cefrScore.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: _AdaptiveStatChip(
                  label: 'Words to review',
                  value: '${summary.dueSrsItems}',
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _AdaptiveStatChip(
                  label: 'Streak',
                  value: '${summary.dailyStreak} days',
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _AdaptiveStatChip(
                  label: 'Total XP',
                  value: '${summary.totalXp}',
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
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
        nav.naviateTo(const AiChatLanguageSetupScreen());
        break;
      case AdaptiveActionType.playGame:
        nav.naviateTo(const LanguageGamesScreen());
        break;
      case AdaptiveActionType.completeLesson:
        nav.naviateTo(const ProgressDashboardScreen());
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
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
        color: isDark ? AfricanTheme.stitchCardDark : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: DesignSystem.shadowSmall,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        title: Text(
          recommendation.title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          recommendation.description,
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16.sp,
          color: isDark ? Colors.grey[300] : Colors.grey[600],
        ),
      ),
    );
  }
}


