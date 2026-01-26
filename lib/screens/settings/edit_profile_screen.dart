import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/widgets/animated/animated_button.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'dart:convert';

/// Edit Profile Screen - Full production implementation
class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final firstNameController = useTextEditingController(text: user?.first_name ?? '');
    final lastNameController = useTextEditingController(text: user?.last_name ?? '');
    final emailController = useTextEditingController(text: user?.email ?? '');
    final usernameController = useTextEditingController(text: user?.username ?? '');
    
    final selectedImage = useState<XFile?>(null);
    final isLoading = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    Future<void> _pickImage() async {
      try {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error picking image: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    Future<void> _takePhoto() async {
      try {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error taking photo: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    Future<void> _saveProfile() async {
      if (formKey.currentState == null || !formKey.currentState!.validate()) return;

      isLoading.value = true;

      try {
        final apiNotifier = ref.read(apiProvider.notifier);
        final Map<String, dynamic> updateData = {
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'username': usernameController.text.trim(),
        };

        // Handle avatar upload if image was selected (backend may expect avatar or avater)
        if (selectedImage.value != null) {
          final imageBytes = await selectedImage.value!.readAsBytes();
          final base64Image = base64Encode(imageBytes);
          updateData['avatar'] = 'data:image/jpeg;base64,$base64Image';
          updateData['avater'] = 'data:image/jpeg;base64,$base64Image';
        }

        final success = await apiNotifier.updateProfile(updateData);

        if (success && context.mounted) {
          await ref.read(userProvider.notifier).refreshUser();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: ${ErrorHandler.getUserFriendlyError(e)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    void _showImagePicker() {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: PanAfricanColors.primary,
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
                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60.sp,
                          backgroundColor: PanAfricanColors.primary,
                          backgroundImage: selectedImage.value != null
                              ? FileImage(File(selectedImage.value!.path))
                              : (user?.avater != null
                                  ? NetworkImage(user!.avater!)
                                  : null) as ImageProvider?,
                          child: (selectedImage.value == null && user?.avater == null)
                              ? Icon(
                                  Icons.person,
                                  size: 60.sp,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20.sp,
                            backgroundColor: PanAfricanColors.primary,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white),
                              onPressed: _showImagePicker,
                              iconSize: 20.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                  
                  // First Name
                  TextFormField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  
                  // Last Name
                  TextFormField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  
                  // Email
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  
                  // Username
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32.h),
                  
                  // Save Button
                  AnimatedButton(
                    text: isLoading.value ? 'Saving...' : 'Save Changes',
                    onPressed: isLoading.value ? null : _saveProfile,
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
