// Performance Utilities
// Helper functions for optimizing app performance

import 'dart:async';
import 'package:flutter/material.dart';

/// Debouncer for search and other frequent operations
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler for rate-limiting operations
class Throttler {
  final Duration delay;
  DateTime? _lastRun;

  Throttler({this.delay = const Duration(milliseconds: 1000)});

  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= delay) {
      _lastRun = now;
      action();
    }
  }
}

/// DEPRECATED: Use simple_cache.dart SimpleCache singleton instead
/// 
/// This generic cache is kept for backward compatibility but should be migrated
/// to the consolidated SimpleCache singleton which has:
/// - LRU eviction
/// - Timer-based cleanup
/// - Statistics
/// - Better memory management
/// 
/// Migration: Replace `SimpleCache<K, V>()` with `SimpleCache()` and convert keys to String
@Deprecated('Use simple_cache.dart SimpleCache singleton instead')
class SimpleCache<K, V> {
  final Map<K, _CacheEntry<V>> _cache = {};
  final Duration defaultTtl;
  final Future<V> Function(K key)? fetcher;

  SimpleCache({
    Duration? ttl,
    this.fetcher,
  }) : defaultTtl = ttl ?? const Duration(hours: 1);

  void set(K key, V value, {Duration? ttl}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl ?? defaultTtl),
    );
  }

  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (entry.expiresAt.isBefore(DateTime.now())) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value;
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  void evictExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => entry.expiresAt.isBefore(now));
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});
}

/// DEPRECATED: Use widgets/performance/optimized_list_view.dart instead
/// 
/// This version is kept for backward compatibility but the consolidated version
/// in widgets/performance/optimized_list_view.dart has more features.
@Deprecated('Use widgets/performance/optimized_list_view.dart OptimizedListView instead')
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double? itemExtent;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent,
    this.controller,
    this.padding,
  });

  /// Factory constructor for builder pattern compatibility
  static Widget builder({
    Key? key,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    double? itemExtent,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    double cacheExtent = 250.0,
    SliverGridDelegate? gridDelegate,
    Axis scrollDirection = Axis.vertical,
  }) {
    // Import and use the optimized_list_view version which supports scrollDirection
    // Note: This method should redirect to the widget in optimized_list_view.dart
    // For now, return basic ListView for backward compatibility
    if (scrollDirection == Axis.horizontal) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        padding: padding,
        controller: controller,
        itemExtent: itemExtent,
        shrinkWrap: shrinkWrap,
        physics: physics,
        cacheExtent: cacheExtent,
      );
    }
    return OptimizedListView(
      key: key,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      itemExtent: itemExtent,
      controller: controller,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemExtent: itemExtent,
      itemBuilder: itemBuilder,
    );
  }
}

/// DEPRECATED: Use widgets/performance/lazy_image.dart instead
/// 
/// This version is kept for backward compatibility but the consolidated version
/// in widgets/performance/lazy_image.dart uses cached_network_image for better performance.
@Deprecated('Use widgets/performance/lazy_image.dart LazyImage instead')
class LazyImage extends StatelessWidget {
  final String? imageUrl;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const LazyImage({
    super.key,
    this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.fit,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return errorWidget ?? 
        Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Icon(Icons.image_not_supported),
        );
    }

    // Use Image.network with error handling
    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? 
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? 
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Icon(Icons.broken_image),
          );
      },
    );
  }
}

/// Memory-efficient image cache manager
class ImageCacheManager {
  static const int maxCacheSize = 100; // MB

  static void configureCache() {
    PaintingBinding.instance.imageCache.maximumSize = maxCacheSize * 1024 * 1024;
    PaintingBinding.instance.imageCache.maximumSizeBytes = maxCacheSize * 1024 * 1024;
  }

  static void clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  static void evict(String url) {
    // Note: Flutter's image cache doesn't expose eviction by key
    // This would need to be implemented with a custom image provider
  }
}

/// Batch processor for processing items in batches
class BatchProcessor<T> {
  final int batchSize;
  final Future<void> Function(List<T>) processor;

  BatchProcessor({
    this.batchSize = 10,
    required this.processor,
  });

  Future<void> processAll(List<T> items) async {
    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.sublist(
        i,
        i + batchSize > items.length ? items.length : i + batchSize,
      );
      await processor(batch);
    }
  }
}

