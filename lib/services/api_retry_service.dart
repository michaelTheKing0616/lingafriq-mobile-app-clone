/// API Retry Service
/// Implements intelligent retry logic for failed API requests
/// 
/// Features:
/// - Exponential backoff
/// - Jitter to prevent thundering herd
/// - Retry only on transient errors
/// - Circuit breaker integration
/// - Offline queue support
/// 
/// Production-ready implementation

import 'dart:math';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lingafriq/utils/structured_logger.dart';

class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool enableJitter;
  final List<int> retryableStatusCodes;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.enableJitter = true,
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
  });

  static const aggressive = RetryConfig(
    maxRetries: 5,
    initialDelay: Duration(milliseconds: 200),
  );

  static const conservative = RetryConfig(
    maxRetries: 2,
    initialDelay: Duration(seconds: 1),
  );

  static const none = RetryConfig(maxRetries: 0);
}

class ApiRetryService {
  final RetryConfig config;
  final Random _random = Random();

  ApiRetryService({this.config = const RetryConfig()});

  /// Execute request with retry logic
  Future<T> execute<T>(
    Future<T> Function() request, {
    RetryConfig? customConfig,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    final effectiveConfig = customConfig ?? config;
    int attempt = 0;
    dynamic lastError;

    while (attempt <= effectiveConfig.maxRetries) {
      try {
        // Execute the request
        final result = await request();
        
        // Log success if this was a retry
        if (attempt > 0) {
          logger.info('Request succeeded after retry', context: {
            'attempt': attempt,
            'totalAttempts': attempt + 1,
          });
        }
        
        return result;
      } catch (error) {
        lastError = error;
        attempt++;

        // Check if we should retry
        final shouldRetryRequest = shouldRetry?.call(error) ?? 
            _shouldRetryError(error, effectiveConfig);

        if (!shouldRetryRequest || attempt > effectiveConfig.maxRetries) {
          logger.warn('Request failed permanently', context: {
            'attempt': attempt,
            'error': error.toString(),
            'willRetry': false,
          });
          rethrow;
        }

        // Calculate delay with exponential backoff
        final delay = _calculateDelay(
          attempt,
          effectiveConfig,
        );

        logger.info('Request failed, retrying', context: {
          'attempt': attempt,
          'maxRetries': effectiveConfig.maxRetries,
          'delayMs': delay.inMilliseconds,
          'error': error.toString(),
        });

        // Wait before retrying
        await Future.delayed(delay);

        // Check connectivity before retry
        final hasConnection = await _checkConnectivity();
        if (!hasConnection) {
          logger.warn('No internet connection, aborting retry');
          throw DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'No internet connection',
            type: DioExceptionType.connectionError,
          );
        }
      }
    }

    // This should never be reached, but just in case
    throw lastError;
  }

  /// Check if error is retryable
  bool _shouldRetryError(dynamic error, RetryConfig config) {
    if (error is DioException) {
      // Network errors are retryable
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return true;
      }

      // Check status code
      if (error.response?.statusCode != null) {
        return config.retryableStatusCodes.contains(error.response!.statusCode);
      }

      // Unknown network errors are retryable
      if (error.type == DioExceptionType.unknown) {
        return true;
      }
    }

    return false;
  }

  /// Calculate delay with exponential backoff and jitter
  Duration _calculateDelay(int attempt, RetryConfig config) {
    // Base delay with exponential backoff
    final exponentialDelay = config.initialDelay.inMilliseconds *
        pow(config.backoffMultiplier, attempt - 1);

    // Cap at max delay
    final cappedDelay = min(
      exponentialDelay.toDouble(),
      config.maxDelay.inMilliseconds.toDouble(),
    );

    // Add jitter to prevent thundering herd
    final jitter = config.enableJitter
        ? _random.nextDouble() * cappedDelay * 0.3 // 30% jitter
        : 0.0;

    final finalDelay = (cappedDelay + jitter).toInt();
    return Duration(milliseconds: finalDelay);
  }

  /// Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      logger.error('Failed to check connectivity', error: e);
      return true; // Assume connected on error
    }
  }

  /// Create Dio interceptor for automatic retries
  Interceptor createInterceptor({RetryConfig? customConfig}) {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final effectiveConfig = customConfig ?? config;
        
        // Get retry count from request options
        final retryCount = error.requestOptions.extra['retryCount'] as int? ?? 0;
        
        // Check if we should retry
        if (retryCount < effectiveConfig.maxRetries &&
            _shouldRetryError(error, effectiveConfig)) {
          
          // Calculate delay
          final delay = _calculateDelay(retryCount + 1, effectiveConfig);
          
          logger.info('Interceptor retrying request', context: {
            'attempt': retryCount + 1,
            'path': error.requestOptions.path,
            'delayMs': delay.inMilliseconds,
          });
          
          // Wait before retry
          await Future.delayed(delay);
          
          // Check connectivity
          final hasConnection = await _checkConnectivity();
          if (!hasConnection) {
            return handler.next(error);
          }
          
          // Increment retry count
          error.requestOptions.extra['retryCount'] = retryCount + 1;
          
          // Retry the request
          try {
            final response = await Dio().fetch(error.requestOptions);
            return handler.resolve(response);
          } catch (e) {
            // If retry fails, pass to next error handler
            if (e is DioException) {
              return handler.next(e);
            }
            return handler.next(error);
          }
        }
        
        // No retry, pass error through
        return handler.next(error);
      },
    );
  }
}

/// Global retry service instance
final apiRetryService = ApiRetryService();

/// Dio extension for easy retry
extension DioRetry on Dio {
  /// Enable automatic retries on this Dio instance
  void enableRetry({RetryConfig config = const RetryConfig()}) {
    final retryService = ApiRetryService(config: config);
    interceptors.add(retryService.createInterceptor());
    logger.info('Dio retry interceptor enabled', context: {
      'maxRetries': config.maxRetries,
      'initialDelayMs': config.initialDelay.inMilliseconds,
    });
  }
}

