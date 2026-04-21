import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/socket_provider.dart';
import '../../models/leaderboard_entry_model.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/skeleton_loader.dart';

/// Leaderboard screen with tribe, regional, and global rankings
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardType _currentType = LeaderboardType.global;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardProvider.notifier).fetchLeaderboards(type: LeaderboardType.global);
      final user = ref.read(userProvider);
      if (user != null) {
        ref.read(leaderboardProvider.notifier).fetchUserRanks(user.id.toString());
      }
    });
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentType = LeaderboardType.global;
            break;
          case 1:
            _currentType = LeaderboardType.tribe;
            break;
          case 2:
            _currentType = LeaderboardType.country;
            break;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tribe = _currentType == LeaderboardType.tribe
            ? ref.read(gamificationProvider.notifier).gamification.tribe
            : null;
        final country = _currentType == LeaderboardType.country
            ? ref.read(userProvider)?.nationality
            : null;
        ref.read(leaderboardProvider.notifier).fetchLeaderboards(
          type: _currentType,
          tribe: tribe,
          country: country,
        );
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to leaderboard updates via Socket.io
    final socketService = ref.read(socketServiceProvider);
    final user = ref.read(userProvider);
    if (user != null) {
      socketService.subscribeToLeaderboard('global:weekly');
      socketService.onLeaderboardUpdate((data) {
        if (mounted) {
          ref.read(leaderboardProvider.notifier).refresh(type: LeaderboardType.global);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardState = ref.watch(leaderboardProvider);
    final leaderboard = ref.watch(leaderboardProvider.notifier);
    final gamification = ref.watch(gamificationProvider.notifier).gamification;
    final user = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Leaderboards',
          style: PanAfricanTypography.headlineMedium(context),
        ),
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Semantics(
            label: 'Leaderboard tabs: Global, Tribe, Regional',
            child: TabBar(
              controller: _tabController,
              onTap: (_) => HapticFeedback.lightImpact(),
              labelStyle: PanAfricanTypography.titleSmall(context),
              indicatorColor: PanAfricanColors.secondary,
              tabs: const [
                Tab(text: 'Global'),
                Tab(text: 'Tribe'),
                Tab(text: 'Regional'),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: PanAfricanColors.primary,
        onRefresh: () => leaderboard.refresh(),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLeaderboardList(
              LeaderboardType.global,
              leaderboard.getGlobalLeaderboard(),
              isDark,
              isLoading: leaderboardState.isLoading,
              error: leaderboardState.errorMessage,
            ),
            _buildLeaderboardList(
              LeaderboardType.tribe,
              leaderboard.getTribeLeaderboard(gamification.tribe ?? ''),
              isDark,
              isLoading: leaderboardState.isLoading,
              error: leaderboardState.errorMessage,
            ),
            _buildLeaderboardList(
              LeaderboardType.country,
              leaderboard.getCountryLeaderboard(user?.nationality ?? ''),
              isDark,
              isLoading: leaderboardState.isLoading,
              error: leaderboardState.errorMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(
    LeaderboardType type,
    List<LeaderboardEntry> entries,
    bool isDark, {
    bool isLoading = false,
    String? error,
  }) {
    if (isLoading && entries.isEmpty) {
      return ListView.builder(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        itemCount: 8,
        itemBuilder: (context, index) => const SkeletonListCard(),
      );
    }

    if (error != null && entries.isEmpty) {
      return AppErrorState(
        message: error,
        onRetry: () {
          HapticFeedback.lightImpact();
          ref.read(leaderboardProvider.notifier).fetchLeaderboards(type: type);
        },
        icon: Icons.error_outline_rounded,
      );
    }

    if (entries.isEmpty) {
      return AppEmptyState(
        icon: Icons.leaderboard_outlined,
        title: 'No rankings yet',
        subtitle: 'Complete lessons and quizzes to climb the leaderboard.',
        actionLabel: 'Refresh',
        onAction: () {
          HapticFeedback.lightImpact();
          _refetchForType(type);
        },
      );
    }

    final user = ref.read(userProvider);
    final userRanks = ref.read(leaderboardProvider.notifier).userRanks;
    final userInList = user != null && entries.any((e) => e.userId == user.id.toString());

    return ListView.builder(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      itemCount: entries.length + (userInList || user == null ? 0 : 1),
      // Use BouncingScrollPhysics for iOS-native feel and ClampingScrollPhysics fallback
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      // Add item extent estimate for better scroll performance
      itemExtent: null, // Let items size naturally
      // Add key for proper widget recycling
      key: ValueKey('leaderboard_${type.name}'),
      itemBuilder: (context, index) {
        // Show "Your Rank" card at top if user is not in the visible list
        if (!userInList && user != null && index == 0) {
          final periodKey = type == LeaderboardType.global
              ? 'global:weekly'
              : type == LeaderboardType.monthly
                  ? 'global:monthly'
                  : type == LeaderboardType.allTime
                      ? 'global:alltime'
                      : 'global:weekly';
          final rankData = userRanks?[periodKey];
          final myRank = rankData?['rank'] as int? ?? 0;
          final myScore = (rankData?['score'] as num?)?.toInt() ?? 0;

          return Container(
            margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [PanAfricanColors.primary.withOpacity(0.15), PanAfricanColors.secondary.withOpacity(0.10)],
              ),
              borderRadius: PanAfricanRadius.lgBR,
              border: Border.all(color: PanAfricanColors.primary, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.person_pin, color: PanAfricanColors.primary, size: 32.sp),
                SizedBox(width: PanAfricanSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Ranking', style: PanAfricanTypography.titleSmall(context)),
                      SizedBox(height: PanAfricanSpacing.xxs),
                      Text(
                        myRank > 0 ? '#$myRank • $myScore XP' : 'Not ranked yet — earn XP to appear!',
                        style: PanAfricanTypography.bodySmall(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
        }

        final entryIndex = !userInList && user != null ? index - 1 : index;
        if (entryIndex < 0 || entryIndex >= entries.length) {
          return const SizedBox.shrink();
        }
        
        final entry = entries[entryIndex];
        final isCurrentUser = user != null &&
            entry.userId.isNotEmpty &&
            entry.userId == user.id.toString();
        
        return _LeaderboardCard(
          key: ValueKey('leaderboard_card_${entry.userId}_$entryIndex'),
          entry: entry,
          isCurrentUser: isCurrentUser,
          rank: entryIndex + 1,
          isDark: isDark,
        )
            .animate(delay: Duration(milliseconds: entryIndex * 50))
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.1, end: 0);
      },
    );
  }
}

class _LeaderboardCard extends StatefulWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  final int rank;
  final bool isDark;

  const _LeaderboardCard({
    super.key,
    required this.entry,
    required this.isCurrentUser,
    required this.rank,
    required this.isDark,
  });

  @override
  State<_LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<_LeaderboardCard> {

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return PanAfricanColors.secondary; // Gold
      case 2:
        return const Color(0xFFA8A8A8); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return PanAfricanColors.primary;
    }
  }

  Widget _buildRankBadge(BuildContext context, int rank) {
    final badgeSize = 48.0.w.clamp(40.0, 56.0);
    final iconSize = 28.0.sp.clamp(22.0, 32.0);
    final colorScheme = Theme.of(context).colorScheme;

    if (rank <= 3) {
      final bgColor = _getRankColor(rank);
      return Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: rank == 1
              ? Border.all(color: PanAfricanColors.secondary.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Center(
          child: Icon(
            Icons.emoji_events_rounded,
            color: colorScheme.onPrimary,
            size: iconSize,
          ),
        ),
      );
    }
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: widget.isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: PanAfricanTypography.titleMedium(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expanded = _expandedState;
    return Semantics(
      label: 'Rank ${widget.rank}: ${widget.entry.username}, ${widget.entry.xp} XP${widget.isCurrentUser ? ", your rank" : ""}',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _expandedState = !_expandedState);
        },
        child: Container(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
        decoration: BoxDecoration(
          color: widget.isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.lgBR,
          border: Border.all(
            color: widget.isCurrentUser
                ? PanAfricanColors.primary
                : (widget.isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
            width: widget.isCurrentUser ? 2 : 1,
          ),
          boxShadow: widget.isCurrentUser ? PanAfricanShadows.md : PanAfricanShadows.sm,
        ),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: Row(
            children: [
              _buildRankBadge(context, widget.rank),
              SizedBox(width: PanAfricanSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.entry.username,
                      style: PanAfricanTypography.titleMedium(
                        context,
                        color: widget.isCurrentUser ? PanAfricanColors.primary : null,
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.xxs),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14.0.sp,
                          color: PanAfricanColors.secondary,
                          semanticLabel: 'XP',
                        ),
                        SizedBox(width: PanAfricanSpacing.xxs),
                        Text(
                          '${widget.entry.xp} XP',
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      ],
                    ),
                    if (expanded) ...[
                      SizedBox(height: PanAfricanSpacing.xs),
                      if (widget.entry.tribe != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: PanAfricanSpacing.xxs),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: PanAfricanSpacing.xs,
                              vertical: PanAfricanSpacing.xxxs,
                            ),
                            decoration: BoxDecoration(
                              color: PanAfricanColors.primaryContainer,
                              borderRadius: PanAfricanRadius.roundBR,
                            ),
                            child: Text(
                              widget.entry.tribe!,
                              style: PanAfricanTypography.labelSmall(
                                context,
                                color: PanAfricanColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        'Level ${widget.entry.level} • ${widget.entry.levelTitle}',
                        style: PanAfricanTypography.bodySmall(context),
                      ),
                      SizedBox(height: PanAfricanSpacing.xxs),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 14.0.sp,
                            color: PanAfricanColors.tertiary,
                          ),
                          SizedBox(width: PanAfricanSpacing.xxs),
                          Text(
                            '${widget.entry.dailyStreak} day streak',
                            style: PanAfricanTypography.labelSmall(context),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: PanAfricanColors.neutralMedium,
                size: 20.sp,
                semanticLabel: expanded ? 'Collapse' : 'Expand',
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  late bool _expandedState;

  @override
  void initState() {
    super.initState();
    _expandedState = widget.isCurrentUser;
  }
}

