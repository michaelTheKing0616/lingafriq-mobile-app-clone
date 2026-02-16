import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/lingafriq_ui_helpers.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Change Password Screen - Pan-African Design System
class ChangePasswordScreen extends HookConsumerWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final currentPasswordController = useTextEditingController();
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();

    final showCurrentPassword = useState(false);
    final showNewPassword = useState(false);
    final showConfirmPassword = useState(false);
    final isLoading = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    Future<void> changePassword() async {
      if (formKey.currentState == null || !formKey.currentState!.validate()) {
        return;
      }

      HapticFeedback.mediumImpact();
      isLoading.value = true;

      try {
        final apiNotifier = ref.read(apiProvider.notifier);
        final success = await apiNotifier.changePassword(
          currentPassword: currentPasswordController.text,
          newPassword: newPasswordController.text,
        );

        if (success && context.mounted) {
          showLingAfriqSuccess(context, 'Password changed successfully!');
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          showLingAfriqError(
            context,
            'Error changing password: ${ErrorHandler.getUserFriendlyError(e)}',
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colorScheme.onPrimary,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        title: Text(
          'Change Password',
          style: PanAfricanTypography.titleLarge(context)
              .copyWith(color: colorScheme.onPrimary),
        ),
        backgroundColor: PanAfricanColors.primary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.primary.withOpacity(0.05),
                    PanAfricanColors.surfaceLight,
                  ],
                ),
        ),
        child: ResponsiveSafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: PanAfricanSpacing.lg),

                  // Info Card
                  Container(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    decoration: BoxDecoration(
                      color: PanAfricanColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                      border: Border.all(
                        color: PanAfricanColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(PanAfricanSpacing.sm),
                          decoration: BoxDecoration(
                            color: PanAfricanColors.primary.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(PanAfricanRadius.md),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: PanAfricanColors.primary,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: PanAfricanSpacing.md),
                        Expanded(
                          child: Text(
                            'Use at least 8 characters with a mix of letters and numbers.',
                            style: PanAfricanTypography.bodyMedium(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xl),

                  // Current Password
                  _PasswordTextField(
                    controller: currentPasswordController,
                    label: 'Current Password',
                    icon: Icons.lock_outline_rounded,
                    showPassword: showCurrentPassword.value,
                    onToggleVisibility: () {
                      HapticFeedback.selectionClick();
                      showCurrentPassword.value = !showCurrentPassword.value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Current password is required';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.md),

                  // New Password
                  _PasswordTextField(
                    controller: newPasswordController,
                    label: 'New Password',
                    icon: Icons.lock_rounded,
                    showPassword: showNewPassword.value,
                    onToggleVisibility: () {
                      HapticFeedback.selectionClick();
                      showNewPassword.value = !showNewPassword.value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'New password is required';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
                        return 'Password must contain letters and numbers';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.md),

                  // Confirm Password
                  _PasswordTextField(
                    controller: confirmPasswordController,
                    label: 'Confirm New Password',
                    icon: Icons.lock_clock_rounded,
                    showPassword: showConfirmPassword.value,
                    onToggleVisibility: () {
                      HapticFeedback.selectionClick();
                      showConfirmPassword.value = !showConfirmPassword.value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.xl),

                  // Change Password Button
                  _ChangePasswordButton(
                    isLoading: isLoading.value,
                    onPressed: changePassword,
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool showPassword;
  final VoidCallback onToggleVisibility;
  final String? Function(String?)? validator;
  final bool isDark;

  const _PasswordTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.showPassword,
    required this.onToggleVisibility,
    this.validator,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !showPassword,
      validator: validator,
      style: PanAfricanTypography.bodyLarge(context),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: PanAfricanTypography.bodyMedium(context).copyWith(
          color: PanAfricanColors.textSecondary,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.all(PanAfricanSpacing.sm),
          padding: EdgeInsets.all(PanAfricanSpacing.sm),
          decoration: BoxDecoration(
            color: PanAfricanColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
          ),
          child: Icon(
            icon,
            color: PanAfricanColors.primary,
            size: 20.sp,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            color: PanAfricanColors.neutralMedium,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor:
            isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          borderSide: BorderSide(
            color: isDark
                ? PanAfricanColors.borderDark
                : PanAfricanColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          borderSide: BorderSide(
            color: isDark
                ? PanAfricanColors.borderDark
                : PanAfricanColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          borderSide: BorderSide(
            color: PanAfricanColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          borderSide: BorderSide(
            color: PanAfricanColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          borderSide: BorderSide(
            color: PanAfricanColors.error,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _ChangePasswordButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Change password',
      button: true,
      child: Material(
        color: PanAfricanColors.primary,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24.sp,
                    height: 24.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(colorScheme.onPrimary),
                    ),
                  )
                : Text(
                      'Change Password',
                      style: PanAfricanTypography.titleMedium(context).copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
