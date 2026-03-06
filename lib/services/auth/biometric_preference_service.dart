import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/services/auth/biometric_auth_service.dart';

/// Stores biometric sign-in preference in an account-aware way.
///
/// We bind biometric preference to an email so one device can safely support
/// multiple users without cross-account biometric sign-in confusion.
class BiometricPreferenceService {
  static const String _enabledKey = 'biometric_enabled';
  static const String _accountEmailKey = 'biometric_account_email';

  final BiometricAuthService _biometricAuthService;

  BiometricPreferenceService({BiometricAuthService? biometricAuthService})
      : _biometricAuthService = biometricAuthService ?? BiometricAuthService();

  Future<bool> isDeviceBiometricCapable() async {
    return _biometricAuthService.isAvailable();
  }

  Future<bool> isEnabledForEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final boundEmail = prefs.getString(_accountEmailKey)?.toLowerCase().trim();
    return enabled && boundEmail == email.toLowerCase().trim();
  }

  Future<String?> getBoundEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accountEmailKey);
  }

  /// Enroll biometrics for a specific account after successful auth challenge.
  Future<void> enableForEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    await prefs.setString(_accountEmailKey, email.toLowerCase().trim());
  }

  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
    await prefs.remove(_accountEmailKey);
  }
}

