/// Consolidated Performance Utilities
/// 
/// This file re-exports the consolidated implementations from their dedicated files
/// Use this for convenience imports, or import directly from the source files

export '../widgets/performance/optimized_list_view.dart';
export '../widgets/performance/lazy_image.dart';
export 'simple_cache.dart';
export 'debouncer.dart';

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

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

