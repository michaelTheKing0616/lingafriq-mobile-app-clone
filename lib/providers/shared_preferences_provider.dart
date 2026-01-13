import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

///Override provider in provider scope
final sharedPreferencesProvider = Provider<SharedPreferencesProvider>((ref) {
  throw StateError(
    'sharedPreferencesProvider must be overridden in ProviderScope. '
    'See main.dart where SharedPreferences is initialized and injected.',
  );
});

class SharedPreferencesProvider {
  const SharedPreferencesProvider(this.prefs);
  final SharedPreferences prefs;

  final emailKey = 'email';
  final passwordKey = 'password';
  static const _onboardingSeenKey = 'onboarding_seen';

  Future<void> storeEmailAndPassword(String email, String password) async {
    // SECURITY: Never store raw passwords on-device.
    //
    // Legacy callers may still call this method; we store only the email and
    // explicitly delete any previously stored password.
    final emailStoreFuture = prefs.setString(emailKey, email);
    final passwordRemoveFuture = prefs.remove(passwordKey);
    await Future.wait([emailStoreFuture, passwordRemoveFuture]);
  }

  Future<void> storeUser(ProfileModel user, String emailKey) async {
    await prefs.setString(emailKey, user.toJson());
  }

  Future<ProfileModel?> getUser(emailKey) async {
    final userJson = prefs.getString(emailKey);
    if (userJson == null) return null;
    return ProfileModel.fromJson(userJson);
  }

  Future<void> removeEmailAndPassword() async {
    final emailRemoveFuture = prefs.remove(emailKey);
    final passwordRemoveFuture = prefs.remove(passwordKey);
    await Future.wait([emailRemoveFuture, passwordRemoveFuture]);
  }

  String get getEmail {
    final email = prefs.getString(emailKey) ?? '';
    return email;
  }

  Map<String, String>? get getEmailAndPassword {
    final email = prefs.getString(emailKey);
    final password = prefs.getString(passwordKey);
    if (email == null || password == null) {
      return null;
    }
    return {emailKey: email, passwordKey: password};
  }

  Map<String, dynamic>? get requestEmailAndPass {
    final email = prefs.getString(emailKey);
    final password = prefs.getString(passwordKey);
    if (email == null || password == null) {
      return null;
    }
    return {"email": email, "password": password};
  }

  /// Legacy API: historically returned stored email+password.
  /// SECURITY: we no longer store raw passwords on-device, so this can be null.
  _EmailAndPassword? get emailAndPassword {
    final email = prefs.getString(emailKey);
    final password = prefs.getString(passwordKey);
    if (email == null || password == null) return null;
    return _EmailAndPassword(email, password);
  }

  bool showLanguageIntro(int id) {
    return prefs.getBool("language/$id") ?? true;
  }

  Future<void> setLanguageIntro(int id) async {
    await prefs.setBool("language/$id", false);
  }

  /// Onboarding flags
  bool get hasSeenOnboarding =>
      prefs.getBool(_onboardingSeenKey) ?? false;

  Future<void> setOnboardingSeen([bool value = true]) async {
    await prefs.setBool(_onboardingSeenKey, value);
  }
}

class _EmailAndPassword {
  final String email;
  final String password;

  _EmailAndPassword(this.email, this.password);
}
