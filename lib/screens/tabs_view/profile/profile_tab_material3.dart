import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/profile/change_password_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_edit_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/suggest_language_screen.dart';
import 'package:lingafriq/screens/tabs_view/standings/standings_tab_material3.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/gamification/currency_display_widget.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/pan_african_app_bar.dart';
import 'package:lingafriq/providers/tab_scaffold_provider.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/avatars/avatars.dart';
import 'delete_account_dialogue.dart';
import 'package:lingafriq/l10n/l10n_of.dart';

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
                  title: l10nOf(context).shellProfile,
                  showBackButton: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () {
                        ref.read(scaffoldKeyProvider).currentState?.openDrawer();
                      },
                      tooltip: l10nOf(context).shellMenu,
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
                    gradientStart: context.panSecondary,
                    gradientEnd: context.panTertiary,
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Row(
                      children: [
                        // Profile Avatar (from Avatar Intelligence System)
                        Semantics(
                          label: l10nOf(context).shellProfileAvatarTapToEditProfile,
                          button: true,
                          child: LingAfriqAvatar(
                            size: 0.25.sw,
                            showBorder: true,
                            onTap: () {
                              ref.read(navigationProvider).navigateTo(
                                const ProfileEditScreen(),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: PanAfricanSpacing.md),
                        // Profile Details
                        Expanded(
                          child: Semantics(
                            label: l10nOf(context).shellProfileValueValue2LevelValue3Streak(user?.username ?? 'User', user?.email ?? '', '${user?.level ?? 1}', '${user?.streak ?? 0}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (user != null)
                                  Text(
                                    user.username,
                                    style: PanAfricanTypography.headlineSmall(context),
                                  ),
                                SizedBox(height: PanAfricanSpacing.xs),
                                if (user != null)
                                  Text(
                                    user.email,
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
                                      label: l10nOf(context).shellLevelValue('${user?.level ?? 1}'),
                                      color: PanAfricanColors.primary,
                                      icon: Icons.trending_up_rounded,
                                    ),
                                    PanAfricanBadge(
                                      label: l10nOf(context).shellStreakValue('${user?.streak ?? 0}'),
                                      color: context.panTertiary,
                                      icon: Icons.local_fire_department_rounded,
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                          const CurrencyDisplayWidget(compact: false),
                          SizedBox(height: PanAfricanSpacing.md),

                          // Achievements Summary
                          PanAfricanCard(
                            hasGradientBorder: true,
                            gradientStart: PanAfricanColors.primary,
                            gradientEnd: context.panSecondary,
                            padding: EdgeInsets.all(PanAfricanSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.workspace_premium_rounded,
                                        color: context.panSecondary),
                                    SizedBox(width: PanAfricanSpacing.sm),
                                    Text(
                                      l10nOf(context).shellAchievements,
                                      style: PanAfricanTypography.titleLarge(context),
                                    ),
                                    const Spacer(),
                                    Text(
                                      l10nOf(context).shellUnlockedbadgesTotalbadges(unlockedBadges.toString(), totalBadges.toString()),
                                      style: PanAfricanTypography.labelLarge(context).copyWith(
                                        color: PanAfricanColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: PanAfricanSpacing.sm),
                                Semantics(
                                  label: l10nOf(context).shellAchievementProgressUnlockedbadgesOutOfTotal(unlockedBadges.toString(), totalBadges.toString()),
                                  value: '${(badgeProgress * 100).toInt()}%',
                                  child: PanAfricanProgressBar(
                                    progress: badgeProgress,
                                    color: context.panSecondary,
                                    height: 8.h,
                                  ),
                                ),
                                SizedBox(height: PanAfricanSpacing.md),
                                Wrap(
                                  spacing: PanAfricanSpacing.sm,
                                  runSpacing: PanAfricanSpacing.xxs,
                                  children: [
                                    PanAfricanBadge(
                                      label: l10nOf(context).shellValueXp('${gamification.xp}'),
                                      color: PanAfricanColors.primary,
                                      icon: Icons.stars_rounded,
                                    ),
                                    PanAfricanBadge(
                                      label: gamification.levelTitle,
                                      color: context.panTertiary,
                                      icon: Icons.emoji_events_rounded,
                                    ),
                                    PanAfricanBadge(
                                      label: l10nOf(context).shellStreakValue('${gamification.dailyStreak}'),
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
                                    color: context.panSecondary,
                                  ),
                                  SizedBox(width: PanAfricanSpacing.sm),
                                  Text(
                                    l10nOf(context).shellGlobalRanking,
                                    style: PanAfricanTypography.titleMedium(
                                      context,
                                    ),
                                  ),
                                  const Spacer(),
                                  Semantics(
                                    label: l10nOf(context).shellGlobalRankValue('${user?.rank ?? 0}'),
                                    child: PanAfricanBadge(
                                      label: l10nOf(context).shellValue12bd('${user?.rank ?? 0}'),
                                      color: PanAfricanColors.primary,
                                      icon: Icons.trending_up_rounded,
                                    ),
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
                              title: l10nOf(context).shellChangePassword,
                              subtitle: l10nOf(context).shellUpdateYourCredentialsSecurely,
                              leading: const Icon(
                                Icons.lock_outline,
                                color: PanAfricanColors.primary,
                              ),
                              trailing: const Icon(
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
                              title: l10nOf(context).shellGiveUsFeedback,
                              subtitle: l10nOf(context).shellHelpUsImproveLingafriq,
                              leading: const Icon(
                                Icons.feedback_outlined,
                                color: PanAfricanColors.primary,
                              ),
                              trailing: const Icon(
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
                              title: l10nOf(context).shellWhoAreWe,
                              subtitle: l10nOf(context).shellLearnAboutTheLingafriqMission,
                              leading: const Icon(
                                Icons.info_outline,
                                color: PanAfricanColors.primary,
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: PanAfricanColors.neutralMedium,
                              ),
                            ),
                            onTap: () {
                              kLaunchUrl('${EnvConfig.appWebUrl}/#about-us');
                            },
                          ),

                          _ProfileCard(
                            isDark: isDark,
                            child: PanAfricanListTile(
                              title: l10nOf(context).shellPrivacyUserPolicy,
                              subtitle: l10nOf(context).shellReadHowYourDataIsProtected,
                              leading: const Icon(
                                Icons.privacy_tip_outlined,
                                color: PanAfricanColors.primary,
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: PanAfricanColors.neutralMedium,
                              ),
                            ),
                            onTap: () {
                              kLaunchUrl('${EnvConfig.appWebUrl}/app-policy.html');
                            },
                          ),

                          _ProfileCard(
                            isDark: isDark,
                            child: PanAfricanListTile(
                              title: l10nOf(context).shellDeleteYourAccount,
                              subtitle: l10nOf(context).shellThisActionIsPermanent,
                              leading: Icon(
                                Icons.delete_outline,
                                color: context.panError,
                              ),
                              trailing: const Icon(
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
                              if (!context.mounted) return;
                              final typedPassword =
                                  await EnterPasswordDialog.show(context);
                              if (typedPassword == null ||
                                  typedPassword.isEmpty) {
                                return;
                              }

                              final data = {
                                "current_password": typedPassword,
                              };
                              final deleteResult =
                                  await ref.read(apiProvider.notifier).deleteUser(
                                        data,
                                      );
                              if (deleteResult != true) return;
                              await ref
                                  .read(dialogProvider(""))
                                  .showPlatformDialogue(
                                    title: l10nOf(context).shellAccountDeleted,
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

