import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/screens/social/challenge_friend_screen.dart';
import 'package:lingafriq/screens/social/social_gifting_screen.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/integration_helpers.dart';

class FriendProfileScreen extends HookConsumerWidget {
  final String friendId;

  const FriendProfileScreen({
    Key? key,
    required this.friendId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(true);
    final friendData = useState<Map<String, dynamic>?>(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    useEffect(() {
      _loadFriendProfile();
      return null;
    }, []);

    Future<void> _loadFriendProfile() async {
      isLoading.value = true;
      await safeAsync(
        context: context,
        operation: () async {
          final response = await ApiService.get(
            ApiContract.url('/api/users/$friendId/profile'),
          );

          if (response.statusCode == 200 && response.data != null) {
            friendData.value = response.data as Map<String, dynamic>;
          }
        },
        errorContext: 'loadFriendProfile',
        showError: true,
      );
      isLoading.value = false;
    }

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
          child: isLoading.value
              ? Center(
                  child: CircularProgressIndicator(color: PolieColors.goldEmber),
                )
              : friendData.value == null
                  ? Center(
                      child: Text(
                        'Friend not found',
                        style: PolieTypography.body(context).copyWith(
                          color: PolieColors.textSecondary,
                        ),
                      ),
                    )
                  : _buildProfileContent(context, friendData.value!, isDark),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, Map<String, dynamic> data, bool isDark) {
    final username = data['username']?.toString() ?? 'User';
    final bio = data['bio']?.toString();
    final streak = data['streak'] ?? 0;
    final xp = data['xp'] ?? 0;
    final level = data['level'] ?? 1;
    final badges = data['badges'] as List? ?? [];
    final languages = data['languages'] as List? ?? [];
    final memberSince = data['createdAt'] != null
        ? DateTime.parse(data['createdAt'].toString())
        : DateTime.now();

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(context, username),
          SizedBox(height: PolieSpacing.lg),
          _buildAvatarSection(context, username, isDark),
          SizedBox(height: PolieSpacing.lg),
          _buildStatsSection(context, streak, xp, level, isDark),
          SizedBox(height: PolieSpacing.lg),
          if (bio != null && bio.isNotEmpty) ...[
            _buildBioSection(context, bio, isDark),
            SizedBox(height: PolieSpacing.lg),
          ],
          if (languages.isNotEmpty) ...[
            _buildLanguagesSection(context, languages, isDark),
            SizedBox(height: PolieSpacing.lg),
          ],
          if (badges.isNotEmpty) ...[
            _buildBadgesSection(context, badges, isDark),
            SizedBox(height: PolieSpacing.lg),
          ],
          _buildActionsSection(context, isDark),
          SizedBox(height: PolieSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String username) {
    return Padding(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: PolieColors.textPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          Expanded(
            child: Text(
              username,
              style: PolieTypography.h1(context).copyWith(
                color: PolieColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, String username, bool isDark) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50.r,
            backgroundColor: PolieColors.royalAmethyst.withOpacity(0.2),
            child: Text(
              username[0].toUpperCase(),
              style: PolieTypography.h1(context).copyWith(
                color: PolieColors.royalAmethyst,
                fontSize: 48.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, int streak, int xp, int level, bool isDark) {
    return PolieGlassCard(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, 'Streak', streak.toString(), Icons.local_fire_department_rounded, PolieColors.error),
          _buildStatItem(context, 'XP', xp.toString(), Icons.star_rounded, PolieColors.goldEmber),
          _buildStatItem(context, 'Level', level.toString(), Icons.trending_up_rounded, PolieColors.electricTeal),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: PolieSpacing.xs),
        Text(
          value,
          style: PolieTypography.h2(context).copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: PolieSpacing.xs),
        Text(
          label,
          style: PolieTypography.bodySmall(context).copyWith(
            color: PolieColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection(BuildContext context, String bio, bool isDark) {
    return PolieGlassCard(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bio',
            style: PolieTypography.h3(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: PolieSpacing.sm),
          Text(
            bio,
            style: PolieTypography.body(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection(BuildContext context, List languages, bool isDark) {
    return PolieGlassCard(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning',
            style: PolieTypography.h3(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: PolieSpacing.sm),
          Wrap(
            spacing: PolieSpacing.sm,
            runSpacing: PolieSpacing.sm,
            children: languages.map((lang) {
              final langName = lang is Map ? lang['name']?.toString() ?? lang.toString() : lang.toString();
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: PolieSpacing.md,
                  vertical: PolieSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: PolieColors.electricTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(PolieRadius.pill),
                  border: Border.all(color: PolieColors.electricTeal.withOpacity(0.5)),
                ),
                child: Text(
                  langName,
                  style: PolieTypography.bodySmall(context),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, List badges, bool isDark) {
    return PolieGlassCard(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Badges',
            style: PolieTypography.h3(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: PolieSpacing.md),
          SizedBox(
            height: 80.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                final badgeName = badge is Map ? badge['name']?.toString() ?? 'Badge' : badge.toString();
                return Container(
                  margin: EdgeInsets.only(right: PolieSpacing.sm),
                  width: 80.w,
                  child: Column(
                    children: [
                      Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          color: PolieColors.goldEmber.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: PolieColors.goldEmber),
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: PolieColors.goldEmber,
                          size: 32,
                        ),
                      ),
                      SizedBox(height: PolieSpacing.xs),
                      Text(
                        badgeName,
                        style: PolieTypography.bodySmall(context),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PolieSpacing.lg),
      child: Column(
        children: [
          PoliePrimaryButton(
            label: 'Challenge',
            icon: Icons.emoji_events_rounded,
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => ChallengeFriendScreen(friendId: friendId),
                ),
              );
            },
          ),
          SizedBox(height: PolieSpacing.md),
          PoliePrimaryButton(
            label: 'Send Gift',
            icon: Icons.card_giftcard_rounded,
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const SocialGiftingScreen(),
                ),
              );
            },
          ),
          SizedBox(height: PolieSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _removeFriend(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PolieColors.error,
                    side: BorderSide(color: PolieColors.error),
                  ),
                  child: Text('Remove Friend'),
                ),
              ),
              SizedBox(width: PolieSpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _blockFriend(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PolieColors.error,
                    side: BorderSide(color: PolieColors.error),
                  ),
                  child: Text('Block'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _removeFriend(BuildContext context) async {
    // Implement remove friend logic
  }

  Future<void> _blockFriend(BuildContext context) async {
    // Implement block friend logic
  }
}
