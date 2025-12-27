/// BiometricAuthService - Service wrapper for BiometricAuth
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

  /// Get biometric type name as string
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
      default:
        return 'Biometric';
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to continue',
  }) async {
    return await BiometricAuth.authenticate(localizedReason: localizedReason);
  }
}

