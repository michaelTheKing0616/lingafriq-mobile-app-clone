import 'package:lingafriq/screens/vocabulary/lexicon_entry_screen.dart';

/// Concept link field on verified lexeme payloads (server: lexiconConcept.service.ts).
const String kLexiconConceptIdField = 'concept_id';

/// Verified equivalent for Multilingual Relay (reads concept links, P7-927 AC3).
class RelayLexemeEquivalent {
  const RelayLexemeEquivalent({
    required this.languageCode,
    required this.lemma,
    required this.lexemeId,
    this.verified = true,
  });

  final String languageCode;
  final String lemma;
  final String lexemeId;
  final bool verified;
}

String? readConceptIdFromEntry(Map<String, dynamic> entry) {
  final raw = entry[kLexiconConceptIdField];
  if (raw == null) return null;
  final id = raw.toString().trim();
  return id.isEmpty ? null : id;
}

/// In-memory concept index built from verified lexicon rows (offline / pack sync).
class MultilingualRelayLexicon {
  MultilingualRelayLexicon._(this._byConcept);

  final Map<String, List<RelayLexemeEquivalent>> _byConcept;

  factory MultilingualRelayLexicon.fromVerifiedEntries(
    Iterable<Map<String, dynamic>> entries,
  ) {
    final byConcept = <String, List<RelayLexemeEquivalent>>{};
    for (final entry in entries) {
      final conceptId = readConceptIdFromEntry(entry);
      if (conceptId == null) continue;
      final lexemeId = (entry['id'] ?? entry['lexeme_id'] ?? '').toString().trim();
      final lang = _languageFromLexemeId(lexemeId) ??
          (entry['language'] ?? '').toString().trim().toLowerCase();
      final lemma = _lemmaFromEntry(entry);
      if (lexemeId.isEmpty || lang.isEmpty || lemma.isEmpty) continue;
      byConcept.putIfAbsent(conceptId, () => []).add(
            RelayLexemeEquivalent(
              languageCode: lang,
              lemma: lemma,
              lexemeId: lexemeId,
            ),
          );
    }
    return MultilingualRelayLexicon._(byConcept);
  }

  List<RelayLexemeEquivalent> equivalentsForConcept(
    String conceptId, {
    String? excludeLanguage,
  }) {
    final rows = _byConcept[conceptId.trim()] ?? const [];
    if (excludeLanguage == null) return List.unmodifiable(rows);
    final exclude = excludeLanguage.trim().toLowerCase();
    return rows.where((r) => r.languageCode != exclude).toList(growable: false);
  }

  /// Same resolution path as [SameIdeaView] / server `buildSameIdeaForEntry`.
  List<LexiconSameIdeaRow> sameIdeaRowsForEntry(Map<String, dynamic> entry) {
    final conceptId = readConceptIdFromEntry(entry);
    if (conceptId != null) {
      final sourceLang = _languageFromLexemeId(
            (entry['id'] ?? entry['lexeme_id'] ?? '').toString(),
          ) ??
          (entry['language'] ?? '').toString().trim().toLowerCase();
      return equivalentsForConcept(conceptId, excludeLanguage: sourceLang)
          .map(
            (eq) => LexiconSameIdeaRow(
              languageCode: eq.languageCode,
              languageLabel: languageLabelForCode(eq.languageCode),
              lemma: eq.lemma,
              lexemeId: eq.lexemeId,
              verified: eq.verified,
            ),
          )
          .toList(growable: false);
    }
    return parseSameIdeaInOtherLanguages(entry);
  }

  String? relayTargetLemma({
    required Map<String, dynamic> sourceEntry,
    required String targetLanguage,
  }) {
    final conceptId = readConceptIdFromEntry(sourceEntry);
    if (conceptId == null) return null;
    final lang = targetLanguage.trim().toLowerCase();
    final matches =
        equivalentsForConcept(conceptId).where((r) => r.languageCode == lang);
    if (matches.length != 1) return null;
    final match = matches.first;
    return match.verified ? match.lemma : null;
  }
}

String? _languageFromLexemeId(String lexemeId) {
  final match = RegExp(r'^([a-z]{2,3})\.lex\.').firstMatch(lexemeId.trim());
  return match?.group(1);
}

String _lemmaFromEntry(Map<String, dynamic> entry) {
  final ortho = entry['orthography'];
  if (ortho is Map) {
    final standard = ortho['standard']?.toString().trim();
    if (standard != null && standard.isNotEmpty) return standard;
  }
  return (entry['lemma'] ?? '').toString().trim();
}
