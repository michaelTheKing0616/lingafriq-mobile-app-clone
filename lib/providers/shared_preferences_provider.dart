import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared Preferences Provider - manages local storage
/// This provider is overridden in main.dart with an actual instance
/// The default implementation will throw if not overridden (should not happen in production)
final sharedPreferencesProvider = Provider<SharedPreferencesProvider>((ref) {
  // This should never be reached in production as it's overridden in main.dart
  // However, we provide a fallback that will throw a descriptive error
  throw StateError(
    'sharedPreferencesProvider must be overridden in ProviderScope. '
    'This should be done in main.dart during app initialization.'
  );
});

class SharedPreferencesProvider {
  const SharedPreferencesProvider(this.prefs);
  final SharedPreferences prefs;

  final emailKey = 'email';
  /// Legacy key cleared by [removeEmailAndPassword] for older installs.
  final passwordKey = 'password';
  final accessTokenKey = 'auth_token';
  final refreshTokenKey = 'refresh_token';

  /// Store authentication tokens
  Future<void> storeAuthTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      prefs.setString(accessTokenKey, accessToken),
      prefs.setString(refreshTokenKey, refreshToken),
    ]);
  }

  /// Get access token
  String? getAccessToken() {
    return prefs.getString(accessTokenKey);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return prefs.getString(refreshTokenKey);
  }

  /// Clear authentication tokens
  Future<void> clearAuthTokens() async {
    await Future.wait([
      prefs.remove(accessTokenKey),
      prefs.remove(refreshTokenKey),
    ]);
  }

  Future<void> storeUser(ProfileModel user, String emailKey) async {
    await prefs.setString(emailKey, user.toJson());
  }

  Future<ProfileModel?> getUser(String emailKey) async {
    final userJson = prefs.getString(emailKey);
    if (userJson == null) return null;
    return ProfileModel.fromJson(userJson);
  }

  Future<void> removeEmailAndPassword() async {
    final emailRemoveFuture = prefs.remove(emailKey);
    final passwordRemoveFuture = prefs.remove(passwordKey);
    await Future.wait([emailRemoveFuture, passwordRemoveFuture]);
  }

  bool showLanguageIntro(int id) {
    return prefs.getBool("language/$id") ?? true;
  }

  Future<void> setLanguageIntro(int id) async {
    await prefs.setBool("language/$id", false);
  }

  /// Check if onboarding has been seen
  bool get isOnboardingSeen {
    return prefs.getBool("onboarding_seen") ?? false;
  }

  /// Mark onboarding as seen
  Future<void> setOnboardingSeen() async {
    await prefs.setBool("onboarding_seen", true);
  }
}
