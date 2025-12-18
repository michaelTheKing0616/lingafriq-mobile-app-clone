import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/validators.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/primary_text_field.dart';
import 'package:lingafriq/widgets/title_logo.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController(text: kDebugMode ? "atif@gmail.com" : null);
    final formKey = GlobalObjectKey<FormState>(context);
    final isLoading = ref.watch(apiProvider).isLoading;
    return LoadingOverlayPro(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(),
        body: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              0.15.sh.heightBox,
              const TitleLogo().centered(),
              32.heightBox,
              PrimaryTextField(
                controller: emailController,
                title: "Email",
                hintText: "Enter your registered email",
                validator: Validators.emailValidator,
                textInputAction: TextInputAction.next,
              ),
              24.heightBox,
              PrimaryButton(
                onTap: () async {
                  if (!formKey.currentState!.validate()) return;
                  final result =
                      await ref.read(apiProvider.notifier).resetPassword(emailController.text.trim());
                  if (result != true) return;
                  await ref.read(dialogProvider('')).showPlatformDialogue(
                      title: "Reset Password",
                      content: Text(
                        "An email with instructions to reset your password has been sent to ${emailController.text.trim()}",
                      ));
                  Navigator.of(context).pop();
                },
                text: "Reset Password",
              ),
              16.heightBox,
            ],
          ).scrollVertical().px16().safeArea(),
        ),
      ),
    );
  }
}
