import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/utils/utils.dart';

import '../screens/auth/login_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
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
    final emailAndPassword = ref.read(sharedPreferencesProvider).requestEmailAndPass;
    if (emailAndPassword == null) {
      ref.read(navigationProvider).naviateOffAll(const LoginScreen());
      return;
    }

    final email = emailAndPassword['email']!;
    final password = emailAndPassword['password']!;

    final user = await login(email: email, password: password);

    //Login suceess, login can fail is user has changed the password in the web
    if (user is ProfileModel) {
      ref.read(userProvider.notifier).overrideUser(user);
      await ref.read(apiProvider.notifier).regiserDevice();
      ref.read(navigationProvider).naviateOffAll(const TabsView());
      return;
    }

    ref.read(navigationProvider).naviateOffAll(const LoginScreen());
  }

  Future<ProfileModel?> login({
    required String email,
    required String password,
    bool storeCredentials = false,
    bool splashlogin = false,
    bool updateProfile = false,
  }) async {
    try {
      if (storeCredentials) {
        state = state.copyWith(isLoading: true);
      }
      final data = {"email": email, "password": password};
      final user = await ref.read(apiProvider.notifier).login(data);
      if (storeCredentials) {
        await ref.read(sharedPreferencesProvider).storeEmailAndPassword(email, password);
        ref.read(apiProvider.notifier).accountUpdate();
        await Future.delayed(const Duration(seconds: 3));
        state = state.copyWith(isLoading: false);
        ref.read(userProvider.notifier).overrideUser(user);

        ref.read(navigationProvider).naviateOffAll(const OnboardingScreen());
        return user;
      }
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      await ref.read(dialogProvider(e)).showExceptionDialog();
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
