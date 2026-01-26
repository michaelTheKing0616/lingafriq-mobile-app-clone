/// Request Batching Utility
/// Batches multiple API requests into single calls for efficiency
/// 
/// Features:
/// - Automatic batching
/// - Configurable batch size
/// - Batch timeout
/// - Error handling
/// - Retry logic
/// 
/// Production-ready implementation (December 2025)

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lingafriq/utils/structured_logger.dart';

/// Batch request item
class BatchRequestItem {
  final String id;
  final String method; // GET, POST, PUT, DELETE, PATCH
  final String endpoint;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? queryParameters;
  final Completer<Response> completer;

  BatchRequestItem({
    required this.id,
    required this.method,
    required this.endpoint,
    this.data,
    this.queryParameters,
    required this.completer,
  });
}

/// Request Batcher
class RequestBatcher {
  final Dio dio;
  final int maxBatchSize;
  final Duration batchTimeout;
  final List<BatchRequestItem> _queue = [];
  Timer? _batchTimer;
  bool _isProcessing = false;
  bool? _batchEndpointAvailable; // lazily detected

  RequestBatcher({
    required this.dio,
    this.maxBatchSize = 50,
    this.batchTimeout = const Duration(milliseconds: 100),
  });

  /// Add request to batch
  Future<Response> addRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<Response>();
    
    final item = BatchRequestItem(
      id: id,
      method: method,
      endpoint: endpoint,
      data: data,
      queryParameters: queryParameters,
      completer: completer,
    );

    _queue.add(item);
    _scheduleBatch();

    return completer.future;
  }

  /// Schedule batch processing
  void _scheduleBatch() {
    // If queue is full, process immediately
    if (_queue.length >= maxBatchSize) {
      _processBatch();
      return;
    }

    // Otherwise, schedule with timeout
    _batchTimer?.cancel();
    _batchTimer = Timer(batchTimeout, () {
      if (_queue.isNotEmpty) {
        _processBatch();
      }
    });
  }

  /// Process batch of requests
  Future<void> _processBatch() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    _batchTimer?.cancel();

    final batch = List<BatchRequestItem>.from(_queue);
    _queue.clear();

    try {
      logger.debug('Processing batch of ${batch.length} requests');

      // Group requests by method and endpoint pattern
      final grouped = _groupRequests(batch);

      // Process each group
      for (final group in grouped.values) {
        await _processGroup(group);
      }

      logger.info('Batch processing completed: ${batch.length} requests');
    } catch (e) {
      logger.error('Batch processing failed', error: e);
      // Fail all requests in batch
      for (final item in batch) {
        if (!item.completer.isCompleted) {
          item.completer.completeError(e);
        }
      }
    } finally {
      _isProcessing = false;
      
      // Process remaining items if any
      if (_queue.isNotEmpty) {
        _scheduleBatch();
      }
    }
  }

  /// Group requests by method and endpoint pattern
  Map<String, List<BatchRequestItem>> _groupRequests(List<BatchRequestItem> batch) {
    final groups = <String, List<BatchRequestItem>>{};

    for (final item in batch) {
      // Group by method and base endpoint (without query params)
      final baseEndpoint = item.endpoint.split('?').first;
      final key = '${item.method}:$baseEndpoint';
      
      groups.putIfAbsent(key, () => []).add(item);
    }

    return groups;
  }

  /// Process a group of similar requests
  Future<void> _processGroup(List<BatchRequestItem> group) async {
    if (group.isEmpty) return;

    final first = group.first;

    // For GET requests, can batch into single request with multiple IDs
    if (first.method == 'GET' && group.length > 1) {
      await _processBatchGet(group);
    } else {
      // For other methods, process individually or use batch endpoint if available
      await _processIndividual(group);
    }
  }

  /// Process batch GET requests
  Future<void> _processBatchGet(List<BatchRequestItem> group) async {
    try {
      // If we already detected the endpoint is unavailable, skip the attempt.
      if (_batchEndpointAvailable == false) {
        await _processIndividual(group);
        return;
      }

      // Extract IDs from endpoints (assuming RESTful API with IDs)
      final ids = group.map((item) {
        final parts = item.endpoint.split('/');
        return parts.last;
      }).toList();

      // Make batch request (assuming backend supports /batch endpoint)
      final response = await dio.post(
        '/api/v1/batch',
        data: {
          'requests': group.map((item) => {
            'method': item.method,
            'endpoint': item.endpoint,
            'queryParameters': item.queryParameters,
          }).toList(),
        },
      );

      // Distribute responses
      if (response.data is Map && response.data['responses'] != null) {
        _batchEndpointAvailable = true;
        final responses = response.data['responses'] as List;
        for (int i = 0; i < group.length && i < responses.length; i++) {
          final item = group[i];
          final responseData = responses[i];
          
          // Create response object
          final itemResponse = Response(
            data: responseData['data'],
            statusCode: responseData['statusCode'] ?? 200,
            requestOptions: RequestOptions(path: item.endpoint),
          );
          
          if (!item.completer.isCompleted) {
            item.completer.complete(itemResponse);
          }
        }
      }
    } catch (e) {
      // Fallback to individual requests
      logger.warn('Batch GET failed, falling back to individual requests', error: e);
      _batchEndpointAvailable = false;
      await _processIndividual(group);
    }
  }

  /// Process requests individually
  Future<void> _processIndividual(List<BatchRequestItem> group) async {
    await Future.wait(
      group.map((item) => _processItem(item)),
      eagerError: false,
    );
  }

  /// Process individual request item
  Future<void> _processItem(BatchRequestItem item) async {
    try {
      Response response;

      switch (item.method.toUpperCase()) {
        case 'GET':
          response = await dio.get(
            item.endpoint,
            queryParameters: item.queryParameters,
          );
          break;
        case 'POST':
          response = await dio.post(
            item.endpoint,
            data: item.data,
            queryParameters: item.queryParameters,
          );
          break;
        case 'PUT':
          response = await dio.put(
            item.endpoint,
            data: item.data,
            queryParameters: item.queryParameters,
          );
          break;
        case 'PATCH':
          response = await dio.patch(
            item.endpoint,
            data: item.data,
            queryParameters: item.queryParameters,
          );
          break;
        case 'DELETE':
          response = await dio.delete(
            item.endpoint,
            data: item.data,
            queryParameters: item.queryParameters,
          );
          break;
        default:
          throw Exception('Unsupported method: ${item.method}');
      }

      if (!item.completer.isCompleted) {
        item.completer.complete(response);
      }
    } catch (e) {
      if (!item.completer.isCompleted) {
        item.completer.completeError(e);
      }
    }
  }

  /// Get batch statistics
  Map<String, dynamic> getStatistics() {
    return {
      'queueSize': _queue.length,
      'isProcessing': _isProcessing,
      'maxBatchSize': maxBatchSize,
      'batchTimeoutMs': batchTimeout.inMilliseconds,
    };
  }

  /// Clear batch queue
  void clear() {
    _queue.clear();
    _batchTimer?.cancel();
  }
}

/// Global request batcher instance
RequestBatcher? _globalBatcher;

/// Initialize global request batcher
void initRequestBatcher(Dio dio, {int? maxBatchSize, Duration? batchTimeout}) {
  _globalBatcher = RequestBatcher(
    dio: dio,
    maxBatchSize: maxBatchSize ?? 50,
    batchTimeout: batchTimeout ?? const Duration(milliseconds: 100),
  );
}

/// Get global request batcher
RequestBatcher? getRequestBatcher() => _globalBatcher;

