import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_tab.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/validators.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/primary_text_field.dart';
import 'package:lingafriq/widgets/titled_drop_down.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../utils/api.dart';
import '../../../widgets/delete_account_dialogue.dart';
import '../../../services/account_service.dart';

class ProfileEditScreen extends HookConsumerWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final firstnameController = useTextEditingController(text: user?.first_name);
    final lastNameController = useTextEditingController(text: user?.last_name);
    final selectedCountry = useState<String?>(user?.nationality);
    final isLoading = ref.watch(apiProvider.select((value) => value.isLoading));

    return LoadingOverlayPro(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Edit Profile'),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 16.sp,
            vertical: 24.sp,
          ),
          child: Column(
          children: [
            // ✅ Avatar section
            Center(
              child: ProfileImageBuilder(
                onTap: () async {
                  final user = ref.read(userProvider);
                  if (user == null) return;

                  final current = kAvatarsList.containsKey(user.avater)
                      ? kAvatarsList[user.avater]!
                      : kAvatarsList.values.first;

                  final selectedAvatar = await _AvatarSelector.showAvatarSelectorDialog(
                    context,
                    selectedAvatar: current,
                  );

                  if (selectedAvatar == null) return;

                  final updatedUser = user.copyWith(avater: selectedAvatar);
                  await ref.read(apiProvider.notifier).updateProfile(updatedUser.toMap());
                  ref.read(userProvider.notifier).overrideUser(updatedUser);

                  Navigator.of(context).pop();
                  HapticFeedback.lightImpact();
                  VxToast.show(context, msg: 'Avatar updated');
                },
              ),
            ),
            24.heightBox,
            const Center(
              child: ProfileDetailsBuilder(crossAxisAlignment: CrossAxisAlignment.center),
            ),
            32.heightBox,

            // ✅ Input fields
            PrimaryTextField(
              controller: firstnameController,
              title: "First name",
              hintText: "Enter your First name",
              validator: Validators.emptyValidator,
              textInputAction: TextInputAction.next,
            ),
            16.heightBox,
            PrimaryTextField(
              controller: lastNameController,
              title: "Last name",
              hintText: "Enter your Last name",
              validator: Validators.emptyValidator,
              textInputAction: TextInputAction.next,
            ),
            12.heightBox,
            IgnorePointer(
              ignoring: true,
              child: TitledDropDown<String>(
                title: "Country of Residence",
                titles: kCountries.keys.toList(),
                items: kCountries.keys.toList(),
                value: selectedCountry.value,
                onChanged: (value) => selectedCountry.value = value,
              ),
            ),
            24.heightBox,

            // ✅ Save button
            Center(
              child: PrimaryButton(
                width: 0.6.sw,
                onTap: () async {
                  final user = ref.read(userProvider);
                  if (user == null) return;

                  final updatedUser = user.copyWith(
                    first_name: firstnameController.text.trim(),
                    last_name: lastNameController.text.trim(),
                    nationality: selectedCountry.value,
                  );

                  await ref.read(apiProvider.notifier).updateProfile(updatedUser.toMap());
                  ref.read(userProvider.notifier).overrideUser(updatedUser);

                  Navigator.of(context).pop();
                  HapticFeedback.lightImpact();
                  VxToast.show(context, msg: 'Success');
                },
                text: "Save",
              ),
            ),
            32.heightBox,

            // ✅ Delete Account Button
            Center(
              child: PrimaryButton(
                width: 0.6.sw,
                text: "Delete Account",
                color: AppColors.red,
                onTap: () async {
                  final confirm = await DeleteAccountDialog.showDeleteAccountDialog(context);
                  if (confirm == true) {
                    final password = await EnterPasswordDialog.show(context);
                    if (password != null && password.isNotEmpty) {
                      try {
                        final svc = AccountService(ref);
                        final msg = await svc.deleteAccount(password);

                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(msg)));

                        // ✅ Proper logout and navigation
                        await ref.read(authProvider.notifier).signOut(deleteAccount: true);
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    }
                  }
                },
              ),
            ),
            32.heightBox,
          ],
        ),
      ),
      ),
    );
  }
}

class _AvatarSelector extends HookWidget {
  final String avatar;
  const _AvatarSelector({Key? key, required this.avatar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedAvatar = useState<String>(avatar);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SizedBox(
        height: 0.55.sh,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              children: kAvatarsList.entries.map((entry) {
                final selected = selectedAvatar.value == entry.value;
                return GestureDetector(
                  onTap: () {
                    selectedAvatar.value = entry.value;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: selected
                          ? Border.all(color: context.primaryColor, width: 3)
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(entry.value).p8(),
                    ),
                  ),
                );
              }).toList(),
            ),
            12.heightBox,
            PrimaryButton(
              color: AppColors.red,
              onTap: () {
                final assetName = selectedAvatar.value.split("/").last;
                final avatarUrl = "${Api.baseurl}media/avatars/$assetName";
                Navigator.of(context).pop(avatarUrl);
              },
              width: 0.5.sw,
              text: "Select Avatar",
            ),
          ],
        ),
      ),
    );
  }

  static Future<String?> showAvatarSelectorDialog(
    BuildContext context, {
    String selectedAvatar = "assets/images/avatar_3.png",
  }) async {
    return await showDialog<String?>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => _AvatarSelector(avatar: selectedAvatar),
    );
  }
}
