/// Canonical dialect preference ids (P4-116), aligned with [dialect_policy_decision.json].
class DialectPreference {
  final String umbrellaLanguage;
  final String preferredDialectId;

  const DialectPreference({
    required this.umbrellaLanguage,
    required this.preferredDialectId,
  });

  static const standardDialectId = 'standard';

  /// Current SharedPreferences key prefix (v1).
  static const prefsKeyPrefixV1 = 'learning_dialect_preferred_tag_v1_';

  /// Pre-v1 cache keys (no version segment).
  static const legacyPrefsKeyPrefix = 'learning_dialect_preferred_tag_';

  static String normalizeUmbrella(String umbrellaLanguage) =>
      umbrellaLanguage.trim().toLowerCase();

  static String prefsKeyV1(String umbrellaLanguage) =>
      '$prefsKeyPrefixV1${normalizeUmbrella(umbrellaLanguage)}';

  static String? legacyPrefsKey(String umbrellaLanguage) {
    final u = normalizeUmbrella(umbrellaLanguage);
    if (u.isEmpty) return null;
    return '$legacyPrefsKeyPrefix$u';
  }

  /// Maps stored user tags to canonical dialect ids (e.g. `lagos` → `yo-lagos`).
  static String migrateStoredTag(String umbrellaLanguage, String rawTag) {
    final umb = normalizeUmbrella(umbrellaLanguage);
    var tag = rawTag.trim().toLowerCase();
    if (tag.isEmpty) return standardDialectId;
    if (tag == standardDialectId) return standardDialectId;
    if (RegExp(r'^[a-z0-9_-]{2,64}$').hasMatch(tag) && tag.contains('-')) {
      return tag;
    }
    final suffix = tag.replaceAll(RegExp(r'[^a-z0-9_-]'), '');
    if (suffix.isEmpty) return standardDialectId;
    if (umb.isNotEmpty && !tag.startsWith('$umb-')) {
      return '$umb-$suffix';
    }
    return tag;
  }

  factory DialectPreference.fromStored({
    required String umbrellaLanguage,
    required String storedTag,
  }) {
    return DialectPreference(
      umbrellaLanguage: normalizeUmbrella(umbrellaLanguage),
      preferredDialectId: migrateStoredTag(umbrellaLanguage, storedTag),
    );
  }

  Map<String, dynamic> toApiMap() => {
        'umbrellaLanguage': umbrellaLanguage,
        'preferredDialectTag': preferredDialectId,
      };
}
