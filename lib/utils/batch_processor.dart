/// Batch Processor Utility
/// Processes items in batches for better performance and memory management
/// 
/// Features:
/// - Configurable batch size
/// - Progress reporting
/// - Error handling per batch
/// - Memory-efficient processing

import 'dart:async';
import 'dart:collection';
import 'dart:collection';

/// Batch processing result
class BatchProcessResult<T> {
  final int totalItems;
  final int processedItems;
  final int failedItems;
  final List<T> results;
  final List<BatchError> errors;
  final Duration totalDuration;

  BatchProcessResult({
    required this.totalItems,
    required this.processedItems,
    required this.failedItems,
    required this.results,
    required this.errors,
    required this.totalDuration,
  });

  bool get isComplete => processedItems + failedItems >= totalItems;
  double get successRate => totalItems > 0 ? processedItems / totalItems : 0.0;
}

/// Batch processing error
class BatchError {
  final int index;
  final dynamic item;
  final dynamic error;
  final StackTrace? stackTrace;

  BatchError({
    required this.index,
    required this.item,
    required this.error,
    this.stackTrace,
  });
}

/// Batch Processor
class BatchProcessor<T, R> {
  final int batchSize;
  final Future<R> Function(T item, int index) processor;
  final void Function(int processed, int total)? onProgress;
  final bool continueOnError;
  final Duration? delayBetweenBatches;

  BatchProcessor({
    this.batchSize = 10,
    required this.processor,
    this.onProgress,
    this.continueOnError = true,
    this.delayBetweenBatches,
  });

  /// Process all items in batches
  Future<BatchProcessResult<R>> processAll(List<T> items) async {
    final startTime = DateTime.now();
    final results = <R>[];
    final errors = <BatchError>[];
    int processedCount = 0;

    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.sublist(
        i,
        i + batchSize > items.length ? items.length : i + batchSize,
      );

      for (int j = 0; j < batch.length; j++) {
        final index = i + j;
        final item = batch[j];

        try {
          final result = await processor(item, index);
          results.add(result);
          processedCount++;
        } catch (error, stackTrace) {
          errors.add(BatchError(
            index: index,
            item: item,
            error: error,
            stackTrace: stackTrace,
          ));

          if (!continueOnError) {
            break;
          }
        }

        // Report progress
        onProgress?.call(processedCount + errors.length, items.length);
      }

      // Delay between batches if specified
      if (delayBetweenBatches != null && i + batchSize < items.length) {
        await Future.delayed(delayBetweenBatches!);
      }
    }

    final duration = DateTime.now().difference(startTime);

    return BatchProcessResult<R>(
      totalItems: items.length,
      processedItems: processedCount,
      failedItems: errors.length,
      results: results,
      errors: errors,
      totalDuration: duration,
    );
  }

  /// Process items with concurrency limit
  Future<BatchProcessResult<R>> processConcurrent(
    List<T> items, {
    int concurrency = 5,
  }) async {
    final startTime = DateTime.now();
    final results = <R>[];
    final errors = <BatchError>[];
    int processedCount = 0;
    final completer = Completer<BatchProcessResult<R>>();
    final queue = Queue<T>.from(items);
    final activeTasks = <Future<void>>[];

    Future<void> processNext() async {
      if (queue.isEmpty && activeTasks.isEmpty) {
        if (!completer.isCompleted) {
          final duration = DateTime.now().difference(startTime);
          completer.complete(BatchProcessResult<R>(
            totalItems: items.length,
            processedItems: processedCount,
            failedItems: errors.length,
            results: results,
            errors: errors,
            totalDuration: duration,
          ));
        }
        return;
      }

      if (queue.isEmpty) return;

      final item = queue.removeFirst();
      final index = items.length - queue.length - activeTasks.length - 1;

      late final Future<void> task;
      task = processor(item, index).then((result) {
        results.add(result);
        processedCount++;
        onProgress?.call(processedCount + errors.length, items.length);
        activeTasks.remove(task);
        processNext();
      }).catchError((error, stackTrace) {
        errors.add(BatchError(
          index: index,
          item: item,
          error: error,
          stackTrace: stackTrace,
        ));
        onProgress?.call(processedCount + errors.length, items.length);
        activeTasks.remove(task);

        if (continueOnError) {
          processNext();
        } else {
          if (!completer.isCompleted) {
            final duration = DateTime.now().difference(startTime);
            completer.complete(BatchProcessResult<R>(
              totalItems: items.length,
              processedItems: processedCount,
              failedItems: errors.length,
              results: results,
              errors: errors,
              totalDuration: duration,
            ));
          }
        }
      });

      activeTasks.add(task);

      // Start more tasks if we have capacity
      while (activeTasks.length < concurrency && queue.isNotEmpty) {
        processNext();
      }
    }

    // Start initial batch
    for (int i = 0; i < concurrency && i < items.length; i++) {
      processNext();
    }

    return completer.future;
  }
}

