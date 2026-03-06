String normalizeApiId(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is num) return value.toString();
  return value.toString().trim();
}

String firstNonEmptyId(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = normalizeApiId(json[key]);
    if (value.isNotEmpty) return value;
  }
  return '';
}
