import 'package:flutter/material.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
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
import 'package:lingafriq/widgets/primary_text_field.dart';
import 'package:lingafriq/widgets/titled_drop_down.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../utils/api.dart';
import '../../../widgets/delete_account_dialogue.dart';
import '../../../services/account_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/avatars/avatars.dart';

class ProfileEditScreen extends HookConsumerWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final firstnameController = useTextEditingController(text: user?.first_name ?? '');
    final lastNameController = useTextEditingController(text: user?.last_name ?? '');
    final globalIdController = useTextEditingController(text: user?.global_id ?? user?.username ?? '');
    final selectedCountry = useState<String?>(user?.nationality);
    final isLoading = ref.watch(apiProvider.select((value) => value.isLoading));
    final isUpdatingHandle = useState(false);
    final handleError = useState<String?>(null);

    return LoadingOverlayPro(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(systemOverlayStyle: SystemUiOverlayStyle.dark),
        body: Column(
          children: [
            // Avatar section - uses new Avatar Intelligence System
            Column(
              children: [
                LingAfriqAvatar(
                  size: 100,
                  showBorder: true,
                  onTap: () {
                    // Open avatar customizer
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.85,
                        maxChildSize: 0.95,
                        minChildSize: 0.5,
                        builder: (context, scrollController) => Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: const UserAvatarCustomizer(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to customize',
                  style: PanAfricanTypography.labelSmall(context).copyWith(
                    color: PanAfricanColors.neutralMedium,
                  ),
                ),
              ],
            ).centered(),
            24.heightBox,
            const ProfileDetailsBuilder(crossAxisAlignment: CrossAxisAlignment.center).centered(),
            16.heightBox,

            // ✅ Input fields
            PrimaryTextField(
              controller: firstnameController,
              title: "First name",
              hintText: "Enter your First name",
              validator: Validators.emptyValidator,
              textInputAction: TextInputAction.next,
            ),
            12.heightBox,
            PrimaryTextField(
              controller: lastNameController,
              title: "Last name",
              hintText: "Enter your Last name",
              validator: Validators.emptyValidator,
              textInputAction: TextInputAction.next,
            ),
            12.heightBox,
            
            // Global ID / Handle Editor
            PanAfricanTextField(
              controller: globalIdController,
              label: 'Your Handle (global_id)',
              hint: 'e.g., your_handle',
              prefixIcon: Icons.alternate_email,
              helperText: 'This is your unique identifier. Use it to find you in chat (@your_handle).',
              errorText: handleError.value,
              onChanged: (value) {
                handleError.value = null;
                // Remove @ if user types it
                if (value.startsWith('@')) {
                  globalIdController.value = TextEditingValue(
                    text: value.substring(1),
                    selection: TextSelection.collapsed(offset: value.length - 1),
                  );
                }
                // Validate format: alphanumeric and underscore only, 3-30 chars
                if (value.isNotEmpty) {
                  if (value.length < 3) {
                    handleError.value = 'Handle must be at least 3 characters';
                  } else if (value.length > 30) {
                    handleError.value = 'Handle must be 30 characters or less';
                  } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                    handleError.value = 'Handle can only contain letters, numbers, and underscores';
                  }
                }
              },
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
            PanAfricanButton(
              width: 0.6.sw,
              onPressed: () async {
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
              label: "Save",
            ),
            24.heightBox,

            // ✅ Delete Account Button
            PanAfricanButton(
              width: 0.6.sw,
              label: "Delete Account",
              backgroundColor: PanAfricanColors.error,
              foregroundColor: Colors.white,
              onPressed: () async {
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
          ],
        ).p16().scrollVertical(),
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
            PanAfricanButton(
              backgroundColor: PanAfricanColors.primary,
              foregroundColor: Colors.white,
              onPressed: () {
                final assetName = selectedAvatar.value.split("/").last;
                final avatarUrl = "${Api.baseurl}media/avatars/$assetName";
                Navigator.of(context).pop(avatarUrl);
              },
              width: 0.5.sw,
              label: "Select Avatar",
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
