import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view_material3.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/services/auth/credential_storage_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'dart:async';

import '../screens/auth/world_class_login_screen.dart';
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
  bool _isLoggingIn = false; // Prevent duplicate login requests
  
  @override
  BaseProviderState build() {
    return BaseProviderState();
  }

  Future<void> navigateBasedOnCondition() async {
    // Check if onboarding has been seen first
    final isOnboardingSeen = ref.read(sharedPreferencesProvider).isOnboardingSeen;
    
    if (!isOnboardingSeen) {
      ref.read(navigationProvider).naviateOffAll(const OnboardingScreenMaterial3());
      return;
    }

    // CRITICAL FIX: Check if user is already logged in before making API call
    final currentUser = ref.read(userProvider);
    final apiNotifier = ref.read(apiProvider.notifier);
    
    // If user is already logged in and has a token, skip login API call
    // This prevents unnecessary API calls on every splash screen load
    if (currentUser != null && (apiNotifier.token?.isNotEmpty ?? false)) {
      // Already logged in, navigate to tabs view
      ref.read(navigationProvider).naviateOffAll(const TabsViewMaterial3());
      return;
    }

    // Use secure credential storage instead of SharedPreferences
    final credentialStorage = CredentialStorageService();
    final storedCredentials = await credentialStorage.getStoredCredentials();
    
    if (storedCredentials == null) {
      ref.read(navigationProvider).naviateOffAll(const WorldClassLoginScreen());
      return;
    }

    final email = storedCredentials['email']!;
    final password = storedCredentials['password']!;

    final user = await login(email: email, password: password);

    //Login suceess, login can fail is user has changed the password in the web
    if (user is ProfileModel) {
      ref.read(userProvider.notifier).overrideUser(user);
      await ref.read(apiProvider.notifier).registerDevice();
      ref.read(navigationProvider).naviateOffAll(const TabsViewMaterial3());
      return;
    }

    ref.read(navigationProvider).naviateOffAll(const WorldClassLoginScreen());
  }

  Future<ProfileModel?> login({
    required String email,
    required String password,
    bool storeCredentials = false,
    bool splashlogin = false,
    bool updateProfile = false,
  }) async {
    // CRITICAL: Prevent duplicate login requests
    if (_isLoggingIn) {
      return null; // Login already in progress
    }
    
    final shouldShowLoading = storeCredentials || splashlogin;
    try {
      _isLoggingIn = true;
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
        final isOnboardingSeen = ref.read(sharedPreferencesProvider).isOnboardingSeen;
        ref.read(navigationProvider).naviateOffAll(
          isOnboardingSeen ? const TabsViewMaterial3() : const OnboardingScreenMaterial3(),
        );
      }

      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      await ref.read(dialogProvider(e)).showExceptionDialog();
      return null;
    } finally {
      if (shouldShowLoading) {
        state = state.copyWith(isLoading: false);
      }
      _isLoggingIn = false; // Always reset flag
    }
  }

  Future<void> register(Map<String, dynamic> registerData) async {
    try {
      state = state.copyWith(isLoading: true);
      await ref.read(apiProvider.notifier).register(FormData.fromMap(registerData));
      // await ref.read(apiProvider.notifier).accountUpdate();
      "Account Updated".log('register');
      final email = registerData['email'] as String;
      final password = registerData['password'] as String;

      await login(email: email, password: password, storeCredentials: true);
      // await ref.read(dialogProvider("")).showPlatformDialogue(
      //       title: "Account Created",
      //       content:
      //           const Text("Please check your inbox to activate your account"),
      //     );

      // ref.read(navigationProvider).naviateOffAll(const LoginScreen());
      state = state.copyWith(isLoading: false);
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
