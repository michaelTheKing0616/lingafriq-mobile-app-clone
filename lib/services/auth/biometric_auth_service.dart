/// BiometricAuthService - Service wrapper for BiometricAuth
import 'biometric_auth.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  // No initialization needed - uses static methods
}

