import 'package:flutter/material.dart';
import 'package:lingafriq/services/auth/biometric_auth_service.dart';
import 'package:lingafriq/services/auth/biometric_preference_service.dart';
import 'package:lingafriq/utils/error_handler.dart';

/// Coordinates opt-in biometric enrollment prompts in a reusable way.
class BiometricEnrollmentService {
  Future<bool> maybeOfferEnrollment({
    required BuildContext context,
    required String email,
    BiometricAuthService? biometricAuth,
    BiometricPreferenceService? biometricPreferenceService,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !context.mounted) return false;

    final auth = biometricAuth ?? BiometricAuthService();
    final preference = biometricPreferenceService ?? BiometricPreferenceService();

    final available = await auth.isAvailable();
    if (!available) return false;

    final alreadyEnabled = await preference.isEnabledForEmail(normalizedEmail);
    if (alreadyEnabled || !context.mounted) return false;

    final biometricName = await auth.getBestBiometricName();
    if (!context.mounted) return false;

    final shouldEnable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enable Biometric Sign-In'),
        content: Text(
          'Use $biometricName for faster, secure sign-in on this device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (shouldEnable != true || !context.mounted) return false;

    final challenge = await auth.authenticateWithResult(
      localizedReason: 'Confirm your identity to enable biometric sign-in',
      biometricOnly: true,
    );
    if (!challenge.success) {
      if (context.mounted) {
        ErrorHandler.showError(
          context,
          challenge.errorMessage ?? 'Unable to enable biometric sign-in.',
        );
      }
      return false;
    }

    await preference.enableForEmail(normalizedEmail);
    return true;
  }
}
