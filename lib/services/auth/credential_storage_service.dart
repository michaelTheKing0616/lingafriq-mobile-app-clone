// CredentialStorageService - Service wrapper for CredentialStorage
import 'credential_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStorageService {
  static final CredentialStorageService _instance = CredentialStorageService._internal();
  factory CredentialStorageService() => _instance;
  CredentialStorageService._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  Future<void> initialize() async {
    // CredentialStorage uses FlutterSecureStorage which initializes on first use
    // No explicit initialization needed - storage is ready when accessed
  }

  Future<void> storeCredentials({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    await _storage.write(key: 'email', value: email);
    // SECURITY: Do NOT persist raw passwords on device.
    // We rely on refresh tokens for silent re-auth instead.
    await _storage.delete(key: 'password');
    if (firstName != null) {
      await _storage.write(key: 'firstName', value: firstName);
    }
    if (lastName != null) {
      await _storage.write(key: 'lastName', value: lastName);
    }
    // Legacy credential storage intentionally not used (password persistence removed).
    // If older builds stored credentials, they will be cleared on next clearCredentials().
  }

  Future<Map<String, String>?> getStoredCredentials() async {
    final email = await _storage.read(key: 'email');
    // SECURITY: password is no longer stored.
    if (email != null && email.trim().isNotEmpty) {
      return {
        'email': email,
        'firstName': await _storage.read(key: 'firstName') ?? '',
        'lastName': await _storage.read(key: 'lastName') ?? '',
      };
    }
    return null;
  }

  Future<bool> hasStoredCredentials() async {
    final email = await _storage.read(key: 'email');
    return email != null && email.trim().isNotEmpty;
  }

  Future<String?> getStoredEmail() async {
    return await _storage.read(key: 'email');
  }

  Future<String?> getStoredPassword() async {
    // SECURITY: password is no longer stored.
    return null;
  }

  Future<String?> getStoredFirstName() async {
    return await _storage.read(key: 'firstName');
  }

  Future<String?> getStoredLastName() async {
    return await _storage.read(key: 'lastName');
  }

  Future<void> clearCredentials() async {
    await _storage.deleteAll();
    await CredentialStorage.clearAll();
  }
}

