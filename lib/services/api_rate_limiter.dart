// API Rate Limiter with Exponential Backoff
// Prevents excessive API calls and handles rate limiting gracefully
// 
// Features:
// - Client-side rate limiting per endpoint
// - Exponential backoff with jitter
// - Queue management for pending requests
// - Automatic retry with configurable limits
// - Persistent state across app restarts

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/structured_logger.dart';

/// Rate limiter configuration
class RateLimiterConfig {
  /// Maximum requests per time window
  final int maxRequests;
  
  /// Time window in milliseconds
  final int windowMs;
  
  /// Initial backoff delay in milliseconds
  final int initialBackoffMs;
  
  /// Maximum backoff delay in milliseconds
  final int maxBackoffMs;
  
  /// Maximum retry attempts
  final int maxRetries;
  
  /// Jitter factor (0.0 - 1.0) for randomizing backoff
  final double jitterFactor;

  const RateLimiterConfig({
    this.maxRequests = 60,
    this.windowMs = 60000, // 1 minute
    this.initialBackoffMs = 1000, // 1 second
    this.maxBackoffMs = 60000, // 1 minute
    this.maxRetries = 5,
    this.jitterFactor = 0.3,
  });

  /// Default config for translation endpoints
  static const translation = RateLimiterConfig(
    maxRequests: 30,
    windowMs: 60000,
    initialBackoffMs: 2000,
    maxBackoffMs: 30000,
    maxRetries: 3,
  );

  /// Default config for AI chat endpoints
  static const aiChat = RateLimiterConfig(
    maxRequests: 20,
    windowMs: 60000,
    initialBackoffMs: 3000,
    maxBackoffMs: 60000,
    maxRetries: 3,
  );

  /// Default config for general API endpoints
  static const general = RateLimiterConfig(
    maxRequests: 100,
    windowMs: 60000,
    initialBackoffMs: 1000,
    maxBackoffMs: 30000,
    maxRetries: 5,
  );
}

/// Result of a rate-limited operation
class RateLimitResult<T> {
  final T? data;
  final bool success;
  final String? error;
  final int retryCount;
  final int totalDelayMs;
  final bool rateLimited;

  RateLimitResult({
    this.data,
    this.success = false,
    this.error,
    this.retryCount = 0,
    this.totalDelayMs = 0,
    this.rateLimited = false,
  });

  factory RateLimitResult.success(T data, {int retryCount = 0, int totalDelayMs = 0}) {
    return RateLimitResult(
      data: data,
      success: true,
      retryCount: retryCount,
      totalDelayMs: totalDelayMs,
    );
  }

  factory RateLimitResult.error(String error, {bool rateLimited = false}) {
    return RateLimitResult(
      error: error,
      rateLimited: rateLimited,
    );
  }
}

/// API Rate Limiter with Exponential Backoff
class ApiRateLimiter {
  static final ApiRateLimiter _instance = ApiRateLimiter._internal();
  factory ApiRateLimiter() => _instance;
  ApiRateLimiter._internal();

