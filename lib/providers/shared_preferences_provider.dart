import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

///Override provider in provider scope
final sharedPreferencesProvider = Provider<SharedPreferencesProvider>((ref) {
  throw UnimplementedError();
});

class SharedPreferencesProvider {
  const SharedPreferencesProvider(this.prefs);
  final SharedPreferences prefs;

  final emailKey = 'email';
  final passwordKey = 'password';

  Future<void> storeEmailAndPassword(String email, String password) async {
    final emailStoreFuture = prefs.setString(emailKey, email);
    final passwordStoreFuture = prefs.setString(passwordKey, password);
    await Future.wait([emailStoreFuture, passwordStoreFuture]);
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

  _EmailAndPassword get emailAndPassword {
    final email = prefs.getString(emailKey)!;
    final password = prefs.getString(passwordKey)!;
    return _EmailAndPassword(email, password);
  }

  bool showLanguageIntro(int id) {
    return prefs.getBool("language/$id") ?? true;
  }

  Future<void> setLanguageIntro(int id) async {
    await prefs.setBool("language/$id", false);
  }

  bool get hasSeenOnboarding {
    return prefs.getBool("has_seen_onboarding") ?? false;
  }

  Future<void> setOnboardingSeen() async {
    await prefs.setBool("has_seen_onboarding", true);
  }

  // Cache languages for offline access and stability
  Future<void> cacheLanguages(String languagesJson) async {
    await prefs.setString("cached_languages", languagesJson);
    await prefs.setInt("cached_languages_timestamp", DateTime.now().millisecondsSinceEpoch);
  }

  String? getCachedLanguages() {
    // Check if cache is less than 24 hours old
    final timestamp = prefs.getInt("cached_languages_timestamp");
    if (timestamp != null) {
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      // Cache valid for 24 hours
      if (cacheAge < 24 * 60 * 60 * 1000) {
        return prefs.getString("cached_languages");
      }
    }
    return null;
  }
}

class _EmailAndPassword {
  final String email;
  final String password;

  _EmailAndPassword(this.email, this.password);
}
