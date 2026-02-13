/// Biometric Authentication - World-class Fingerprint/Face ID authentication
/// Provides secure biometric authentication using local_auth package
/// 
/// Security considerations:
/// - Uses platform-native biometric APIs (Face ID, Touch ID, Android BiometricPrompt)
/// - Supports strong biometrics only for enhanced security
/// - Provides detailed error handling for debugging and user feedback
/// - Configurable security levels (biometric-only vs fallback to device PIN)

import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Result of a biometric authentication attempt
class BiometricAuthResult {
  final bool success;
  final BiometricAuthError? error;
  final String? errorMessage;

  const BiometricAuthResult({
    required this.success,
    this.error,
    this.errorMessage,
  });

  factory BiometricAuthResult.success() => const BiometricAuthResult(success: true);
  
  factory BiometricAuthResult.failure(BiometricAuthError error, [String? message]) =>
      BiometricAuthResult(success: false, error: error, errorMessage: message);
}

/// Categorized biometric authentication errors
enum BiometricAuthError {
  /// Biometrics not available on this device
  notAvailable,
  /// No biometrics enrolled (user hasn't set up Face ID/fingerprint)
  notEnrolled,
  /// User cancelled authentication
  cancelled,
  /// Too many failed attempts - locked out
  lockedOut,
  /// Permanently locked - requires device passcode
  permanentlyLockedOut,
  /// Authentication failed (wrong face/fingerprint)
  failed,
  /// OS version doesn't support this feature
  osVersionNotSupported,
  /// Passcode not set on device
  passcodeNotSet,
  /// Unknown error
  unknown,
}

class BiometricAuth {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  static Future<bool> isAvailable() async {
    try {
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return isAvailable || isDeviceSupported;
    } catch (e) {
      debugPrint('BiometricAuth: Error checking availability: $e');
      return false;
    }
  }

  /// Get available biometric types with detailed info
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      debugPrint('BiometricAuth: Available biometrics: ${biometrics.map((b) => getBiometricTypeName(b)).join(', ')}');
      return biometrics;
    } catch (e) {
      debugPrint('BiometricAuth: Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if strong biometrics (Face ID, fingerprint) are available
  /// Strong biometrics cannot be spoofed with a photo
  static Future<bool> hasStrongBiometrics() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.any((b) => 
        b == BiometricType.face || 
        b == BiometricType.fingerprint ||
        b == BiometricType.strong ||
        b == BiometricType.iris
      );
    } catch (e) {
      return false;
    }
  }

  /// Authenticate using biometrics with detailed result
  /// 
  /// [localizedReason] - Message shown to user explaining why auth is needed
  /// [useErrorDialogs] - Show system error dialogs for failed attempts
  /// [stickyAuth] - Keep auth active if app goes to background briefly
  /// [biometricOnly] - If true, only allow biometric auth (no PIN fallback)
  ///                   Set to true for maximum security, false for better UX
  static Future<BiometricAuthResult> authenticateWithResult({
    String localizedReason = 'Please authenticate to access your LingAfriq account',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    // First check if biometrics are available
    final available = await isAvailable();
    if (!available) {
      return BiometricAuthResult.failure(
        BiometricAuthError.notAvailable,
        'Biometric authentication is not available on this device',
      );
    }

    // Check if biometrics are enrolled
    final biometrics = await getAvailableBiometrics();
    if (biometrics.isEmpty) {
      return BiometricAuthResult.failure(
        BiometricAuthError.notEnrolled,
        'No biometrics enrolled. Please set up Face ID or fingerprint in your device settings.',
      );
    }

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );

      if (authenticated) {
        return BiometricAuthResult.success();
      } else {
        return BiometricAuthResult.failure(
          BiometricAuthError.failed,
          'Authentication failed. Please try again.',
        );
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      debugPrint('BiometricAuth: Unknown error during authentication: $e');
      return BiometricAuthResult.failure(
        BiometricAuthError.unknown,
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Legacy authenticate method for backward compatibility
  /// Returns true/false, losing error details
  static Future<bool> authenticate({
    String localizedReason = 'Please authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    final result = await authenticateWithResult(
      localizedReason: localizedReason,
      useErrorDialogs: useErrorDialogs,
      stickyAuth: stickyAuth,
      biometricOnly: biometricOnly,
    );
    return result.success;
  }

  /// Handle platform-specific exceptions and convert to BiometricAuthResult
  static BiometricAuthResult _handlePlatformException(PlatformException e) {
    debugPrint('BiometricAuth: Platform exception: ${e.code} - ${e.message}');
    
    switch (e.code) {
      case auth_error.notAvailable:
        return BiometricAuthResult.failure(
          BiometricAuthError.notAvailable,
          'Biometric authentication is not available.',
        );
      case auth_error.notEnrolled:
        return BiometricAuthResult.failure(
          BiometricAuthError.notEnrolled,
          'No biometrics enrolled. Please set up Face ID or fingerprint.',
        );
      case auth_error.lockedOut:
        return BiometricAuthResult.failure(
          BiometricAuthError.lockedOut,
          'Too many failed attempts. Please wait and try again.',
        );
      // Note: permanentLockout was removed in newer local_auth versions
      // Biometric lockout is now handled via lockedOut or platform-specific codes
      case auth_error.passcodeNotSet:
        return BiometricAuthResult.failure(
          BiometricAuthError.passcodeNotSet,
          'Please set up a device passcode to use biometric authentication.',
        );
      case auth_error.otherOperatingSystem:
        return BiometricAuthResult.failure(
          BiometricAuthError.osVersionNotSupported,
          'Your operating system version does not support this feature.',
        );
      default:
        // User cancelled or other failure
        if (e.message?.toLowerCase().contains('cancel') == true ||
            e.code == 'auth_in_progress') {
          return BiometricAuthResult.failure(
            BiometricAuthError.cancelled,
            'Authentication was cancelled.',
          );
        }
        return BiometricAuthResult.failure(
          BiometricAuthError.unknown,
          e.message ?? 'An unexpected error occurred.',
        );
    }
  }

  /// Stop authentication (if in progress)
  static Future<bool> stopAuthentication() async {
    try {
      return await _auth.stopAuthentication();
    } catch (e) {
      debugPrint('BiometricAuth: Error stopping authentication: $e');
      return false;
    }
  }

  /// Check if biometrics are enabled in settings (device supports and user has enabled)
  static Future<bool> isBiometricsEnabled() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } catch (e) {
      debugPrint('BiometricAuth: Error checking if biometrics enabled: $e');
      return false;
    }
  }

  /// Get human-readable name for biometric type
  static String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
      case BiometricType.iris:
        return 'Iris';
      default:
        return 'Biometric';
    }
  }

  /// Get the best available biometric type name for UI display
  static Future<String> getBestBiometricName() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Biometric';
    }
    return 'Biometric';
  }
}

