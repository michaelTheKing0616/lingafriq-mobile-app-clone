import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/profile/change_password_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_edit_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/suggest_language_screen.dart';
import 'package:lingafriq/screens/tabs_view/standings/standings_tab_material3.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/gamification/currency_display_widget.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/pan_african_app_bar.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';
import 'package:lingafriq/providers/tab_scaffold_provider.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/avatars/avatars.dart';
import 'delete_account_dialogue.dart';

/// Beautiful Material 3 Profile Tab with Pan-African Design
class ProfileTabMaterial3 extends HookConsumerWidget {
  const ProfileTabMaterial3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isLoading = ref.watch(apiProvider.select((value) => value.isLoading));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(gamificationProvider);
    final gamificationNotifier = ref.read(gamificationProvider.notifier);
    final gamification = gamificationNotifier.gamification;
    final unlockedBadges = gamificationNotifier.unlockedBadges.length;
    final totalBadges = gamificationNotifier.allBadges.length;
    final badgeProgress = totalBadges > 0 ? unlockedBadges / totalBadges : 0.0;

    return LoadingOverlayPro(
      isLoading: isLoading,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? PanAfricanGradients.darkSurface
                : PanAfricanGradients.forest,
          ),
          child: ResponsiveSafeArea(
            child: Column(
              children: [
                // Header with Pan-African App Bar
                PanAfricanAppBar(
                  title: 'Profile',
                  showBackButton: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () {
                        ref.read(scaffoldKeyProvider).currentState?.openDrawer();
                      },
                      tooltip: 'Menu',
                    ),
                  ],
                ),

                // Profile Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AdaptiveLayout.sideMargin(context),
                    vertical: PanAfricanSpacing.md,
                  ),
                  child: PanAfricanCard(
                    hasGradientBorder: true,
                    gradientStart: PanAfricanColors.secondary,
                    gradientEnd: PanAfricanColors.tertiary,
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Row(
                      children: [
                        // Profile Avatar (from Avatar Intelligence System)
                        LingAfriqAvatar(
                          size: 0.25.sw,
                          showBorder: true,
                          onTap: () {
                            ref.read(navigationProvider).navigateTo(
                              const ProfileEditScreen(),
                            );
                          },
                        ),
                        SizedBox(width: PanAfricanSpacing.md),
                        // Profile Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (user != null)
                                Text(
                                  user.username ?? 'User',
                                  style: PanAfricanTypography.headlineSmall(context),
                                ),
                              SizedBox(height: PanAfricanSpacing.xs),
                              if (user != null)
                                Text(
                                  user.email ?? '',
                                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                                    color: PanAfricanColors.neutralMedium,
                                  ),
                                ),
                              SizedBox(height: PanAfricanSpacing.sm),
                              Wrap(
                                spacing: PanAfricanSpacing.xs,
                                runSpacing: PanAfricanSpacing.xxs,
                                children: [
                                  PanAfricanBadge(
                                    label: 'Level ${user?.level ?? 1}',
                                    color: PanAfricanColors.primary,
                                    icon: Icons.trending_up_rounded,
                                  ),
                                  PanAfricanBadge(
                                    label: 'Streak ${user?.streak ?? 0}',
                                    color: PanAfricanColors.tertiary,
                                    icon: Icons.local_fire_department_rounded,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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
                      padding: EdgeInsets.symmetric(
                        horizontal: AdaptiveLayout.sideMargin(context),
                        vertical: PanAfricanSpacing.md,
                      ),
                      child: Column(
                        children: [
                          // Currency Display
                          CurrencyDisplayWidget(compact: false),
                          SizedBox(height: PanAfricanSpacing.md),

                          // Achievements Summary
                          PanAfricanCard(
                            hasGradientBorder: true,
                            gradientStart: PanAfricanColors.primary,
                            gradientEnd: PanAfricanColors.secondary,
                            padding: EdgeInsets.all(PanAfricanSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.workspace_premium_rounded,
                                        color: PanAfricanColors.secondary),
                                    SizedBox(width: PanAfricanSpacing.sm),
                                    Text(
                                      'Achievements',
                                      style: PanAfricanTypography.titleLarge(context),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$unlockedBadges/$totalBadges',
                                      style: PanAfricanTypography.labelLarge(context).copyWith(
                                        color: PanAfricanColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: PanAfricanSpacing.sm),
                                PanAfricanProgressBar(
                                  progress: badgeProgress,
                                  color: PanAfricanColors.secondary,
                                  height: 8.h,
                                ),
                                SizedBox(height: PanAfricanSpacing.md),
                                Wrap(
                                  spacing: PanAfricanSpacing.sm,
                                  runSpacing: PanAfricanSpacing.xxs,
                                  children: [
                                    PanAfricanBadge(
                                      label: '${gamification.xp} XP',
                                      color: PanAfricanColors.primary,
                                      icon: Icons.stars_rounded,
                                    ),
                                    PanAfricanBadge(
                                      label: gamification.levelTitle,
                                      color: PanAfricanColors.tertiary,
                                      icon: Icons.emoji_events_rounded,
                                    ),
                                    PanAfricanBadge(
                                      label: 'Streak ${gamification.dailyStreak}',
                                      color: PanAfricanColors.kenteRed,
                                      icon: Icons.local_fire_department_rounded,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: PanAfricanSpacing.md),

                          // Global Ranking
                          if (user?.rank != null)
                            _ProfileCard(
                              isDark: isDark,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events_rounded,
                                    color: PanAfricanColors.secondary,
                                  ),
                                  SizedBox(width: PanAfricanSpacing.sm),
                                  Text(
                                    'Global Ranking',
                                    style: PanAfricanTypography.titleMedium(
                                      context,
                                    ),
                                  ),
                                  const Spacer(),
                                  PanAfricanBadge(
                                    label: '#${user?.rank ?? 0}',
                                    color: PanAfricanColors.primary,
                                    icon: Icons.trending_up_rounded,
                                  ),
                                ],
                              ),
                              onTap: () {
                                ref.read(navigationProvider).navigateTo(
                                      const StandingsTabMaterial3(),
                                    );
                              },
                            ),

                          SizedBox(height: PanAfricanSpacing.md),

                          // Menu Items
                          _ProfileCard(
                            isDark: isDark,
                            child: PanAfricanListTile(
                              title: 'Change Password',
                              subtitle: 'Update your credentials securely',
                              leading: Icon(
                                Icons.lock_outline,
                                color: PanAfricanColors.primary,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: PanAfricanColors.neutralMedium,
                              ),
                            ),
                            onTap: () {
                              ref.read(navigationProvider).navigateTo(
                                const ChangePasswordScreen(),
                              );
                            },
                          ),

                          _ProfileCard(
                            isDark: isDark,
                            child: PanAfricanListTile(
                              title: 'Give us Feedback',
                              subtitle: 'Help us improve LingAfriq',
                              leading: Icon(
                                Icons.feedback_outlined,
                                color: PanAfricanColors.primary,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: PanAfricanColors.neutralMedium,
                              ),
                            ),
                            onTap: () {
                              ref.read(navigationProvider).navigateTo(
                                const SuggestLanguageScreen(),
                              );
                            },
                          ),

                          _ProfileCard(
                            isDark: isDark,
                            child: PanAfricanListTile(
                              title: 'Who are we?',
                              subtitle: 'Learn about the LingAfriq mission',
                              leading: Icon(
                                Icons.info_outline,
                                color: PanAfricanColors.primary,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: PanAfricanColors.neutralMedium,
                              ),
                            ),
                            onTap: () {
                              kLaunchUrl('https://lingafriq.com/#about-us');
                            },
                          ),

                          _ProfileCard(
                            isDark: isDark,
                            child: PanAfricanListTile(
                              title: 'Privacy & User Policy',
                              subtitle: 'Read how your data is protected',
                              leading: Icon(
                                Icons.privacy_tip_outlined,
                                color: PanAfricanColors.primary,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: PanAfricanColors.neutralMedium,
                              ),
                            ),
                            onTap: () {
                              kLaunchUrl('https://lingafriq.com/app-policy.html');
                            },
                          ),

                          _ProfileCard(
                            isDark: isDark,
                            child: PanAfricanListTile(
                              title: 'Delete your account',
                              subtitle: 'This action is permanent',
                              leading: Icon(
                                Icons.delete_outline,
                                color: PanAfricanColors.error,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: PanAfricanColors.neutralMedium,
                              ),
                            ),
                            onTap: () async {
                              final result =
                                  await DeleteAccountDialog.showDeleteAccountDialog(
                                context,
                              );
                              if (result != true) return;
                              final confirmation =
                                  await EnterPasswordDialog.show(context);
                              if (confirmation is! String) return;

                              final password = ref
                                  .read(sharedPreferencesProvider)
                                  .emailAndPassword
                                  .password;
                              final data = {"current_password": password};
                              if (confirmation != password) {
                                await ref
                                    .read(dialogProvider(""))
                                    .showPlatformDialogue(
                                      title: "Incorrect Password",
                                    );
                                return;
                              }
                              final deleteResult =
                                  await ref.read(apiProvider.notifier).deleteUser(
                                        data,
                                      );
                              if (deleteResult != true) return;
                              await ref
                                  .read(dialogProvider(""))
                                  .showPlatformDialogue(
                                    title: "Account Deleted",
                                  );
                              ref.read(authProvider.notifier).signOut(
                                    deleteAccount: true,
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileImageBuilder extends ConsumerWidget {
  final VoidCallback? onTap;
  final bool showEditIcon;

  const _ProfileImageBuilder({
    required this.onTap,
    this.showEditIcon = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final current = kAvatarsList.containsKey(user?.avatar)
        ? kAvatarsList[user?.avatar]!
        : kAvatarsList.values.first;

    return Stack(
      children: [
        Container(
          width: 0.25.sw,
          height: 0.25.sw,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: PanAfricanGradients.savannaGold,
            boxShadow: PanAfricanShadows.glowGold(0.6),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1000),
            child: Image.asset(
              current,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showEditIcon)
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: PanAfricanColors.cardLight,
                  shape: BoxShape.circle,
                  boxShadow: PanAfricanShadows.sm,
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: PanAfricanColors.primary,
                  size: 20.sp,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isDark;

  const _ProfileCard({
    required this.child,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return PanAfricanCard(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      backgroundColor:
          isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      onTap: onTap,
      child: child,
    );
  }
}

