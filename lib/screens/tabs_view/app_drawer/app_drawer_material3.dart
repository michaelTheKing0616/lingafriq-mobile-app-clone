import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
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
import 'package:lingafriq/screens/chat/tribe_chat_screen_material3.dart';
import 'package:lingafriq/screens/chat/community_chat_screen_material3.dart';
import 'package:lingafriq/screens/chat/live_classroom_screen_material3.dart';
import 'package:lingafriq/screens/ugc/create_lesson_screen_enhanced.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

/// Modern Pan-African App Drawer with Future-Forward Styling
class AppDrawerMaterial3 extends HookConsumerWidget {
  const AppDrawerMaterial3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(authProvider);

    Future<void> toggleDarkMode() async {
      final prefs = await SharedPreferences.getInstance();
      final currentMode = prefs.getBool('dark_mode') ?? false;
      await prefs.setBool('dark_mode', !currentMode);
      
      // Trigger theme rebuild
      if (context.mounted) {
        // This would typically be handled by a theme provider
        // For now, we'll just show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dark mode ${!currentMode ? 'enabled' : 'disabled'}. Restart app to apply.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    return Drawer(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      child: SafeArea(
        child: Column(
          children: [
            // Header with User Info
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              decoration: BoxDecoration(
                gradient: isDark
                    ? PanAfricanGradients.appBarDark
                    : PanAfricanGradients.forest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30.r,
                        backgroundColor: PanAfricanColors.secondary,
                        child: Text(
                          currentUser?.username?[0].toUpperCase() ?? 'U',
                          style: PanAfricanTypography.headlineSmall(context)
                              .copyWith(color: PanAfricanColors.neutralDarkest),
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

            // Navigation Items
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
                        isDark: isDark,
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
                        isDark: isDark,
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
                        isDark: isDark,
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
                        isDark: isDark,
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
                        isDark: isDark,
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
                        isDark: isDark,
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
                        isDark: isDark,
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
                        isDark: isDark,
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
                        isDark: isDark,
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
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.group_outlined,
                        label: 'Tribe Chat',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: TribeChatScreenMaterial3()),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.people_outline,
                        label: 'Community Chat',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: CommunityChatScreenMaterial3()),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.school_outlined,
                        label: 'Live Classroom',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute(
                              child: LiveClassroomScreenMaterial3(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.community,
                        label: 'Language Villages',
                        onTap: () {
                          // Navigate to villages
                          Navigator.pop(context);
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.tribe,
                        label: 'My Tribes',
                        onTap: () {
                          // Navigate to tribes
                          Navigator.pop(context);
                        },
                        isDark: isDark,
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
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.trophy,
                        label: 'Leaderboards',
                        onTap: () {
                          // Navigate to leaderboards
                          Navigator.pop(context);
                        },
                        isDark: isDark,
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
                        isDark: isDark,
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
                        isDark: isDark,
                      ),
                      // Dark Mode Toggle
                      SwitchListTile(
                        value: isDark,
                        onChanged: (_) => toggleDarkMode(),
                        title: Text('Dark Mode'),
                        subtitle: Text('Toggle theme'),
                        secondary: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
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
                color: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
                border: Border(
                  top: BorderSide(
                    color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
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
                      title: Text('Logout'),
                      content: Text('Are you sure you want to logout?'),
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
      leading: Icon(
        icon,
        color: PanAfricanColors.primary,
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
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideX(begin: -0.1);
  }
}

