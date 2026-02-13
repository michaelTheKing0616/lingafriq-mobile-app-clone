import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view_material3.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/services/auth/credential_storage_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../screens/auth/world_class_login_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/onboarding/onboarding_screen_material3.dart';
import 'api_provider.dart';
import 'base_provider.dart';
import 'dialog_provider.dart';
import 'navigation_provider.dart';
import 'shared_preferences_provider.dart';

final authProvider = NotifierProvider<AuthProvider, BaseProviderState>(() {
  return AuthProvider();
});

class AuthProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  Completer<ProfileModel?>? _loginLock;
  
  @override
  BaseProviderState build() {
    return BaseProviderState();
  }

  static const _lastSeenAppVersionKey = 'last_seen_app_version';

  Future<void> navigateBasedOnCondition() async {
    final prefs = ref.read(sharedPreferencesProvider).prefs;

    // App version gate: after an update, require onboarding + login again (no auto-login)
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = '${info.version}+${info.buildNumber}';
      final lastSeenVersion = prefs.getString(_lastSeenAppVersionKey);
      if (lastSeenVersion == null || lastSeenVersion != currentVersion) {
        logger.info('App version changed, resetting flow', context: {
          'lastSeen': lastSeenVersion,
          'current': currentVersion,
        });
        await prefs.setBool('onboarding_seen', false);
        await prefs.remove('onboarding_complete');
        await prefs.remove('onboarding_data');
        await ref.read(sharedPreferencesProvider).clearAuthTokens();
        ref.read(apiProvider.notifier).clearToken();
        ref.read(userProvider.notifier).overrideUser(null);
        try {
          await CredentialStorageService().clearCredentials();
        } catch (_) {
          // Ignore clear errors
        }
        await prefs.setString(_lastSeenAppVersionKey, currentVersion);
      }
    } catch (e) {
      logger.warn('Version check failed, continuing with existing flow', error: e);
    }

    // Log backend URL configuration for debugging
    logger.info('App startup navigation', context: {
      'backendUrl': ApiContract.baseUrl,
    });

    // CRITICAL FIX: Check if onboarding was actually COMPLETED, not just seen
    final isOnboardingSeen = ref.read(sharedPreferencesProvider).isOnboardingSeen;
    final onboardingComplete = prefs.getString('onboarding_complete') == 'true';
    final hasOnboardingData = prefs.getString('onboarding_data') != null;

    logger.info('Onboarding status check', context: {
      'isOnboardingSeen': isOnboardingSeen,
      'onboardingComplete': onboardingComplete,
      'hasOnboardingData': hasOnboardingData,
    });

    // If onboarding wasn't fully completed, reset and show onboarding
    if (!isOnboardingSeen || (!onboardingComplete && !hasOnboardingData)) {
      if (isOnboardingSeen && !onboardingComplete) {
        await prefs.setBool('onboarding_seen', false);
        await prefs.remove('onboarding_complete');
        await prefs.remove('onboarding_data');
      }
      ref.read(navigationProvider).navigateOffAll(const OnboardingScreenMaterial3());
      return;
    }

    // CRITICAL FIX: Check if user is already logged in before making API call
    final currentUser = ref.read(userProvider);
    final apiNotifier = ref.read(apiProvider.notifier);
    
    // If user is already logged in and has a token, skip login API call
    // This prevents unnecessary API calls on every splash screen load
    if (currentUser != null && (apiNotifier.token?.isNotEmpty ?? false)) {
      // Check email verification status
      if (!currentUser.emailVerified) {
        // Get email from stored credentials or user model
        final credentialStorage = CredentialStorageService();
        final storedCredentials = await credentialStorage.getStoredCredentials();
        final userEmail = storedCredentials?['email'] ?? currentUser.email;
        
        ref.read(navigationProvider).navigateOffAll(
          EmailVerificationScreen(
            email: userEmail,
            firstName: currentUser.first_name,
          ),
        );
        return;
      }
      
      // Already logged in and verified, navigate to tabs view
      ref.read(navigationProvider).navigateOffAll(const TabsViewMaterial3());
      return;
    }

    // Use secure credential storage instead of SharedPreferences
    final credentialStorage = CredentialStorageService();
    final storedCredentials = await credentialStorage.getStoredCredentials();
    
    if (storedCredentials == null) {
      ref.read(navigationProvider).navigateOffAll(const WorldClassLoginScreen());
      return;
    }

    final email = storedCredentials['email']!;
    final password = storedCredentials['password']!;

    // CRITICAL FIX: Handle login errors gracefully - don't block navigation
    try {
      // Log auto-login attempt
      logger.info('Auto-login attempt', context: {'email': email});
      
      final user = await login(email: email, password: password, splashlogin: true);

      // Login success
      if (user is ProfileModel) {
        logger.info('Auto-login successful');
        ref.read(userProvider.notifier).overrideUser(user);
        unawaited(ref.read(apiProvider.notifier).registerDevice()); // Non-blocking
        
        // Check email verification status
        if (!user.emailVerified) {
          ref.read(navigationProvider).navigateOffAll(
            EmailVerificationScreen(
              email: email,
              firstName: user.first_name,
            ),
          );
          return;
        }
        
        ref.read(navigationProvider).navigateOffAll(const TabsViewMaterial3());
        return;
      }
    } catch (e) {
      // Login failed - clear invalid credentials and show login screen
      logger.warn('Auto-login failed, showing login screen', error: e, context: {
        'errorType': e.runtimeType.toString(),
        'isDioException': e is DioException,
        'dioErrorType': e is DioException ? e.type.toString() : null,
      });
      try {
        await credentialStorage.clearCredentials();
      } catch (_) {
        // Ignore clear errors
      }
    }

    // Navigate to login screen (either no credentials or login failed)
    ref.read(navigationProvider).navigateOffAll(const WorldClassLoginScreen());
  }

  Future<ProfileModel?> login({
    required String email,
    required String password,
    bool storeCredentials = false,
    bool splashlogin = false,
    bool updateProfile = false,
  }) async {
    if (_loginLock != null) {
      return _loginLock!.future;
    }
    final completer = Completer<ProfileModel?>();
    _loginLock = completer;
    final shouldShowLoading = storeCredentials || splashlogin;
    try {
      if (shouldShowLoading) {
        state = state.copyWith(isLoading: true);
      }
      final data = {"email": email, "password": password};
      final user = await ref.read(apiProvider.notifier).login(data);

      // Persist credentials only when explicitly requested (UI login/register).
      if (storeCredentials) {
        final credentialStorage = CredentialStorageService();
        await credentialStorage.storeCredentials(email: email, password: password);
        // Store email (non-sensitive) for backward compatibility.
        await ref.read(sharedPreferencesProvider).prefs.setString('email', email);
      }

      // Refresh server-side account snapshot (non-blocking for UX).
      try {
        await ref.read(apiProvider.notifier).accountUpdate().timeout(
          const Duration(seconds: 6),
          onTimeout: () => false,
        );
      } catch (_) {
        // Ignore, not critical for login.
      }

      // Ensure user state is set immediately.
      ref.read(userProvider.notifier).overrideUser(user);

      // Register push token in background (non-blocking).
      unawaited(ref.read(apiProvider.notifier).registerDevice());

      // World-class UX: always navigate to the correct next screen after explicit login/register.
      if (storeCredentials && !updateProfile) {
        // Check email verification status first
        if (!user.emailVerified) {
          ref.read(navigationProvider).navigateOffAll(
            EmailVerificationScreen(
              email: email,
              firstName: user.first_name,
            ),
          );
        } else {
          final isOnboardingSeen = ref.read(sharedPreferencesProvider).isOnboardingSeen;
          ref.read(navigationProvider).navigateOffAll(
            isOnboardingSeen ? const TabsViewMaterial3() : const OnboardingScreenMaterial3(),
          );
        }
      }

      if (!completer.isCompleted) completer.complete(user);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // CRITICAL FIX: Don't show error dialogs during splash auto-login
      // Errors are handled gracefully in navigateBasedOnCondition
      if (!splashlogin) {
        await ref.read(dialogProvider(e)).showExceptionDialog();
      }
      if (!completer.isCompleted) completer.complete(null);
      return null;
    } finally {
      if (shouldShowLoading) {
        state = state.copyWith(isLoading: false);
      }
      _loginLock = null;
    }
  }

  Future<void> register(Map<String, dynamic> registerData, {VoidCallback? onSuccess}) async {
    try {
      state = state.copyWith(isLoading: true);
      await ref.read(apiProvider.notifier).register(FormData.fromMap(registerData));
      // await ref.read(apiProvider.notifier).accountUpdate();
      "Account Updated".log('register');
      
      // Don't auto-login - user needs to verify email first
      // Navigation to verification screen is handled by the calling screen
      state = state.copyWith(isLoading: false);
      
      if (onSuccess != null) {
        onSuccess();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ref.read(dialogProvider(e)).showExceptionDialog();
      return;
    }
  }

  // Future<void> updateProfile(Map<String, String?> data) async {
  //   try {
  //     setBusy();
  //     await ref.read(apiProvider).updateProfile(data: data);
  //     final emailAndPassword = ref.read(sharedPreferencesProvider).requestEmailAndPass!;
  //     final email = emailAndPassword['email']!;
  //     final password = emailAndPassword['password']!;
  //     await login(email: email, password: password, updateProfile: true);
  //     setIdle();
  //     showPlatformDialogue(title: "Profile updated successfully");
  //   } catch (e) {
  //     setIdle();
  //     showExceptionDialog(e);
  //     return;
  //   }
  // }

  // Future<void> changePassword({
  //   required String email,
  //   required String currentPassword,
  //   required String newPassword,
  // }) async {
  //   try {
  //     setBusy();
  //     await login(email: email, password: currentPassword, updateProfile: true);
  //     final token = ref.read(userProvider)!.recuperoCodice;
  //     final data = {"email": email, "password": newPassword, "token": token};
  //     await ref.read(apiProvider).changePassword(data: data);
  //     ref.read(sharedPreferencesProvider).storeEmailAndPassword(email, newPassword);
  //     setIdle();
  //     showPlatformDialogue(title: "Password updated successfully");
  //   } catch (e) {
  //     setIdle();
  //     if (e is Map && ((e['message'] ?? '') as String).contains("mismatch")) {
  //       print("mismatch");
  //       showPlatformDialogue(title: "Current password is wrong");
  //       return;
  //     }

  //     showExceptionDialog(e);
  //     return;
  //   }
  // }

  Future<void> signOut({bool deleteAccount = false}) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.removeEmailAndPassword();
      "Delete Account $deleteAccount".log('signout');
      
      // Try to unregister device, but don't block if it fails
      if (deleteAccount == false) {
        try {
          await ref.read(apiProvider.notifier).unregisterDevice().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Unregister device timeout');
            },
          );
        } catch (e) {
          // Log but continue - logout should work even if backend is unavailable
          logger.warn('Failed to unregister device during logout, continuing', error: e);
        }
      }

      // Clear user state immediately
      ref.read(userProvider.notifier).overrideUser(null);
      
      // Navigate based on condition (will show login or onboarding)
      navigateBasedOnCondition();
      
      // Small delay to ensure navigation completes
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      // Even if something fails, ensure user is logged out locally
      logger.error('Error during signOut, forcing local logout', error: e);
      ref.read(userProvider.notifier).overrideUser(null);
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.removeEmailAndPassword();
      navigateBasedOnCondition();
    }
  }
}
