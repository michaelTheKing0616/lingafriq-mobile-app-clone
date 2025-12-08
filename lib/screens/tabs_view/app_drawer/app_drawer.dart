import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_screen.dart';
import 'package:lingafriq/screens/games/games_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_edit_screen.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/screens/settings/settings_screen.dart';
import 'package:lingafriq/screens/profile/user_profile_screen.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_language_setup_screen.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/goals/daily_goals_screen.dart';
import 'package:lingafriq/screens/progress/progress_dashboard_screen.dart';
import 'package:lingafriq/screens/achievements/achievements_screen.dart';
import 'package:lingafriq/screens/media/import_media_screen.dart';
import 'package:lingafriq/screens/global/global_progress_screen.dart';
import 'package:lingafriq/screens/magazine/culture_magazine_screen.dart';
import 'package:lingafriq/screens/chat/global_chat_screen.dart';
import 'package:lingafriq/screens/chat/private_chat_list_screen.dart';
import 'package:lingafriq/screens/social/user_connections_screen.dart';
import 'package:lingafriq/screens/curriculum/curriculum_screen.dart';
import 'package:lingafriq/screens/gamification/badge_collection_screen.dart';
import 'package:lingafriq/screens/gamification/leaderboard_screen.dart';
import 'package:lingafriq/screens/gamification/quest_screen.dart';
import 'package:lingafriq/screens/gamification/tribe_selection_screen.dart';
import 'package:lingafriq/screens/gamification/seasonal_events_screen.dart';
import 'package:lingafriq/screens/gamification/magic_items_screen.dart';
import 'package:lingafriq/screens/social/language_villages_screen.dart';
import 'package:lingafriq/screens/social/tribe_vs_tribe_screen.dart';
import 'package:lingafriq/screens/social/social_gifting_screen.dart';
import 'package:lingafriq/screens/social/ancestral_tree_screen.dart';
import 'package:lingafriq/screens/help/features_guide_screen.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/primary_button.dart';

import '../../../providers/navigation_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackButton(
              color: context.adaptive,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    0.05.sh.heightBox,
                    ListTile(
                  leading: Icon(
                    Icons.home_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Home'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    ref.read(tabIndexProvider.notifier).setIndex(0);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: context.primaryColor,
                  ),
                  title: 'Profile'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const UserProfileScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'AI Chat'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(
                          const AiChatLanguageSetupScreen(
                            initialMode: PolieMode.translation,
                          ),
                        );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.games_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Language Games'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const GamesScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.track_changes_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Daily Goals'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const DailyGoalsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.analytics_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Progress Dashboard'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const ProgressDashboardScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.emoji_events_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Achievements'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const AchievementsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.workspace_premium_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Badges'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const BadgeCollectionScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.leaderboard_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Leaderboards'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const LeaderboardScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.auto_stories_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'The Great Journey'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const QuestScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.group_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'My Tribe'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const TribeSelectionScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.location_city,
                    color: context.primaryColor,
                  ),
                  title: 'Language Villages'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const LanguageVillagesScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.groups_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Tribe vs Tribe'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const TribeVsTribeScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.card_giftcard_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Send a Lesson'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const SocialGiftingScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.account_tree_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Ancestral Tree'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const AncestralTreeScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.event_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Seasonal Events'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const SeasonalEventsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.auto_awesome_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Magic Items'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const MagicItemsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.public_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Global Progress'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const GlobalProgressScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.upload_file_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Import Media'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const ImportMediaScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.menu_book_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Culture Magazine'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const CultureMagazineScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.people_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Connect with Users'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const UserConnectionsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.forum_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Global Chat'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const GlobalChatScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.lock_outline_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Private Chats'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref
                        .read(navigationProvider)
                        .navigateTo(const PrivateChatListScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.school_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Comprehensive Curriculum'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const CurriculumScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.help_outline_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Features Guide'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  subtitle: 'Learn how to use all features'.text.sm.gray500.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const FeaturesGuideScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Settings'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(navigationProvider).navigateTo(const SettingsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.support_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'App Policy'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    kLaunchUrl('https://lingafriq.com/app-policy.html');
                  },
                ),
                  ],
                ),
              ),
            ),
            PrimaryButton(
              onTap: () async {
                final result = await ref.read(dialogProvider('')).showPlatformDialogue(
                      title: "Logout",
                      content: const Text("Are you sure you want to logout?"),
                      action1OnTap: true,
                      action2OnTap: false,
                      action1Text: "Logout",
                      action2Text: "No",
                    );
                if (result != true) return;
                ref.read(authProvider.notifier).signOut();
              },
              child: Row(
                children: [
                  const Icon(Icons.power_settings_new_outlined, color: Colors.white),
                  12.widthBox,
                  "Log out".text.white.xl.make()
                ],
              ).p8(),
            ).px16(),
            24.heightBox,
          ],
        ),
      ),
    );
  }
}
