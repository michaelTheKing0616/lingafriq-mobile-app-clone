import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/settings/settings_screen_material3.dart';
import 'package:lingafriq/screens/gamification/badge_collection_screen.dart';
import 'package:lingafriq/screens/gamification/leaderboard_screen.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_edit_screen.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

/// Beautiful Material 3 Profile Screen with Pan-African Design
class ProfileScreenMaterial3 extends HookConsumerWidget {
  const ProfileScreenMaterial3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, isDark),
              
              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? PanAfricanColors.surfaceDark
                        : PanAfricanColors.surfaceLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(PanAfricanRadius.xl),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(PanAfricanSpacing.lg),
                    child: Column(
                      children: [
                        // Profile Info Card
                        _buildProfileInfoCard(context, isDark, user, ref),
                        SizedBox(height: PanAfricanSpacing.lg),

                        // Stats
                        _buildStats(context, isDark),
                        SizedBox(height: PanAfricanSpacing.lg),

                        // Menu Items
                        _buildMenuItems(context, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Profile',
              style: PanAfricanTypography.headlineMedium(context)
                  .copyWith(color: Colors.white),
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                SmoothPageRoute(child: SettingsScreenMaterial3(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard(BuildContext context, bool isDark, ProfileModel? user, WidgetRef ref) {
    final displayName = user != null 
        ? '${user.first_name} ${user.last_name}'.trim()
        : 'User';
    final globalId = user?.global_id ?? user?.username ?? 'username';
    final avatar = user?.avater;
    
    return Card(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50.r,
                  backgroundColor: PanAfricanColors.primary,
                  backgroundImage: avatar != null && avatar.isNotEmpty 
                      ? NetworkImage(avatar) 
                      : null,
                  child: avatar == null || avatar.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 50.sp,
                          color: Colors.white,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(PanAfricanSpacing.xxs),
                    decoration: BoxDecoration(
                      color: PanAfricanColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? PanAfricanColors.surfaceDark
                            : PanAfricanColors.surfaceLight,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16.sp,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              displayName,
              style: PanAfricanTypography.headlineSmall(context),
            ),
            SizedBox(height: PanAfricanSpacing.xxs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.alternate_email,
                  size: 14.sp,
                  color: PanAfricanColors.primary,
                ),
                SizedBox(width: PanAfricanSpacing.xxs),
                Text(
                  '@$globalId',
                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                    color: PanAfricanColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: PanAfricanSpacing.xs),
                Tooltip(
                  message: 'Your unique handle (global_id) - shown in chat and search',
                  child: Icon(
                    Icons.info_outline,
                    size: 14.sp,
                    color: PanAfricanColors.neutralMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            PanAfricanButton(
              label: 'Edit Profile',
              icon: Icons.edit,
              onPressed: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    child: ProfileEditScreen(),
                  ),
                );
              },
              hasGradient: true,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildStats(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            label: 'Streak',
            value: '7',
            icon: Icons.local_fire_department,
            color: PanAfricanColors.tertiary,
            isDark: isDark,
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms).slideX(begin: -0.2),
        ),
        SizedBox(width: PanAfricanSpacing.md),
        Expanded(
          child: _StatItem(
            label: 'XP',
            value: '2,450',
            icon: Icons.star,
            color: PanAfricanColors.secondary,
            isDark: isDark,
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
        ),
        SizedBox(width: PanAfricanSpacing.md),
        Expanded(
          child: _StatItem(
            label: 'Level',
            value: '12',
            icon: Icons.trending_up,
            color: PanAfricanColors.primary,
            isDark: isDark,
          ).animate(delay: 300.ms).fadeIn(duration: 300.ms).slideX(begin: 0.2),
        ),
      ],
    );
  }

  Widget _buildMenuItems(BuildContext context, bool isDark) {
    final menuItems = [
      {
        'title': 'Badges',
        'icon': Icons.workspace_premium,
        'color': PanAfricanColors.secondary,
        'onTap': () {
          Navigator.push(
            context,
            SmoothPageRoute(child: BadgeCollectionScreen(),
            ),
          );
        },
      },
      {
        'title': 'Leaderboard',
        'icon': Icons.emoji_events,
        'color': PanAfricanColors.tertiary,
        'onTap': () {
          Navigator.push(
            context,
            SmoothPageRoute(child: LeaderboardScreen(),
            ),
          );
        },
      },
      {
        'title': 'Achievements',
        'icon': Icons.stars,
        'color': PanAfricanColors.kenteBlue,
        'onTap': () {},
      },
      {
        'title': 'Progress',
        'icon': Icons.timeline,
        'color': PanAfricanColors.primary,
        'onTap': () {},
      },
      {
        'title': 'Settings',
        'icon': Icons.settings,
        'color': PanAfricanColors.neutralMedium,
        'onTap': () {
          Navigator.push(
            context,
            SmoothPageRoute(child: SettingsScreenMaterial3(),
            ),
          );
        },
      },
    ];

    return Column(
      children: menuItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Card(
          margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(PanAfricanSpacing.sm),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: item['color'] as Color,
              ),
            ),
            title: Text(
              item['title'] as String,
              style: PanAfricanTypography.titleMedium(context),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
            onTap: () {
              HapticFeedback.mediumImpact();
              (item['onTap'] as VoidCallback)();
            },
          ),
        )
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.2);
      }).toList(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: PanAfricanSpacing.xs),
          Text(
            value,
            style: PanAfricanTypography.titleLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.xxs),
          Text(
            label,
            style: PanAfricanTypography.bodySmall(context),
          ),
        ],
      ),
    );
  }
}

