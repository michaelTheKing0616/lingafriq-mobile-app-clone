import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/validators.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/primary_text_field.dart';
import 'package:lingafriq/widgets/title_logo.dart';
import 'package:lingafriq/widgets/titled_drop_down.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

class SignupScreen extends HookConsumerWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstnameController = useTextEditingController(text: kDebugMode ? "Atif" : null);
    final lastNameController = useTextEditingController(text: kDebugMode ? "Siddiqui" : null);
    final usernameController =
        useTextEditingController(text: kDebugMode ? "itsatifsiddiqui" : null);
    final emailController =
        useTextEditingController(text: kDebugMode ? "itsatifsiddiqui@gmail.com" : null);
    final passwordController = useTextEditingController(text: kDebugMode ? "Mubeen12" : null);
    final selectedCountry = useState<String?>(kDebugMode ? "Pakistan" : null);
    final formKey = GlobalObjectKey<FormState>(context);
    final isLoading = ref.watch(authProvider.select((value) => value.isLoading));

    final showPassword = useState<bool>(false);
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
              TitleLogo(width: 0.5.sw).centered(),
              16.heightBox,
              PrimaryTextField(
                controller: firstnameController,
                title: "First name",
                hintText: "Enter your First Name",
                validator: Validators.emptyValidator,
                textInputAction: TextInputAction.next,
              ),
              12.heightBox,
              PrimaryTextField(
                controller: lastNameController,
                title: "Last name",
                hintText: "Enter your Last Name",
                validator: Validators.emptyValidator,
                textInputAction: TextInputAction.next,
              ),
              12.heightBox,
              PrimaryTextField(
                controller: usernameController,
                title: "Username",
                hintText: "Enter a name that stands you out",
                validator: Validators.usernameValidator,
                textInputAction: TextInputAction.next,
              ),
              12.heightBox,
              PrimaryTextField(
                controller: emailController,
                title: "Email: (You need a valid, accessible email to complete this process)",
                hintText: "Enter a valid email which contains an @",
                validator: Validators.emailValidator,
                textInputAction: TextInputAction.next,
              ),
              12.heightBox,
              PrimaryTextField(
                controller: passwordController,
                title: "Password",
                hintText: "Enter a strong password",
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
              12.heightBox,
              TitledDropDown<String>(
                title: "Country of Residence",
                titles: kCountries.keys.toList(),
                items: kCountries.keys.toList(),
                value: selectedCountry.value,
                onChanged: (value) => selectedCountry.value = value,
              ),
              24.heightBox,
              PrimaryButton(
                onTap: () {
                  if (!formKey.currentState!.validate()) return;
                  final registerData = {
                    "username": usernameController.text.trim(),
                    "first_name": firstnameController.text.trim().firstLetterUpperCase(),
                    "last_name": lastNameController.text.trim().firstLetterUpperCase(),
                    "nationality": selectedCountry.value!,
                    "agree_to_privacy_terms": true,
                    "email": emailController.text.trim(),
                    "password": passwordController.text.trim(),
                    "ranks": "Basic",
                    "points": 0,
                    "level": "Beginner",
                    "avatar": kAvatarsList.keys.last,
                    "image_url": kAvatarsList.keys.last,
                  };
                  ref.read(authProvider.notifier).register(registerData);
                },
                text: "Signup",
              ),
              16.heightBox,
            ],
          ).scrollVertical().px16().safeArea(),
        ),
      ),
    );
  }
}
