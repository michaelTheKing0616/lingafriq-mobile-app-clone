/// Cache Encryption - Encrypts sensitive cached data
/// Uses AES encryption for secure local storage

import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  /// Encrypt data
  static Future<String> encrypt(String plainText) async {
    final key = await _getKey();
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Combine IV and encrypted data
    final combined = '${iv.base64}:${encrypted.base64}';
    return combined;
  }

  /// Decrypt data
  static Future<String> decrypt(String encryptedData) async {
    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted data format');
      }

      final key = await _getKey();
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      final encrypter = Encrypter(AES(key));
      
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      // If decryption fails, return original (might be unencrypted)
      return encryptedData;
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
}

