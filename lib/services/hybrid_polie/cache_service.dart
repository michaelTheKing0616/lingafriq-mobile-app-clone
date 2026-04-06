// Cache Service for Hybrid Polie
// Implements caching for translations and canonical phrases to reduce API calls

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class HybridPolieCache {
  static const String _cachePrefix = 'hybrid_polie_cache_';
  static const int _maxCacheSize = 1000; // Maximum cached items
  static const Duration _defaultTTL = Duration(days: 7); // 7 days TTL

  /// Get cached translation
  static Future<String?> getCachedTranslation({
    required String text,
    required String sourceLang,
    required String targetLang,
    String? modelTag,
  }) async {
    try {
      final key = _generateCacheKey('translation', text, sourceLang, targetLang, modelTag);
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp'] as String);
        final ttl = Duration(seconds: data['ttl'] as int? ?? _defaultTTL.inSeconds);
        
        if (DateTime.now().difference(timestamp) < ttl) {
          return data['result'] as String;
        } else {
          // Expired, remove it
          await prefs.remove(key);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache translation result
  static Future<void> cacheTranslation({
    required String text,
    required String sourceLang,
    required String targetLang,
    required String result,
    Duration? ttl,
    String? modelTag,
  }) async {
    try {
      final key = _generateCacheKey('translation', text, sourceLang, targetLang, modelTag);
      final prefs = await SharedPreferences.getInstance();
      
      final data = {
        'result': result,
        'timestamp': DateTime.now().toIso8601String(),
        'ttl': (ttl ?? _defaultTTL).inSeconds,
      };
      
      await prefs.setString(key, jsonEncode(data));
      await _enforceCacheSize(prefs);
    } catch (e) {
      // Cache failure shouldn't break the app
    }
  }

  /// Get cached canonical phrase
  static Future<String?> getCachedCanonical({
    required String phrase,
    required String language,
  }) async {
    try {
      final key = _generateCacheKey('canonical', phrase, language);
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp'] as String);
        final ttl = Duration(seconds: data['ttl'] as int? ?? _defaultTTL.inSeconds);
        
        if (DateTime.now().difference(timestamp) < ttl) {
          return data['result'] as String;
        } else {
          await prefs.remove(key);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache canonical phrase result
  static Future<void> cacheCanonical({
    required String phrase,
    required String language,
    required String result,
    Duration? ttl,
  }) async {
    try {
      final key = _generateCacheKey('canonical', phrase, language);
      final prefs = await SharedPreferences.getInstance();
      
      final data = {
        'result': result,
        'timestamp': DateTime.now().toIso8601String(),
        'ttl': (ttl ?? _defaultTTL).inSeconds,
      };
      
      await prefs.setString(key, jsonEncode(data));
      await _enforceCacheSize(prefs);
    } catch (e) {
      // Cache failure shouldn't break the app
    }
  }

  /// Clear all cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear cache entries for a specific language
  /// This is called when the user changes their target language
  static Future<void> clearByLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
      final normalizedLang = language.toLowerCase();
      int cleared = 0;
      
      for (final key in keys) {
        final cached = prefs.getString(key);
        if (cached != null) {
          try {
            // Note: Since we hash the cache key, we can't directly check the language
            // Instead, we track language in the cached data
            final data = jsonDecode(cached) as Map<String, dynamic>;
            final cachedLang = data['language']?.toString().toLowerCase();
            final cachedTargetLang = data['targetLang']?.toString().toLowerCase();
            final cachedSourceLang = data['sourceLang']?.toString().toLowerCase();
            
            if (cachedLang == normalizedLang || 
                cachedTargetLang == normalizedLang || 
                cachedSourceLang == normalizedLang) {
              await prefs.remove(key);
              cleared++;
            }
          } catch (e) {
            // Invalid entry, skip
          }
        }
      }
      
      // If we couldn't identify language-specific entries (due to hashing),
      // clear a portion of old cache to make room for new language
      if (cleared == 0) {
        await _clearOldestEntries(prefs, keys.length ~/ 4); // Clear 25% of oldest
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear oldest N entries from cache
  static Future<void> _clearOldestEntries(SharedPreferences prefs, int count) async {
    if (count <= 0) return;
    
    try {
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
      final entries = <Map<String, dynamic>>[];
      
      for (final key in keys) {
        final cached = prefs.getString(key);
        if (cached != null) {
          try {
            final data = jsonDecode(cached) as Map<String, dynamic>;
            entries.add({
              'key': key,
              'timestamp': DateTime.parse(data['timestamp'] as String),
            });
          } catch (e) {
            // Remove invalid entries
            await prefs.remove(key);
          }
        }
      }
      
      // Sort by timestamp (oldest first)
      entries.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
      
      // Remove oldest entries
      final toRemove = count.clamp(0, entries.length);
      for (int i = 0; i < toRemove; i++) {
        await prefs.remove(entries[i]['key'] as String);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
      final count = keys.length;
      
      int totalSize = 0;
      int expiredCount = 0;
      final now = DateTime.now();
      
      for (final key in keys) {
        final cached = prefs.getString(key);
        if (cached != null) {
          totalSize += cached.length;
          try {
            final data = jsonDecode(cached) as Map<String, dynamic>;
            final timestamp = DateTime.parse(data['timestamp'] as String);
            final ttl = Duration(seconds: data['ttl'] as int? ?? _defaultTTL.inSeconds);
            if (now.difference(timestamp) >= ttl) {
              expiredCount++;
            }
          } catch (e) {
            // Ignore parse errors
          }
        }
      }
      
      return {
        'totalItems': count,
        'totalSize': totalSize,
        'expiredItems': expiredCount,
        'activeItems': count - expiredCount,
      };
    } catch (e) {
      return {'totalItems': 0, 'totalSize': 0, 'expiredItems': 0, 'activeItems': 0};
    }
  }

  /// Generate cache key
  static String _generateCacheKey(String type, String text, [String? lang1, String? lang2, String? modelTag]) {
    final normalized = text.toLowerCase().trim();
    final parts = [type, normalized];
    if (lang1 != null) parts.add(lang1.toLowerCase());
    if (lang2 != null) parts.add(lang2.toLowerCase());
    if (modelTag != null && modelTag.isNotEmpty) {
      parts.add('model:${modelTag.toLowerCase()}');
    }
    
    final keyString = parts.join('|');
    final bytes = utf8.encode(keyString);
    final hash = sha256.convert(bytes);
    return '$_cachePrefix${hash.toString()}';
  }

  /// Enforce maximum cache size (LRU eviction)
  static Future<void> _enforceCacheSize(SharedPreferences prefs) async {
    try {
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
      
      if (keys.length > _maxCacheSize) {
        // Get all cache entries with timestamps
        final entries = <Map<String, dynamic>>[];
        for (final key in keys) {
          final cached = prefs.getString(key);
          if (cached != null) {
            try {
              final data = jsonDecode(cached) as Map<String, dynamic>;
              entries.add({
                'key': key,
                'timestamp': DateTime.parse(data['timestamp'] as String),
              });
            } catch (e) {
              // Remove invalid entries
              await prefs.remove(key);
            }
          }
        }
        
        // Sort by timestamp (oldest first)
        entries.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
        
        // Remove oldest entries
        final toRemove = entries.length - _maxCacheSize;
        for (int i = 0; i < toRemove; i++) {
          await prefs.remove(entries[i]['key'] as String);
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }
}

