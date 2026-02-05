import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/lingafriq_ui_helpers.dart';
import 'package:lingafriq/widgets/animated/animated_button.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Change Password Screen - Full production implementation
class ChangePasswordScreen extends HookConsumerWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final currentPasswordController = useTextEditingController();
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    
    final showCurrentPassword = useState(false);
    final showNewPassword = useState(false);
    final showConfirmPassword = useState(false);
    final isLoading = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    Future<void> _changePassword() async {
      if (formKey.currentState == null || !formKey.currentState!.validate()) return;

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
          showLingAfriqError(context, 'Error changing password: ${ErrorHandler.getUserFriendlyError(e)}');
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Change Password'),
            Text('LingAfriq', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: PanAfricanColors.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: ResponsiveSafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.sp),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 24.h),
                  
                  // Info Card
                  Container(
                    padding: EdgeInsets.all(16.sp),
                    decoration: BoxDecoration(
                      color: PanAfricanColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PanAfricanColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: PanAfricanColors.primary,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Use at least 8 characters with a mix of letters and numbers.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                  
                  // Current Password
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: !showCurrentPassword.value,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showCurrentPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          showCurrentPassword.value = !showCurrentPassword.value;
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Current password is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  
                  // New Password
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: !showNewPassword.value,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showNewPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          showNewPassword.value = !showNewPassword.value;
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
                  ),
                  SizedBox(height: 16.h),
                  
                  // Confirm Password
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !showConfirmPassword.value,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_clock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showConfirmPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          showConfirmPassword.value = !showConfirmPassword.value;
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32.h),
                  
                  // Change Password Button
                  AnimatedButton(
                    text: isLoading.value ? 'Changing Password...' : 'Change Password',
                    onPressed: isLoading.value ? null : _changePassword,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
