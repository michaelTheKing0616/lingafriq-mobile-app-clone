// BiometricAuthService - Service wrapper for BiometricAuth
// Provides a singleton service layer for biometric authentication
import 'biometric_auth.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  // No initialization needed - uses static methods

  /// Check if biometric authentication is available
  Future<bool> isAvailable() async {
    return await BiometricAuth.isAvailable();
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await BiometricAuth.getAvailableBiometrics();
  }

  /// Check if strong biometrics (Face ID, fingerprint) are available
  Future<bool> hasStrongBiometrics() async {
    return await BiometricAuth.hasStrongBiometrics();
  }

  /// Get biometric type name as string
  String getBiometricTypeName(BiometricType type) {
    return BiometricAuth.getBiometricTypeName(type);
  }

  /// Get the best available biometric type name for UI display
  Future<String> getBestBiometricName() async {
    return await BiometricAuth.getBestBiometricName();
  }

  /// Authenticate using biometrics (simple bool result)
  /// For detailed error handling, use authenticateWithResult()
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access your LingAfriq account',
    bool biometricOnly = false,
  }) async {
    return await BiometricAuth.authenticate(
      localizedReason: localizedReason,
      biometricOnly: biometricOnly,
    );
  }

  /// Authenticate using biometrics with detailed result
  /// Returns BiometricAuthResult with success/failure and specific error info
  Future<BiometricAuthResult> authenticateWithResult({
    String localizedReason = 'Please authenticate to access your LingAfriq account',
    bool biometricOnly = false,
  }) async {
    return await BiometricAuth.authenticateWithResult(
      localizedReason: localizedReason,
      biometricOnly: biometricOnly,
    );
  }

  /// Get user-friendly error message for biometric auth failure
  String getErrorMessage(BiometricAuthError error) {
    switch (error) {
      case BiometricAuthError.notAvailable:
        return 'Biometric authentication is not available on this device.';
      case BiometricAuthError.notEnrolled:
        return 'No biometrics enrolled. Please set up Face ID or fingerprint in your device settings.';
      case BiometricAuthError.cancelled:
        return 'Authentication was cancelled.';
      case BiometricAuthError.lockedOut:
        return 'Too many failed attempts. Please wait and try again.';
      case BiometricAuthError.permanentlyLockedOut:
        return 'Biometric authentication is locked. Please unlock your device with PIN/password.';
      case BiometricAuthError.failed:
        return 'Authentication failed. Please try again.';
      case BiometricAuthError.osVersionNotSupported:
        return 'Your device does not support this feature.';
      case BiometricAuthError.passcodeNotSet:
        return 'Please set up a device passcode to use biometric authentication.';
      case BiometricAuthError.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Check if biometrics are enabled in device settings
  Future<bool> isBiometricsEnabled() async {
    return await BiometricAuth.isBiometricsEnabled();
  }

  /// Stop any in-progress authentication
  Future<bool> stopAuthentication() async {
    return await BiometricAuth.stopAuthentication();
  }
}

