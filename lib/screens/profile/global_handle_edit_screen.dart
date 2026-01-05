import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Global Handle Edit Screen
/// Allows users to set/edit their unique global handle (global_id)
/// Validates uniqueness and checks against reserved names
class GlobalHandleEditScreen extends HookConsumerWidget {
  final String? currentGlobalId;

  const GlobalHandleEditScreen({
    Key? key,
    this.currentGlobalId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handleController = useTextEditingController(text: currentGlobalId?.replaceFirst('@', '') ?? '');
    final isChecking = useState(false);
    final isSaving = useState(false);
    final validationMessage = useState<String?>(null);
    final isValid = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Reserved names that cannot be used
    final reservedNames = [
      'admin', 'administrator', 'moderator', 'support', 'help',
      'system', 'api', 'bot', 'lingafriq', 'polie', 'official',
      'null', 'undefined', 'test', 'demo', 'example',
    ];

    Future<void> validateHandle(String handle) async {
      if (handle.isEmpty) {
        validationMessage.value = null;
        isValid.value = false;
        return;
      }

      // Basic validation
      if (handle.length < 3) {
        validationMessage.value = 'Handle must be at least 3 characters';
        isValid.value = false;
        return;
      }

      if (handle.length > 30) {
        validationMessage.value = 'Handle must be 30 characters or less';
        isValid.value = false;
        return;
      }

      // Check for valid characters (alphanumeric, underscore, hyphen)
      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(handle)) {
        validationMessage.value = 'Handle can only contain letters, numbers, underscores, and hyphens';
        isValid.value = false;
        return;
      }

      // Check against reserved names (case-insensitive)
      if (reservedNames.any((reserved) => handle.toLowerCase() == reserved.toLowerCase())) {
        validationMessage.value = 'This handle is reserved and cannot be used';
        isValid.value = false;
        return;
      }

      // If it's the same as current, it's valid
      if (handle.toLowerCase() == currentGlobalId?.replaceFirst('@', '').toLowerCase()) {
        validationMessage.value = 'This is your current handle';
        isValid.value = true;
        return;
      }

      // Check uniqueness with backend
      isChecking.value = true;
      try {
        final response = await ApiService.get(
          '${AppConfig.backendBaseUrl}/api/v1/accounts/auth/users/check-handle',
          queryParameters: {
            'handle': handle,
          },
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data['available'] == true) {
            validationMessage.value = '✓ This handle is available';
            isValid.value = true;
          } else {
            validationMessage.value = 'This handle is already taken';
            isValid.value = false;
          }
        } else {
          validationMessage.value = 'Unable to check handle availability';
          isValid.value = false;
        }
      } catch (e) {
        // If endpoint doesn't exist, try alternative check
        try {
          final searchResponse = await ApiService.get(
            Api.searchUsersByHandle(handle),
          );
          
          if (searchResponse.statusCode == 200) {
            final users = searchResponse.data;
            if (users is List && users.isEmpty) {
              validationMessage.value = '✓ This handle is available';
              isValid.value = true;
            } else {
              validationMessage.value = 'This handle is already taken';
              isValid.value = false;
            }
          } else {
            validationMessage.value = 'Unable to check handle availability';
            isValid.value = false;
          }
        } catch (e2) {
          validationMessage.value = 'Unable to verify handle. Please try again.';
          isValid.value = false;
        }
      } finally {
        isChecking.value = false;
      }
    }

    Future<void> saveHandle() async {
      if (!isValid.value || handleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid handle')),
        );
        return;
      }

      isSaving.value = true;
      try {
        final response = await ApiService.patch(
          '${AppConfig.backendBaseUrl}/api/v1/accounts/auth/users/profile',
          data: {
            'global_id': handleController.text.trim(),
          },
        );

        if (response.statusCode == 200) {
          // Update user provider
          await ref.read(userProvider.notifier).refreshUser();
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Global handle updated successfully!'),
                backgroundColor: PanAfricanColors.success,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('Failed to update handle');
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      } finally {
        isSaving.value = false;
      }
    }

