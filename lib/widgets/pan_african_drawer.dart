import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/pan_african_design_system.dart';
import '../providers/user_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/navigation_provider.dart';
import '../screens/tabs_view/tabs_view.dart';

/// Beautiful Pan-African themed navigation drawer
/// 
/// Features:
/// - User profile header with XP and level
/// - Organized sections with icons
/// - Beautiful transitions and animations
/// - Material 3 compliant
class PanAfricanDrawer extends ConsumerWidget {
  const PanAfricanDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final gamification = ref.watch(gamificationProvider.notifier).gamification;
    final isDark = context.isDark;

    return Drawer(
      backgroundColor: context.panSurface,
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            _buildUserHeader(context, ref, user, gamification, isDark),
            
            // Drawer Items
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      context: context,
                      title: 'Learn',
                      items: [
                        _DrawerItem(
                          icon: Icons.home_rounded,
                          title: 'Home',
                          onTap: () => _navigateToTab(context, ref, 0),
                        ),
                        _DrawerItem(
                          icon: Icons.smart_toy_rounded,
                          title: 'AI Chat (Polie)',
                          subtitle: 'Your AI language tutor',
                          onTap: () => _navigateTo(context, ref, 'ai_chat_select'),
                        ),
                        _DrawerItem(
                          icon: Icons.school_rounded,
                          title: 'Curriculum',
                          onTap: () => _navigateTo(context, ref, 'curriculum'),
                        ),
                        _DrawerItem(
                          icon: Icons.sports_esports_rounded,
                          title: 'Language Games',
                          subtitle: '35+ educational games',
                          onTap: () => _navigateTo(context, ref, 'games'),
                        ),
                      ],
                    ),
                    
                    _buildSection(
                      context: context,
                      title: 'Progress & Goals',
                      items: [
                        _DrawerItem(
                          icon: Icons.track_changes_rounded,
                          title: 'Daily Goals',
                          onTap: () => _navigateTo(context, ref, 'daily_goals'),
                        ),
                        _DrawerItem(
                          icon: Icons.analytics_rounded,
                          title: 'Progress Dashboard',
                          onTap: () => _navigateTo(context, ref, 'progress'),
                        ),
                        _DrawerItem(
                          icon: Icons.emoji_events_rounded,
                          title: 'Achievements',
                          onTap: () => _navigateTo(context, ref, 'achievements'),
                        ),
                        _DrawerItem(
                          icon: Icons.workspace_premium_rounded,
                          title: 'Badges',
                          onTap: () => _navigateTo(context, ref, 'badges'),
                        ),
                      ],
                    ),
                    
                    _buildSection(
                      context: context,
                      title: 'Community & Social',
                      items: [
                        _DrawerItem(
                          icon: Icons.leaderboard_rounded,
                          title: 'Leaderboards',
                          onTap: () => _navigateTo(context, ref, 'leaderboard'),
                        ),
                        _DrawerItem(
                          icon: Icons.groups_rounded,
                          title: 'My Tribe',
                          onTap: () => _navigateTo(context, ref, 'tribe'),
                        ),
                        _DrawerItem(
                          icon: Icons.stadium_rounded,
                          title: 'Tribe vs Tribe',
                          onTap: () => _navigateTo(context, ref, 'tribe_vs_tribe'),
                        ),
                        _DrawerItem(
                          icon: Icons.location_city_rounded,
                          title: 'Language Villages',
                          onTap: () => _navigateTo(context, ref, 'villages'),
                        ),
                        _DrawerItem(
                          icon: Icons.forum_rounded,
                          title: 'Global Chat',
                          onTap: () => _navigateTo(context, ref, 'global_chat'),
                        ),
                        _DrawerItem(
                          icon: Icons.people_rounded,
                          title: 'Connections',
                          onTap: () => _navigateTo(context, ref, 'connections'),
                        ),
                      ],
                    ),
                    
