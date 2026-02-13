import 'package:dio/dio.dart';

class TransportErrorPolicy {
  TransportErrorPolicy._();

  static bool isNetworkIssue(DioException error) {
    if (error.type != DioExceptionType.connectionError) return false;
    final message = (error.message ?? error.toString()).toLowerCase();
    return message.contains('failed host lookup') ||
        message.contains('name resolution') ||
        message.contains('network is unreachable') ||
        message.contains('no route to host') ||
        message.contains('socketexception') ||
        message.contains('os error');
  }

  static bool isBackendIssue(DioException error) {
    final statusCode = error.response?.statusCode;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    if (statusCode != null && statusCode >= 500) {
      return true;
    }
    if (error.type == DioExceptionType.connectionError) {
      final message = (error.message ?? error.toString()).toLowerCase();
      return message.contains('connection refused') ||
          message.contains('connection reset') ||
          message.contains('connection closed');
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
    if (isBackendIssue(error)) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return 'Server is temporarily unavailable. Your data is saved locally and will sync when the server is back online.';
      }
      return 'Cannot connect to server. Please try again shortly.';
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
    if (error.type == DioExceptionType.badCertificate) {
      return 'Security certificate error. Please try again.';
    }
    return 'Unable to reach server. Please try again.';
  }
}
