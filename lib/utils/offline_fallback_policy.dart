import 'package:dio/dio.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';

enum OfflineFallbackReason {
  /// Device genuinely has no connectivity (DNS failure, airplane mode, etc.)
  noInternet,

  /// Backend is unreachable / timing out / returning 5xx.
  backendUnavailable,
}

class OfflineFallbackDecision {
  final bool shouldQueue;
  final OfflineFallbackReason? reason;
  final String? userMessage;

  const OfflineFallbackDecision._({
    required this.shouldQueue,
    required this.reason,
    required this.userMessage,
  });

  const OfflineFallbackDecision.doNotQueue({String? userMessage})
      : this._(shouldQueue: false, reason: null, userMessage: userMessage);

  const OfflineFallbackDecision.queue({
    required OfflineFallbackReason reason,
    required String userMessage,
  }) : this._(shouldQueue: true, reason: reason, userMessage: userMessage);
}

/// Policy: Only queue “offline-first” operations when the failure is a transport
/// failure (no internet) or a backend reachability failure (timeouts, 5xx, TLS),
/// not for 4xx client errors.
class OfflineFallbackPolicy {
  OfflineFallbackPolicy._();

  static OfflineFallbackDecision decide(Object error) {
    if (error is! DioException) {
      return const OfflineFallbackDecision.doNotQueue();
    }

    // 4xx responses are not offline; show the real user-facing message.
    final status = error.response?.statusCode;
    if (status != null && status >= 400 && status < 500 && status != 429) {
      return OfflineFallbackDecision.doNotQueue(
        userMessage: TransportErrorPolicy.toUserMessage(error),
      );
    }

    if (TransportErrorPolicy.isNetworkIssue(error)) {
      return const OfflineFallbackDecision.queue(
        reason: OfflineFallbackReason.noInternet,
        userMessage:
            'Saved offline. We’ll sync it automatically when you’re back online.',
      );
    }

    if (TransportErrorPolicy.isBackendIssue(error)) {
      return const OfflineFallbackDecision.queue(
        reason: OfflineFallbackReason.backendUnavailable,
        userMessage:
            'Saved for retry. The server looks temporarily unavailable — we’ll sync it automatically soon.',
      );
    }

    // Unknown: don’t claim offline.
    return OfflineFallbackDecision.doNotQueue(
      userMessage: TransportErrorPolicy.toUserMessage(error),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';

enum OfflineFallbackReason {
  /// Device genuinely has no connectivity (DNS failure, airplane mode, etc.)
  noInternet,

  /// Backend is unreachable / timing out / returning 5xx.
  backendUnavailable,
}

class OfflineFallbackDecision {
  final bool shouldQueue;
  final OfflineFallbackReason? reason;
  final String? userMessage;

  const OfflineFallbackDecision._({
    required this.shouldQueue,
    required this.reason,
    required this.userMessage,
  });

  const OfflineFallbackDecision.doNotQueue({String? userMessage})
      : this._(shouldQueue: false, reason: null, userMessage: userMessage);

  const OfflineFallbackDecision.queue({
    required OfflineFallbackReason reason,
    required String userMessage,
  }) : this._(shouldQueue: true, reason: reason, userMessage: userMessage);
}

/// Policy: Only queue “offline-first” operations when the failure is a transport
/// failure (no internet) or a backend reachability failure (timeouts, 5xx, TLS),
/// not for 4xx client errors.
class OfflineFallbackPolicy {
  OfflineFallbackPolicy._();

  static OfflineFallbackDecision decide(Object error) {
    if (error is! DioException) {
      return const OfflineFallbackDecision.doNotQueue();
    }

    // 4xx responses are not offline; show the real user-facing message.
    final status = error.response?.statusCode;
    if (status != null && status >= 400 && status < 500 && status != 429) {
      return OfflineFallbackDecision.doNotQueue(
        userMessage: TransportErrorPolicy.toUserMessage(error),
      );
    }

    if (TransportErrorPolicy.isNetworkIssue(error)) {
      return const OfflineFallbackDecision.queue(
        reason: OfflineFallbackReason.noInternet,
        userMessage: 'Saved offline. We’ll sync it automatically when you’re back online.',
      );
    }

    if (TransportErrorPolicy.isBackendIssue(error)) {
      return const OfflineFallbackDecision.queue(
        reason: OfflineFallbackReason.backendUnavailable,
        userMessage:
            'Saved for retry. The server looks temporarily unavailable — we’ll sync it automatically soon.',
      );
    }

    // Unknown: don’t claim offline.
    return OfflineFallbackDecision.doNotQueue(
      userMessage: TransportErrorPolicy.toUserMessage(error),
    );
  }
}

