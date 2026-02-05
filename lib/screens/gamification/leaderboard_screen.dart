import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/lingafriq_ui_helpers.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/socket_provider.dart';
import '../../models/leaderboard_entry_model.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/error_handler.dart';
import '../../utils/integration_helpers.dart';
import '../../utils/performance_utils.dart';

/// Leaderboard screen with tribe, country, and global rankings
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

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
        // Refresh leaderboard when update received
        if (mounted) {
          ref.read(leaderboardProvider.notifier).refresh();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => HapticFeedback.lightImpact(),
          labelStyle: PanAfricanTypography.titleSmall(context),
          indicatorColor: PanAfricanColors.secondary,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Tribe'),
            Tab(text: 'Country'),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: PanAfricanColors.primary,
        onRefresh: () => leaderboard.refresh(),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLeaderboardList(LeaderboardType.global, leaderboard.getGlobalLeaderboard(), isDark),
            _buildLeaderboardList(
              LeaderboardType.tribe,
              leaderboard.getTribeLeaderboard(gamification.tribe ?? ''),
              isDark,
            ),
            _buildLeaderboardList(
              LeaderboardType.country,
              leaderboard.getCountryLeaderboard(user?.nationality ?? ''),
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(LeaderboardType type, List<LeaderboardEntry> entries, bool isDark) {
    if (entries.isEmpty) {
      return LingAfriqEmptyState(
        icon: Icons.leaderboard_outlined,
        title: 'No rankings yet',
        subtitle: 'Complete lessons and quizzes to climb the leaderboard.',
        actionLabel: 'Refresh',
        onAction: () {
          HapticFeedback.lightImpact();
          ref.read(leaderboardProvider.notifier).fetchLeaderboards(type: type);
        },
      );
    }

    return OptimizedListView.builder(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isCurrentUser = entry.userId == 'current_user';
        
        return _LeaderboardCard(
          entry: entry,
          isCurrentUser: isCurrentUser,
          rank: index + 1,
          isDark: isDark,
        );
      },
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  final int rank;
  final bool isDark;

  const _LeaderboardCard({
    required this.entry,
    required this.isCurrentUser,
    required this.rank,
    required this.isDark,
  });

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return PanAfricanColors.secondary; // Gold
      case 2:
        return PanAfricanColors.neutralMedium; // Silver
      case 3:
        return PanAfricanColors.tertiary; // Bronze
      default:
        return PanAfricanColors.primary;
    }
  }

  Widget _buildRankBadge(BuildContext context, int rank) {
    if (rank <= 3) {
      return Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          gradient: rank == 1
              ? PanAfricanGradients.savannaGold
              : null,
          color: rank != 1 ? _getRankColor(rank).withOpacity(0.2) : null,
          shape: BoxShape.circle,
          boxShadow: rank == 1 ? PanAfricanShadows.glowGold(0.3) : null,
        ),
        child: Center(
          child: Icon(
            Icons.emoji_events_rounded,
            color: _getRankColor(rank),
            size: 28.sp,
          ),
        ),
      );
    }
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
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
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.lgBR,
          border: Border.all(
            color: isCurrentUser
                ? PanAfricanColors.primary
                : (isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
            width: isCurrentUser ? 2 : 1,
          ),
          boxShadow: isCurrentUser ? PanAfricanShadows.md : PanAfricanShadows.sm,
        ),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: Row(
            children: [
              _buildRankBadge(context, rank),
              SizedBox(width: PanAfricanSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.username,
                            style: PanAfricanTypography.titleMedium(
                              context,
                              color: isCurrentUser ? PanAfricanColors.primary : null,
                            ),
                          ),
                        ),
                        if (entry.tribe != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: PanAfricanSpacing.xs,
                              vertical: PanAfricanSpacing.xxxs,
                            ),
                            decoration: BoxDecoration(
                              color: PanAfricanColors.primaryContainer,
                              borderRadius: PanAfricanRadius.roundBR,
                            ),
                            child: Text(
                              entry.tribe!,
                              style: PanAfricanTypography.labelSmall(
                                context,
                                color: PanAfricanColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: PanAfricanSpacing.xxs),
                    Text(
                      'Level ${entry.level} • ${entry.levelTitle}',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.xxs),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 16.sp,
                          color: PanAfricanColors.tertiary,
                        ),
                        SizedBox(width: PanAfricanSpacing.xxs),
                        Text(
                          '${entry.dailyStreak} day streak',
                          style: PanAfricanTypography.labelSmall(context),
                        ),
                        SizedBox(width: PanAfricanSpacing.md),
                        Icon(
                          Icons.star_rounded,
                          size: 16.sp,
                          color: PanAfricanColors.secondary,
                        ),
                        SizedBox(width: PanAfricanSpacing.xxs),
                        Text(
                          '${entry.xp} XP',
                          style: PanAfricanTypography.labelSmall(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Lv. ${entry.level}',
                    style: PanAfricanTypography.titleLarge(
                      context,
                      color: PanAfricanColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