                    _buildSection(
                      context: context,
                      title: 'Adventure',
                      items: [
                        _DrawerItem(
                          icon: Icons.auto_stories_rounded,
                          title: 'The Great Journey',
                          subtitle: 'Story mode',
                          accentColor: PanAfricanColors.secondary,
                          onTap: () => _navigateTo(context, ref, 'quest'),
                        ),
                        _DrawerItem(
                          icon: Icons.event_rounded,
                          title: 'Seasonal Events',
                          onTap: () => _navigateTo(context, ref, 'events'),
                        ),
                        _DrawerItem(
                          icon: Icons.auto_awesome_rounded,
                          title: 'Magic Items',
                          onTap: () => _navigateTo(context, ref, 'magic_items'),
                        ),
                        _DrawerItem(
                          icon: Icons.account_tree_rounded,
                          title: 'Ancestral Tree',
                          onTap: () => _navigateTo(context, ref, 'ancestral_tree'),
                        ),
                      ],
                    ),
                    
                    _buildSection(
                      context: context,
                      title: 'Culture & Content',
                      items: [
                        _DrawerItem(
                          icon: Icons.menu_book_rounded,
                          title: 'Culture Magazine',
                          onTap: () => _navigateTo(context, ref, 'magazine'),
                        ),
                        _DrawerItem(
                          icon: Icons.create_rounded,
                          title: 'Create Content',
                          subtitle: 'Lessons, quizzes, stories',
                          onTap: () => _navigateTo(context, ref, 'ugc'),
                        ),
                        _DrawerItem(
                          icon: Icons.record_voice_over_rounded,
                          title: 'Contribute Your Voice',
                          subtitle: 'Help train our AI',
                          accentColor: PanAfricanColors.kenteBlue,
                          onTap: () => _navigateTo(context, ref, 'contribute_voice'),
                        ),
                        _DrawerItem(
                          icon: Icons.upload_file_rounded,
                          title: 'Import Media',
                          onTap: () => _navigateTo(context, ref, 'import_media'),
                        ),
                      ],
                    ),
                    
