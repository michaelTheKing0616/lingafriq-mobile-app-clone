import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/features/global_chat/global_chat_policy.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/lingafriq_ui_helpers.dart';
import 'package:lingafriq/widgets/pan_african_components.dart'
    hide PanAfricanIcons;
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/theme_mode_provider.dart';
import 'package:lingafriq/providers/tab_scaffold_provider.dart';
import 'package:lingafriq/screens/profile/profile_screen_material3.dart';
import 'package:lingafriq/screens/settings/settings_screen_material3.dart';
import 'package:lingafriq/screens/lessons/lessons_map_entry_screen.dart';
import 'package:lingafriq/screens/content/native_content_review_screen.dart';
import 'package:lingafriq/screens/curriculum/authentic_curriculum_entry_screen.dart';
import 'package:lingafriq/screens/games/games_screen_material3.dart';
import 'package:lingafriq/screens/gamification/badge_collection_screen_material3.dart';
import 'package:lingafriq/screens/chat/lingchat_ai_conversation_screen.dart';
import 'package:lingafriq/screens/ai_chat/polie_mode_selection_screen.dart';
import 'package:lingafriq/screens/magazine/culture_magazine_screen_enhanced.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/heritage/flb_heritage_archive_screen.dart';
import 'package:lingafriq/screens/media/import_media_screen_enhanced.dart';
import 'package:lingafriq/screens/vocabulary/living_dictionary_screen.dart';
import 'package:lingafriq/screens/learning/phrase_dna/phrase_dna_templates_screen.dart';
import 'package:lingafriq/screens/learning/tone_rhythm/tone_rhythm_trainer_screen.dart';
import 'package:lingafriq/screens/ar/point_and_say_screen.dart';
import 'package:lingafriq/screens/live_translate/live_translate_screen.dart';
import 'package:lingafriq/screens/chat/global_chat_screen_material3.dart';
import 'package:lingafriq/screens/feed/x_feed_home_screen.dart';
import 'package:lingafriq/providers/age_policy_provider.dart';
import 'package:lingafriq/screens/chat/chat_list_screen.dart';
import 'package:lingafriq/screens/home_screen.dart';
import 'package:lingafriq/screens/community/micro_mentor_hub_screen.dart';
import 'package:lingafriq/screens/staff/micro_mentor_reports_screen.dart';
import 'package:lingafriq/screens/chat/live_classroom_screen_material3.dart';
import 'package:lingafriq/screens/ugc/create_lesson_screen_enhanced.dart';
import 'package:lingafriq/screens/social_audio/room_discovery_screen.dart';
import 'package:lingafriq/screens/village/villages_hub_screen.dart';
import 'package:lingafriq/screens/gamification/tribe_selection_screen.dart';
import 'package:lingafriq/screens/gamification/leaderboard_screen.dart';
import 'package:lingafriq/screens/personalities/personality_selection_screen.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/l10n/l10n_of.dart';

