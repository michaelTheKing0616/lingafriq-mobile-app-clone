/// CredentialStorageService - Service wrapper for CredentialStorage
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
    await _storage.write(key: 'password', value: password);
    if (firstName != null) {
      await _storage.write(key: 'firstName', value: firstName);
    }
    if (lastName != null) {
      await _storage.write(key: 'lastName', value: lastName);
    }
    // Also store as username for compatibility
    await CredentialStorage.storeCredentials(username: email, password: password);
  }

  Future<Map<String, String>?> getStoredCredentials() async {
    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');
    if (email != null && password != null) {
      return {
        'email': email,
        'password': password,
        'firstName': await _storage.read(key: 'firstName') ?? '',
        'lastName': await _storage.read(key: 'lastName') ?? '',
      };
    }
    return null;
  }

  Future<bool> hasStoredCredentials() async {
    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');
    return email != null && password != null;
  }

  Future<String?> getStoredEmail() async {
    return await _storage.read(key: 'email');
  }

  Future<String?> getStoredPassword() async {
    return await _storage.read(key: 'password');
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

