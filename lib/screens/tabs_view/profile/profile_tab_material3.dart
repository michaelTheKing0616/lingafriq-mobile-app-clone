import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/profile/change_password_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_edit_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/suggest_language_screen.dart';
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
import 'delete_account_dialogue.dart';

/// Beautiful Material 3 Profile Tab with Pan-African Design
class ProfileTabMaterial3 extends HookConsumerWidget {
  const ProfileTabMaterial3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isLoading = ref.watch(apiProvider.select((value) => value.isLoading));
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AdaptiveLayout.sideMargin(context),
                    vertical: PanAfricanSpacing.md,
                  ),
                  child: Row(
                    children: [
                      // Profile Image
                      _ProfileImageBuilder(
                        showEditIcon: user != null,
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
                                style: PanAfricanTypography.headlineSmall(
                                  context,
                                ),
                              ),
                            SizedBox(height: PanAfricanSpacing.xs),
                            if (user != null)
                              Text(
                                user.email ?? '',
                                style: PanAfricanTypography.bodyMedium(context)
                                    .copyWith(
                                  color: PanAfricanColors.neutralMedium,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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

                          // Global Ranking
                          if (user?.rank != null)
                            _ProfileCard(
                              isDark: isDark,
                              child: Row(
                                children: [
                                  Text(
                                    'Global Ranking',
                                    style: PanAfricanTypography.titleMedium(
                                      context,
                                    ),
                                  ),
                                  const Spacer(),
                                  Chip(
                                    label: Text(
                                      (user?.rank ?? 0).toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: PanAfricanColors.primary,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: PanAfricanSpacing.md,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                ref.read(tabIndexProvider.notifier).setIndex(2);
                              },
                            ),

                          SizedBox(height: PanAfricanSpacing.md),

                          // Menu Items
                          _ProfileCard(
                            isDark: isDark,
                            child: ListTile(
                              leading: Icon(
                                Icons.lock_outline,
                                color: PanAfricanColors.primary,
                              ),
                              title: Text(
                                'Change Password',
                                style: PanAfricanTypography.bodyLarge(context),
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
                            child: ListTile(
                              leading: Icon(
                                Icons.feedback_outlined,
                                color: PanAfricanColors.primary,
                              ),
                              title: Text(
                                'Give us Feedback',
                                style: PanAfricanTypography.bodyLarge(context),
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
                            child: ListTile(
                              leading: Icon(
                                Icons.info_outline,
                                color: PanAfricanColors.primary,
                              ),
                              title: Text(
                                'Who are we?',
                                style: PanAfricanTypography.bodyLarge(context),
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
                            child: ListTile(
                              leading: Icon(
                                Icons.privacy_tip_outlined,
                                color: PanAfricanColors.primary,
                              ),
                              title: Text(
                                'App Privacy and User Policy',
                                style: PanAfricanTypography.bodyLarge(context),
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
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              title: Text(
                                'Delete your Account',
                                style: PanAfricanTypography.bodyLarge(context)
                                    .copyWith(
                                  color: Colors.red,
                                ),
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
    final current = kAvatarsList.containsKey(user?.avater)
        ? kAvatarsList[user?.avater]!
        : kAvatarsList.values.first;

    return Stack(
      children: [
        Container(
          width: 0.25.sw,
          height: 0.25.sw,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PanAfricanColors.neutralLight,
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
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
    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: child,
      ),
    );
  }
}

