import 'package:flutter/foundation.dart' show visibleForTesting;

/// Timeout for lesson/quiz API calls to avoid endless loading.
const apiLessonReceiveTimeout = Duration(seconds: 30);

const apiUserContentBase = '/api/user-content';

@visibleForTesting
Map<String, dynamic>? apiCoerceMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

@visibleForTesting
List<dynamic> apiExtractListPayload(dynamic payload) {
  if (payload is List) return payload;
  final map = apiCoerceMap(payload);
  if (map == null) return const [];
  final candidates = [
    map['result'],
    map['results'],
    map['data'],
    map['items'],
  ];
  for (final candidate in candidates) {
    if (candidate is List) return candidate;
  }
  return const [];
}

int apiCoerceInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return fallback;
}

bool? apiCoerceNullableBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}
