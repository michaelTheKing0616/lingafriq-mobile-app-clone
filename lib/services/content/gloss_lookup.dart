/// Resolves gloss, IPA and minimal-pair data for [TargetText] long-press sheets.
class GlossLookup {
  GlossLookup({Future<TargetLexemeGloss?> Function(String lexemeId)? resolve})
      : _resolve = resolve;

  final Future<TargetLexemeGloss?> Function(String lexemeId)? _resolve;

  Future<TargetLexemeGloss?> lookup(String? lexemeId) async {
    if (lexemeId == null || lexemeId.trim().isEmpty) return null;
    final resolver = _resolve;
    if (resolver == null) return null;
    return resolver(lexemeId.trim());
  }

  /// Builds gloss data from a v2 lexeme JSON map (see `schemas/v2/content/lexeme.schema.json`).
  static TargetLexemeGloss? fromLexemeJson(Map<String, dynamic> json) {
    final senses = json['senses'];
    String? glossEn;
    if (senses is List && senses.isNotEmpty) {
      final first = senses.first;
      if (first is Map) {
        glossEn = first['gloss_en']?.toString();
      }
    }
    final ipa = json['ipa']?.toString();
    final pairs = <TargetMinimalPair>[];
    final rawPairs = json['minimal_pairs'];
    if (rawPairs is List) {
      for (final entry in rawPairs) {
        if (entry is String && entry.isNotEmpty) {
          pairs.add(TargetMinimalPair(lexemeId: entry, label: entry));
        }
      }
    }
    if (glossEn == null && (ipa == null || ipa.isEmpty) && pairs.isEmpty) {
      return null;
    }
    return TargetLexemeGloss(glossEn: glossEn, ipa: ipa, minimalPairs: pairs);
  }
}

class TargetLexemeGloss {
  const TargetLexemeGloss({
    this.glossEn,
    this.ipa,
    this.minimalPairs = const [],
  });

  final String? glossEn;
  final String? ipa;
  final List<TargetMinimalPair> minimalPairs;

  bool get isEmpty =>
      (glossEn == null || glossEn!.trim().isEmpty) &&
      (ipa == null || ipa!.trim().isEmpty) &&
      minimalPairs.isEmpty;
}

class TargetMinimalPair {
  const TargetMinimalPair({required this.lexemeId, this.label});

  final String lexemeId;
  final String? label;
}
