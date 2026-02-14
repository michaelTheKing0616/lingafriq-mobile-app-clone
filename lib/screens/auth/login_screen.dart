import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/screens/auth/sign_up_screen.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/validators.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/title_logo.dart';
import 'package:loading_overlay_pro/loading_overlay_pro.dart';

import 'forgot_password_screen.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController =
        useTextEditingController(text: kDebugMode ? "itsatifsiddiqui@gmail.com" : null);
    final passwordController = useTextEditingController(text: kDebugMode ? "Mubeen12" : null);
    final formKey = GlobalObjectKey<FormState>(context);
    final isLoading = ref.watch(authProvider.select((value) => value.isLoading));
    final showPassword = useState<bool>(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LoadingOverlayPro(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
        body: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.always,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 0.15.sh),
                  Center(child: const TitleLogo()),
                  SizedBox(height: PanAfricanSpacing.lg),
                  
                  // Email field
                  Text(
                    'Email',
                    style: PanAfricanTypography.labelLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.emailValidator,
                    style: PanAfricanTypography.bodyLarge(context),
                    decoration: _inputDecoration(
                      context,
                      hintText: 'Enter your registered email',
                      prefixIcon: Icons.email_outlined,
                      isDark: isDark,
                    ),
                  ),
                  
                  SizedBox(height: PanAfricanSpacing.md),
                  
                  // Password field
                  Text(
                    'Password',
                    style: PanAfricanTypography.labelLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  TextFormField(
                    controller: passwordController,
                    obscureText: !showPassword.value,
                    textInputAction: TextInputAction.done,
                    validator: Validators.passwordValidator,
                    maxLines: 1,
                    style: PanAfricanTypography.bodyLarge(context),
                    decoration: _inputDecoration(
                      context,
                      hintText: 'Enter your password',
                      prefixIcon: Icons.lock_outline,
                      isDark: isDark,
                      suffixIcon: IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          showPassword.value = !showPassword.value;
                        },
                        icon: Icon(
                          showPassword.value ? Icons.visibility_off : Icons.visibility,
                          color: PanAfricanColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: PanAfricanSpacing.xs),
                  
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(navigationProvider).navigateTo(const ForgotPasswordScreen());
                      },
                      child: Text(
                        'Forgot password?',
                        style: PanAfricanTypography.bodyMedium(context).copyWith(
                          color: PanAfricanColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: PanAfricanSpacing.lg),
                  
                  // Login button
                  Semantics(
                    label: 'Login button',
                    button: true,
                    child: GestureDetector(
                      onTap: () {
                        if (formKey.currentState == null || !formKey.currentState!.validate()) {
                          HapticFeedback.mediumImpact();
                          return;
                        }
                        HapticFeedback.mediumImpact();
                        ref.read(authProvider.notifier).login(
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                              storeCredentials: true,
                            );
                      },
                      child: Container(
                        height: 56.h,
                        decoration: BoxDecoration(
                          gradient: PanAfricanGradients.forest,
                          borderRadius: PanAfricanRadius.lgBR,
                          boxShadow: PanAfricanShadows.glowGreen(0.3),
                        ),
                        child: Center(
                          child: Text(
                            'Login',
                            style: PanAfricanTypography.titleLarge(context).copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: PanAfricanSpacing.md),
                  
                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: PanAfricanTypography.bodyMedium(context),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(navigationProvider).navigateTo(const SignupScreen());
                        },
                        child: Text(
                          'Sign up',
                          style: PanAfricanTypography.bodyMedium(context).copyWith(
                            color: PanAfricanColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: PanAfricanColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: PanAfricanColors.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark
          ? PanAfricanColors.surfaceContainerDark
          : PanAfricanColors.surfaceContainerLight,
      border: OutlineInputBorder(
        borderRadius: PanAfricanRadius.lgBR,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: PanAfricanRadius.lgBR,
        borderSide: BorderSide(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: PanAfricanRadius.lgBR,
        borderSide: BorderSide(
          color: PanAfricanColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: PanAfricanRadius.lgBR,
        borderSide: BorderSide(color: PanAfricanColors.error, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.md,
        vertical: PanAfricanSpacing.md,
      ),
    );
  }
}
