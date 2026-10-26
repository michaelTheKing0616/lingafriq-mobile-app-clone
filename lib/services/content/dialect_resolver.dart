import 'package:lingafriq/models/dialect_preference.dart';

/// Resolves standard vs regional content using the learner's dialect preference (P4-116).
class DialectResolver {
  final Map<String, String> dialectLabels;

  const DialectResolver({required this.dialectLabels});

  static String normalizeTag(String? tag) {
    final t = tag?.trim().toLowerCase() ?? '';
    if (t.isEmpty) return DialectPreference.standardDialectId;
    return t;
  }

  /// Picks a regional row when [preferredDialectId] matches; otherwise [standardEntry].
  DialectResolveResult resolve({
    required String preferredDialectId,
    required Map<String, dynamic> standardEntry,
    required List<Map<String, dynamic>> regionalVariants,
  }) {
    final pref = DialectPreference.migrateStoredTag(
      standardEntry['umbrella_language']?.toString() ?? '',
      preferredDialectId,
    );
    if (pref != DialectPreference.standardDialectId) {
      for (final variant in regionalVariants) {
        final tag = normalizeTag(variant['dialect_tag']?.toString());
        if (tag == pref) {
          return DialectResolveResult(
            entry: Map<String, dynamic>.from(variant),
            usedPreferredDialect: true,
            uiDialectLabel: dialectLabels[tag],
            preferredDialectId: pref,
          );
        }
      }
    }

    final fallbackLabel = pref != DialectPreference.standardDialectId
        ? dialectLabels[pref]
        : null;

    return DialectResolveResult(
      entry: Map<String, dynamic>.from(standardEntry),
      usedPreferredDialect: false,
      uiDialectLabel: fallbackLabel,
      preferredDialectId: pref,
    );
  }
}

class DialectResolveResult {
  final Map<String, dynamic> entry;
  final bool usedPreferredDialect;
  final String? uiDialectLabel;
  final String preferredDialectId;

  const DialectResolveResult({
    required this.entry,
    required this.usedPreferredDialect,
    required this.uiDialectLabel,
    required this.preferredDialectId,
  });
}
