import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/theme_mode_provider.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart' hide PanAfricanIcons;
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/screens/dashboard/dashboard_screen_material3.dart';
import 'package:lingafriq/screens/profile/profile_screen_material3.dart';
import 'package:lingafriq/screens/settings/settings_screen_material3.dart';
import 'package:lingafriq/screens/curriculum/curriculum_screen_material3.dart';
import 'package:lingafriq/screens/games/games_screen_material3.dart';
import 'package:lingafriq/screens/gamification/badge_collection_screen_material3.dart';
import 'package:lingafriq/screens/tutor/tutor_dashboard_screen.dart';
import 'package:lingafriq/screens/ai_chat/ai_language_selection_screen.dart';
import 'package:lingafriq/screens/magazine/culture_magazine_screen_enhanced.dart';
import 'package:lingafriq/screens/media/import_media_screen_enhanced.dart';
import 'package:lingafriq/screens/chat/global_chat_screen_material3.dart';
import 'package:lingafriq/screens/chat/private_chat_list_screen.dart';
import 'package:lingafriq/screens/social/language_villages_screen.dart';
import 'package:lingafriq/screens/ugc/create_lesson_screen_enhanced.dart';
import 'package:lingafriq/screens/gamification/tribe_selection_screen.dart';
import 'package:lingafriq/screens/gamification/leaderboard_screen.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

