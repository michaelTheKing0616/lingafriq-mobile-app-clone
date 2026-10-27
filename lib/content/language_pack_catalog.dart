import 'dart:convert';

/// Describes one CMS language pack row from [pack_catalog.json].
class LanguagePackEntry {
  const LanguagePackEntry({
    required this.id,
    required this.languageKey,
    required this.displayName,
    required this.bundled,
    this.packUrl,
    this.sha256,
    this.sizeBytes,
  });

  final String id;
  final String languageKey;
  final String displayName;
  final bool bundled;
  final String? packUrl;
  final String? sha256;
  final int? sizeBytes;

  factory LanguagePackEntry.fromJson(Map<String, dynamic> json) {
    final size = json['sizeBytes'];
    return LanguagePackEntry(
      id: (json['id'] ?? '').toString(),
      languageKey: (json['languageKey'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      bundled: json['bundled'] == true,
      packUrl: json['packUrl']?.toString(),
      sha256: json['sha256']?.toString(),
      sizeBytes: size is num ? size.round() : int.tryParse('$size'),
    );
  }
}

class LanguagePackCatalog {
  LanguagePackCatalog({
    required this.schemaVersion,
    required this.chunkBytes,
    required this.coreLanguageIds,
    required this.languages,
  });

  final int schemaVersion;
  final int chunkBytes;
  final List<String> coreLanguageIds;
  final List<LanguagePackEntry> languages;

  LanguagePackEntry? entryForKey(String languageKey) {
    final key = languageKey.trim().toLowerCase();
    for (final row in languages) {
      if (row.languageKey == key) return row;
      if (key == 'pidgin' && row.languageKey == 'nigerian_pidgin') return row;
    }
    return null;
  }

  factory LanguagePackCatalog.fromJson(Map<String, dynamic> json) {
    final langs = (json['languages'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => LanguagePackEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final chunk = json['chunkBytes'];
    return LanguagePackCatalog(
      schemaVersion: (json['schemaVersion'] as num?)?.round() ?? 1,
      chunkBytes: chunk is num ? chunk.round() : 262144,
      coreLanguageIds: (json['coreLanguageIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      languages: langs,
    );
  }

  static LanguagePackCatalog parse(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return LanguagePackCatalog.fromJson(decoded);
  }
}
