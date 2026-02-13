// Simple Cache Utility (Consolidated)
// Provides in-memory caching with TTL (Time To Live)
// 
// Features:
// - Key-value storage (String keys, typed values)
// - Automatic expiration with timer-based cleanup
// - LRU eviction when cache is full
// - Memory-efficient
// - Thread-safe singleton
// - Cache statistics
// - getOrCompute methods for lazy loading
// 
// This is the consolidated cache implementation.
// Use this instead of performance_utils.SimpleCache

import 'dart:async';
class CacheEntry<T> {
  final T value;
  final DateTime expiryTime;
  final DateTime createdAt;

  CacheEntry({
    required this.value,
    required Duration ttl,
  })  : expiryTime = DateTime.now().add(ttl),
        createdAt = DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiryTime);
  
  Duration get age => DateTime.now().difference(createdAt);
}

class SimpleCache {
  static final SimpleCache _instance = SimpleCache._internal();
  factory SimpleCache() => _instance;
  SimpleCache._internal();

  final Map<String, CacheEntry<dynamic>> _cache = {};
  final Map<String, Timer> _timers = {};
  final Map<String, DateTime> _accessTimes = {}; // For LRU tracking
  
  /// Maximum number of entries (LRU eviction)
  static const int maxEntries = 1000;

  /// Default TTL
  static const Duration defaultTTL = Duration(hours: 1);

  /// Get value from cache
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      if (entry != null) {
        _cache.remove(key);
        _timers[key]?.cancel();
        _timers.remove(key);
        _accessTimes.remove(key);
      }
      return null;
    }
    
    // Update access time for LRU
    _accessTimes[key] = DateTime.now();
    
    return entry.value as T;
  }

  /// Set value in cache with TTL
  void set<T>(String key, T value, {Duration? ttl}) {
    // Remove existing entry if present
    _cache.remove(key);
    _timers[key]?.cancel();
    _timers.remove(key);
    _accessTimes.remove(key);

    // Check if cache is full
    if (_cache.length >= maxEntries) {
      _evictLRU();
    }

    final cacheTTL = ttl ?? defaultTTL;
    _cache[key] = CacheEntry<T>(
      value: value,
      ttl: cacheTTL,
    );
    
    // Update access time
    _accessTimes[key] = DateTime.now();

    // Schedule cleanup
    _timers[key] = Timer(cacheTTL, () {
      _cache.remove(key);
      _timers.remove(key);
      _accessTimes.remove(key);
    });
  }

  /// Check if key exists and is not expired
  bool contains(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      if (entry != null) {
        _cache.remove(key);
        _timers[key]?.cancel();
        _timers.remove(key);
      }
      return false;
    }
    return true;
  }

  /// Remove value from cache
  void remove(String key) {
    _cache.remove(key);
    _timers[key]?.cancel();
    _timers.remove(key);
    _accessTimes.remove(key);
  }

  /// Clear all cache
  void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _cache.clear();
    _timers.clear();
    _accessTimes.clear();
  }

  /// Get or compute value
  Future<T> getOrCompute<T>(
    String key,
    Future<T> Function() compute, {
    Duration? ttl,
  }) async {
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }

    final value = await compute();
    set(key, value, ttl: ttl);
    return value;
  }

  /// Get or compute synchronously
  T getOrComputeSync<T>(
    String key,
    T Function() compute, {
    Duration? ttl,
  }) {
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }

    final value = compute();
    set(key, value, ttl: ttl);
    return value;
  }

  /// Evict least recently used entry
  void _evictLRU() {
    if (_cache.isEmpty || _accessTimes.isEmpty) return;

    // Find least recently used entry
    String? lruKey;
    DateTime? oldestAccess;

    for (final entry in _accessTimes.entries) {
      if (oldestAccess == null || entry.value.isBefore(oldestAccess)) {
        oldestAccess = entry.value;
        lruKey = entry.key;
      }
    }

    if (lruKey != null) {
      remove(lruKey);
    } else {
      // Fallback: remove first entry
      final firstKey = _cache.keys.first;
      remove(firstKey);
    }
  }

  /// Get cache size
  int get size => _cache.length;

  /// Get cache stats
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int expired = 0;
    int active = 0;

    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expired++;
      } else {
        active++;
      }
    }

    return {
      'total': _cache.length,
      'active': active,
      'expired': expired,
      'max_entries': maxEntries,
    };
  }
}

