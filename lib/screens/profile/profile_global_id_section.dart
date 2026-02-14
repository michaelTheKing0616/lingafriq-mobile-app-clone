import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Global ID Display and Edit Section for Profile
/// Shows user's unique handle and allows editing with uniqueness validation
class ProfileGlobalIdSection extends HookConsumerWidget {
  const ProfileGlobalIdSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isEditing = useState(false);
    final handleController = useTextEditingController(text: user?.global_id?.replaceFirst('@', '') ?? '');
    final isUpdating = useState(false);
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> updateGlobalId() async {
      final newHandle = handleController.text.trim();
      if (newHandle.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Handle cannot be empty')),
        );
        return;
      }

      if (newHandle.length < 3 || newHandle.length > 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Handle must be between 3 and 30 characters')),
        );
        return;
      }

      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(newHandle)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Handle may only contain letters, numbers, and underscores')),
        );
        return;
      }

      isUpdating.value = true;
      try {
        final response = await ApiService.put(
          '${AppConfig.apiBaseUrl}/accounts/auth/users/me',
          data: {
            'handle': newHandle,
          },
        );

        if (response.statusCode == 200) {
          // Update user provider
          if (user != null) {
            ref.read(userProvider.notifier).overrideUser(
              user.copyWith(global_id: newHandle),
            );
          }

          isEditing.value = false;
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Handle updated successfully!'),
              backgroundColor: PanAfricanColors.success,
            ),
          );
        }
      } catch (e) {
        final errorMsg = e.toString();
        String message = 'Failed to update handle';
        
        if (errorMsg.contains('already taken')) {
          message = 'This handle is already taken. Please choose another.';
        } else if (errorMsg.contains('reserved')) {
          message = 'This handle is reserved. Please choose another.';
        } else if (errorMsg.contains('between 3 and 30')) {
          message = 'Handle must be between 3 and 30 characters.';
        } else if (errorMsg.contains('letters, numbers, and underscores')) {
          message = 'Handle may only contain letters, numbers, and underscores.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: PanAfricanColors.error,
          ),
        );
      } finally {
        isUpdating.value = false;
      }
    }

    final currentHandle = user?.global_id ?? 'Not set';
    final displayHandle = currentHandle.startsWith('@') ? currentHandle : '@$currentHandle';

    return PanAfricanCard(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.alternate_email,
                    color: PanAfricanColors.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: PanAfricanSpacing.sm),
                  Text(
                    'Your Handle',
                    style: PanAfricanTypography.titleMedium(context),
                  ),
                ],
              ),
              if (!isEditing.value && user?.is_current_user == true)
                TextButton.icon(
                  onPressed: () {
                    isEditing.value = true;
                    handleController.text = currentHandle.replaceFirst('@', '').replaceFirst('u_', '');
                    HapticFeedback.lightImpact();
                  },
                  icon: Icon(Icons.edit, size: 16.sp),
                  label: Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: PanAfricanColors.primary,
                  ),
                ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          
          if (!isEditing.value)
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: PanAfricanColors.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                border: Border.all(
                  color: PanAfricanColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayHandle,
                      style: PanAfricanTypography.titleLarge(context).copyWith(
                        color: PanAfricanColors.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Icon(
                    Icons.copy,
                    size: 18.sp,
                    color: PanAfricanColors.primary,
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: handleController,
                  maxLength: 30,
                  decoration: InputDecoration(
                    labelText: 'Handle',
                    hintText: 'e.g., myhandle123',
                    prefixText: '@',
                    helperText: '3-30 characters, letters, numbers, and underscores only',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isUpdating.value ? null : () {
                          isEditing.value = false;
                          handleController.text = currentHandle.replaceFirst('@', '').replaceFirst('u_', '');
                        },
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isUpdating.value ? null : updateGlobalId,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PanAfricanColors.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: isUpdating.value
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          
          SizedBox(height: PanAfricanSpacing.xs),
          Text(
            'Your unique handle for finding you in chats and connecting with other learners',
            style: PanAfricanTypography.bodySmall(context).copyWith(
              color: PanAfricanColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

