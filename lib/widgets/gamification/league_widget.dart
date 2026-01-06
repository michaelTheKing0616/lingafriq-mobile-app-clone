import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/league_model.dart';
import '../../providers/league_provider.dart';
import '../../utils/pan_african_design_system.dart';

/// League/Division Widget showing user's tier and leaderboard position
class LeagueWidget extends ConsumerStatefulWidget {
  final bool showLeaderboard;
  final int maxLeaderboardEntries;

  const LeagueWidget({
    Key? key,
    this.showLeaderboard = true,
    this.maxLeaderboardEntries = 10,
  }) : super(key: key);

  @override
  ConsumerState<LeagueWidget> createState() => _LeagueWidgetState();
}

class _LeagueWidgetState extends ConsumerState<LeagueWidget> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leagueState = ref.watch(leagueProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = leagueState.tierConfig;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [PanAfricanColors.surfaceDark, PanAfricanColors.cardDark]
              : [Colors.white, PanAfricanColors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(color: config.color.withOpacity(0.3), width: 2),
        boxShadow: PanAfricanShadows.md,
      ),
      child: Column(
        children: [
          _buildHeader(config, leagueState, isDark),
          _buildUserStatus(leagueState, isDark),
          if (widget.showLeaderboard) _buildLeaderboard(leagueState, isDark),
          _buildFooter(leagueState, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(LeagueTierConfig config, LeagueState state, bool isDark) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        gradient: config.gradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(PanAfricanRadius.lg - 2),
          topRight: Radius.circular(PanAfricanRadius.lg - 2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            ),
            child: Center(
              child: Text(config.emoji, style: TextStyle(fontSize: 32.sp)),
            ),
          ),
          SizedBox(width: PanAfricanSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${config.name} League',
                  style: PanAfricanTypography.headlineSmall(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Week ends in ${_formatDuration(state.timeRemaining)}',
                  style: PanAfricanTypography.bodySmall(context).copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: PanAfricanRadius.roundBR,
            ),
            child: Column(
              children: [
                Text(
                  '${config.xpMultiplier}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'XP Bonus',
                  style: TextStyle(fontSize: 10.sp, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatus(LeagueState state, bool isDark) {
    final statusMessage = ref.read(leagueProvider.notifier).getStatusMessage();
    final config = state.tierConfig;

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Rank', '#${state.userRank}', Icons.leaderboard_rounded, isDark),
              _buildStatItem('Weekly XP', '${state.userWeeklyXP}', Icons.star_rounded, isDark),
              _buildStatItem('Reward', '${config.weeklyReward} 🐚', Icons.card_giftcard_rounded, isDark),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.sm),
            decoration: BoxDecoration(
              color: state.willPromote
                  ? PanAfricanColors.primary.withOpacity(0.1)
                  : (state.willDemote ? PanAfricanColors.tertiary.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.05) : PanAfricanColors.surface)),
              borderRadius: PanAfricanRadius.mdBR,
              border: Border.all(
                color: state.willPromote
                    ? PanAfricanColors.primary.withOpacity(0.3)
                    : (state.willDemote ? PanAfricanColors.tertiary.withOpacity(0.3) : Colors.transparent),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  state.willPromote ? Icons.arrow_upward_rounded : (state.willDemote ? Icons.arrow_downward_rounded : Icons.info_outline_rounded),
                  color: state.willPromote ? PanAfricanColors.primary : (state.willDemote ? PanAfricanColors.tertiary : (isDark ? Colors.white70 : PanAfricanColors.textSecondary)),
                  size: 20.sp,
                ),
                SizedBox(width: PanAfricanSpacing.xs),
                Expanded(
                  child: Text(
                    statusMessage,
                    style: PanAfricanTypography.bodySmall(context).copyWith(
                      color: isDark ? Colors.white : PanAfricanColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: PanAfricanColors.secondary, size: 24.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: PanAfricanTypography.titleMedium(context).copyWith(
            color: isDark ? Colors.white : PanAfricanColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: PanAfricanTypography.bodySmall(context).copyWith(
            color: isDark ? Colors.white60 : PanAfricanColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(LeagueState state, bool isDark) {
    final entries = state.leaderboard.take(widget.maxLeaderboardEntries).toList();
    final config = state.tierConfig;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: isDark ? Colors.white12 : PanAfricanColors.outline.withOpacity(0.2)),
          Padding(
            padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
            child: Row(
              children: [
                Text('Leaderboard', style: PanAfricanTypography.titleSmall(context).copyWith(
                  color: isDark ? Colors.white : PanAfricanColors.textPrimary,
                  fontWeight: FontWeight.bold,
                )),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.primary.withOpacity(0.1),
                    borderRadius: PanAfricanRadius.roundBR,
                  ),
                  child: Text(
                    'Top ${config.promoteCount} promote ↑',
                    style: TextStyle(fontSize: 10.sp, color: PanAfricanColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          ...entries.map((pos) => _buildLeaderboardEntry(pos, state, isDark)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(LeaguePosition pos, LeagueState state, bool isDark) {
    final isCurrentUser = pos.isCurrentUser;
    final config = state.tierConfig;

    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
      padding: EdgeInsets.all(PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? PanAfricanColors.primary.withOpacity(0.15)
            : (pos.willPromote ? PanAfricanColors.primary.withOpacity(0.05) : (pos.willDemote ? PanAfricanColors.tertiary.withOpacity(0.05) : Colors.transparent)),
        borderRadius: PanAfricanRadius.smBR,
        border: isCurrentUser ? Border.all(color: PanAfricanColors.primary, width: 2) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32.w,
            child: Text(
              _getRankDisplay(pos.rank),
              style: TextStyle(
                fontSize: pos.rank <= 3 ? 18.sp : 14.sp,
                fontWeight: FontWeight.bold,
                color: _getRankColor(pos.rank),
              ),
            ),
          ),
          CircleAvatar(
            radius: 16.r,
            backgroundColor: isDark ? Colors.white12 : PanAfricanColors.surface,
            backgroundImage: pos.profilePicUrl != null ? NetworkImage(pos.profilePicUrl!) : null,
            child: pos.profilePicUrl == null
                ? Text(pos.username[0].toUpperCase(), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold))
                : null,
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Text(
              pos.username,
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: isDark ? Colors.white : PanAfricanColors.textPrimary,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (pos.willPromote)
            Icon(Icons.arrow_upward_rounded, color: PanAfricanColors.primary, size: 16.sp),
          if (pos.willDemote)
            Icon(Icons.arrow_downward_rounded, color: PanAfricanColors.tertiary, size: 16.sp),
          SizedBox(width: PanAfricanSpacing.xs),
          Text(
            '${pos.weeklyXP} XP',
            style: PanAfricanTypography.labelMedium(context).copyWith(
              color: PanAfricanColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(LeagueState state, bool isDark) {
    final config = state.tierConfig;

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (config.demoteCount > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: PanAfricanColors.tertiary.withOpacity(0.1),
                borderRadius: PanAfricanRadius.roundBR,
              ),
              child: Text(
                'Bottom ${config.demoteCount} demote ↓',
                style: TextStyle(fontSize: 10.sp, color: PanAfricanColors.tertiary, fontWeight: FontWeight.bold),
              ),
            ),
          TextButton.icon(
            onPressed: () => ref.read(leagueProvider.notifier).refreshLeaderboard(),
            icon: Icon(Icons.refresh_rounded, size: 16.sp),
            label: Text('Refresh'),
            style: TextButton.styleFrom(foregroundColor: PanAfricanColors.primary),
          ),
        ],
      ),
    );
  }

  String _getRankDisplay(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return PanAfricanColors.textSecondary;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '0d 0h';
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

