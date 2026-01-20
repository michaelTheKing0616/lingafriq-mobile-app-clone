/// Cache Eviction Policies
/// Implements intelligent cache management with eviction strategies
/// 
/// Features:
/// - LRU (Least Recently Used) eviction
/// - Size-based eviction
/// - Time-based eviction
/// - Priority-based eviction
/// - Configurable limits
/// 
/// Production-ready implementation (December 2025)

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'dart:convert';

/// Cache eviction policy types
enum EvictionPolicy {
  lru, // Least Recently Used
  lfu, // Least Frequently Used
  fifo, // First In First Out
  sizeBased, // Based on size
  timeBased, // Based on age
  priorityBased, // Based on priority
}

/// Cache entry metadata
class CacheEntry {
  final String key;
  final DateTime lastAccessed;
  final int accessCount;
  final int sizeBytes;
  final DateTime createdAt;
  final int priority; // 0-10, higher is more important

  CacheEntry({
    required this.key,
    required this.lastAccessed,
    required this.accessCount,
    required this.sizeBytes,
    required this.createdAt,
    this.priority = 5,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'lastAccessed': lastAccessed.toIso8601String(),
    'accessCount': accessCount,
    'sizeBytes': sizeBytes,
    'createdAt': createdAt.toIso8601String(),
    'priority': priority,
  };
}

/// Cache Eviction Manager
class CacheEvictionManager {
  static final CacheEvictionManager _instance = CacheEvictionManager._internal();
  factory CacheEvictionManager() => _instance;
  CacheEvictionManager._internal();

  // Default limits
  static const int defaultMaxSizeBytes = 100 * 1024 * 1024; // 100MB
  static const int defaultMaxEntries = 10000;
  static const Duration defaultMaxAge = Duration(days: 30);

  int _maxSizeBytes = defaultMaxSizeBytes;
  int _maxEntries = defaultMaxEntries;
  Duration _maxAge = defaultMaxAge;
  EvictionPolicy _policy = EvictionPolicy.lru;

  /// Configure eviction policy
  void configure({
    int? maxSizeBytes,
    int? maxEntries,
    Duration? maxAge,
    EvictionPolicy? policy,
  }) {
    if (maxSizeBytes != null) _maxSizeBytes = maxSizeBytes;
    if (maxEntries != null) _maxEntries = maxEntries;
    if (maxAge != null) _maxAge = maxAge;
    if (policy != null) _policy = policy;
  }

  /// Evict cache entries based on policy
  Future<int> evict({bool force = false}) async {
    try {
      logger.info('Starting cache eviction', context: {
        'policy': _policy.name,
        'maxSize': _maxSizeBytes,
        'maxEntries': _maxEntries,
      });

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      if (keys.isEmpty) {
        logger.debug('Cache is empty, nothing to evict');
        return 0;
      }

      // Build cache entries with metadata
      final entries = <CacheEntry>[];
      int totalSize = 0;

      for (final key in keys) {
        final value = prefs.get(key);
        final size = _calculateSize(key, value);
        totalSize += size;

        // Get metadata (stored separately)
        final metadataJson = prefs.getString('_cache_meta_$key');
        final metadata = metadataJson != null
            ? (() {
                try {
                  final decoded = jsonDecode(metadataJson);
                  if (decoded is Map<String, dynamic>) return decoded;
                  if (decoded is Map) return Map<String, dynamic>.from(decoded);
                } catch (_) {}
                return <String, dynamic>{};
              })()
            : <String, dynamic>{};

        entries.add(CacheEntry(
          key: key,
          lastAccessed: metadata['lastAccessed'] != null
              ? DateTime.parse(metadata['lastAccessed'])
              : DateTime.now(),
          accessCount: metadata['accessCount'] ?? 0,
          sizeBytes: size,
          createdAt: metadata['createdAt'] != null
              ? DateTime.parse(metadata['createdAt'])
              : DateTime.now(),
          priority: metadata['priority'] ?? 5,
        ));
      }

      // Check if eviction is needed
      final needsEviction = force ||
          totalSize > _maxSizeBytes ||
          entries.length > _maxEntries ||
          entries.any((e) => DateTime.now().difference(e.createdAt) > _maxAge);

      if (!needsEviction && !force) {
        logger.debug('Cache within limits, no eviction needed');
        return 0;
      }

      // Sort entries based on eviction policy
      final sortedEntries = _sortForEviction(entries);

      // Evict entries until within limits
      int evictedCount = 0;
      int currentSize = totalSize;
      final entriesToEvict = <String>[];

      for (final entry in sortedEntries) {
        // Check if we're within limits
        if (currentSize <= _maxSizeBytes &&
            (entries.length - evictedCount) <= _maxEntries &&
            !_isExpired(entry)) {
          break;
        }

        entriesToEvict.add(entry.key);
        currentSize -= entry.sizeBytes;
        evictedCount++;
      }

      // Remove evicted entries
      for (final key in entriesToEvict) {
        await prefs.remove(key);
        await prefs.remove('_cache_meta_$key');
      }

      logger.info('Cache eviction completed', context: {
        'evictedCount': evictedCount,
        'remainingSize': currentSize,
        'remainingEntries': entries.length - evictedCount,
      });

      return evictedCount;
    } catch (e) {
      logger.error('Cache eviction failed', error: e);
      return 0;
    }
  }

