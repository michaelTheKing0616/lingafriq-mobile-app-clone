import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/services/secure_storage_service.dart';
import 'package:lingafriq/utils/utils.dart';

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

  Future<void> navigateBasedOnCondition() async {
    final secureStorage = SecureStorageService();
    
    // Check if user has seen onboarding
    final hasSeenOnboarding = ref.read(sharedPreferencesProvider).hasSeenOnboarding;
    if (!hasSeenOnboarding) {
      ref.read(navigationProvider).naviateOffAll(const KijijiOnboardingScreen());
      return;
    }
    
    // Check for valid session token first (1 hour TTL)
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
          ref.read(navigationProvider).naviateOffAll(const TabsView());
          return;
        }
      }
    }
    
    // Check for valid refresh token (30 days TTL)
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
          ref.read(navigationProvider).naviateOffAll(const TabsView());
          return;
        }
      }
    }
    
    // If no valid tokens, show login screen
    ref.read(navigationProvider).naviateOffAll(const LoginScreen());
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
          ref.read(navigationProvider).naviateOffAll(const TabsView());
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
    final secureStorage = SecureStorageService();
    
    // Clear all tokens
    await secureStorage.clearAllTokens();
    await secureStorage.clearUserProfile();
    
    await ref.read(sharedPreferencesProvider).removeEmailAndPassword();
    "Delete Account $deleteAccount".log('signout');
    if (deleteAccount == false) {
      await ref.read(apiProvider.notifier).unregisterDevice();
    }

    // ref.read(tabIndexProvider.state).state = 0;
    navigateBasedOnCondition();
    await Future.delayed(const Duration(milliseconds: 500));
    ref.read(userProvider.notifier).overrideUser(null);
  }
}
