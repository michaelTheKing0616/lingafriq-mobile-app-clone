import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/daily_challenge_model.dart';
import '../../providers/daily_challenges_provider.dart';
import '../../services/sound_effects_service.dart';
import '../../utils/pan_african_design_system.dart';

/// Daily Challenges Card Widget
/// 
/// Shows daily challenges with progress, rewards, and claim buttons.
/// Uses Pan-African design system for styling.
class DailyChallengesWidget extends ConsumerStatefulWidget {
  final bool compact;
  final VoidCallback? onViewAll;

  const DailyChallengesWidget({
    Key? key,
    this.compact = false,
    this.onViewAll,
  }) : super(key: key);

  @override
  ConsumerState<DailyChallengesWidget> createState() => _DailyChallengesWidgetState();
}

class _DailyChallengesWidgetState extends ConsumerState<DailyChallengesWidget> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final challengesState = ref.watch(dailyChallengesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (challengesState.isLoading) {
      return _buildLoadingState(isDark);
    }

    final challenges = widget.compact 
        ? challengesState.activeChallenges.take(3).toList()
        : challengesState.activeChallenges;

    if (challenges.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [PanAfricanColors.surfaceDark, PanAfricanColors.surfaceDark.withOpacity(0.8)]
              : [Colors.white, PanAfricanColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(
          color: isDark 
              ? PanAfricanColors.primaryLight.withOpacity(0.2)
              : PanAfricanColors.outline.withOpacity(0.3),
        ),
        boxShadow: PanAfricanShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(challengesState, isDark),
          if (challengesState.claimableChallenges.isNotEmpty)
            _buildClaimAllButton(challengesState, isDark),
          ...challenges.map((challenge) => _buildChallengeItem(challenge, isDark)),
          if (challengesState.isWeekend && challengesState.weekendChallenges.isNotEmpty)
            _buildWeekendSection(challengesState.weekendChallenges, isDark),
          if (widget.compact && challengesState.activeChallenges.length > 3)
            _buildViewAllButton(isDark),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.surfaceDark : Colors.white,
        borderRadius: PanAfricanRadius.lgBR,
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: PanAfricanColors.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.surfaceDark : Colors.white,
        borderRadius: PanAfricanRadius.lgBR,
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 48.sp,
            color: PanAfricanColors.primary,
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            'All challenges completed!',
            style: PanAfricanTypography.titleMedium(context).copyWith(
              color: isDark ? Colors.white : PanAfricanColors.textPrimary,
            ),
          ),
          SizedBox(height: PanAfricanSpacing.xxs),
          Text(
            'Come back tomorrow for new challenges',
            style: PanAfricanTypography.bodySmall(context).copyWith(
              color: isDark ? Colors.white70 : PanAfricanColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(DailyChallengesState state, bool isDark) {
    final timeRemaining = _getTimeRemainingString(state.challenges.isNotEmpty 
        ? state.challenges.first.timeRemaining 
        : Duration.zero);

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.sunset,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(PanAfricanRadius.lg),
          topRight: Radius.circular(PanAfricanRadius.lg),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: PanAfricanRadius.roundBR,
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Challenges',
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Resets in $timeRemaining',
                  style: PanAfricanTypography.bodySmall(context).copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.sm,
              vertical: PanAfricanSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: PanAfricanRadius.roundBR,
            ),
            child: Text(
              '${state.claimableChallenges.length} ready',
              style: PanAfricanTypography.labelSmall(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimAllButton(DailyChallengesState state, bool isDark) {
    return Container(
      margin: EdgeInsets.all(PanAfricanSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _claimAllChallenges(),
          borderRadius: PanAfricanRadius.mdBR,
          child: Container(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              gradient: PanAfricanGradients.primaryGreen,
              borderRadius: PanAfricanRadius.mdBR,
              boxShadow: PanAfricanShadows.glow(PanAfricanColors.primary),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Claim All (+${state.totalClaimableXP} XP)',
                  style: PanAfricanTypography.labelLarge(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeItem(DailyChallenge challenge, bool isDark) {
    final isCompleted = challenge.isCompleted;
    final canClaim = challenge.canClaim;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.md,
        vertical: PanAfricanSpacing.xs,
      ),
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark 
            ? PanAfricanColors.cardDark 
            : (isCompleted ? PanAfricanColors.primaryLight.withOpacity(0.1) : Colors.white),
        borderRadius: PanAfricanRadius.mdBR,
        border: Border.all(
          color: isCompleted 
              ? PanAfricanColors.primary.withOpacity(0.5)
              : (isDark ? Colors.white12 : PanAfricanColors.outline.withOpacity(0.2)),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Emoji
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: _getDifficultyColor(challenge.difficulty).withOpacity(0.15),
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                child: Center(
                  child: Text(
                    challenge.emoji,
                    style: TextStyle(fontSize: 24.sp),
                  ),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.title,
                            style: PanAfricanTypography.titleSmall(context).copyWith(
                              color: isDark ? Colors.white : PanAfricanColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildDifficultyBadge(challenge.difficulty),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      challenge.description,
                      style: PanAfricanTypography.bodySmall(context).copyWith(
                        color: isDark ? Colors.white70 : PanAfricanColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: PanAfricanRadius.roundBR,
                  child: LinearProgressIndicator(
                    value: challenge.progressPercent,
                    backgroundColor: isDark 
                        ? Colors.white12 
                        : PanAfricanColors.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted 
                          ? PanAfricanColors.primary 
                          : _getDifficultyColor(challenge.difficulty),
                    ),
                    minHeight: 8.h,
                  ),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              Text(
                '${challenge.progress}/${challenge.target}',
                style: PanAfricanTypography.labelSmall(context).copyWith(
                  color: isDark ? Colors.white70 : PanAfricanColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          // Rewards and claim button
          Row(
            children: [
              // XP reward
              _buildRewardChip(
                Icons.star_rounded,
                '+${challenge.xpReward}',
                PanAfricanColors.secondary,
              ),
              SizedBox(width: PanAfricanSpacing.xs),
              // Cowries reward
              if (challenge.cowriesReward > 0)
                _buildRewardChip(
                  Icons.monetization_on_rounded,
                  '+${challenge.cowriesReward}',
                  PanAfricanColors.primary,
                ),
              const Spacer(),
              // Claim button
              if (canClaim)
                _buildClaimButton(challenge)
              else if (isCompleted)
                _buildClaimedBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(ChallengeDifficulty difficulty) {
    final color = _getDifficultyColor(difficulty);
    final text = difficulty.name.toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.xs,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: PanAfricanRadius.roundBR,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRewardChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.xs,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: PanAfricanRadius.roundBR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 2.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimButton(DailyChallenge challenge) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _claimChallenge(challenge),
        borderRadius: PanAfricanRadius.roundBR,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md,
            vertical: PanAfricanSpacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: PanAfricanGradients.primaryGreen,
            borderRadius: PanAfricanRadius.roundBR,
            boxShadow: PanAfricanShadows.glowGreen(0.3),
          ),
          child: Text(
            'CLAIM',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClaimedBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm,
        vertical: PanAfricanSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: PanAfricanColors.primary.withOpacity(0.1),
        borderRadius: PanAfricanRadius.roundBR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14.sp,
            color: PanAfricanColors.primary,
          ),
          SizedBox(width: 4.w),
          Text(
            'CLAIMED',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: PanAfricanColors.primary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekendSection(List<DailyChallenge> weekendChallenges, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md,
            vertical: PanAfricanSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                '🔥',
                style: TextStyle(fontSize: 20.sp),
              ),
              SizedBox(width: PanAfricanSpacing.xs),
              Text(
                'Weekend Warrior Bonus (2x XP!)',
                style: PanAfricanTypography.titleSmall(context).copyWith(
                  color: PanAfricanColors.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...weekendChallenges.map((c) => _buildChallengeItem(c, isDark)),
      ],
    );
  }

  Widget _buildViewAllButton(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: TextButton(
        onPressed: widget.onViewAll,
        child: Text(
          'View All Challenges →',
          style: PanAfricanTypography.labelMedium(context).copyWith(
            color: PanAfricanColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return PanAfricanColors.primary;
      case ChallengeDifficulty.medium:
        return PanAfricanColors.secondary;
      case ChallengeDifficulty.hard:
        return PanAfricanColors.tertiary;
      case ChallengeDifficulty.expert:
        return const Color(0xFF9C27B0); // Purple for expert
    }
  }

  String _getTimeRemainingString(Duration duration) {
    if (duration.isNegative) return '00:00:00';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _claimChallenge(DailyChallenge challenge) async {
    ref.read(soundEffectsProvider).play(SoundEffect.buttonTap);
    final success = await ref.read(dailyChallengesProvider.notifier).claimChallenge(challenge.id);
    
    if (success && mounted) {
      ref.read(soundEffectsProvider).playCelebration();
    }
  }

  Future<void> _claimAllChallenges() async {
    ref.read(soundEffectsProvider).play(SoundEffect.buttonTap);
    final claimed = await ref.read(dailyChallengesProvider.notifier).claimAllChallenges();
    
    if (claimed > 0 && mounted) {
      ref.read(soundEffectsProvider).playCelebration();
    }
  }
}