  /// Sort entries based on eviction policy
  List<CacheEntry> _sortForEviction(List<CacheEntry> entries) {
    switch (_policy) {
      case EvictionPolicy.lru:
        // Least recently used first
        entries.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));
        break;
      case EvictionPolicy.lfu:
        // Least frequently used first
        entries.sort((a, b) => a.accessCount.compareTo(b.accessCount));
        break;
      case EvictionPolicy.fifo:
        // Oldest first
        entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case EvictionPolicy.sizeBased:
        // Largest first
        entries.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
      case EvictionPolicy.timeBased:
        // Oldest first
        entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case EvictionPolicy.priorityBased:
        // Lowest priority first
        entries.sort((a, b) => a.priority.compareTo(b.priority));
        break;
    }
    return entries;
  }

  /// Check if entry is expired
  bool _isExpired(CacheEntry entry) {
    return DateTime.now().difference(entry.createdAt) > _maxAge;
  }

  /// Calculate size of cache entry
  int _calculateSize(String key, dynamic value) {
    int size = key.length * 2; // UTF-16 encoding

    if (value is String) {
      size += value.length * 2;
    } else if (value is int) {
      size += 8;
    } else if (value is double) {
      size += 8;
    } else if (value is bool) {
      size += 1;
    } else if (value is List) {
      size += value.length * 16; // Rough estimate
    } else if (value is Map) {
      size += value.length * 32; // Rough estimate
    }

    return size;
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    int totalSize = 0;
    int expiredCount = 0;
    final now = DateTime.now();

    for (final key in keys) {
      if (key.startsWith('_cache_meta_')) continue;
      
      final value = prefs.get(key);
      totalSize += _calculateSize(key, value);

      final metadataJson = prefs.getString('_cache_meta_$key');
      if (metadataJson != null) {
        final metadata = (() {
          try {
            final decoded = jsonDecode(metadataJson);
            if (decoded is Map<String, dynamic>) return decoded;
            if (decoded is Map) return Map<String, dynamic>.from(decoded);
          } catch (_) {}
          return <String, dynamic>{};
        })();
        final createdAt = metadata['createdAt'] != null
            ? DateTime.parse(metadata['createdAt'])
            : null;
        if (createdAt != null && now.difference(createdAt) > _maxAge) {
          expiredCount++;
        }
      }
    }

    return {
      'totalEntries': keys.length,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'maxSizeBytes': _maxSizeBytes,
      'maxEntries': _maxEntries,
      'expiredEntries': expiredCount,
      'policy': _policy.name,
    };
  }
}

/// Global cache eviction manager
final cacheEvictionManager = CacheEvictionManager();