  final Map<String, _EndpointState> _endpointStates = {};
  final Random _random = Random();
  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Initialize the rate limiter
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadState();
    _initialized = true;
  }

  /// Execute a rate-limited operation with automatic retry and backoff
  Future<RateLimitResult<T>> execute<T>({
    required String endpoint,
    required Future<T> Function() operation,
    RateLimiterConfig config = const RateLimiterConfig(),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    if (!_initialized) await initialize();

    final state = _getOrCreateState(endpoint, config);
    int retryCount = 0;
    int totalDelayMs = 0;

    // Check if we're currently rate limited
    if (state.isRateLimited) {
      final waitTime = state.rateLimitedUntil!.difference(DateTime.now()).inMilliseconds;
      if (waitTime > 0) {
        debugPrint('[$endpoint] Rate limited, waiting ${waitTime}ms');
        await Future.delayed(Duration(milliseconds: waitTime));
        totalDelayMs += waitTime;
      }
      state.clearRateLimit();
    }

    // Check request count within window
    if (!state.canMakeRequest(config)) {
      final waitTime = state.msUntilWindowReset;
      logger.debug('Request limit reached, waiting ${waitTime}ms', tag: 'rate-limiter', context: {'endpoint': endpoint});
      await Future.delayed(Duration(milliseconds: waitTime));
      totalDelayMs += waitTime;
      state.resetWindow();
    }

    // Execute with retry
    while (retryCount <= config.maxRetries) {
      try {
        state.recordRequest();
        final result = await operation();
        state.recordSuccess();
        await _saveState();
        return RateLimitResult.success(result, retryCount: retryCount, totalDelayMs: totalDelayMs);
      } catch (e) {
        final isRateLimitError = _isRateLimitError(e);
        final shouldRetryError = shouldRetry?.call(e) ?? _defaultShouldRetry(e);

        if (isRateLimitError) {
          // Server said we're rate limited
          state.applyRateLimit(Duration(milliseconds: config.maxBackoffMs));
          retryCount++;
          
          if (retryCount <= config.maxRetries) {
            final backoff = _calculateBackoff(retryCount, config);
            debugPrint('[$endpoint] Server rate limit, backing off ${backoff}ms (attempt $retryCount/${config.maxRetries})');
            await Future.delayed(Duration(milliseconds: backoff));
            totalDelayMs += backoff;
          }
        } else if (shouldRetryError && retryCount < config.maxRetries) {
          retryCount++;
          final backoff = _calculateBackoff(retryCount, config);
          logger.warn('Error, retrying in ${backoff}ms', tag: 'rate-limiter', context: {'endpoint': endpoint, 'attempt': retryCount, 'maxRetries': config.maxRetries}, error: e);
          await Future.delayed(Duration(milliseconds: backoff));
          totalDelayMs += backoff;
        } else {
          // Don't retry
          state.recordFailure();
          await _saveState();
          return RateLimitResult.error(
            e.toString(),
            rateLimited: isRateLimitError,
          );
        }
      }
    }

    await _saveState();
    return RateLimitResult.error(
      'Max retries exceeded',
      rateLimited: false,
    );
  }

  /// Calculate backoff with jitter
  int _calculateBackoff(int attempt, RateLimiterConfig config) {
    // Exponential backoff: initialBackoff * 2^(attempt-1)
    int backoff = config.initialBackoffMs * pow(2, attempt - 1).toInt();
    
    // Cap at max backoff
    backoff = min(backoff, config.maxBackoffMs);
    
    // Add jitter: +/- jitterFactor% of the backoff
    final jitter = (backoff * config.jitterFactor * (_random.nextDouble() * 2 - 1)).toInt();
    backoff += jitter;
    
    // Ensure positive
    return max(backoff, 100);
  }

  /// Check if an error is a rate limit error
  bool _isRateLimitError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('429') ||
           errorStr.contains('rate limit') ||
           errorStr.contains('too many requests') ||
           errorStr.contains('quota exceeded');
  }

  /// Default retry decision
  bool _defaultShouldRetry(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    // Retry on network errors and 5xx server errors
    return errorStr.contains('socket') ||
           errorStr.contains('timeout') ||
           errorStr.contains('network') ||
           errorStr.contains('500') ||
           errorStr.contains('502') ||
           errorStr.contains('503') ||
           errorStr.contains('504');
  }

  /// Get or create endpoint state
  _EndpointState _getOrCreateState(String endpoint, RateLimiterConfig config) {
    return _endpointStates.putIfAbsent(
      endpoint,
      () => _EndpointState(
        windowStartTime: DateTime.now(),
        requestsInWindow: 0,
        maxRequests: config.maxRequests,
        windowMs: config.windowMs,
      ),
    );
  }

  /// Load state from persistent storage
  Future<void> _loadState() async {
    try {
      final stateJson = _prefs?.getString('rate_limiter_state');
      if (stateJson != null) {
        final Map<String, dynamic> state = json.decode(stateJson);
        state.forEach((endpoint, data) {
          _endpointStates[endpoint] = _EndpointState.fromJson(data);
        });
      }
    } catch (e) {
      debugPrint('Failed to load rate limiter state: $e');
    }
  }

  /// Save state to persistent storage
  Future<void> _saveState() async {
    try {
      final state = _endpointStates.map((k, v) => MapEntry(k, v.toJson()));
      await _prefs?.setString('rate_limiter_state', json.encode(state));
    } catch (e) {
      logger.warn('Failed to save rate limiter state', tag: 'rate-limiter', error: e);
    }
  }

  /// Clear all rate limit state
  Future<void> clearState() async {
    _endpointStates.clear();
    await _prefs?.remove('rate_limiter_state');
  }

  /// Get current state for an endpoint
  Map<String, dynamic>? getEndpointState(String endpoint) {
    return _endpointStates[endpoint]?.toJson();
  }
}

/// Internal state for an endpoint
class _EndpointState {
  DateTime windowStartTime;
  int requestsInWindow;
  int maxRequests;
  int windowMs;
  DateTime? rateLimitedUntil;
  int successCount;
  int failureCount;

  _EndpointState({
    required this.windowStartTime,
    required this.requestsInWindow,
    required this.maxRequests,
    required this.windowMs,
    this.rateLimitedUntil,
    this.successCount = 0,
    this.failureCount = 0,
  });

  bool get isRateLimited => 
      rateLimitedUntil != null && DateTime.now().isBefore(rateLimitedUntil!);

  int get msUntilWindowReset {
    final elapsed = DateTime.now().difference(windowStartTime).inMilliseconds;
    return max(0, windowMs - elapsed);
  }

  bool canMakeRequest(RateLimiterConfig config) {
    // Check if window has expired
    if (DateTime.now().difference(windowStartTime).inMilliseconds >= windowMs) {
      resetWindow();
      return true;
    }
    return requestsInWindow < maxRequests;
  }

  void recordRequest() {
    requestsInWindow++;
  }

  void recordSuccess() {
    successCount++;
  }

  void recordFailure() {
    failureCount++;
  }

  void resetWindow() {
    windowStartTime = DateTime.now();
    requestsInWindow = 0;
  }

  void applyRateLimit(Duration duration) {
    rateLimitedUntil = DateTime.now().add(duration);
  }

  void clearRateLimit() {
    rateLimitedUntil = null;
  }

  Map<String, dynamic> toJson() => {
    'windowStartTime': windowStartTime.toIso8601String(),
    'requestsInWindow': requestsInWindow,
    'maxRequests': maxRequests,
    'windowMs': windowMs,
    'rateLimitedUntil': rateLimitedUntil?.toIso8601String(),
    'successCount': successCount,
    'failureCount': failureCount,
  };

  factory _EndpointState.fromJson(Map<String, dynamic> json) {
    return _EndpointState(
      windowStartTime: DateTime.parse(json['windowStartTime']),
      requestsInWindow: json['requestsInWindow'] ?? 0,
      maxRequests: json['maxRequests'] ?? 60,
      windowMs: json['windowMs'] ?? 60000,
      rateLimitedUntil: json['rateLimitedUntil'] != null 
          ? DateTime.parse(json['rateLimitedUntil']) 
          : null,
      successCount: json['successCount'] ?? 0,
      failureCount: json['failureCount'] ?? 0,
    );
  }
}