                    _buildSection(
                      context: context,
                      title: 'Settings & Help',
                      items: [
                        _DrawerItem(
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          onTap: () => _navigateTo(context, ref, 'settings'),
                        ),
                        _DrawerItem(
                          icon: Icons.help_outline_rounded,
                          title: 'Features Guide',
                          onTap: () => _navigateTo(context, ref, 'features_guide'),
                        ),
                        _DrawerItem(
                          icon: Icons.policy_rounded,
                          title: 'App Policy',
                          onTap: () => _navigateTo(context, ref, 'policy'),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: PanAfricanSpacing.xl),
                  ],
                ),
              ),
            ),
            
            // Logout Button
            _buildLogoutButton(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    dynamic gamification,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.forest,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(PanAfricanRadius.xl),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Close button
              IconButton(
                icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              // Settings quick access
              IconButton(
                icon: Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
                onPressed: () => _navigateTo(context, ref, 'settings'),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          
          // User Avatar
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: PanAfricanColors.secondary, width: 3),
              boxShadow: PanAfricanShadows.glowGold(0.3),
            ),
            child: ClipOval(
              child: user?.profilePicUrl != null && user.profilePicUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: user.profilePicUrl,
                      fit: BoxFit.cover,
                      placeholder: (ctx, __) => _buildAvatarPlaceholder(ctx, user),
                      errorWidget: (ctx, __, ___) => _buildAvatarPlaceholder(ctx, user),
                    )
                  : _buildAvatarPlaceholder(context, user),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          
          // User Name
          Text(
            user?.fullName ?? 'Guest User',
            style: PanAfricanTypography.titleLarge(context, color: Theme.of(context).colorScheme.onPrimary),
          ),
          SizedBox(height: PanAfricanSpacing.xxs),
          
          // Level & Title
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.sm,
              vertical: PanAfricanSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: PanAfricanColors.secondary.withOpacity(0.2),
              borderRadius: PanAfricanRadius.roundBR,
              border: Border.all(color: PanAfricanColors.secondary.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: PanAfricanColors.secondary, size: 16.sp),
                SizedBox(width: PanAfricanSpacing.xxs),
                Text(
                  'Level ${gamification.level} • ${gamification.levelTitle}',
                  style: PanAfricanTypography.labelMedium(context, color: PanAfricanColors.secondary),
                ),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          
          // XP Progress Bar
          _buildXPProgressBar(context, gamification),
          
          SizedBox(height: PanAfricanSpacing.sm),
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(context, '🔥', '${gamification.dailyStreak}', 'Streak'),
              _buildStatItem(context, '⭐', '${gamification.xp}', 'XP'),
              _buildStatItem(context, '🐚', '${gamification.cowries}', 'Cowries'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(BuildContext context, dynamic user) {
    final initials = user?.fullName?.isNotEmpty == true
        ? user.fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase()
        : 'GU';
    
    return Container(
      color: PanAfricanColors.primaryDark,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildXPProgressBar(BuildContext context, dynamic gamification) {
    final currentLevel = gamification.level;
    final xpForCurrentLevel = (currentLevel * currentLevel * 100);
    final xpForNextLevel = ((currentLevel + 1) * (currentLevel + 1) * 100);
    final xpInCurrentLevel = gamification.xp - xpForCurrentLevel;
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;
    final progress = xpNeeded > 0 ? (xpInCurrentLevel / xpNeeded).clamp(0.0, 1.0) : 1.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toInt()}% to Level ${currentLevel + 1}',
              style: PanAfricanTypography.labelSmall(context, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
            ),
            Text(
              '$xpInCurrentLevel / $xpNeeded XP',
              style: PanAfricanTypography.labelSmall(context, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
            ),
          ],
        ),
        SizedBox(height: PanAfricanSpacing.xxs),
        ClipRRect(
          borderRadius: PanAfricanRadius.roundBR,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6.h,
            backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(PanAfricanColors.secondary),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String emoji, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 16.sp)),
            SizedBox(width: 4.w),
            Text(
              value,
              style: PanAfricanTypography.titleMedium(context, color: Theme.of(context).colorScheme.onPrimary),
            ),
          ],
        ),
        Text(
          label,
          style: PanAfricanTypography.labelSmall(context, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<_DrawerItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            PanAfricanSpacing.lg,
            PanAfricanSpacing.lg,
            PanAfricanSpacing.lg,
            PanAfricanSpacing.xs,
          ),
          child: Text(
            title.toUpperCase(),
            style: PanAfricanTypography.labelSmall(context).copyWith(
              color: context.panTextSecondary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...items.map((item) => _buildDrawerTile(context, item)),
      ],
    );
  }

  Widget _buildDrawerTile(BuildContext context, _DrawerItem item) {
    final iconColor = item.accentColor ?? context.panPrimary;
    
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: PanAfricanRadius.smBR,
        ),
        child: Icon(item.icon, color: iconColor, size: 22.sp),
      ),
      title: Text(
        item.title,
        style: PanAfricanTypography.titleMedium(context),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: PanAfricanTypography.bodySmall(context),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: context.panTextSecondary,
        size: 20.sp,
      ),
      onTap: item.onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.lg,
        vertical: PanAfricanSpacing.xxs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: PanAfricanRadius.smBR,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _handleLogout(context, ref),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: PanAfricanColors.error,
            side: BorderSide(color: PanAfricanColors.error.withOpacity(0.5)),
            padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: PanAfricanRadius.mdBR,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTab(BuildContext context, WidgetRef ref, int index) {
    ref.read(tabIndexProvider.notifier).setIndex(index);
    Navigator.of(context).pop();
  }

  void _navigateTo(BuildContext context, WidgetRef ref, String route) {
    Navigator.of(context).pop();
    // Map route names to actual screens
    // This would be replaced with proper routing
    ref.read(navigationProvider).navigateToNamed(route);
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: PanAfricanColors.error,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Handle logout
    }
  }
}

class _DrawerItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? accentColor;
  final VoidCallback onTap;

  _DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.accentColor,
    required this.onTap,
  });
}

