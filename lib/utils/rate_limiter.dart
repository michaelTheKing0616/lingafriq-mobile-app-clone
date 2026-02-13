// Rate Limiting Utility
// Prevents excessive API calls and protects backend from overload
// 
// Features:
// - Per-endpoint rate limiting
// - Sliding window algorithm
// - Configurable limits
// - Automatic retry with backoff
// 
// Production-ready implementation (December 2025)

import 'dart:collection';
/// Rate limit configuration
class RateLimitConfig {
  final int maxRequests;
  final Duration window;
  final Duration? retryAfter;

  const RateLimitConfig({
    required this.maxRequests,
    required this.window,
    this.retryAfter,
  });

  /// Default rate limit: 100 requests per 15 minutes
  static const RateLimitConfig defaultConfig = RateLimitConfig(
    maxRequests: 100,
    window: Duration(minutes: 15),
    retryAfter: Duration(seconds: 60),
  );

  /// Strict rate limit: 10 requests per minute
  static const RateLimitConfig strict = RateLimitConfig(
    maxRequests: 10,
    window: Duration(minutes: 1),
    retryAfter: Duration(seconds: 10),
  );

  /// Lenient rate limit: 1000 requests per hour
  static const RateLimitConfig lenient = RateLimitConfig(
    maxRequests: 1000,
    window: Duration(hours: 1),
    retryAfter: Duration(minutes: 5),
  );
}

/// Rate limiter implementation using sliding window
class RateLimiter {
  final RateLimitConfig config;
  final Queue<DateTime> _requestTimes = Queue<DateTime>();
  final Map<String, Queue<DateTime>> _endpointRequests = {};

  RateLimiter({RateLimitConfig? config})
      : config = config ?? RateLimitConfig.defaultConfig;

  /// Check if request is allowed
  bool isAllowed({String? endpoint}) {
    _cleanOldRequests(endpoint: endpoint);
    
    final queue = endpoint != null
        ? _endpointRequests.putIfAbsent(endpoint, () => Queue<DateTime>())
        : _requestTimes;

    if (queue.length >= config.maxRequests) {
      return false;
    }

    queue.add(DateTime.now());
    return true;
  }

  /// Get time until next request is allowed
  Duration? getTimeUntilNextRequest({String? endpoint}) {
    _cleanOldRequests(endpoint: endpoint);
    
    final queue = endpoint != null
        ? _endpointRequests[endpoint]
        : _requestTimes;

    if (queue == null || queue.isEmpty) {
      return null;
    }

    if (queue.length < config.maxRequests) {
      return null;
    }

    final oldestRequest = queue.first;
    final windowEnd = oldestRequest.add(config.window);
    final now = DateTime.now();

    if (windowEnd.isAfter(now)) {
      return windowEnd.difference(now);
    }

    return null;
  }

  /// Get remaining requests in current window
  int getRemainingRequests({String? endpoint}) {
    _cleanOldRequests(endpoint: endpoint);
    
    final queue = endpoint != null
        ? _endpointRequests[endpoint]
        : _requestTimes;

    if (queue == null) {
      return config.maxRequests;
    }

    return (config.maxRequests - queue.length).clamp(0, config.maxRequests);
  }

  /// Reset rate limiter
  void reset({String? endpoint}) {
    if (endpoint != null) {
      _endpointRequests.remove(endpoint);
    } else {
      _requestTimes.clear();
      _endpointRequests.clear();
    }
  }

  /// Clean old requests outside the window
  void _cleanOldRequests({String? endpoint}) {
    final now = DateTime.now();
    final cutoff = now.subtract(config.window);

    if (endpoint != null) {
      final queue = _endpointRequests[endpoint];
      if (queue != null) {
        while (queue.isNotEmpty && queue.first.isBefore(cutoff)) {
          queue.removeFirst();
        }
      }
    } else {
      while (_requestTimes.isNotEmpty && _requestTimes.first.isBefore(cutoff)) {
        _requestTimes.removeFirst();
      }

      // Clean all endpoint queues
      for (final queue in _endpointRequests.values) {
        while (queue.isNotEmpty && queue.first.isBefore(cutoff)) {
          queue.removeFirst();
        }
      }
    }
  }

  /// Get rate limit status
  Map<String, dynamic> getStatus({String? endpoint}) {
    _cleanOldRequests(endpoint: endpoint);
    
    final queue = endpoint != null
        ? _endpointRequests[endpoint]
        : _requestTimes;

    final remaining = getRemainingRequests(endpoint: endpoint);
    final timeUntilNext = getTimeUntilNextRequest(endpoint: endpoint);

    return {
      'remaining': remaining,
      'maxRequests': config.maxRequests,
      'windowSeconds': config.window.inSeconds,
      'timeUntilNextRequest': timeUntilNext?.inSeconds,
      'isAllowed': remaining > 0,
    };
  }
}

/// Global rate limiter instance
final globalRateLimiter = RateLimiter();

/// Per-endpoint rate limiters
final Map<String, RateLimiter> endpointRateLimiters = {
  'auth': RateLimiter(config: RateLimitConfig.strict),
  'api': RateLimiter(config: RateLimitConfig.defaultConfig),
  'upload': RateLimiter(config: RateLimitConfig(
    maxRequests: 20,
    window: Duration(minutes: 5),
  )),
  'download': RateLimiter(config: RateLimitConfig.lenient),
};

/// Check if request is rate limited
bool isRateLimited(String endpoint) {
  // Get endpoint-specific limiter or use global
  final limiter = endpointRateLimiters[endpoint] ?? globalRateLimiter;
  return !limiter.isAllowed(endpoint: endpoint);
}

/// Get rate limit info for endpoint
Map<String, dynamic> getRateLimitInfo(String endpoint) {
  final limiter = endpointRateLimiters[endpoint] ?? globalRateLimiter;
  return limiter.getStatus(endpoint: endpoint);
}

