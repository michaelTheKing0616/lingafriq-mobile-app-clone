import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/profile/change_password_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_edit_screen.dart';
import 'package:lingafriq/screens/tabs_view/profile/suggest_language_screen.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/dialog_provider.dart';
import '../../../utils/constants.dart';
import 'delete_account_dialogue.dart';

class ProfileTab extends HookConsumerWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isLoading = ref.watch(apiProvider.select((value) => value.isLoading));
    return LoadingOverlayPro(
      isLoading: isLoading,
      child: Scaffold(
        body: Column(
          children: [
            TopGradientBox(
              child: Row(
                children: [
                  0.1.sw.widthBox,
                  ProfileImageBuilder(
                    showEditIcon: ref.read(userProvider) != null,
                    onTap: () {
                      ref
                          .read(navigationProvider)
                          .naviateTo(const ProfileEditScreen());
                    },
                  ),
                  16.widthBox,
                  const ProfileDetailsBuilder().expand()
                ],
              ).py32(),
            ),
            Column(
              children: [
                if (user?.rank != null)
                  _ProfileItem(
                    title: "",
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      "Global Ranking".text.lg.make().expand(),
                      Chip(
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: AppColors.primaryGreen,
                        visualDensity: VisualDensity.compact,
                        label: Text(user?.rank.toString()??'',style: TextStyle(
                          color: Colors.white
                        ),),
                        // label: (user?.rank ?? "0")
                        //     .toString()
                        //     .text
                        //     .color(Colors.white)
                        //     .make(),
                      ),
                    ]),
                    onTap: () {
                      ref.read(tabIndexProvider.notifier).setIndex(2);
                    },
                  ),
                _ProfileItem(
                  title: "Change Password",
                  onTap: () {
                    ref
                        .read(navigationProvider)
                        .naviateTo(const ChangePasswordScreen());
                  },
                ),
                _ProfileItem(
                  title: "Give us Feedback",
                  onTap: () {
                    ref
                        .read(navigationProvider)
                        .naviateTo(const SuggestLanguageScreen());
                  },
                ),
                _ProfileItem(
                  title: "Who are we?",
                  onTap: () {
                    kLaunchUrl('https://lingafriq.com/#about-us');
                    // ref.read(navigationProvider).naviateTo(const AboutUsScreen());
                  },
                ),
                _ProfileItem(
                  title: "App Privacy and User Policy",
                  onTap: () {
                    kLaunchUrl('https://lingafriq.com/app-policy.html');
                    // ref.read(navigationProvider).naviateTo(const AppPolicyScreen());
                  },
                ),
                _ProfileItem(
                  title: "Delete your Account",
                  onTap: () async {
                    final result =
                        await DeleteAccountDialog.showDeleteAccountDialog(
                            context);
                    result.toString().log();
                    if (result != true) return;
                    final confirmation =
                        await EnterPasswordDialog.show(context);
                    confirmation.toString().log();
                    if (confirmation is! String) return;

                    final password = ref
                        .read(sharedPreferencesProvider)
                        .emailAndPassword
                        .password;
                    final data = {"current_password": password};
                    if (confirmation != password) {
                      await ref
                          .read(dialogProvider(""))
                          .showPlatformDialogue(title: "Incorrect Password");
                      return;
                    }
                    final deleteResult =
                        await ref.read(apiProvider.notifier).deleteUser(data);
                    if (deleteResult != true) return;
                    await ref
                        .read(dialogProvider(""))
                        .showPlatformDialogue(title: "Account Deleted");
                    ref.read(authProvider.notifier).signOut(deleteAccount: true);
                  },
                ),
              ],
            ).p16().scrollVertical().expand()
          ],
        ),
      ),
    );
  }
}

class ProfileDetailsBuilder extends ConsumerWidget {
  final CrossAxisAlignment? crossAxisAlignment;
  const ProfileDetailsBuilder({
    Key? key,
    this.crossAxisAlignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Column(
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
      children: [
        // if (user?.rank.toString().isNotEmpty ?? false)
        //   Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        //     decoration: BoxDecoration(
        //       color: Colors.white.withOpacity(0.20),
        //       borderRadius: BorderRadius.circular(100),
        //     ),
        //     child: (user?.rank.toString().firstLetterUpperCase() ?? "Beginner").text.make(),
        //   ),
        if (user != null)
          user.username.text.color(context.adaptive).xl3.semiBold.make(),
        4.heightBox,
        if (user != null) user.email.text.color(context.adaptive).lg.make(),
        8.heightBox,
      ],
    ).pOnly(right: 12);
  }
}

class ProfileImageBuilder extends ConsumerWidget {
  final VoidCallback? onTap;
  final bool showEditIcon;
  final Size? size;
  const ProfileImageBuilder({
    Key? key,
    this.onTap,
    this.showEditIcon = true,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final current = kAvatarsList.containsKey(user?.avater)
        ? kAvatarsList[user?.avater]!
        : kAvatarsList.values.first;

    return Container(
      width: size?.width ?? 0.3.sw,
      height: size?.height ?? 0.3.sw,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.adaptive12,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(1000),
            child: Image.asset(
              current,
              width: 0.3.sw,
              height: 0.3.sw,
            ),
          ).p8(),
          if (showEditIcon)
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryOrange,
                    size: 24.sp,
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Widget? child;
  final EdgeInsets? padding;
  const _ProfileItem(
      {Key? key,
      required this.title,
      required this.onTap,
      this.child,
      this.padding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
         margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child ?? title.text.lg.make(),
      ),
    );
  }
}
