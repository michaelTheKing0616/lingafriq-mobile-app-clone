import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Report of one crash or ANR. Email addresses and bearer tokens are removed
/// before this map is logged or handed to the transport.
class CrashReporter {
  CrashReporter({
    this.release = 'unknown',
    this.device = 'unknown',
    this.log,
  });

  static final CrashReporter instance = CrashReporter();
  static const anrChannel = MethodChannel('lingafriq/anr_exits');

  String release;
  String device;
  bool ready = false;
  String? diagnostic;
  void Function(String message)? log;

  /// Test stand-in for the Android exit-reason channel.
  Future<List<Map<String, Object>>> Function()? readPreviousAnrs;

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

  /// Previous Android ANR exits. iOS and Android before API 30 return none.
  Future<List<Map<String, Object>>> collectPreviousAnrs() async {
    final reader = readPreviousAnrs ?? _platformAnrs;
    List<Map<String, Object>> rows;
    try {
      rows = await reader();
    } catch (error) {
      log?.call('crash reporter failed to read anr exits: $error');
      return [];
    }
    return [
      for (final row in rows)
        reportAnr(
          row['description'] ?? 'anr',
          context: {
            if (row['timestamp'] is num) 'timestamp': row['timestamp'] as num,
          },
        ),
    ];
  }

  static Future<List<Map<String, Object>>> _platformAnrs() async {
    if (kIsWeb || !Platform.isAndroid) return [];
    final raw = await anrChannel.invokeMethod<List<dynamic>>('previousAnrs');
    if (raw == null) return [];
    return [
      for (final item in raw)
        if (item is Map)
          {
            for (final entry in item.entries)
              if (entry.key is String && (entry.value is String || entry.value is num))
                entry.key as String: entry.value as Object,
          },
    ];
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