/// Enhanced Modern Pan-African App Drawer with Future-Forward Styling
class AppDrawer extends HookConsumerWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = useState(Theme.of(context).brightness == Brightness.dark);
    final currentUser = ref.watch(userProvider);

    Future<void> toggleDarkMode() async {
      await ref.read(themeModeProvider.notifier).toggleDarkMode();
      isDark.value = !isDark.value;
      HapticFeedback.mediumImpact();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dark mode ${isDark.value ? 'enabled' : 'disabled'}'),
            duration: Duration(seconds: 2),
            backgroundColor: PanAfricanColors.primary,
          ),
        );
      }
    }

    return Drawer(
      backgroundColor: isDark.value ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      child: ResponsiveSafeArea(
        child: Column(
          children: [
            // Header with User Info and Gradient
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              decoration: BoxDecoration(
                gradient: isDark.value
                    ? PanAfricanGradients.appBarDark
                    : PanAfricanGradients.forest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // Dark Mode Toggle in Header
                      IconButton(
                        icon: Icon(
                          isDark.value ? Icons.light_mode : Icons.dark_mode,
                          color: Colors.white,
                        ),
                        onPressed: toggleDarkMode,
                        tooltip: 'Toggle Dark Mode',
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  Row(
                    children: [
                      Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: PanAfricanGradients.savannaGold,
                          boxShadow: PanAfricanShadows.glowGold(0.3),
                        ),
                        child: Center(
                          child: Text(
                            currentUser?.username?[0].toUpperCase() ?? 'U',
                            style: PanAfricanTypography.headlineSmall(context)
                                .copyWith(color: PanAfricanColors.neutralDarkest),
                          ),
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.username ?? 'User',
                              style: PanAfricanTypography.titleLarge(context)
                                  .copyWith(color: Colors.white),
                            ),
                            SizedBox(height: PanAfricanSpacing.xxs),
                            Text(
                              currentUser?.email ?? '',
                              style: PanAfricanTypography.bodySmall(context)
                                  .copyWith(color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideX(begin: -0.2),

            // Navigation Items with Sections
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                children: [
                  // Main Navigation
                  _DrawerSection(
                    title: 'Main',
                    children: [
                      _DrawerItem(
                        icon: PanAfricanIcons.home,
                        label: 'Dashboard',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            SmoothPageRoute(child: DashboardScreenMaterial3()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.book,
                        label: 'Curriculum',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: CurriculumScreenMaterial3()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.lesson,
                        label: 'Tutor Mode',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: TutorDashboardScreen()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.chat,
                        label: 'AI Assistant',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: AILanguageSelectionScreen()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                    ],
                  ),

                  // Learning & Content
                  _DrawerSection(
                    title: 'Learning',
                    children: [
                      _DrawerItem(
                        icon: PanAfricanIcons.quiz,
                        label: 'Games',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: GamesScreenMaterial3()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.magazine,
                        label: 'Cultural Magazine',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: CultureMagazineScreenEnhanced()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                      _DrawerItem(
                        icon: Icons.upload,
                        label: 'Import Media',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: ImportMediaScreenEnhanced()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                      _DrawerItem(
                        icon: Icons.create,
                        label: 'Create Content',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: CreateLessonScreenEnhanced()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                    ],
                  ),

                  // Social & Community
                  _DrawerSection(
                    title: 'Community',
                    children: [
                      _DrawerItem(
                        icon: PanAfricanIcons.chat,
                        label: 'Global Chat',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: GlobalChatScreenMaterial3()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                      _DrawerItem(
                        icon: Icons.chat_bubble_outline,
                        label: 'Private Chat',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: PrivateChatListScreen()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.community,
                        label: 'Language Villages',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: const LanguageVillagesScreen()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.tribe,
                        label: 'My Tribes',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: const TribeSelectionScreen()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                    ],
                  ),

                  // Gamification
                  _DrawerSection(
                    title: 'Achievements',
                    children: [
                      _DrawerItem(
                        icon: PanAfricanIcons.badge,
                        label: 'Badges',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: BadgeCollectionScreenMaterial3()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.trophy,
                        label: 'Leaderboards',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: const LeaderboardScreen()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                    ],
                  ),

                  // Settings & Profile
                  _DrawerSection(
                    title: 'Account',
                    children: [
                      _DrawerItem(
                        icon: PanAfricanIcons.profile,
                        label: 'Profile',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: ProfileScreenMaterial3()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.settings,
                        label: 'Settings',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: SettingsScreenMaterial3()),
                          );
                        },
                        isDark: isDark.value,
                      ),
                      // Dark Mode Toggle
                      SwitchListTile(
                        value: isDark.value,
                        onChanged: (_) => toggleDarkMode(),
                        title: Text('Dark Mode', style: PanAfricanTypography.bodyLarge(context)),
                        subtitle: Text('Switch between light and dark theme', 
                            style: PanAfricanTypography.bodySmall(context)),
                        secondary: Icon(
                          isDark.value ? Icons.dark_mode : Icons.light_mode,
                          color: PanAfricanColors.primary,
                        ),
                        activeColor: PanAfricanColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer with Logout
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: isDark.value
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
                border: Border(
                  top: BorderSide(
                    color: isDark.value ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                  ),
                ),
              ),
              child: PanAfricanButton(
                label: 'Logout',
                icon: Icons.logout,
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Logout', style: PanAfricanTypography.titleLarge(context)),
                      content: Text('Are you sure you want to logout?',
                          style: PanAfricanTypography.bodyMedium(context)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PanAfricanColors.error,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    Navigator.pop(context);
                    ref.read(authProvider.notifier).signOut();
                  }
                },
                backgroundColor: PanAfricanColors.error,
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DrawerSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.lg,
            vertical: PanAfricanSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: PanAfricanTypography.labelSmall(context).copyWith(
              color: isDark
                  ? PanAfricanColors.textSecondaryDark
                  : PanAfricanColors.textSecondaryLight,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...children,
        SizedBox(height: PanAfricanSpacing.sm),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.sm),
        decoration: BoxDecoration(
          color: PanAfricanColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
        ),
        child: Icon(
          icon,
          color: PanAfricanColors.primary,
          size: 20.sp,
        ),
      ),
      title: Text(
        label,
        style: PanAfricanTypography.bodyLarge(context),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.lg,
        vertical: PanAfricanSpacing.xs,
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideX(begin: -0.1);
  }
}
