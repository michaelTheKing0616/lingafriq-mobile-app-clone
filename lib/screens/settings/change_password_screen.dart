import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/animated/animated_button.dart';
import 'package:lingafriq/utils/app_colors.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error changing password: ${ErrorHandler.getUserFriendlyMessage(e)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: PanAfricanColors.primaryGreen,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: SafeArea(
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
                      color: PanAfricanColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PanAfricanColors.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: PanAfricanColors.primaryGreen,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Your password must be at least 8 characters long and contain a mix of letters and numbers.',
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
                          setState(() {
                            showCurrentPassword.value = !showCurrentPassword.value;
                          });
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
                          setState(() {
                            showNewPassword.value = !showNewPassword.value;
                          });
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
                          setState(() {
                            showConfirmPassword.value = !showConfirmPassword.value;
                          });
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
