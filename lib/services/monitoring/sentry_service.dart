import 'package:sentry_flutter/sentry_flutter.dart';

/// Lightweight Sentry wrapper used by services.
///
/// Keeps callsites stable (`SentryService().captureException(...)`) while using
/// `sentry_flutter` under the hood.
class SentryService {
  Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (context != null) {
          context.forEach((k, v) => scope.setContexts(k, {'value': v}));
        }
      },
    );
  }
}

