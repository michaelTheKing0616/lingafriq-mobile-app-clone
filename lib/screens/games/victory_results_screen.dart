import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';

class VictoryResultsScreen extends ConsumerStatefulWidget {
  const VictoryResultsScreen({
    super.key,
    required this.xpEarned,
    required this.vocabularyLearned,
    required this.finalScore,
    required this.masteryPercent,
    required this.griotRank,
    required this.idiomsLearnt,
    required this.onClaimRewards,
    this.onReplayMission,
  });

  final int xpEarned;
  final int vocabularyLearned;
  final int finalScore;
  final int masteryPercent;
  final String griotRank;
  final int idiomsLearnt;
  final VoidCallback onClaimRewards;
  final VoidCallback? onReplayMission;

  @override
  ConsumerState<VictoryResultsScreen> createState() =>
      _VictoryResultsScreenState();
}

class _VictoryResultsScreenState extends ConsumerState<VictoryResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Mission complete')),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ModernGriotColors.primaryContainer.withAlpha(35),
                    cs.surface,
                    ModernGriotColors.secondaryContainer.withAlpha(20),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  _ScrollArtifactIcon(glowAnim: _glowAnim),
                  SizedBox(height: 8.h),
                  Text(
                    'Mission Complete!',
                    style: ModernGriotTypography.headlineMedium(
                      context: context,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'You\'ve earned your rewards',
                    style: ModernGriotTypography.bodyMedium(
                      context: context,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  GriotGlassPanel(
                    padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: GriotStatCard(
                            icon: Icons.star_rounded,
                            iconColor: ModernGriotColors.primaryContainer,
                            value: '+${widget.xpEarned}',
                            label: 'XP',
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: GriotStatCard(
                            icon: Icons.translate_rounded,
                            iconColor: ModernGriotColors.secondary,
                            value: '${widget.vocabularyLearned}',
                            label: 'Vocabulary',
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: GriotStatCard(
                            icon: Icons.emoji_events_rounded,
                            iconColor: const Color(0xFFFFC107),
                            value: '${widget.finalScore}',
                            label: 'Score',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _MasteryInsightsSection(
                    idiomsLearnt: widget.idiomsLearnt,
                    griotRank: widget.griotRank,
                    masteryPercent: widget.masteryPercent,
                  ),
                  SizedBox(height: 36.h),
                  GriotGradientButton(
                    label: 'Claim Rewards',
                    icon: Icons.card_giftcard_rounded,
                    onPressed: widget.onClaimRewards,
                  ),
                  SizedBox(height: 10.h),
                  GriotSecondaryButton(
                    label: 'Replay Mission',
                    icon: Icons.replay_rounded,
                    onPressed: widget.onReplayMission,
                  ),
                  SizedBox(height: safePadding.bottom + 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollArtifactIcon extends StatelessWidget {
  const _ScrollArtifactIcon({required this.glowAnim});
  final Animation<double> glowAnim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnim,
      builder: (context, child) {
        return Container(
          width: 100.r,
          height: 100.r,
          decoration: BoxDecoration(
            borderRadius: ModernGriotRadius.borderXxl,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ModernGriotColors.primaryContainer,
                ModernGriotColors.primary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: ModernGriotColors.primaryContainer
                    .withAlpha((glowAnim.value * 120).round()),
                blurRadius: 24 * glowAnim.value,
                spreadRadius: 4 * glowAnim.value,
              ),
            ],
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            size: 48.sp,
            color: ModernGriotColors.onPrimary,
          ),
        );
      },
    );
  }
}

class _MasteryInsightsSection extends StatelessWidget {
  const _MasteryInsightsSection({
    required this.idiomsLearnt,
    required this.griotRank,
    required this.masteryPercent,
  });

  final int idiomsLearnt;
  final String griotRank;
  final int masteryPercent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mastery Insights',
          style: ModernGriotTypography.titleMedium(context: context, color: cs.onSurface),
        ),
        SizedBox(height: 12.h),
        _InsightCard(
          icon: Icons.format_quote_rounded,
          iconColor: ModernGriotColors.secondary,
          title: 'Idioms Learnt',
          trailing: '$idiomsLearnt',
        ),
        SizedBox(height: 10.h),
        _RankCard(
          rank: griotRank,
          masteryPercent: masteryPercent,
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderLg,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20.sp, color: iconColor),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              title,
              style: ModernGriotTypography.bodyLarge(context: context, color: cs.onSurface),
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.rank, required this.masteryPercent});
  final String rank;
  final int masteryPercent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderLg,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: ModernGriotColors.primaryContainer.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.military_tech_rounded,
                  size: 20.sp,
                  color: ModernGriotColors.primaryContainer,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Griot Rank',
                      style: ModernGriotTypography.bodySmall(
                        context: context,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      rank,
                      style: ModernGriotTypography.titleMedium(
                        context: context,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$masteryPercent%',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GriotProgressBar(
            value: masteryPercent / 100,
            showGlowTip: true,
          ),
        ],
      ),
    );
  }
}
