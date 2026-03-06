/// World-Class Login Screen
/// Surpasses best apps with smooth animations, biometric auth, auto-fill, and modern UX
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/services/auth/credential_storage_service.dart';
import 'package:lingafriq/services/auth/biometric_auth_service.dart';
import 'package:lingafriq/services/auth/biometric_preference_service.dart';
import 'package:lingafriq/services/auth/biometric_enrollment_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/utils/validators.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/screens/auth/world_class_signup_screen.dart';
import 'package:lingafriq/screens/auth/forgot_password_screen.dart';

class WorldClassLoginScreen extends HookConsumerWidget {
  const WorldClassLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = ref.watch(authProvider.select((value) => value.isLoading));
    final showPassword = useState<bool>(false);
    final isBiometricAvailable = useState<bool?>(null);
    final biometricEnabledForAccount = useState<bool>(false);
    final credentialStorage = CredentialStorageService();
    final biometricAuth = BiometricAuthService();
    final biometricPreferenceService = BiometricPreferenceService();
    final biometricEnrollmentService = BiometricEnrollmentService();

    // Load stored credentials on init
    useEffect(() {
      _loadStoredCredentials(
        emailController,
        passwordController,
        credentialStorage,
        isBiometricAvailable,
        biometricEnabledForAccount,
        biometricAuth,
        biometricPreferenceService,
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
          child: ResponsiveSafeArea(
            child:               SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AdaptiveLayout.sideMargin(context),
                  vertical: PanAfricanSpacing.lg,
                ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: PanAfricanSpacing.xl),
                    
                    // Logo with animation
                    _buildLogo(context)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: Offset(0.8, 0.8), duration: 400.ms),
                    
                    SizedBox(height: PanAfricanSpacing.xxl),
                    
                    // Welcome text
                    _buildWelcomeText(context, isDark)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.1, duration: 400.ms),
                    
                    SizedBox(height: PanAfricanSpacing.xl),
                    
                    // Email & password with AutofillGroup for Smart Lock / password managers
                    AutofillGroup(
                      child: Column(
                        children: [
                          _buildEmailField(
                            context,
                            emailController,
                            credentialStorage,
                            isDark,
                          )
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 400.ms)
                              .slideX(begin: -0.1, duration: 400.ms),
                          
                          SizedBox(height: PanAfricanSpacing.md),
                          
                          _buildPasswordField(
                            context,
                            passwordController,
                            showPassword,
                            isDark,
                          )
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 400.ms)
                              .slideX(begin: -0.1, duration: 400.ms),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: PanAfricanSpacing.sm),
                    
                    // Forgot password
                    _buildForgotPassword(context, ref)
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 400.ms),
                    
                    SizedBox(height: PanAfricanSpacing.xl),
                    
                    // Login button
                    _buildLoginButton(
                      context,
                      formKey,
                      emailController,
                      passwordController,
                      credentialStorage,
                      biometricEnrollmentService,
                      biometricAuth,
                      biometricPreferenceService,
                      ref,
                      isDark,
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 400.ms)
                        .scale(delay: 600.ms, duration: 400.ms),
                    
                    SizedBox(height: PanAfricanSpacing.lg),
                    
                    // Biometric login
                    if (isBiometricAvailable.value == true &&
                        biometricEnabledForAccount.value)
                      _buildBiometricButton(
                        context,
                        emailController,
                        passwordController,
                        credentialStorage,
                        biometricAuth,
                        biometricPreferenceService,
                        ref,
                        isDark,
                      )
                          .animate()
                          .fadeIn(delay: 700.ms, duration: 400.ms)
                          .scale(delay: 700.ms, duration: 400.ms),
                    
                    SizedBox(height: PanAfricanSpacing.xl),
                    
