import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/screens/auth/sign_up_screen.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/validators.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/primary_text_field.dart';
import 'package:lingafriq/widgets/title_logo.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

import 'forgot_password_screen.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController =
        useTextEditingController(text: kDebugMode ? "itsatifsiddiqui@gmail.com" : null);
    final passwordController = useTextEditingController(text: kDebugMode ? "Mubeen12" : null);
    final formKey = GlobalObjectKey<FormState>(context);
    final isLoading = ref.watch(authProvider.select((value) => value.isLoading));
    final showPassword = useState<bool>(false);

    return LoadingOverlayPro(
      isLoading: isLoading,
      child: Scaffold(
        body: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.always,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              0.2.sh.heightBox,
              const TitleLogo().centered(),
              24.heightBox,
              PrimaryTextField(
                controller: emailController,
                title: "Email",
                hintText: "Enter your registered email",
                validator: Validators.emailValidator,
                textInputAction: TextInputAction.next,
              ),
              16.heightBox,
              PrimaryTextField(
                controller: passwordController,
                title: "Password",
                hintText: "Enter your password",
                validator: Validators.passwordValidator,
                textInputAction: TextInputAction.done,
                obscureText: !showPassword.value,
                maxLines: 1,
                suffixIcon: IconButton(
                    onPressed: () {
                      showPassword.value = !showPassword.value;
                    },
                    icon: Icon(
                      showPassword.value ? Icons.visibility_off : Icons.visibility,
                    )),
              ),
              8.heightBox,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  "Forgot password?".text.make().p8().mdClick(() {
                    ref.read(navigationProvider).naviateTo(const ForgotPasswordScreen());
                  }).make(),
                ],
              ),
              24.heightBox,
              PrimaryButton(
                onTap: () {
                  if (!formKey.currentState!.validate()) return;
                  ref.read(authProvider.notifier).login(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                        storeCredentials: true,
                      );
                },
                text: "Login",
              ),
              16.heightBox,
              "Don't have an account? "
                  .richText
                  .withTextSpanChildren([
                    "Sign up"
                        .textSpan
                        .size(16.sp)
                        .semiBold
                        .underline
                        .color(context.primaryColor)
                        .make(),
                  ])
                  .make()
                  .p8()
                  .mdClick(() {
                    ref.read(navigationProvider).naviateTo(const SignupScreen());
                  })
                  .make()
            ],
          ).scrollVertical().p16().safeArea(),
        ),
      ),
    );
  }
}
