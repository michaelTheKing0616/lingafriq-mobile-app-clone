import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Leaderboards'),
            Text('LingAfriq', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Tribe'),
            Tab(text: 'Country'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => leaderboard.refresh(),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLeaderboardList(LeaderboardType.global, leaderboard.getGlobalLeaderboard()),
            _buildLeaderboardList(
              LeaderboardType.tribe,
              leaderboard.getTribeLeaderboard(gamification.tribe ?? ''),
            ),
            _buildLeaderboardList(
              LeaderboardType.country,
              leaderboard.getCountryLeaderboard(user?.nationality ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(LeaderboardType type, List<LeaderboardEntry> entries) {
    if (entries.isEmpty) {
      return LingAfriqEmptyState(
        icon: Icons.leaderboard_outlined,
        title: 'No rankings yet',
        subtitle: 'Complete lessons and quizzes to climb the leaderboard.',
        actionLabel: 'Refresh',
        onAction: () => ref.read(leaderboardProvider.notifier).fetchLeaderboards(type: type),
      );
    }

    return OptimizedListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isCurrentUser = entry.userId == 'current_user';
        
        return _LeaderboardCard(
          entry: entry,
          isCurrentUser: isCurrentUser,
          rank: index + 1,
        );
      },
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  final int rank;

  const _LeaderboardCard({
    required this.entry,
    required this.isCurrentUser,
    required this.rank,
  });

  Widget _buildRankIcon(int rank) {
    if (rank == 1) {
      return const Icon(Icons.emoji_events, color: Colors.amber, size: 32);
    } else if (rank == 2) {
      return const Icon(Icons.emoji_events, color: Colors.grey, size: 32);
    } else if (rank == 3) {
      return const Icon(Icons.emoji_events, color: Colors.brown, size: 32);
    }
    return Text(
      '#$rank',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCurrentUser ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentUser
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          child: _buildRankIcon(rank),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.username,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (entry.tribe != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.tribe!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level ${entry.level} • ${entry.levelTitle}'),
            Row(
              children: [
                const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text('${entry.dailyStreak} day streak'),
                const SizedBox(width: 16),
                Text('${entry.xp} XP'),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Lv. ${entry.level}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

