import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/providers/social_feed_provider.dart';
import 'package:lingafriq/screens/social/friend_profile_screen.dart';
import 'package:lingafriq/screens/social/challenge_friend_screen.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/integration_helpers.dart';

class SocialHubScreen extends HookConsumerWidget {
  const SocialHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 4);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedItems = ref.watch(socialFeedProvider);

    useEffect(() {
      ref.read(socialFeedProvider.notifier).loadFeed();
      return null;
    }, []);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PolieColors.primary,
              PolieColors.primaryDark,
              PolieColors.obsidian,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              TabBar(
                controller: tabController,
                tabs: const [
                  Tab(text: 'Feed'),
                  Tab(text: 'Friends'),
                  Tab(text: 'Challenges'),
                  Tab(text: 'Tribes'),
                ],
                labelColor: PolieColors.goldEmber,
                unselectedLabelColor: PolieColors.textSecondary,
                indicatorColor: PolieColors.goldEmber,
              ),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    _FeedTab(feedItems: feedItems),
                    _FriendsTab(),
                    _ChallengesTab(),
                    _TribesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Row(
        children: [
          Semantics(
            label: 'Back',
            button: true,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: PolieColors.textPrimary),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            ),
          ),
          SizedBox(width: PolieSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social Hub',
                  style: PolieTypography.h1(context).copyWith(
                    color: PolieColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: PolieSpacing.xs),
                Text(
                  'Connect and compete with friends',
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedTab extends HookConsumerWidget {
  final List<SocialFeedItem> feedItems;

  const _FeedTab({required this.feedItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> _refreshFeed() async {
      isLoading.value = true;
      await ref.read(socialFeedProvider.notifier).loadFeed();
      isLoading.value = false;
    }

    if (feedItems.isEmpty && !isLoading.value) {
      return RefreshIndicator(
        onRefresh: _refreshFeed,
        color: PolieColors.goldEmber,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rss_feed_outlined,
                    size: 64.sp,
                    color: PolieColors.textSecondary,
                  ),
                  SizedBox(height: PolieSpacing.lg),
                  Text(
                    'No activity yet',
                    style: PolieTypography.h3(context).copyWith(
                      color: PolieColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.sm),
                  Text(
                    'Your feed will show friend activities here',
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFeed,
      color: PolieColors.goldEmber,
      child: ListView.builder(
        padding: EdgeInsets.all(PolieSpacing.lg),
        itemCount: feedItems.length,
        itemBuilder: (context, index) {
          final item = feedItems[index];
          return _buildFeedCard(context, item, isDark)
              .animate(delay: Duration(milliseconds: index * 50))
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, SocialFeedItem item, bool isDark) {
    IconData icon;
    Color iconColor;
    String title;
    String subtitle = '';

    switch (item.type) {
      case 'lesson_complete':
        icon = Icons.school;
        iconColor = PolieColors.electricTeal;
        title = '${item.userName} completed a lesson';
        subtitle = item.details ?? 'Great progress!';
        break;
      case 'badge_earned':
        icon = Icons.emoji_events;
        iconColor = PolieColors.goldEmber;
        title = '${item.userName} earned a badge';
        subtitle = item.details ?? 'Achievement unlocked!';
        break;
      case 'streak_milestone':
        icon = Icons.local_fire_department;
        iconColor = PolieColors.error;
        title = '${item.userName} reached a streak milestone';
        subtitle = item.details ?? 'Keep it up!';
        break;
      case 'quest_progress':
        icon = Icons.flag;
        iconColor = PolieColors.royalAmethyst;
        title = '${item.userName} made quest progress';
        subtitle = item.details ?? 'Quest update';
        break;
      default:
        icon = Icons.notifications;
        iconColor = PolieColors.textSecondary;
        title = '${item.userName} has an update';
        subtitle = item.details ?? '';
    }

    final timeAgo = _formatTimeAgo(item.timestamp);

    return Padding(
      padding: EdgeInsets.only(bottom: PolieSpacing.md),
      child: PolieGlassCard(
        padding: EdgeInsets.all(PolieSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(icon, color: iconColor, size: 24.sp),
            ),
            SizedBox(width: PolieSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: PolieSpacing.xs),
                    Text(
                      subtitle,
                      style: PolieTypography.bodySmall(context).copyWith(
                        color: PolieColors.textSecondary,
                      ),
                    ),
                  ],
                  SizedBox(height: PolieSpacing.xs),
                  Text(
                    timeAgo,
                    style: PolieTypography.bodySmall(context).copyWith(
                      color: PolieColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class _FriendsTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final friends = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> _loadFriends() async {
      isLoading.value = true;
      try {
        final response = await ApiService.get(
          ApiContract.url('/api/social/friends'),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          if (data is Map && data['friends'] is List) {
            friends.value = (data['friends'] as List)
                .map((f) => f as Map<String, dynamic>)
                .toList();
          } else if (data is List) {
            friends.value = data.map((f) => f as Map<String, dynamic>).toList();
          }
        }
      } catch (e) {
        friends.value = [];
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      _loadFriends();
      return null;
    }, []);

    final filteredFriends = friends.value.where((friend) {
      final name = friend['username']?.toString().toLowerCase() ?? '';
      return name.contains(searchQuery.value.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(PolieSpacing.lg),
          child: TextField(
            onChanged: (value) => searchQuery.value = value,
            decoration: InputDecoration(
              hintText: 'Search friends...',
              prefixIcon: Icon(Icons.search, color: PolieColors.textSecondary),
              filled: true,
              fillColor: PolieColors.surfaceContainer.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(PolieRadius.md),
                borderSide: BorderSide.none,
              ),
              hintStyle: PolieTypography.body(context).copyWith(
                color: PolieColors.textSecondary,
              ),
            ),
            style: PolieTypography.body(context).copyWith(
              color: PolieColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: isLoading.value
              ? Center(
                  child: CircularProgressIndicator(color: PolieColors.goldEmber),
                )
              : filteredFriends.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64.sp,
                            color: PolieColors.textSecondary,
                          ),
                          SizedBox(height: PolieSpacing.lg),
                          Text(
                            searchQuery.value.isEmpty
                                ? 'No friends yet'
                                : 'No friends found',
                            style: PolieTypography.h3(context).copyWith(
                              color: PolieColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: PolieSpacing.sm),
                          Text(
                            searchQuery.value.isEmpty
                                ? 'Add friends to see them here'
                                : 'Try a different search',
                            style: PolieTypography.body(context).copyWith(
                              color: PolieColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: PolieSpacing.lg),
                      itemCount: filteredFriends.length,
                      itemBuilder: (context, index) {
                        final friend = filteredFriends[index];
                        return _buildFriendCard(context, friend, isDark);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFriendCard(BuildContext context, Map<String, dynamic> friend, bool isDark) {
    final friendId = friend['id']?.toString() ?? friend['_id']?.toString() ?? '';
    final username = friend['username']?.toString() ?? 'User';
    final streak = friend['streak'] ?? 0;
    final xp = friend['xp'] ?? 0;
    final isOnline = friend['isOnline'] ?? false;
    final learningLanguage = friend['learningLanguage']?.toString() ?? 'Yoruba';
    final avatar = friend['avatar']?.toString();

    return Padding(
      padding: EdgeInsets.only(bottom: PolieSpacing.md),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => FriendProfileScreen(friendId: friendId),
            ),
          );
        },
        child: PolieGlassCard(
          padding: EdgeInsets.all(PolieSpacing.md),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: PolieColors.royalAmethyst.withOpacity(0.2),
                    backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null
                        ? Text(
                            username[0].toUpperCase(),
                            style: PolieTypography.h3(context).copyWith(
                              color: PolieColors.royalAmethyst,
                            ),
                          )
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14.w,
                        height: 14.w,
                        decoration: BoxDecoration(
                          color: PolieColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PolieColors.obsidian,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: PolieSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: PolieTypography.body(context).copyWith(
                        color: PolieColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: PolieSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, size: 14.sp, color: PolieColors.error),
                        SizedBox(width: PolieSpacing.xs),
                        Text(
                          '$streak',
                          style: PolieTypography.bodySmall(context).copyWith(
                            color: PolieColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: PolieSpacing.sm),
                        Icon(Icons.star, size: 14.sp, color: PolieColors.goldEmber),
                        SizedBox(width: PolieSpacing.xs),
                        Text(
                          '$xp XP',
                          style: PolieTypography.bodySmall(context).copyWith(
                            color: PolieColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: PolieSpacing.xs),
                    Text(
                      'Learning $learningLanguage',
                      style: PolieTypography.bodySmall(context).copyWith(
                        color: PolieColors.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: PolieColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengesTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChallenges = useState<List<Map<String, dynamic>>>([]);
    final challengeResults = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> _loadChallenges() async {
      isLoading.value = true;
      try {
        final response = await ApiService.get(
          ApiContract.url('/api/social/challenges'),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          activeChallenges.value = (data['active'] as List?)?.map((c) => c as Map<String, dynamic>).toList() ?? [];
          challengeResults.value = (data['results'] as List?)?.map((c) => c as Map<String, dynamic>).toList() ?? [];
        }
      } catch (e) {
        activeChallenges.value = [];
        challengeResults.value = [];
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      _loadChallenges();
      return null;
    }, []);

    return isLoading.value
        ? Center(
            child: CircularProgressIndicator(color: PolieColors.goldEmber),
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(PolieSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const ChallengeFriendScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text('Challenge a Friend'),
                    style: FilledButton.styleFrom(
                      backgroundColor: PolieColors.goldEmber,
                      padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PolieRadius.md),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: PolieSpacing.xl),
                if (activeChallenges.value.isNotEmpty) ...[
                  Text(
                    'Active Challenges',
                    style: PolieTypography.h3(context).copyWith(
                      color: PolieColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.md),
                  ...activeChallenges.value.map((challenge) => _buildChallengeCard(context, challenge, isDark, isActive: true)),
                  SizedBox(height: PolieSpacing.xl),
                ],
                if (challengeResults.value.isNotEmpty) ...[
                  Text(
                    'Recent Results',
                    style: PolieTypography.h3(context).copyWith(
                      color: PolieColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.md),
                  ...challengeResults.value.map((challenge) => _buildChallengeCard(context, challenge, isDark, isActive: false)),
                ],
                if (activeChallenges.value.isEmpty && challengeResults.value.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 64.sp,
                          color: PolieColors.textSecondary,
                        ),
                        SizedBox(height: PolieSpacing.lg),
                        Text(
                          'No challenges yet',
                          style: PolieTypography.h3(context).copyWith(
                            color: PolieColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: PolieSpacing.sm),
                        Text(
                          'Challenge a friend to compete!',
                          style: PolieTypography.body(context).copyWith(
                            color: PolieColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
  }

  Widget _buildChallengeCard(BuildContext context, Map<String, dynamic> challenge, bool isDark, {required bool isActive}) {
    final friendName = challenge['friendName']?.toString() ?? 'Friend';
    final challengeType = challenge['type']?.toString() ?? 'XP Race';
    final progress = challenge['progress'] ?? 0.0;
    final friendProgress = challenge['friendProgress'] ?? 0.0;
    final won = challenge['won'] ?? false;
    final ended = challenge['ended'] ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: PolieSpacing.md),
      child: PolieGlassCard(
        padding: EdgeInsets.all(PolieSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  challengeType,
                  style: PolieTypography.body(context).copyWith(
                    color: PolieColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isActive && ended)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: won ? PolieColors.success.withOpacity(0.2) : PolieColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(PolieRadius.sm),
                    ),
                    child: Text(
                      won ? 'Won' : 'Lost',
                      style: PolieTypography.label(context).copyWith(
                        color: won ? PolieColors.success : PolieColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: PolieSpacing.sm),
            Text(
              'vs $friendName',
              style: PolieTypography.bodySmall(context).copyWith(
                color: PolieColors.textSecondary,
              ),
            ),
            if (isActive) ...[
              SizedBox(height: PolieSpacing.md),
              Text(
                'You: ${progress.toStringAsFixed(0)}',
                style: PolieTypography.bodySmall(context).copyWith(
                  color: PolieColors.textPrimary,
                ),
              ),
              SizedBox(height: PolieSpacing.xs),
              LinearProgressIndicator(
                value: progress / (progress + friendProgress).clamp(0.0, 1.0),
                backgroundColor: PolieColors.textSecondary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(PolieColors.goldEmber),
                minHeight: 6.h,
              ),
              SizedBox(height: PolieSpacing.xs),
              Text(
                '$friendName: ${friendProgress.toStringAsFixed(0)}',
                style: PolieTypography.bodySmall(context).copyWith(
                  color: PolieColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TribesTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tribeData = useState<Map<String, dynamic>?>(null);
    final isLoading = useState(true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> _loadTribeData() async {
      isLoading.value = true;
      try {
        final response = await ApiService.get(
          ApiContract.url('/api/gamification/tribe'),
        );

        if (response.statusCode == 200 && response.data != null) {
          tribeData.value = response.data as Map<String, dynamic>;
        }
      } catch (e) {
        tribeData.value = null;
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      _loadTribeData();
      return null;
    }, []);

    return isLoading.value
        ? Center(
            child: CircularProgressIndicator(color: PolieColors.goldEmber),
          )
        : tribeData.value == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 64.sp,
                      color: PolieColors.textSecondary,
                    ),
                    SizedBox(height: PolieSpacing.lg),
                    Text(
                      'Not in a tribe yet',
                      style: PolieTypography.h3(context).copyWith(
                        color: PolieColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: PolieSpacing.sm),
                    Text(
                      'Join or create a tribe to compete together',
                      style: PolieTypography.body(context).copyWith(
                        color: PolieColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: PolieSpacing.xl),
                    FilledButton(
                      onPressed: () {
                        // Navigate to find/create tribe screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tribe feature coming soon!')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: PolieColors.goldEmber,
                        padding: EdgeInsets.symmetric(
                          horizontal: PolieSpacing.xl,
                          vertical: PolieSpacing.md,
                        ),
                      ),
                      child: Text('Find a Tribe'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(PolieSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PolieGlassCard(
                      padding: EdgeInsets.all(PolieSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tribeData.value!['name']?.toString() ?? 'My Tribe',
                            style: PolieTypography.h2(context).copyWith(
                              color: PolieColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: PolieSpacing.md),
                          Row(
                            children: [
                              Icon(Icons.people, size: 16.sp, color: PolieColors.textSecondary),
                              SizedBox(width: PolieSpacing.xs),
                              Text(
                                '${tribeData.value!['memberCount'] ?? 0} members',
                                style: PolieTypography.body(context).copyWith(
                                  color: PolieColors.textSecondary,
                                ),
                              ),
                              SizedBox(width: PolieSpacing.lg),
                              Icon(Icons.emoji_events, size: 16.sp, color: PolieColors.goldEmber),
                              SizedBox(width: PolieSpacing.xs),
                              Text(
                                'Rank #${tribeData.value!['rank'] ?? 'N/A'}',
                                style: PolieTypography.body(context).copyWith(
                                  color: PolieColors.goldEmber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: PolieSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to tribe chat
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tribe chat coming soon!')),
                          );
                        },
                        icon: Icon(Icons.chat),
                        label: Text('Tribe Chat'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                          side: BorderSide(color: PolieColors.goldEmber),
                        ),
                      ),
                    ),
                    SizedBox(height: PolieSpacing.lg),
                    Text(
                      'Tribe Leaderboard',
                      style: PolieTypography.h3(context).copyWith(
                        color: PolieColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: PolieSpacing.md),
                    PolieGlassCard(
                      padding: EdgeInsets.all(PolieSpacing.lg),
                      child: Column(
                        children: [
                          Text(
                            'Top 3 Members',
                            style: PolieTypography.body(context).copyWith(
                              color: PolieColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: PolieSpacing.md),
                          Text(
                            'Leaderboard data will appear here',
                            style: PolieTypography.bodySmall(context).copyWith(
                              color: PolieColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
  }
}
