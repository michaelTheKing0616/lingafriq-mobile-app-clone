import 'dart:io';
import 'package:dio/dio.dart';

class TransportErrorPolicy {
  TransportErrorPolicy._();

  /// True when the device genuinely has no network connectivity (DNS failure,
  /// airplane mode, Wi-Fi off, etc.). Does NOT include cases where the device
  /// has internet but the specific server is unreachable.
  static bool isNetworkIssue(DioException error) {
    // Only connectionError type can be a true network issue
    if (error.type != DioExceptionType.connectionError) return false;

    final message = (error.message ?? error.toString()).toLowerCase();
    final errorStr = (error.error?.toString() ?? '').toLowerCase();
    final combined = '$message $errorStr';

    // These patterns indicate the device itself has no connectivity
    return combined.contains('failed host lookup') ||
        combined.contains('name resolution') ||
        combined.contains('network is unreachable') ||
        combined.contains('no address associated') ||
        combined.contains('no route to host') ||
        combined.contains('network unreachable') ||
        combined.contains('errno = 101') || // ENETUNREACH on Linux/Android
        combined.contains('errno = 7');     // No address associated
  }

  /// True when the device has internet but the backend server specifically is
  /// unreachable, timing out, or returning 5xx errors.
  static bool isBackendIssue(DioException error) {
    final statusCode = error.response?.statusCode;

    // All timeout types indicate backend unreachability
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    // Server-side errors
    if (statusCode != null && statusCode >= 500) {
      return true;
    }

    // connectionError that is NOT a network issue is a backend issue
    // (e.g. connection refused, connection reset, SSL handshake failure)
    if (error.type == DioExceptionType.connectionError && !isNetworkIssue(error)) {
      return true;
    }

    // Bad certificate usually means server config issue, not network
    if (error.type == DioExceptionType.badCertificate) {
      return true;
    }

    // Unknown errors with SocketException that aren't network issues
    if (error.type == DioExceptionType.unknown) {
      final inner = error.error;
      if (inner is SocketException) {
        // Check if it's specifically a network issue or a server issue
        final msg = inner.toString().toLowerCase();
        if (msg.contains('connection refused') ||
            msg.contains('connection reset') ||
            msg.contains('connection closed') ||
            msg.contains('broken pipe') ||
            msg.contains('software caused connection abort') ||
            msg.contains('handshake')) {
          return true;
        }
      }
    }

    return false;
  }

  /// Whether a DioException is retryable (network, timeout, 5xx, 429, unknown).
  /// Use this in retry interceptors/helpers instead of manual DioExceptionType checks.
  static bool isRetryable(DioException error) {
    if (isNetworkIssue(error)) return true;
    if (isBackendIssue(error)) return true;
    if (error.type == DioExceptionType.unknown) return true;
    final statusCode = error.response?.statusCode;
    if (statusCode == 429) return true;
    // 4xx client errors (except 429) are NOT retryable
    if (statusCode != null && statusCode >= 400 && statusCode < 500) return false;
    return false;
  }

  static String toUserMessage(DioException error) {
    // Check backend issue FIRST — many connection errors are server-side, not
    // network-side. Previous order caused "no internet" for server-down cases.
    if (isBackendIssue(error)) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return 'Server is temporarily unavailable. Your data is saved locally and will sync when the server is back online.';
      }
      if (error.type == DioExceptionType.badCertificate) {
        return 'Could not verify server security certificate. Please update the app or try again later.';
      }
      return 'Cannot connect to the LingAfriq server. The server may be temporarily down — please try again shortly.';
    }

    if (isNetworkIssue(error)) {
      return 'No internet connection. Please check your network settings.';
    }

    if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) return 'Authentication failed. Please log in again.';
      if (statusCode == 403) return 'You don\'t have permission to perform this action.';
      if (statusCode == 404) return 'The requested resource was not found.';
      if (statusCode == 429) {
        final retryAfter = error.response?.headers.value('retry-after');
        if (retryAfter != null) {
          final seconds = int.tryParse(retryAfter) ?? 60;
          final minutes = (seconds / 60).ceil();
          return 'Please slow down. Try again in $minutes minute${minutes > 1 ? 's' : ''}.';
        }
        return 'You\'re making requests too quickly. Please wait a moment and try again.';
      }
      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        final data = error.response?.data;
        if (data is Map) {
          final msg = data['message'] ?? data['error'] ?? data['detail'];
          if (msg is String && msg.trim().isNotEmpty) return msg.trim();
        }
        return 'Request failed. Please try again.';
      }
      return 'Server error. Please try again later.';
    }

    if (error.type == DioExceptionType.cancel) return 'Request was cancelled.';

    return 'Unable to reach server. Please try again.';
  }
}
