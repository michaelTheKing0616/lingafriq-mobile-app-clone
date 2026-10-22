import 'dart:io';

/// Report of one crash or ANR. Email addresses and bearer tokens are removed
/// before this map is logged or handed to the transport.
class CrashReporter {
  CrashReporter({
    this.release = 'unknown',
    this.device = 'unknown',
    this.log,
  });

  static final CrashReporter instance = CrashReporter();

  String release;
  String device;
  bool ready = false;
  String? diagnostic;
  void Function(String message)? log;

  static const _secretKey = r'password|authorization|token|secret|cookie|email|prompt|phone|name';

  /// Starts the transport. A failure is logged and does not throw, so startup continues.
  Future<bool> initialize({
    String? release,
    String? device,
    Future<void> Function()? start,
  }) async {
    try {
      this.release = release ?? this.release;
      this.device = device ?? Platform.operatingSystem;
      if (start != null) await start();
      ready = true;
      diagnostic = null;
      return true;
    } catch (error) {
      ready = false;
      diagnostic = 'crash reporter failed to start';
      log?.call('$diagnostic: $error');
      return false;
    }
  }

  Map<String, Object> report(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object>? context,
    bool anr = false,
  }) {
    return {
      'release': release,
      'device': device,
      'kind': anr ? 'anr' : 'crash',
      'error': scrubText('$error'),
      if (stackTrace != null) 'stack': scrubText('$stackTrace'),
      'context': scrubContext(context ?? const {}),
    };
  }

  Map<String, Object> reportAnr(Object error, {Map<String, Object>? context}) {
    return report(error, context: context, anr: true);
  }

  static String scrubText(String value) {
    return value
        .replaceAll(
          RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false),
          '[redacted]',
        )
        .replaceAll(RegExp(r'Bearer\s+\S+', caseSensitive: false), 'Bearer [redacted]');
  }

  static Map<String, Object> scrubContext(Map<String, Object> context) {
    final kept = <String, Object>{};
    final secret = RegExp(_secretKey, caseSensitive: false);
    context.forEach((key, value) {
      if (secret.hasMatch(key)) return;
      if (value is String) {
        kept[key] = scrubText(value);
      } else if (value is num || value is bool) {
        kept[key] = value;
      }
    });
    return kept;
  }
}
