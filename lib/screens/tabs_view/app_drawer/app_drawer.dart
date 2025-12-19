import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_edit_screen.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/screens/dashboard/modern_dashboard_screen.dart';
import 'package:lingafriq/providers/subscription_provider.dart';
import 'package:lingafriq/screens/subscription/family_dashboard_screen.dart';
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
                    Icons.dashboard_customize_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Smart Dashboard'
                      .text
                      .xl
                      .make()
                      .offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const ModernDashboardScreen());
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: context.primaryColor,
                  ),
                  title: 'Profile'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    ref.read(tabIndexProvider.notifier).setIndex(3);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Settings'.text.xl.make().offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    ref.read(navigationProvider).naviateTo(const ProfileEditScreen());
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final sub = ref.watch(subscriptionProvider);
                    if (sub.tier != SubscriptionTier.family) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      leading: Icon(
                        Icons.family_restroom_rounded,
                        color: context.primaryColor,
                      ),
                      title: 'Family Dashboard'
                          .text
                          .xl
                          .make()
                          .offset(offset: const Offset(-16, 0)),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(navigationProvider).naviateTo(
                              const FamilyDashboardScreen(),
                            );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.help_outline_rounded,
                    color: context.primaryColor,
                  ),
                  title: 'Features Guide'
                      .text
                      .xl
                      .make()
                      .offset(offset: const Offset(-16, 0)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(navigationProvider).naviateTo(const FeaturesGuideScreen());
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
