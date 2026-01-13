import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for managing authentication tokens with TTL
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys
  static const String _sessionTokenKey = 'auth.session_token';
  static const String _sessionExpiryKey = 'auth.session_expiry';
  static const String _refreshTokenKey = 'auth.refresh_token';
  static const String _refreshExpiryKey = 'auth.refresh_expiry';
  static const String _userEmailKey = 'user.email';
  static const String _userDisplayNameKey = 'user.displayName';

  // TTL constants
  static const int sessionTokenTTL = 3600; // 1 hour in seconds
  static const int refreshTokenTTL = 2592000; // 30 days in seconds

  /// Store session token with expiry timestamp
  Future<void> storeSessionToken(String token) async {
    final expiry = DateTime.now().add(Duration(seconds: sessionTokenTTL));
    await Future.wait([
      _storage.write(key: _sessionTokenKey, value: token),
      _storage.write(key: _sessionExpiryKey, value: expiry.millisecondsSinceEpoch.toString()),
    ]);
  }

  /// Store refresh token with expiry timestamp
  Future<void> storeRefreshToken(String token) async {
    final expiry = DateTime.now().add(Duration(seconds: refreshTokenTTL));
    await Future.wait([
      _storage.write(key: _refreshTokenKey, value: token),
      _storage.write(key: _refreshExpiryKey, value: expiry.millisecondsSinceEpoch.toString()),
    ]);
  }

  /// Get session token if valid, null if expired or missing
  Future<String?> getSessionToken() async {
    final token = await _storage.read(key: _sessionTokenKey);
    if (token == null) return null;

    final expiryStr = await _storage.read(key: _sessionExpiryKey);
    if (expiryStr == null) {
      // Clean up invalid state
      await clearSessionToken();
      return null;
    }

    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
    if (DateTime.now().isAfter(expiry)) {
      // Token expired
      await clearSessionToken();
      return null;
    }

    return token;
  }

  /// Get refresh token if valid, null if expired or missing
  Future<String?> getRefreshToken() async {
    final token = await _storage.read(key: _refreshTokenKey);
    if (token == null) return null;

    final expiryStr = await _storage.read(key: _refreshExpiryKey);
    if (expiryStr == null) {
      await clearRefreshToken();
      return null;
    }

    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
    if (DateTime.now().isAfter(expiry)) {
      await clearRefreshToken();
      return null;
    }

    return token;
  }

  /// Check if session token is valid
  Future<bool> hasValidSession() async {
    final token = await getSessionToken();
    return token != null;
  }

  /// Check if refresh token is valid
  Future<bool> hasValidRefreshToken() async {
    final token = await getRefreshToken();
    return token != null;
  }

  /// Clear session token
  Future<void> clearSessionToken() async {
    await Future.wait([
      _storage.delete(key: _sessionTokenKey),
      _storage.delete(key: _sessionExpiryKey),
    ]);
  }

  /// Clear refresh token
  Future<void> clearRefreshToken() async {
    await Future.wait([
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _refreshExpiryKey),
    ]);
  }

  /// Clear all auth tokens
  Future<void> clearAllTokens() async {
    await Future.wait([
      clearSessionToken(),
      clearRefreshToken(),
    ]);
  }

  /// Store user profile info for pre-filling login
  Future<void> storeUserProfile(String email, {String? displayName}) async {
    await Future.wait([
      _storage.write(key: _userEmailKey, value: email),
      if (displayName != null)
        _storage.write(key: _userDisplayNameKey, value: displayName),
    ]);
  }

  /// Get stored user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  /// Get stored user display name
  Future<String?> getUserDisplayName() async {
    return await _storage.read(key: _userDisplayNameKey);
  }

  /// Clear user profile
  Future<void> clearUserProfile() async {
    await Future.wait([
      _storage.delete(key: _userEmailKey),
      _storage.delete(key: _userDisplayNameKey),
    ]);
  }
}

