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
            Column(
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
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: context.primaryColor,
                  ),
                  title: 'Profile'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const UserProfileScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'AI Chat'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(
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
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const GamesScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.track_changes_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Daily Goals'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const DailyGoalsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.analytics_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Progress Dashboard'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const ProgressDashboardScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.emoji_events_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Achievements'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const AchievementsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.public_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Global Progress'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const GlobalProgressScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.upload_file_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Import Media'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const ImportMediaScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.menu_book_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Culture Magazine'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const CultureMagazineScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.people_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Connect with Users'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const UserConnectionsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.forum_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Global Chat'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const GlobalChatScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.lock_outline_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Private Chats'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(navigationProvider)
                        .naviateTo(const PrivateChatListScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.school_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Comprehensive Curriculum'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const CurriculumScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Settings'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const SettingsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.support_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'App Policy'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    kLaunchUrl('https://lingafriq.com/app-policy.html');
                  },
                ),
              ],
            ).scrollVertical().expand(),
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
