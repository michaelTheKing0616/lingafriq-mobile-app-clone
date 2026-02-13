// Credential Storage - Secure storage for user credentials
// Uses Flutter Secure Storage for encrypted local storage

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Store auth token
  static Future<void> storeAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  /// Get auth token
  static Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Store refresh token
  static Future<void> storeRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  /// Store user credentials (username/email)
  static Future<void> storeCredentials({
    required String username,
    String? password,
  }) async {
    await _storage.write(key: 'username', value: username);
    if (password != null) {
      await _storage.write(key: 'password', value: password);
    }
  }

  /// Get stored username
  static Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  /// Clear all credentials
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}