/// Modern Pan-African App Drawer with Future-Forward Styling
class AppDrawerMaterial3 extends HookConsumerWidget {
  const AppDrawerMaterial3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatVisible = ref.watch(globalChatEntryVisibleProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(userProvider);
    final socialBlocked = ref.watch(agePolicyProvider).maybeWhen(
          data: (p) => p.socialSurfacesBlocked,
          orElse: () => true,
        );

    Future<void> toggleDarkMode() async {
      await ref.read(themeModeProvider.notifier).toggleDarkMode();
      if (!context.mounted) return;
      final enabled = Theme.of(context).brightness == Brightness.dark;
      showLingAfriqInfo(
        context,
        l10nOf(context).shellDarkModeValue(enabled ? 'enabled' : 'disabled'),
      );
    }

    return Drawer(
      backgroundColor: isDark
          ? PanAfricanColors.surfaceDark
          : PanAfricanColors.surfaceLight,
      child: ResponsiveSafeArea(
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
                      Semantics(
                        label: l10nOf(context).shellUserAvatar,
                        excludeSemantics: true,
                        child: CircleAvatar(
                          radius: 30.r,
                          backgroundColor: PanAfricanColors.secondary,
                          child: Text(
                            currentUser?.username[0].toUpperCase() ?? 'U',
                            style: PanAfricanTypography.headlineSmall(
                              context,
                            ).copyWith(color: PanAfricanColors.neutralDarkest),
                          ),
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              label:
                                  l10nOf(context).shellUsernameValue(currentUser?.username ?? 'User'),
                              child: Text(
                                currentUser?.username ?? 'User',
                                style: PanAfricanTypography.titleLarge(context)
                                    .copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                              ),
                            ),
                            SizedBox(height: PanAfricanSpacing.xxs),
                            Semantics(
                              label: l10nOf(context).shellEmailValue(currentUser?.email ?? ''),
                              child: Text(
                                currentUser?.email ?? '',
                                style: PanAfricanTypography.bodySmall(context)
                                    .copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary.withValues(alpha: 0.7),
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2),

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
                          ref.read(tabIndexProvider.notifier).setIndex(0);
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.book,
                        label: 'Lessons',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const LessonsMapEntryScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.ai,
                        label: l10nOf(context).shellAuthenticPathA1C1,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const AuthenticCurriculumEntryScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.verified_user_outlined,
                        label: l10nOf(context).shellNativeContentReview,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const NativeContentReviewScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.lesson,
                        label: l10nOf(context).shellPolieTutor,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const PolieModeSelectionScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.chat,
                        label: l10nOf(context).shellAiChat,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const LingChatAiConversationScreen(),
                            ),
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
                            SmoothPageRoute.platform(
                              child: const GamesScreenMaterial3(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.magazine,
                        label: l10nOf(context).shellCulturalMagazine,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const CultureMagazineScreenEnhanced(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.auto_awesome_mosaic_rounded,
                        label: l10nOf(context).shellPhraseDna,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const PhraseDnaTemplatesScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.graphic_eq_rounded,
                        label: l10nOf(context).shellToneRhythm,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const ToneRhythmTrainerScreen(
                                language: 'yoruba',
                              ),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.account_balance_rounded,
                        label: l10n.drawerFlbHeritageArchive,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const FlbHeritageArchiveScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.upload,
                        label: l10nOf(context).shellImportMedia,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const ImportMediaScreenEnhanced(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.center_focus_strong_rounded,
                        label: l10nOf(context).shellPointSay,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const PointAndSayScreen(
                                language: 'yoruba',
                              ),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.mic_none_rounded,
                        label: l10nOf(context).shellLiveTranslate,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, liveTranslateRoute());
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.auto_stories_rounded,
                        label: l10nOf(context).shellLivingDictionary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const LivingDictionaryScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.flag_rounded,
                        label: l10nOf(context).shellHeritageMilestones,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, 'heritage-milestones');
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.translate_rounded,
                        label: l10nOf(context).shellDialectPreference,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, 'dialect-preference');
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.create,
                        label: l10nOf(context).shellCreateContent,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const CreateLessonScreenEnhanced(),
                            ),
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
                      if (!socialBlocked) ...[
                        if (chatVisible) _DrawerItem(
                          icon: PanAfricanIcons.chat,
                          label: l10nOf(context).shellGlobalChat,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              SmoothPageRoute.platform(
                                child: const GlobalChatScreenMaterial3(),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                        _DrawerItem(
                          icon: Icons.dynamic_feed_rounded,
                          label: l10nOf(context).shellCommunityFeed,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              SmoothPageRoute.platform(
                                child: const AgePolicyRouteShell(
                                  child: XFeedHomeScreen(),
                                ),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                      ],
                      _DrawerItem(
                        icon: Icons.volunteer_activism_rounded,
                        label: 'Micro‑Mentors',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const MicroMentorHubScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      if (!socialBlocked)
                        _DrawerItem(
                          icon: Icons.chat_bubble_outline,
                          label: l10nOf(context).shellPrivateChat,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              SmoothPageRoute.platform(
                                child: const ChatListScreen(),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                      _DrawerItem(
                        icon: Icons.school_outlined,
                        label: l10nOf(context).shellLiveClassroom,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const LiveClassroomScreenMaterial3(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.community,
                        label: l10nOf(context).shellLanguageVillages,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const VillagesHubScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      if (!socialBlocked)
                        _DrawerItem(
                          icon: Icons.radio,
                          label: l10nOf(context).shellPracticeRooms,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RoomDiscoveryScreen(),
                              ),
                            );
                          },
                          isDark: isDark,
                        ),
                      _DrawerItem(
                        icon: PanAfricanIcons.tribe,
                        label: l10nOf(context).shellMyTribes,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const TribeSelectionScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: Icons.history_edu,
                        label: l10nOf(context).shellHistoricalPersonas,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const PersonalitySelectionScreen(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),

                  if (currentUser?.isStaffOrAdmin == true)
                    _DrawerSection(
                      title: 'Staff',
                      children: [
                        _DrawerItem(
                          icon: Icons.shield_outlined,
                          label: l10nOf(context).shellMicroMentorReports,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              SmoothPageRoute.platform(
                                child: const StaffMicroMentorReportsScreen(),
                              ),
                            );
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
                            SmoothPageRoute.platform(
                              child: const BadgeCollectionScreenMaterial3(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      _DrawerItem(
                        icon: PanAfricanIcons.trophy,
                        label: 'Leaderboards',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            SmoothPageRoute.platform(
                              child: const LeaderboardScreen(),
                            ),
                          );
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
                            SmoothPageRoute.platform(
                              child: const ProfileScreenMaterial3(),
                            ),
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
                            SmoothPageRoute.platform(
                              child: const SettingsScreenMaterial3(),
                            ),
                          );
                        },
                        isDark: isDark,
                      ),
                      // Dark Mode Toggle
                      Semantics(
                        label: l10nOf(context).shellDarkMode9cf8,
                        value: isDark ? 'enabled' : 'disabled',
                        toggled: isDark,
                        child: SwitchListTile(
                          value: isDark,
                          onChanged: (_) => toggleDarkMode(),
                          title: Text(l10nOf(context).shellDarkMode),
                          subtitle: Text(l10nOf(context).shellToggleTheme),
                          secondary: Semantics(
                            excludeSemantics: true,
                            child: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color: PanAfricanColors.primary,
                            ),
                          ),
                          activeThumbColor: PanAfricanColors.primary,
                        ),
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
                    color: isDark
                        ? PanAfricanColors.borderDark
                        : PanAfricanColors.borderLight,
                  ),
                ),
              ),
              child: Semantics(
                label: l10nOf(context).shellLogout,
                button: true,
                child: PanAfricanButton(
                  label: l10nOf(context).shellLogout,
                  icon: Icons.logout,
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10nOf(context).shellLogout),
                        content: Text(l10nOf(context).shellAreYouSureYouWantTo),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10nOf(context).shellCancel),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PanAfricanColors.error,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                            ),
                            child: Text(l10nOf(context).shellLogout),
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
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DrawerSection({required this.title, required this.children});

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
          child: Semantics(
            label: l10nOf(context).shellTitleSection(title.toString()),
            header: true,
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
    return Semantics(
      label: label,
      button: true,
      child: ListTile(
        leading: Semantics(
          excludeSemantics: true,
          child: Icon(icon, color: PanAfricanColors.primary),
        ),
        title: Text(label, style: PanAfricanTypography.bodyLarge(context)),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.1);
  }
}
