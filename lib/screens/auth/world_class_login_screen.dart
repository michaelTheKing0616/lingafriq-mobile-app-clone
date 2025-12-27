/// World-Class Login Screen
/// Surpasses best apps with smooth animations, biometric auth, auto-fill, and modern UX

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/services/auth/credential_storage_service.dart';
import 'package:lingafriq/services/auth/biometric_auth_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/validators.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/screens/auth/world_class_signup_screen.dart';
import 'package:lingafriq/screens/auth/forgot_password_screen.dart';

class WorldClassLoginScreen extends HookConsumerWidget {
  const WorldClassLoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = ref.watch(authProvider.select((value) => value.isLoading));
    final showPassword = useState<bool>(false);
    final isBiometricAvailable = useState<bool?>(null);
    final credentialStorage = CredentialStorageService();
    final biometricAuth = BiometricAuthService();

    // Load stored credentials on init
    useEffect(() {
      _loadStoredCredentials(
        emailController,
        passwordController,
        credentialStorage,
        isBiometricAvailable,
        biometricAuth,
      );
      return null;
    }, []);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Signing you in...',
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.sp),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 40.h),
                    
                    // Logo with animation
                    _buildLogo(context)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: Offset(0.8, 0.8), duration: 400.ms),
                    
                    SizedBox(height: 48.h),
                    
                    // Welcome text
                    _buildWelcomeText(context, isDark)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.1, duration: 400.ms),
                    
                    SizedBox(height: 32.h),
                    
                    // Email field with auto-fill
                    _buildEmailField(
                      context,
                      emailController,
                      credentialStorage,
                      isDark,
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideX(begin: -0.1, duration: 400.ms),
                    
                    SizedBox(height: 16.h),
                    
                    // Password field
                    _buildPasswordField(
                      context,
                      passwordController,
                      showPassword,
                      isDark,
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 400.ms)
                        .slideX(begin: -0.1, duration: 400.ms),
                    
                    SizedBox(height: 12.h),
                    
                    // Forgot password
                    _buildForgotPassword(context, ref)
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 400.ms),
                    
                    SizedBox(height: 32.h),
                    
                    // Login button
                    _buildLoginButton(
                      context,
                      formKey,
                      emailController,
                      passwordController,
                      credentialStorage,
                      ref,
                      isDark,
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 400.ms)
                        .scale(delay: 600.ms, duration: 400.ms),
                    
                    SizedBox(height: 24.h),
                    
                    // Biometric login
                    if (isBiometricAvailable.value == true)
                      _buildBiometricButton(
                        context,
                        emailController,
                        passwordController,
                        credentialStorage,
                        biometricAuth,
                        ref,
                        isDark,
                      )
                          .animate()
                          .fadeIn(delay: 700.ms, duration: 400.ms)
                          .scale(delay: 700.ms, duration: 400.ms),
                    
                    SizedBox(height: 32.h),
                    
                    // Divider
                    _buildDivider(context, isDark)
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 400.ms),
                    
                    SizedBox(height: 24.h),
                    
                    // Sign up link
                    _buildSignUpLink(context, ref)
                        .animate()
                        .fadeIn(delay: 900.ms, duration: 400.ms),
                    
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Center(
      child: Container(
        width: 120.w,
        height: 120.h,
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
          Icons.language,
          size: 60.sp,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildWelcomeText(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back!',
          style: PanAfricanTypography.headlineLarge(context).copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : PanAfricanColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Sign in to continue your language journey',
          style: PanAfricanTypography.bodyLarge(context).copyWith(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(
    BuildContext context,
    TextEditingController controller,
    CredentialStorageService storage,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: PanAfricanTypography.labelLarge(context).copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : PanAfricanColors.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.emailValidator,
          style: PanAfricanTypography.bodyLarge(context),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email_outlined, color: PanAfricanColors.primaryLight),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 20.sp),
                    onPressed: () => controller.clear(),
                  )
                : null,
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
          textInputAction: TextInputAction.done,
          validator: Validators.passwordValidator,
          style: PanAfricanTypography.bodyLarge(context),
          decoration: InputDecoration(
            hintText: 'Enter your password',
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

  Widget _buildForgotPassword(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            SmoothPageRoute(child: const ForgotPasswordScreen()),
          );
        },
        child: Text(
          'Forgot Password?',
          style: PanAfricanTypography.bodyMedium(context).copyWith(
            color: PanAfricanColors.primaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(
    BuildContext context,
    GlobalKey<FormState> formKey,
    TextEditingController emailController,
    TextEditingController passwordController,
    CredentialStorageService storage,
    WidgetRef ref,
    bool isDark,
  ) {
    return ScaleOnTap(
      onTap: () async {
        if (!formKey.currentState!.validate()) {
          HapticFeedback.mediumImpact();
          return;
        }

        HapticFeedback.lightImpact();

        try {
          // Store credentials for auto-fill
          await storage.storeCredentials(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

          // Login
          await ref.read(authProvider.notifier).login(
                email: emailController.text.trim(),
                password: passwordController.text.trim(),
                storeCredentials: true,
              );
        } catch (e) {
          if (context.mounted) {
            ErrorHandler.showError(context, e);
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
            'Sign In',
            style: PanAfricanTypography.titleLarge(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton(
    BuildContext context,
    TextEditingController emailController,
    TextEditingController passwordController,
    CredentialStorageService storage,
    BiometricAuthService biometricAuth,
    WidgetRef ref,
    bool isDark,
  ) {
    return FutureBuilder<List<BiometricType>>(
      future: biometricAuth.getAvailableBiometrics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox.shrink();
        }

        final biometricType = snapshot.data!.first;
        final icon = biometricType == BiometricType.fingerprint
            ? Icons.fingerprint
            : Icons.face;

        return ScaleOnTap(
          onTap: () async {
            HapticFeedback.lightImpact();
            
            final authenticated = await biometricAuth.authenticate(
              reason: 'Use biometric to sign in',
            );

            if (authenticated) {
              try {
                final credentials = await storage.getStoredCredentials();
                if (credentials != null && credentials.password != null) {
                  emailController.text = credentials.email;
                  passwordController.text = credentials.password!;
                  
                  await ref.read(authProvider.notifier).login(
                        email: credentials.email,
                        password: credentials.password!,
                        storeCredentials: true,
                      );
                }
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
              color: isDark
                  ? Colors.grey[900]!.withOpacity(0.5)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: PanAfricanColors.primaryLight, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  'Sign in with ${biometricAuth.getBiometricTypeName(biometricType)}',
                  style: PanAfricanTypography.bodyLarge(context).copyWith(
                    color: isDark ? Colors.white : PanAfricanColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[300])),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'OR',
            style: PanAfricanTypography.bodySmall(context).copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[300])),
      ],
    );
  }

  Widget _buildSignUpLink(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: PanAfricanTypography.bodyMedium(context),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              SmoothPageRoute(child: const WorldClassSignupScreen()),
            );
          },
          child: Text(
            'Sign Up',
            style: PanAfricanTypography.bodyMedium(context).copyWith(
              color: PanAfricanColors.primaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadStoredCredentials(
    TextEditingController emailController,
    TextEditingController passwordController,
    CredentialStorageService storage,
    ValueNotifier<bool?> isBiometricAvailable,
    BiometricAuthService biometricAuth,
  ) async {
    await storage.initialize();
    await biometricAuth.isAvailable().then((available) {
      isBiometricAvailable.value = available;
    });

    if (await storage.hasStoredCredentials()) {
      final email = await storage.getStoredEmail();
      final password = await storage.getStoredPassword();
      
      if (email != null) {
        emailController.text = email;
      }
      // Don't auto-fill password for security, but enable biometric
    }
  }
}