                    // Divider
                    _buildDivider(context, isDark)
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 400.ms),
                    
                    SizedBox(height: PanAfricanSpacing.lg),
                    
                    // Sign up link
                    _buildSignUpLink(context, ref)
                        .animate()
                        .fadeIn(delay: 900.ms, duration: 400.ms),
                    
                    SizedBox(height: PanAfricanSpacing.xl),
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
        child: Semantics(
          excludeSemantics: true,
          child: Icon(
            Icons.language,
            size: 60.sp,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText(BuildContext context, bool isDark) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back!',
          style: PanAfricanTypography.headlineLarge(context).copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        Text(
          'Sign in to continue your language journey',
          style: PanAfricanTypography.bodyLarge(context).copyWith(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        ],
      ),
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
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        Semantics(
          label: 'Email address',
          textField: true,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.emailValidator,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            style: PanAfricanTypography.bodyLarge(context),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              prefixIcon: Semantics(
                label: 'Email icon',
                excludeSemantics: true,
                child: Icon(Icons.email_outlined, color: PanAfricanColors.primary),
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? Semantics(
                      label: 'Clear email',
                      button: true,
                      child: IconButton(
                        icon: Icon(Icons.clear, size: 20.sp, color: PanAfricanColors.textSecondaryLight),
                        onPressed: () => controller.clear(),
                      ),
                    )
                  : null,
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
            contentPadding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md, vertical: PanAfricanSpacing.md            ),
          ),
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
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: PanAfricanSpacing.xs),
        Semantics(
          label: 'Password',
          textField: true,
          obscured: !showPassword.value,
          child: TextFormField(
            controller: controller,
            obscureText: !showPassword.value,
            keyboardType: TextInputType.visiblePassword,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            validator: Validators.passwordValidator,
            autofillHints: const [AutofillHints.password],
            style: PanAfricanTypography.bodyLarge(context),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: Semantics(
                label: 'Password lock icon',
                excludeSemantics: true,
                child: Icon(Icons.lock_outline, color: PanAfricanColors.primary),
              ),
              suffixIcon: Semantics(
                label: showPassword.value ? 'Hide password' : 'Show password',
                button: true,
                child: IconButton(
                  icon: Icon(
                    showPassword.value ? Icons.visibility_off : Icons.visibility,
                    color: PanAfricanColors.textSecondaryLight,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    showPassword.value = !showPassword.value;
                  },
                ),
              ),
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
            contentPadding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md, vertical: PanAfricanSpacing.md            ),
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerRight,
      child: Semantics(
        label: 'Forgot password',
        button: true,
        child: TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              SmoothPageRoute(child: const ForgotPasswordScreen()),
            );
          },
          child: Text(
            'Forgot Password?',
            style: PanAfricanTypography.bodyMedium(context).copyWith(
              color: PanAfricanColors.primary,
              fontWeight: FontWeight.w600,
            ),
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
    BiometricEnrollmentService biometricEnrollmentService,
    BiometricAuthService biometricAuth,
    BiometricPreferenceService biometricPreferenceService,
    WidgetRef ref,
    bool isDark,
  ) {
    return Semantics(
      label: 'Sign in',
      button: true,
      child: ScaleOnTap(
        onTap: () async {
          if (!formKey.currentState!.validate()) {
            HapticFeedback.mediumImpact();
            return;
          }

          HapticFeedback.lightImpact();

          try {
            // Login first — only persist credentials after success.
            // Storing before login meant failed attempts (server down, wrong
            // password) left stale credentials that auto-login would retry.
            final user = await ref.read(authProvider.notifier).login(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  storeCredentials: true,
                );

            // Persist credentials only on successful login
            if (user != null) {
              await storage.storeCredentials(
                email: emailController.text.trim(),
                password: passwordController.text.trim(),
              );
              if (context.mounted) {
                await biometricEnrollmentService.maybeOfferEnrollment(
                  context: context,
                  email: emailController.text.trim(),
                  biometricAuth: biometricAuth,
                  biometricPreferenceService: biometricPreferenceService,
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ErrorHandler.showError(context, e);
            }
          }
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
            'Sign In',
            style: PanAfricanTypography.titleLarge(context).copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
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
    BiometricPreferenceService biometricPreferenceService,
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

        return Semantics(
          label: 'Sign in with ${biometricAuth.getBiometricTypeName(biometricType)}',
          button: true,
          child: ScaleOnTap(
            onTap: () async {
              HapticFeedback.mediumImpact();
              
              final authenticated = await biometricAuth.authenticateWithResult(
                localizedReason: 'Use biometric to sign in',
              );

              if (authenticated.success) {
                try {
                  final credentials = await storage.getStoredCredentials();
                  if (credentials != null && credentials['password'] != null) {
                    final email = (credentials['email'] ?? '').trim();
                    if (email.isEmpty) {
                      if (context.mounted) {
                        ErrorHandler.showError(context, 'No account is linked for biometric sign-in.');
                      }
                      return;
                    }
                    final biometricEnabled = await biometricPreferenceService.isEnabledForEmail(email);
                    if (!biometricEnabled) {
                      if (context.mounted) {
                        ErrorHandler.showError(
                          context,
                          'Biometric sign-in is not enabled for this account yet.',
                        );
                      }
                      return;
                    }
                    emailController.text = credentials['email'] ?? '';
                    passwordController.text = credentials['password'] ?? '';
                    
                    await ref.read(authProvider.notifier).login(
                          email: credentials['email'] ?? '',
                          password: credentials['password'] ?? '',
                          storeCredentials: true,
                        );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ErrorHandler.showError(context, e);
                  }
                }
              } else if (context.mounted) {
                ErrorHandler.showError(
                  context,
                  authenticated.errorMessage ?? 'Biometric authentication failed.',
                );
              }
            },
            child: Container(
            height: 56.h,
            decoration: BoxDecoration(
              color: isDark
                  ? PanAfricanColors.surfaceContainerDark
                  : PanAfricanColors.surfaceContainerLight,
              borderRadius: PanAfricanRadius.lgBR,
              border: Border.all(
                color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  excludeSemantics: true,
                  child: Icon(icon, color: PanAfricanColors.primary, size: 24.sp),
                ),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  'Sign in with ${biometricAuth.getBiometricTypeName(biometricType)}',
                  style: PanAfricanTypography.bodyLarge(context).copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(child: Divider(color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
          child: Semantics(
            label: 'Or',
            child: Text(
              'OR',
              style: PanAfricanTypography.labelMedium(context).copyWith(
                color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight,
              ),
            ),
          ),
        ),
        Expanded(child: Divider(color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight)),
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
        Semantics(
          label: 'Sign up',
          button: true,
          child: TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                SmoothPageRoute(child: const WorldClassSignupScreen()),
              );
            },
            child: Text(
              'Sign Up',
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: PanAfricanColors.primary,
                fontWeight: FontWeight.bold,
              ),
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
    ValueNotifier<bool> biometricEnabledForAccount,
    BiometricAuthService biometricAuth,
    BiometricPreferenceService biometricPreferenceService,
  ) async {
    await storage.initialize();
    await biometricAuth.isAvailable().then((available) {
      isBiometricAvailable.value = available;
    });

    if (await storage.hasStoredCredentials()) {
      final email = await storage.getStoredEmail();
      
      if (email != null) {
        emailController.text = email;
        biometricEnabledForAccount.value =
            await biometricPreferenceService.isEnabledForEmail(email);
      }
      // Don't auto-fill password for security, but enable biometric
    }
  }

}

