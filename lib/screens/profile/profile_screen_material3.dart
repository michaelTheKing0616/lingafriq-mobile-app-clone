import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/settings/settings_screen_material3.dart';
import 'package:lingafriq/screens/gamification/badge_collection_screen.dart';
import 'package:lingafriq/screens/gamification/leaderboard_screen.dart';
import 'package:lingafriq/screens/gamification/quest_screen.dart';
import 'package:lingafriq/screens/progress/progress_dashboard_screen.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_edit_screen.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/skeleton_loader.dart';
import 'package:lingafriq/widgets/error_state_widget.dart';

/// Beautiful Material 3 Profile Screen with Pan-African Design
class ProfileScreenMaterial3 extends HookConsumerWidget {
  const ProfileScreenMaterial3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider);
    final gamificationState = ref.watch(gamificationProvider);
    final gamification = ref.read(gamificationProvider.notifier).gamification;

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ResponsiveSafeArea(
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
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Column(
                      children: [
                        SizedBox(height: PanAfricanSpacing.sm),

                        // Profile Info Card
                        _buildProfileInfoCard(context, isDark, user, ref),
                        SizedBox(height: PanAfricanSpacing.lg),

                        // Stats
                        gamificationState.hasError
                            ? AppErrorState(
                                message: gamificationState.errorMessage ?? 'Failed to load profile stats.',
                                onRetry: () {
                                  ref.read(userProvider.notifier).refreshUser();
                                  ref.invalidate(gamificationProvider);
                                },
                              )
                            : gamificationState.isLoading
                            ? Row(
                                children: [
                                  Expanded(child: SkeletonStatCard()),
                                  SizedBox(width: PanAfricanSpacing.sm),
                                  Expanded(child: SkeletonStatCard()),
                                  SizedBox(width: PanAfricanSpacing.sm),
                                  Expanded(child: SkeletonStatCard()),
                                ],
                              )
                            : _buildStats(
                          context,
                          isDark,
                              streak: gamification.dailyStreak,
                              totalXp: gamification.xp,
                              level: gamification.level,
                            ),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          SizedBox(width: PanAfricanSpacing.md),
          Expanded(
            child: Text(
              'Profile',
              style: PanAfricanTypography.headlineMedium(context)
                  .copyWith(color: onSurface),
            ),
          ),
          _HeaderIconButton(
            icon: Icons.settings_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                SmoothPageRoute(
                  child: SettingsScreenMaterial3(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard(
      BuildContext context, bool isDark, ProfileModel? user, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = user != null
        ? '${user.first_name} ${user.last_name}'.trim()
        : 'User';
    final globalId = user?.global_id ?? user?.username ?? 'username';
    final avatar = user?.avatar;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        boxShadow: PanAfricanShadows.sm,
      ),
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: PanAfricanShadows.sm,
                ),
                child: CircleAvatar(
                  radius: 50.w,
                  backgroundColor: PanAfricanColors.primary,
                  backgroundImage: avatar != null && avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null,
                  child: avatar == null || avatar.isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          size: 50.sp,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.xxs),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? PanAfricanColors.surfaceDark
                          : PanAfricanColors.surfaceLight,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 16.sp,
                    color: colorScheme.onPrimary,
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
                Icons.alternate_email_rounded,
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
                  Icons.info_outline_rounded,
                  size: 14.sp,
                  color: PanAfricanColors.neutralMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.md),
          PanAfricanButton(
            label: 'Edit Profile',
            icon: Icons.edit_rounded,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                SmoothPageRoute(
                  child: ProfileEditScreen(),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildStats(
    BuildContext context,
    bool isDark, {
    required int streak,
    required int totalXp,
    required int level,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            label: 'Streak',
            value: '$streak',
            icon: Icons.local_fire_department_rounded,
            color: PanAfricanColors.tertiary,
            isDark: isDark,
          )
              .animate(delay: 100.ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.1),
        ),
        SizedBox(width: PanAfricanSpacing.sm),
        Expanded(
          child: _StatItem(
            label: 'XP',
            value: _formatCompactNumber(totalXp),
            icon: Icons.star_rounded,
            color: PanAfricanColors.secondary,
            isDark: isDark,
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
        ),
        SizedBox(width: PanAfricanSpacing.sm),
        Expanded(
          child: _StatItem(
            label: 'Level',
            value: '$level',
            icon: Icons.trending_up_rounded,
            color: PanAfricanColors.primary,
            isDark: isDark,
          ).animate(delay: 300.ms).fadeIn(duration: 300.ms).slideX(begin: 0.1),
        ),
      ],
    );
  }

  String _formatCompactNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(1)}K';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}K';
    return value.toString();
  }

  Widget _buildMenuItems(BuildContext context, bool isDark) {
    final iconColor = PanAfricanColors.primary;
    final menuItems = [
      _MenuItem(
        title: 'Badges',
        icon: Icons.workspace_premium_rounded,
        color: iconColor,
        onTap: () {
          Navigator.push(
            context,
            SmoothPageRoute(
              child: BadgeCollectionScreen(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Leaderboard',
        icon: Icons.emoji_events_rounded,
        color: iconColor,
        onTap: () {
          Navigator.push(
            context,
            SmoothPageRoute(
              child: LeaderboardScreen(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Achievements',
        icon: Icons.stars_rounded,
        color: iconColor,
        onTap: () {
          Navigator.push(
            context,
            SmoothPageRoute(child: const QuestScreen()),
          );
        },
      ),
      _MenuItem(
        title: 'Progress',
        icon: Icons.timeline_rounded,
        color: iconColor,
        onTap: () {
          Navigator.push(
            context,
            SmoothPageRoute(child: const ProgressDashboardScreen()),
          );
        },
      ),
      _MenuItem(
        title: 'Settings',
        icon: Icons.settings_rounded,
        color: iconColor,
        onTap: () {
          Navigator.push(
            context,
            SmoothPageRoute(
              child: SettingsScreenMaterial3(),
            ),
          );
        },
      ),
    ];

    return Column(
      children: menuItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Container(
          margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            boxShadow: PanAfricanShadows.sm,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                item.onTap();
              },
              borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: PanAfricanSpacing.sm,
                  vertical: PanAfricanSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(PanAfricanSpacing.sm),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.md),
                    Expanded(
                      child: Text(
                        item.title,
                        style: PanAfricanTypography.bodyLarge(context),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: PanAfricanColors.neutralMedium,
                      size: 24.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.1);
      }).toList(),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: onSurface.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.sm),
          child: Icon(icon, color: onSurface, size: 24.sp),
        ),
      ),
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

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
