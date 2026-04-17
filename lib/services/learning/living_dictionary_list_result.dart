/// List response from `GET /api/v2/learning/living-dictionary/entries` (includes [page.nextBefore]).
class LivingDictionaryListResult {
  final List<Map<String, dynamic>> entries;
  /// ISO timestamp cursor for the next page, or null when there are no more results.
  final String? nextBefore;
  /// `live` from API, `cache` when served from last successful response for this request URL.
  final String source;

  const LivingDictionaryListResult({
    required this.entries,
    this.nextBefore,
    this.source = 'live',
  });
}

/// Pure JSON parsing for list responses (no HTTP / I/O).
class LivingDictionaryListParse {
  LivingDictionaryListParse._();

  /// Server `page.nextBefore` (ISO cursor for pagination).
  static String? parsePageNextBefore(Map<String, dynamic> data) {
    final page = data['page'];
    if (page is! Map) return null;
    final nb = page['nextBefore'];
    if (nb == null) return null;
    final s = nb.toString().trim();
    return s.isEmpty ? null : s;
  }

  static LivingDictionaryListResult listResultFromApiBody(
    Map<String, dynamic> data, {
    String source = 'live',
  }) {
    final raw = data['entries'];
    final entries = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) entries.add(Map<String, dynamic>.from(e));
      }
    }
    return LivingDictionaryListResult(
      entries: entries,
      nextBefore: parsePageNextBefore(data),
      source: source,
    );
  }
}
