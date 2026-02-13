import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/validators.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/title_logo.dart';
import 'package:lingafriq/screens/auth/email_verification_screen.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LoadingOverlayPro(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            icon: Icon(
              PanAfricanIcons.back,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: TitleLogo(width: 0.5.sw)),
                  SizedBox(height: PanAfricanSpacing.md),
                  
                  // First name
                  _buildTextField(
                    context: context,
                    controller: firstnameController,
                    label: 'First name',
                    hint: 'Enter your First Name',
                    icon: Icons.person_outline,
                    validator: Validators.emptyValidator,
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  
                  // Last name
                  _buildTextField(
                    context: context,
                    controller: lastNameController,
                    label: 'Last name',
                    hint: 'Enter your Last Name',
                    icon: Icons.person_outline,
                    validator: Validators.emptyValidator,
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  
                  // Username
                  _buildTextField(
                    context: context,
                    controller: usernameController,
                    label: 'Username',
                    hint: 'Enter a name that stands you out',
                    icon: Icons.alternate_email,
                    validator: Validators.usernameValidator,
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  
                  // Email
                  _buildTextField(
                    context: context,
                    controller: emailController,
                    label: 'Email',
                    hint: 'Enter a valid email address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.emailValidator,
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  
                  // Password
                  _buildPasswordField(
                    context: context,
                    controller: passwordController,
                    showPassword: showPassword,
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  
                  // Country dropdown
                  Text(
                    'Country of Residence',
                    style: PanAfricanTypography.labelLarge(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  DropdownButtonFormField<String>(
                    value: selectedCountry.value,
                    decoration: _inputDecoration(
                      context,
                      hintText: 'Select your country',
                      prefixIcon: Icons.public,
                      isDark: isDark,
                    ),
                    items: kCountries.keys.map((country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                    onChanged: (value) => selectedCountry.value = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your country';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: PanAfricanSpacing.lg),
                  
                  // Signup button
                  GestureDetector(
                    onTap: () {
                      if (!formKey.currentState!.validate()) {
                        HapticFeedback.mediumImpact();
                        return;
                      }
                      if (selectedCountry.value == null) {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please select your country of residence'),
                            backgroundColor: PanAfricanColors.error,
                          ),
                        );
                        return;
                      }
                      HapticFeedback.mediumImpact();
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
                      ref.read(authProvider.notifier).register(
                        registerData,
                        onSuccess: () {
                          // Navigate to email verification screen after successful registration
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => EmailVerificationScreen(
                                  email: emailController.text.trim(),
                                  firstName: firstnameController.text.trim(),
                                ),
                              ),
                            );
                          }
                        },
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
                          'Sign Up',
                          style: PanAfricanTypography.titleLarge(context).copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: PanAfricanTypography.labelLarge(context).copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          validator: validator,
          style: PanAfricanTypography.bodyLarge(context),
          decoration: _inputDecoration(
            context,
            hintText: hint,
            prefixIcon: icon,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required ValueNotifier<bool> showPassword,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: PanAfricanTypography.labelLarge(context).copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        TextFormField(
          controller: controller,
          obscureText: !showPassword.value,
          textInputAction: TextInputAction.done,
          validator: Validators.passwordValidator,
          maxLines: 1,
          style: PanAfricanTypography.bodyLarge(context),
          decoration: _inputDecoration(
            context,
            hintText: 'Enter a strong password',
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
      ],
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
