// Cache Encryption - Encrypts sensitive cached data
// Uses AES encryption for secure local storage

import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingafriq/services/offline/cache_migrator.dart';

/// Thrown when a cached record fails authenticated decryption.
class CacheIntegrityException implements Exception {
  CacheIntegrityException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'CacheIntegrityException($code): $message';
}

class CacheEncryption {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _keyName = 'cache_encryption_key';

  /// Get or generate encryption key
  static Future<Key> _getKey() async {
    String? keyString = await _storage.read(key: _keyName);
    if (keyString == null) {
      // Generate new key
      final key = Key.fromSecureRandom(32);
      await _storage.write(key: _keyName, value: key.base64);
      return key;
    }
    return Key.fromBase64(keyString);
  }

  /// Encrypt data with AES-GCM. Each record gets a new 12-byte nonce.
  static Future<String> encrypt(String plainText) async {
    final key = await _getKey();
    final nonce = IV.fromSecureRandom(12);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: nonce);
    return 'gcm1:${nonce.base64}:${encrypted.base64}';
  }

  /// Decrypt an authenticated record. A legacy or tampered payload throws
  /// [CacheIntegrityException] and returns no data.
  static Future<String> decrypt(String encryptedData) async {
    final migration = CacheMigrator.migrateRecord(encryptedData);
    if (migration.discarded || migration.record == null) {
      throw CacheIntegrityException(
        code: 'cache_integrity_failed',
        message: 'Cached record is not an authenticated gcm1 payload',
      );
    }
    try {
      final parts = migration.record!.split(':');
      if (parts.length != 3 || parts[0] != 'gcm1') {
        throw CacheIntegrityException(
          code: 'cache_integrity_failed',
          message: 'Cached record is not an authenticated gcm1 payload',
        );
      }
      final key = await _getKey();
      final nonce = IV.fromBase64(parts[1]);
      final encrypted = Encrypted.fromBase64(parts[2]);
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      return encrypter.decrypt(encrypted, iv: nonce);
    } on CacheIntegrityException {
      rethrow;
    } catch (_) {
      throw CacheIntegrityException(
        code: 'cache_integrity_failed',
        message: 'Authenticated decryption failed',
      );
    }
  }

  /// Encrypt JSON data
  static Future<String> encryptJson(Map<String, dynamic> json) async {
    final jsonString = jsonEncode(json);
    return encrypt(jsonString);
  }

  /// Decrypt JSON data
  static Future<Map<String, dynamic>> decryptJson(String encryptedData) async {
    final jsonString = await decrypt(encryptedData);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}

/// Service wrapper for CacheEncryption
class CacheEncryptionService {
  static final CacheEncryptionService _instance = CacheEncryptionService._internal();
  factory CacheEncryptionService() => _instance;
  CacheEncryptionService._internal();

  Future<void> initialize() async {
    // CacheEncryption uses static methods
    // Key generation happens lazily on first use via _getKey()
    // No initialization needed - the static class handles it internally
  }

  /// Check if encryption is enabled
  Future<bool> isEncryptionEnabled() async {
    try {
      // Try to encrypt a test string - if it works, encryption is enabled
      await CacheEncryption.encrypt('test');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Encrypt data
  Future<String> encrypt(String plainText) => CacheEncryption.encrypt(plainText);
  
  /// Decrypt data
  Future<String> decrypt(String encryptedData) => CacheEncryption.decrypt(encryptedData);
  
  /// Encrypt JSON data
  Future<String> encryptJson(Map<String, dynamic> json) => CacheEncryption.encryptJson(json);
  
  /// Decrypt JSON data
  Future<Map<String, dynamic>> decryptJson(String encryptedData) => CacheEncryption.decryptJson(encryptedData);
  
  /// Set encryption enabled state (stores preference)
  Future<void> setEncryptionEnabled(bool enabled) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'cache_encryption_enabled', value: enabled.toString());
  }
  
  /// Check if encryption is enabled from preferences
  Future<bool> getEncryptionEnabled() async {
    const storage = FlutterSecureStorage();
    final value = await storage.read(key: 'cache_encryption_enabled');
    return value == 'true';
  }
}

