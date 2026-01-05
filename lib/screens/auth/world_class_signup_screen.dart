/// World-Class Signup Screen
/// Surpasses best apps with smooth animations, validation, and modern UX

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/services/auth/credential_storage_service.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/validators.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/screens/auth/world_class_login_screen.dart';

class WorldClassSignupScreen extends HookConsumerWidget {
  const WorldClassSignupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstNameController = useTextEditingController();
    final lastNameController = useTextEditingController();
    final usernameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = ref.watch(authProvider.select((value) => value.isLoading));
    final showPassword = useState<bool>(false);
    final showConfirmPassword = useState<bool>(false);
    final selectedCountry = useState<String?>(null);
    final currentStep = useState<int>(0);
    final credentialStorage = CredentialStorageService();

    // Load stored data if available
    useEffect(() {
      _loadStoredData(
        firstNameController,
        lastNameController,
        emailController,
        credentialStorage,
      );
      return null;
    }, []);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSteps = 2;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Creating your account...',
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      PanAfricanColors.primaryDark,
                      PanAfricanColors.secondaryDark,
                    ]
                  : [
                      PanAfricanColors.primaryLight.withOpacity(0.1),
                      PanAfricanColors.secondaryLight.withOpacity(0.1),
                    ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(currentStep.value, totalSteps, isDark)
                    .animate()
                    .fadeIn(duration: 400.ms),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.sp),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 20.h),
                          
                          // Logo
                          _buildLogo(context)
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .scale(begin: Offset(0.8, 0.8), duration: 400.ms),
                          
                          SizedBox(height: 32.h),
                          
                          // Title
                          _buildTitle(context, currentStep.value, isDark)
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 400.ms)
                              .slideY(begin: 0.1, duration: 400.ms),
                          
                          SizedBox(height: 32.h),
                          
                          // Step 0: Personal Info
                          if (currentStep.value == 0) ...[
                            _buildFirstNameField(context, firstNameController, isDark)
                                .animate()
                                .fadeIn(delay: 300.ms, duration: 400.ms)
                                .slideX(begin: -0.1, duration: 400.ms),
                            
                            SizedBox(height: 16.h),
                            
                            _buildLastNameField(context, lastNameController, isDark)
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 400.ms)
                                .slideX(begin: -0.1, duration: 400.ms),
                            
                            SizedBox(height: 16.h),
                            
                            _buildUsernameField(context, usernameController, isDark)
                                .animate()
                                .fadeIn(delay: 500.ms, duration: 400.ms)
                                .slideX(begin: -0.1, duration: 400.ms),
                          ],
                          
                          // Step 1: Account Details
                          if (currentStep.value == 1) ...[
                            _buildEmailField(context, emailController, isDark)
                                .animate()
                                .fadeIn(delay: 300.ms, duration: 400.ms)
                                .slideX(begin: -0.1, duration: 400.ms),
                            
                            SizedBox(height: 16.h),
                            
                            _buildPasswordField(
                              context,
                              passwordController,
                              showPassword,
                              isDark,
                            )
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 400.ms)
                                .slideX(begin: -0.1, duration: 400.ms),
                            
                            SizedBox(height: 16.h),
                            
                            _buildConfirmPasswordField(
                              context,
                              confirmPasswordController,
                              passwordController,
                              showConfirmPassword,
                              isDark,
                            )
                                .animate()
                                .fadeIn(delay: 500.ms, duration: 400.ms)
                                .slideX(begin: -0.1, duration: 400.ms),
                            
                            SizedBox(height: 16.h),
                            
                            _buildCountryField(
                              context,
                              selectedCountry,
                              isDark,
                            )
                                .animate()
                                .fadeIn(delay: 600.ms, duration: 400.ms)
                                .slideX(begin: -0.1, duration: 400.ms),
                          ],
                          
                          SizedBox(height: 32.h),
                          
                          // Navigation buttons
                          _buildNavigationButtons(
                            context,
                            currentStep,
                            totalSteps,
                            formKey,
                            firstNameController,
                            lastNameController,
                            usernameController,
                            emailController,
                            passwordController,
                            selectedCountry,
                            credentialStorage,
                            ref,
                            isDark,
                          )
                              .animate()
                              .fadeIn(delay: 700.ms, duration: 400.ms)
                              .scale(delay: 700.ms, duration: 400.ms),
                          
                          SizedBox(height: 24.h),
                          
                          // Login link
                          _buildLoginLink(context, ref)
                              .animate()
                              .fadeIn(delay: 800.ms, duration: 400.ms),
                          
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep, int totalSteps, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index <= currentStep;
          return Expanded(
            child: Container(
              height: 4.h,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: isActive
                    ? PanAfricanColors.primaryLight
                    : (isDark ? Colors.grey[800] : Colors.grey[300]),
                borderRadius: BorderRadius.circular(2),
              ),
            )
                .animate(target: isActive ? 1 : 0)
                .scaleX(duration: 300.ms, curve: Curves.easeOut),
          );
        }),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Center(
      child: Container(
        width: 100.w,
        height: 100.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              PanAfricanColors.primaryLight,
              PanAfricanColors.secondaryLight,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: PanAfricanColors.primaryLight.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          Icons.person_add,
          size: 50.sp,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, int step, bool isDark) {
    final titles = ['Create Your Account', 'Set Up Your Profile'];
    final subtitles = [
      'Tell us a bit about yourself',
      'Secure your account with a password',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titles[step],
          style: PanAfricanTypography.headlineLarge(context).copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : PanAfricanColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subtitles[step],
          style: PanAfricanTypography.bodyLarge(context).copyWith(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildFirstNameField(
    BuildContext context,
    TextEditingController controller,
    bool isDark,
  ) {
    return _buildTextField(
      context: context,
      controller: controller,
      label: 'First Name',
      hint: 'Enter your first name',
      icon: Icons.person_outline,
      validator: Validators.emptyValidator,
      isDark: isDark,
    );
  }

  Widget _buildLastNameField(
    BuildContext context,
    TextEditingController controller,
    bool isDark,
  ) {
    return _buildTextField(
      context: context,
      controller: controller,
      label: 'Last Name',
      hint: 'Enter your last name',
      icon: Icons.person_outline,
      validator: Validators.emptyValidator,
      isDark: isDark,
    );
  }

  Widget _buildUsernameField(
    BuildContext context,
    TextEditingController controller,
    bool isDark,
  ) {
    return _buildTextField(
      context: context,
      controller: controller,
      label: 'Username',
      hint: 'Choose a unique username',
      icon: Icons.alternate_email,
      validator: Validators.usernameValidator,
      isDark: isDark,
    );
  }

  Widget _buildEmailField(
    BuildContext context,
    TextEditingController controller,
    bool isDark,
  ) {
    return _buildTextField(
      context: context,
      controller: controller,
      label: 'Email',
      hint: 'Enter your email address',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: Validators.emailValidator,
      isDark: isDark,
    );
  }

  Widget _buildPasswordField(
    BuildContext context,
    TextEditingController controller,
    ValueNotifier<bool> showPassword,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: PanAfricanTypography.labelLarge(context).copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : PanAfricanColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: !showPassword.value,
          validator: Validators.passwordValidator,
          style: PanAfricanTypography.bodyLarge(context),
          decoration: InputDecoration(
            hintText: 'Create a strong password',
            prefixIcon: Icon(Icons.lock_outline, color: PanAfricanColors.primaryLight),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword.value ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () => showPassword.value = !showPassword.value,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.grey[900]!.withOpacity(0.5)
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: PanAfricanColors.primaryLight,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          ),
        ),
        SizedBox(height: 8.h),
        _buildPasswordStrengthIndicator(context, controller.text, isDark),
      ],
    );
  }

  Widget _buildConfirmPasswordField(
    BuildContext context,
    TextEditingController controller,
    TextEditingController passwordController,
    ValueNotifier<bool> showPassword,
    bool isDark,
  ) {
    return _buildTextField(
      context: context,
      controller: controller,
      label: 'Confirm Password',
      hint: 'Re-enter your password',
      icon: Icons.lock_outline,
      obscureText: !showPassword.value,
      suffixIcon: IconButton(
        icon: Icon(
          showPassword.value ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[600],
        ),
        onPressed: () => showPassword.value = !showPassword.value,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      isDark: isDark,
    );
  }

  Widget _buildCountryField(
    BuildContext context,
    ValueNotifier<String?> selectedCountry,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country of Residence',
          style: PanAfricanTypography.labelLarge(context).copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : PanAfricanColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: selectedCountry.value,
          decoration: InputDecoration(
            hintText: 'Select your country',
            prefixIcon: Icon(Icons.public, color: PanAfricanColors.primaryLight),
            filled: true,
            fillColor: isDark
                ? Colors.grey[900]!.withOpacity(0.5)
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: PanAfricanColors.primaryLight,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator(BuildContext context, String password, bool isDark) {
    if (password.isEmpty) return SizedBox.shrink();

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.lightGreen,
      Colors.green,
    ];

    final labels = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: Container(
                height: 4.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: index < strength
                      ? colors[strength - 1]
                      : (isDark ? Colors.grey[800] : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 4.h),
        Text(
          labels[strength.clamp(0, 4)],
          style: PanAfricanTypography.bodySmall(context).copyWith(
            color: colors[strength.clamp(0, 4)],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    bool obscureText = false,
    Widget? suffixIcon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: PanAfricanTypography.labelLarge(context).copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : PanAfricanColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: PanAfricanTypography.bodyLarge(context),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: PanAfricanColors.primaryLight),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark
                ? Colors.grey[900]!.withOpacity(0.5)
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: PanAfricanColors.primaryLight,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    ValueNotifier<int> currentStep,
    int totalSteps,
    GlobalKey<FormState> formKey,
    TextEditingController firstNameController,
    TextEditingController lastNameController,
    TextEditingController usernameController,
    TextEditingController emailController,
    TextEditingController passwordController,
    ValueNotifier<String?> selectedCountry,
    CredentialStorageService storage,
    WidgetRef ref,
    bool isDark,
  ) {
    return Row(
      children: [
        if (currentStep.value > 0)
          Expanded(
            child: ScaleOnTap(
              onTap: () {
                HapticFeedback.lightImpact();
                currentStep.value--;
              },
              child: Container(
                height: 56.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[900]!.withOpacity(0.5)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Back',
                    style: PanAfricanTypography.titleMedium(context).copyWith(
                      color: isDark ? Colors.white : PanAfricanColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (currentStep.value > 0) SizedBox(width: 16.w),
        Expanded(
          child: ScaleOnTap(
            onTap: () async {
              if (!formKey.currentState!.validate()) {
                HapticFeedback.mediumImpact();
                return;
              }

              HapticFeedback.lightImpact();

              if (currentStep.value < totalSteps - 1) {
                currentStep.value++;
              } else {
                // Final step - register
                final registerData = {
                  "username": usernameController.text.trim(),
                  "first_name": firstNameController.text.trim(),
                  "last_name": lastNameController.text.trim(),
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

                try {
                  // Store credentials
                  await storage.storeCredentials(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                  );

                  await ref.read(authProvider.notifier).register(registerData);
                } catch (e) {
                  if (context.mounted) {
                    ErrorHandler.showError(context, e);
                  }
                }
              }
            },
            child: Container(
              height: 56.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PanAfricanColors.primaryLight,
                    PanAfricanColors.secondaryLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: PanAfricanColors.primaryLight.withOpacity(0.4),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  currentStep.value < totalSteps - 1 ? 'Continue' : 'Create Account',
                  style: PanAfricanTypography.titleLarge(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: PanAfricanTypography.bodyMedium(context),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              SmoothPageRoute(child: const WorldClassLoginScreen()),
            );
          },
          child: Text(
            'Sign In',
            style: PanAfricanTypography.bodyMedium(context).copyWith(
              color: PanAfricanColors.primaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadStoredData(
    TextEditingController firstNameController,
    TextEditingController lastNameController,
    TextEditingController emailController,
    CredentialStorageService storage,
  ) async {
    await storage.initialize();
    final firstName = await storage.getStoredFirstName();
    final lastName = await storage.getStoredLastName();
    final email = await storage.getStoredEmail();

    if (firstName != null) firstNameController.text = firstName;
    if (lastName != null) lastNameController.text = lastName;
    if (email != null) emailController.text = email;
  }
}

