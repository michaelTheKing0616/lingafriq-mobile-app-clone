import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/services/secure_storage_service.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/auth/login_screen.dart';
import '../screens/onboarding/kijiji_onboarding_screen.dart';
import 'api_provider.dart';
import 'base_provider.dart';
import 'dialog_provider.dart';
import 'navigation_provider.dart';
import 'shared_preferences_provider.dart';

final authProvider = NotifierProvider<AuthProvider, BaseProviderState>(() {
  return AuthProvider();
});

class AuthProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  @override
  BaseProviderState build() {
    return BaseProviderState();
  }

  /// Navigate based on app state:
  /// 1. Show onboarding first (with skip option) if not seen OR if fresh install/update
  /// 2. Show login screen (with pre-filled credentials if available)
  /// 3. Auto-login if valid session exists
  Future<void> navigateBasedOnCondition() async {
    final secureStorage = SecureStorageService();
    
    // STEP 1: Check if this is a fresh install or update
    final isFreshInstall = await ref.read(sharedPreferencesProvider).isFreshInstallOrUpdate();
    
    // STEP 2: Check if user has seen onboarding
    // For fresh installs, updates, or if onboarding not seen, show onboarding first
    final hasSeenOnboarding = ref.read(sharedPreferencesProvider).hasSeenOnboarding;
    
    // Show onboarding if:
    // - User hasn't seen onboarding, OR
    // - This is a fresh install/update (to show new features)
    // Note: For updates, you can optionally force onboarding by uncommenting the reset line below
    if (!hasSeenOnboarding || isFreshInstall) {
      // For fresh installs/updates, optionally reset onboarding to show it again
      // (Uncomment the next line if you want to force onboarding on every update)
      // if (isFreshInstall && !hasSeenOnboarding) {
      //   await ref.read(sharedPreferencesProvider).resetOnboarding();
      // }
      
      // Show onboarding - it will navigate to login when completed/skipped
      ref.read(navigationProvider).navigateOffAll(const KijijiOnboardingScreen());
      return;
    }
    
    // STEP 3: Check for valid session token first (1 hour TTL)
    final hasValidSession = await secureStorage.hasValidSession();
    if (hasValidSession) {
      // Get and set token in API provider for all subsequent requests
      final sessionToken = await secureStorage.getSessionToken();
      if (sessionToken != null) {
        ref.read(apiProvider.notifier).token = sessionToken;
      }
      
      // Session is valid, navigate to main app
      // Try to get user from stored data
      final email = await secureStorage.getUserEmail();
      if (email != null) {
        final user = await ref.read(sharedPreferencesProvider).getUser(email);
        if (user != null) {
          ref.read(userProvider.notifier).overrideUser(user);
          await ref.read(apiProvider.notifier).regiserDevice();
          ref.read(navigationProvider).navigateOffAll(const TabsView());
          return;
        }
      }
    }
    
    // STEP 3: Check for valid refresh token (30 days TTL)
    final hasValidRefresh = await secureStorage.hasValidRefreshToken();
    if (hasValidRefresh) {
      // Try to refresh session using stored credentials
      final emailAndPassword = ref.read(sharedPreferencesProvider).requestEmailAndPass;
      if (emailAndPassword != null) {
        final email = emailAndPassword['email']!;
        final password = emailAndPassword['password']!;
        final user = await login(email: email, password: password, silentRefresh: true);

        if (user is ProfileModel) {
          ref.read(userProvider.notifier).overrideUser(user);
          await ref.read(apiProvider.notifier).regiserDevice();
          ref.read(navigationProvider).navigateOffAll(const TabsView());
          return;
        }
      }
    }
    
    // STEP 4: If no valid tokens, show login screen
    // Login screen will automatically pre-fill credentials from SharedPreferences
    ref.read(navigationProvider).navigateOffAll(const LoginScreen());
  }

  Future<ProfileModel?> login({
    required String email,
    required String password,
    bool storeCredentials = false,
    bool splashlogin = false,
    bool updateProfile = false,
    bool silentRefresh = false,
  }) async {
    try {
      if (storeCredentials && !silentRefresh) {
        state = state.copyWith(isLoading: true);
      }
      final data = {"email": email, "password": password};
      final user = await ref.read(apiProvider.notifier).login(data);
      
      // Store tokens in secure storage
      final secureStorage = SecureStorageService();
      final apiProviderInstance = ref.read(apiProvider.notifier);
      if (apiProviderInstance.token != null) {
        await secureStorage.storeSessionToken(apiProviderInstance.token!);
        // If backend provides refresh token, store it too
        // For now, we'll use the same token as refresh (backend may need to be updated)
        await secureStorage.storeRefreshToken(apiProviderInstance.token!);
      }
      
      // Store user profile for pre-filling
      final displayName = user.username.isNotEmpty ? user.username : '${user.first_name} ${user.last_name}'.trim();
      await secureStorage.storeUserProfile(email, displayName: displayName);
      
      if (storeCredentials) {
        await ref.read(sharedPreferencesProvider).storeEmailAndPassword(email, password);
        ref.read(apiProvider.notifier).accountUpdate();
        if (!silentRefresh) {
          await Future.delayed(const Duration(seconds: 3));
        }
        state = state.copyWith(isLoading: false);
        ref.read(userProvider.notifier).overrideUser(user);

        if (!silentRefresh) {
          ref.read(navigationProvider).navigateOffAll(const TabsView());
        }
        return user;
      }
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (!silentRefresh) {
        await ref.read(dialogProvider(e)).showExceptionDialog();
      }
      return null;
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

      // ref.read(navigationProvider).navigateOffAll(const LoginScreen());
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

  /// Sign out user completely - clears all data and navigates to login
  Future<void> signOut({bool deleteAccount = false}) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final secureStorage = SecureStorageService();
      
      // Clear all tokens first
      await secureStorage.clearAllTokens();
      await secureStorage.clearUserProfile();
      
      // Clear stored credentials
      await ref.read(sharedPreferencesProvider).removeEmailAndPassword();
      
      // Clear user data from SharedPreferences
      final email = await secureStorage.getUserEmail();
      if (email != null) {
        await ref.read(sharedPreferencesProvider).removeUser(email);
      }
      
      // Clear API provider token
      ref.read(apiProvider.notifier).token = null;
      
      // Clear user provider
      ref.read(userProvider.notifier).overrideUser(null);
      
      // Unregister device (unless deleting account)
      if (deleteAccount == false) {
        try {
          await ref.read(apiProvider.notifier).unregisterDevice();
        } catch (e) {
          // Ignore errors during device unregistration
          debugPrint('Error unregistering device: $e');
        }
      }
      
      // Clear chat history and other cached data
      try {
        final prefs = await SharedPreferences.getInstance();
        // Clear all Polie chat histories
        final keys = prefs.getKeys();
        for (final key in keys) {
          if (key.startsWith('ai_chat_history_')) {
            await prefs.remove(key);
          }
        }
      } catch (e) {
        debugPrint('Error clearing chat history: $e');
      }
      
      state = state.copyWith(isLoading: false);
      
      // Navigate directly to login screen (don't use navigateBasedOnCondition)
      ref.read(navigationProvider).navigateOffAll(const LoginScreen());
      
      "Logout successful".log('signout');
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint('Error during logout: $e');
      // Even if there's an error, try to navigate to login
      ref.read(navigationProvider).navigateOffAll(const LoginScreen());
    }
  }
}
