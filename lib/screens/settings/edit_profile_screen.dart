import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/lingafriq_ui_helpers.dart';
import 'dart:convert';

/// Edit Profile Screen - Pan-African Design System
class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final firstNameController =
        useTextEditingController(text: user?.first_name ?? '');
    final lastNameController =
        useTextEditingController(text: user?.last_name ?? '');
    final emailController = useTextEditingController(text: user?.email ?? '');
    final usernameController =
        useTextEditingController(text: user?.username ?? '');

    final selectedImage = useState<XFile?>(null);
    final isLoading = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    Future<void> _pickImage() async {
      try {
        HapticFeedback.selectionClick();
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        if (image != null) {
          selectedImage.value = image;
        }
      } catch (e) {
        if (context.mounted) {
          showLingAfriqError(context, 'Error picking image: ${e.toString()}');
        }
      }
    }

    Future<void> _takePhoto() async {
      try {
        HapticFeedback.selectionClick();
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        if (image != null) {
          selectedImage.value = image;
        }
      } catch (e) {
        if (context.mounted) {
          showLingAfriqError(context, 'Error taking photo: ${e.toString()}');
        }
      }
    }

    Future<void> _saveProfile() async {
      if (formKey.currentState == null || !formKey.currentState!.validate())
        return;

      HapticFeedback.mediumImpact();
      isLoading.value = true;

      try {
        final apiNotifier = ref.read(apiProvider.notifier);
        final Map<String, dynamic> updateData = {
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'username': usernameController.text.trim(),
        };

        // Handle avatar upload if image was selected
        if (selectedImage.value != null) {
          final imageBytes = await selectedImage.value!.readAsBytes();
          final base64Image = base64Encode(imageBytes);
          updateData['avatar'] = 'data:image/jpeg;base64,$base64Image';
          updateData['avater'] = 'data:image/jpeg;base64,$base64Image';
        }

        final success = await apiNotifier.updateProfile(updateData);

        if (success && context.mounted) {
          await ref.read(userProvider.notifier).refreshUser();
          showLingAfriqSuccess(context, 'Profile updated successfully!');
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          showLingAfriqError(
            context,
            'Error updating profile: ${ErrorHandler.getUserFriendlyError(e)}',
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    void _showImagePicker() {
      HapticFeedback.lightImpact();
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: isDark
                  ? PanAfricanColors.cardDark
                  : PanAfricanColors.cardLight,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(PanAfricanRadius.xl),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: PanAfricanSpacing.sm),
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: PanAfricanColors.neutralLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),
                  Text(
                    'Change Profile Photo',
                    style: PanAfricanTypography.titleMedium(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  _ImagePickerOption(
                    icon: Icons.photo_library_rounded,
                    title: 'Choose from Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                    isDark: isDark,
                  ),
                  _ImagePickerOption(
                    icon: Icons.camera_alt_rounded,
                    title: 'Take Photo',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                    isDark: isDark,
                  ),
                  _ImagePickerOption(
                    icon: Icons.close_rounded,
                    title: 'Cancel',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    isDark: isDark,
                    isDestructive: true,
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Edit Profile',
          style: PanAfricanTypography.titleLarge(context)
              .copyWith(color: Colors.white),
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

                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: PanAfricanShadows.md,
                          ),
                          child: CircleAvatar(
                            radius: 50.w,
                            backgroundColor: PanAfricanColors.primary,
                            backgroundImage: selectedImage.value != null
                                ? FileImage(File(selectedImage.value!.path))
                                : (user?.avater != null
                                        ? NetworkImage(user!.avater!)
                                        : null)
                                    as ImageProvider?,
                            child: (selectedImage.value == null &&
                                    user?.avater == null)
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 50.sp,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImagePicker,
                            child: Container(
                              padding: EdgeInsets.all(PanAfricanSpacing.sm),
                              decoration: BoxDecoration(
                                color: PanAfricanColors.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? PanAfricanColors.surfaceDark
                                      : PanAfricanColors.surfaceLight,
                                  width: 3,
                                ),
                                boxShadow: PanAfricanShadows.sm,
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.black,
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xl),

                  // First Name
                  _ProfileTextField(
                    controller: firstNameController,
                    label: 'First Name',
                    icon: Icons.person_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.md),

                  // Last Name
                  _ProfileTextField(
                    controller: lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.md),

                  // Email
                  _ProfileTextField(
                    controller: emailController,
                    label: 'Email',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.md),

                  // Username
                  _ProfileTextField(
                    controller: usernameController,
                    label: 'Username',
                    icon: Icons.alternate_email_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  SizedBox(height: PanAfricanSpacing.xl),

                  // Save Button
                  _SaveButton(
                    isLoading: isLoading.value,
                    onPressed: _saveProfile,
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

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool isDark;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
        filled: true,
        fillColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
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

class _ImagePickerOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;

  const _ImagePickerOption({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.sm),
        decoration: BoxDecoration(
          color: isDestructive
              ? PanAfricanColors.error.withOpacity(0.1)
              : PanAfricanColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        ),
        child: Icon(
          icon,
          color: isDestructive ? PanAfricanColors.error : PanAfricanColors.primary,
          size: 24.sp,
        ),
      ),
      title: Text(
        title,
        style: PanAfricanTypography.bodyLarge(context).copyWith(
          color: isDestructive ? PanAfricanColors.error : null,
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
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
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    'Save Changes',
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
