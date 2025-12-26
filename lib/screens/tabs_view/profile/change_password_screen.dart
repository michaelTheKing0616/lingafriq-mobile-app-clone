import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_tab.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/validators.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/primary_text_field.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

import '../../../providers/shared_preferences_provider.dart';

class ChangePasswordScreen extends HookConsumerWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPasswordController =
        useTextEditingController(text: kDebugMode ? "Atif@1234" : null);
    final passwordController = useTextEditingController(text: kDebugMode ? "atif@1234" : null);
    final confirmPasswordController =
        useTextEditingController(text: kDebugMode ? "atif@1234" : null);
    final formKey = GlobalObjectKey<FormState>(context);
    final isLoading = ref.watch(apiProvider).isLoading;

    return LoadingOverlayPro(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(),
        body: Form(
          key: formKey,
          child: Column(
            children: [
              ProfileImageBuilder(
                showEditIcon: false,
                onTap: () {},
              ).centered(),
              24.heightBox,
              const ProfileDetailsBuilder(
                crossAxisAlignment: CrossAxisAlignment.center,
              ).centered(),
              32.heightBox,
              PrimaryTextField(
                controller: currentPasswordController,
                title: "Current Password",
                hintText: "Enter your current password",
                validator: Validators.passwordValidator,
                textInputAction: TextInputAction.next,
                obscureText: true,
                maxLines: 1,
              ),
              12.heightBox,
              PrimaryTextField(
                controller: passwordController,
                title: "New Password",
                hintText: "Enter new password",
                validator: Validators.passwordValidator,
                textInputAction: TextInputAction.next,
                obscureText: true,
                maxLines: 1,
              ),
              12.heightBox,
              PrimaryTextField(
                controller: confirmPasswordController,
                title: "Confirm Password",
                hintText: "Confirm your new password",
                validator: (value) => Validators.confirmPasswordValidator(
                  value,
                  passwordController.text.trim(),
                ),
                textInputAction: TextInputAction.done,
                obscureText: true,
                maxLines: 1,
              ),
              24.heightBox,
              PrimaryButton(
                width: 0.6.sw,
                onTap: () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  await safeAsync(
                    context: context,
                    operation: () async {
                      final result = await ref.read(apiProvider.notifier).changePassword(
                            currentPassword: currentPasswordController.text.trim(),
                            newPassword: passwordController.text.trim(),
                          );
                      if (result == true) {
                        ref.read(sharedPreferencesProvider).removeEmailAndPassword();
                        ref.read(navigationProvider).pop();
                        HapticFeedback.lightImpact();
                        VxToast.show(context, msg: 'Password Changed');
                      } else {
                        throw Exception('Failed to change password');
                      }
                    },
                    errorContext: 'changePassword',
                    showError: true,
                  );
                },
                text: "Change Password",
              )
            ],
          ).p16().scrollVertical(),
        ),
      ),
    );
  }
}
