import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// Polie Response Cache Service
/// Caches Polie-generated content to reduce API calls and improve performance
class PolieCacheService {
  static const String _cachePrefix = 'polie_cache_';
  static const int _maxCacheSize = 100; // Maximum cached items
  static const Duration _defaultTTL = Duration(days: 7); // Cache expires after 7 days

  /// Generate cache key from parameters
  static String _generateCacheKey(String type, String language, {String? additional}) {
    final keyString = '$type:$language${additional != null ? ':$additional' : ''}';
    final bytes = utf8.encode(keyString);
    final digest = sha256.convert(bytes);
    return '$_cachePrefix${digest.toString().substring(0, 16)}';
  }

  /// Check if cached content exists and is valid
  static Future<bool> hasCachedContent(
    String type,
    String language, {
    String? additional,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(type, language, additional: additional);
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData == null) return false;
      
      final decoded = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = DateTime.parse(decoded['timestamp'] as String);
      final ttl = Duration(seconds: decoded['ttl'] as int? ?? _defaultTTL.inSeconds);
      
      return DateTime.now().difference(timestamp) < ttl;
    } catch (e) {
      debugPrint('Error checking cache: $e');
      return false;
    }
  }

  /// Get cached content
  static Future<Map<String, dynamic>?> getCachedContent(
    String type,
    String language, {
    String? additional,
  }) async {
    try {
      if (!await hasCachedContent(type, language, additional: additional)) {
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(type, language, additional: additional);
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData == null) return null;
      
      final decoded = jsonDecode(cachedData) as Map<String, dynamic>;
      return decoded['content'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting cached content: $e');
      return null;
    }
  }

  /// Cache content with TTL
  static Future<void> cacheContent(
    String type,
    String language,
    Map<String, dynamic> content, {
    String? additional,
    Duration? ttl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(type, language, additional: additional);
      
      final cacheData = {
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
        'ttl': (ttl ?? _defaultTTL).inSeconds,
        'type': type,
        'language': language,
      };
      
      await prefs.setString(cacheKey, jsonEncode(cacheData));
      
      // Clean up old cache entries if we exceed max size
      await _cleanupCache(prefs);
    } catch (e) {
      debugPrint('Error caching content: $e');
    }
  }

  /// Clean up old cache entries
  static Future<void> _cleanupCache(SharedPreferences prefs) async {
    try {
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
      
      if (keys.length <= _maxCacheSize) return;
      
      // Sort by timestamp and remove oldest
      final entries = <MapEntry<String, DateTime>>[];
      for (final key in keys) {
        try {
          final data = prefs.getString(key);
          if (data != null) {
            final decoded = jsonDecode(data) as Map<String, dynamic>;
            final timestamp = DateTime.parse(decoded['timestamp'] as String);
            entries.add(MapEntry(key, timestamp));
          }
        } catch (_) {
          // Remove invalid entries
          await prefs.remove(key);
        }
      }
      
      // Sort by timestamp (oldest first)
      entries.sort((a, b) => a.value.compareTo(b.value));
      
      // Remove oldest entries
      final toRemove = entries.length - _maxCacheSize;
      for (int i = 0; i < toRemove; i++) {
        await prefs.remove(entries[i].key);
      }
    } catch (e) {
      debugPrint('Error cleaning cache: $e');
    }
  }

  /// Clear all cached content
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
      
      int validEntries = 0;
      int expiredEntries = 0;
      int totalSize = 0;
      
      for (final key in keys) {
        try {
          final data = prefs.getString(key);
          if (data != null) {
            totalSize += data.length;
            final decoded = jsonDecode(data) as Map<String, dynamic>;
            final timestamp = DateTime.parse(decoded['timestamp'] as String);
            final ttl = Duration(seconds: decoded['ttl'] as int? ?? _defaultTTL.inSeconds);
            
            if (DateTime.now().difference(timestamp) < ttl) {
              validEntries++;
            } else {
              expiredEntries++;
            }
          }
        } catch (_) {
          expiredEntries++;
        }
      }
      
      return {
        'total_entries': keys.length,
        'valid_entries': validEntries,
        'expired_entries': expiredEntries,
        'total_size_bytes': totalSize,
        'max_size': _maxCacheSize,
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {};
    }
  }
}

