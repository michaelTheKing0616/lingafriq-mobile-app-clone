// Batch Processor for Hybrid Polie
// Batches multiple requests to reduce API calls and improve efficiency

import 'dart:async';
class BatchProcessor<T> {
  final Duration _batchWindow;
  final int _maxBatchSize;
  final Future<List<T>> Function(List<BatchItem>) _processor;
  
  final List<BatchItem> _pendingItems = [];
  Timer? _batchTimer;
  final Map<String, Completer<T>> _completers = {};

  BatchProcessor({
    Duration batchWindow = const Duration(milliseconds: 500),
    int maxBatchSize = 10,
    required Future<List<T>> Function(List<BatchItem>) processor,
  })  : _batchWindow = batchWindow,
        _maxBatchSize = maxBatchSize,
        _processor = processor;

  /// Add item to batch
  Future<T> add(BatchItem item) {
    final completer = Completer<T>();
    _completers[item.id] = completer;
    _pendingItems.add(item);

    // If batch is full, process immediately
    if (_pendingItems.length >= _maxBatchSize) {
      _processBatch();
    } else {
      // Otherwise, start/reset timer
      _batchTimer?.cancel();
      _batchTimer = Timer(_batchWindow, _processBatch);
    }

    return completer.future;
  }

  /// Process current batch
  Future<void> _processBatch() async {
    _batchTimer?.cancel();
    _batchTimer = null;

    if (_pendingItems.isEmpty) return;

    final itemsToProcess = List<BatchItem>.from(_pendingItems);
    _pendingItems.clear();

    try {
      final results = await _processor(itemsToProcess);
      
      // Match results to completers
      for (int i = 0; i < itemsToProcess.length && i < results.length; i++) {
        final item = itemsToProcess[i];
        final completer = _completers.remove(item.id);
        completer?.complete(results[i]);
      }

      // Complete any remaining with error
      for (final item in itemsToProcess) {
        final completer = _completers.remove(item.id);
        if (completer != null && !completer.isCompleted) {
          completer.completeError('Batch processing failed');
        }
      }
    } catch (e) {
      // Complete all with error
      for (final item in itemsToProcess) {
        final completer = _completers.remove(item.id);
        completer?.completeError(e);
      }
    }
  }

  /// Force process current batch
  Future<void> flush() async {
    await _processBatch();
  }

  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    for (final completer in _completers.values) {
      if (!completer.isCompleted) {
        completer.completeError('Batch processor disposed');
      }
    }
    _completers.clear();
    _pendingItems.clear();
  }
}

class BatchItem {
  final String id;
  final Map<String, dynamic> data;

  BatchItem({
    required this.id,
    required this.data,
  });
}

/// Translation Batch Processor
class TranslationBatchProcessor {
  static final BatchProcessor<String> _instance = BatchProcessor<String>(
    batchWindow: const Duration(milliseconds: 300),
    maxBatchSize: 20,
    processor: _processTranslations,
  );

  static Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) {
    return _instance.add(BatchItem(
      id: '${sourceLang}_${targetLang}_${text.hashCode}',
      data: {
        'text': text,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
      },
    ));
  }

  static Future<List<String>> _processTranslations(List<BatchItem> items) async {
    // Group by language pair
    final groups = <String, List<BatchItem>>{};
    for (final item in items) {
      final key = '${item.data['sourceLang']}_${item.data['targetLang']}';
      groups.putIfAbsent(key, () => []).add(item);
    }

    final results = <String>[];
    
    // Process each group
    for (final group in groups.values) {
      // In a real implementation, this would call the translation API
      // with all items in the batch
      for (final item in group) {
        // For now, return placeholder
        // This would be replaced with actual batch API call
        results.add(item.data['text'] as String);
      }
    }

    return results;
  }

  static void dispose() {
    _instance.dispose();
  }
}