    return LoadingOverlay(
      isLoading: isSaving.value,
      message: 'Updating handle...',
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Global Handle'),
          backgroundColor: Colors.transparent,
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
                      PanAfricanColors.surfaceLight,
                      PanAfricanColors.surfaceContainerLight,
                    ],
                  ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Your Global Handle',
                    style: PanAfricanTypography.headlineMedium(context),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Text(
                    'Choose a unique handle that others can use to find you. This will be your @username across the app.',
                    style: PanAfricanTypography.bodyMedium(context),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                  SizedBox(height: PanAfricanSpacing.xl),

                  // Current Handle Display
                  if (currentGlobalId != null) ...[
                    Card(
                      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                      child: Padding(
                        padding: EdgeInsets.all(PanAfricanSpacing.md),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: PanAfricanColors.primary),
                            SizedBox(width: PanAfricanSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Handle',
                                    style: PanAfricanTypography.labelSmall(context),
                                  ),
                                  SizedBox(height: PanAfricanSpacing.xxs),
                                  Text(
                                    '@$currentGlobalId',
                                    style: PanAfricanTypography.titleMedium(context)?.copyWith(
                                      color: PanAfricanColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.lg),
                  ],

                  // Handle Input
                  TextField(
                    controller: handleController,
                    decoration: InputDecoration(
                      labelText: 'Handle',
                      hintText: 'username',
                      prefixText: '@',
                      helperText: '3-30 characters, letters, numbers, underscores, and hyphens only',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? PanAfricanColors.surfaceContainerDark
                          : PanAfricanColors.surfaceContainerLight,
                      suffixIcon: isChecking.value
                          ? Padding(
                              padding: EdgeInsets.all(PanAfricanSpacing.md),
                              child: SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (value) {
                      validationMessage.value = null;
                      isValid.value = false;
                      if (value.isNotEmpty) {
                        validateHandle(value.trim());
                      }
                    },
                    onSubmitted: (_) {
                      if (isValid.value) {
                        saveHandle();
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                      LengthLimitingTextInputFormatter(30),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),

                  // Validation Message
                  if (validationMessage.value != null)
                    Container(
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      decoration: BoxDecoration(
                        color: isValid.value
                            ? PanAfricanColors.success.withOpacity(0.1)
                            : PanAfricanColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                        border: Border.all(
                          color: isValid.value
                              ? PanAfricanColors.success
                              : PanAfricanColors.error,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isValid.value ? Icons.check_circle : Icons.error_outline,
                            color: isValid.value
                                ? PanAfricanColors.success
                                : PanAfricanColors.error,
                            size: 20.sp,
                          ),
                          SizedBox(width: PanAfricanSpacing.sm),
                          Expanded(
                            child: Text(
                              validationMessage.value!,
                              style: PanAfricanTypography.bodySmall(context)?.copyWith(
                                color: isValid.value
                                    ? PanAfricanColors.success
                                    : PanAfricanColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1),
                  SizedBox(height: PanAfricanSpacing.xl),

                  // Rules
                  Card(
                    color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                    child: Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.rule, color: PanAfricanColors.primary),
                              SizedBox(width: PanAfricanSpacing.sm),
                              Text(
                                'Handle Rules',
                                style: PanAfricanTypography.titleSmall(context),
                              ),
                            ],
                          ),
                          SizedBox(height: PanAfricanSpacing.sm),
                          _buildRule(context, '3-30 characters long'),
                          _buildRule(context, 'Only letters, numbers, underscores (_), and hyphens (-)'),
                          _buildRule(context, 'Must be unique (not taken by another user)'),
                          _buildRule(context, 'Cannot be a reserved name'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xl),

                  // Save Button
                  ElevatedButton(
                    onPressed: (isValid.value && !isSaving.value && !isChecking.value)
                        ? saveHandle
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PanAfricanColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                    ),
                    child: Text(
                      'Save Handle',
                      style: PanAfricanTypography.titleMedium(context)?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRule(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16.sp, color: PanAfricanColors.primary),
          SizedBox(width: PanAfricanSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: PanAfricanTypography.bodySmall(context),
            ),
          ),
        ],
      ),
    );
  }
}

