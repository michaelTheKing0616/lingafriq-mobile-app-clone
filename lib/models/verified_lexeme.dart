/// Shared Verified Lexicon row (ADR-013 layer 1, P7-916).
class VerifiedLexeme {
  const VerifiedLexeme({
    required this.lexemeId,
    required this.language,
    required this.verificationStatus,
    required this.lemma,
    required this.standardOrthography,
    required this.exampleSentence,
    required this.audioUris,
    required this.raw,
  });

  final String lexemeId;
  final String language;
  final String verificationStatus;
  final String lemma;
  final String standardOrthography;
  final String? exampleSentence;
  final List<String> audioUris;
  final Map<String, dynamic> raw;

  factory VerifiedLexeme.fromApiJson(Map<String, dynamic> json) {
    final entry = (json['entry'] as Map?)?.cast<String, dynamic>() ??
        json.cast<String, dynamic>();
    final orthography =
        (entry['orthography'] as Map?)?.cast<String, dynamic>() ?? const {};
    final senses = (entry['senses'] as List?) ?? const [];
    String? example;
    if (senses.isNotEmpty) {
      final first = senses.first;
      if (first is Map) {
        example = first['example_target'] as String? ??
            first['gloss_en'] as String?;
      }
    }
    final audio = (entry['audio'] as List?) ?? const [];
    final uris = <String>[];
    for (final clip in audio) {
      if (clip is Map) {
        final uri = clip['uri'];
        if (uri is String && uri.isNotEmpty) {
          uris.add(uri);
        }
      }
    }
    return VerifiedLexeme(
      lexemeId: (json['lexeme_id'] ?? entry['id'] ?? '').toString(),
      language: (json['language'] ?? _languageFromId(entry['id'])).toString(),
      verificationStatus: (json['verification_status'] ?? entry['label'] ?? '')
          .toString(),
      lemma: (entry['lemma'] ?? '').toString(),
      standardOrthography: (orthography['standard'] ?? entry['lemma'] ?? '')
          .toString(),
      exampleSentence: example,
      audioUris: uris,
      raw: entry,
    );
  }

  static String _languageFromId(Object? id) {
    final text = id?.toString() ?? '';
    final match = RegExp(r'^([a-z]{2,3})\.lex\.').firstMatch(text);
    return match?.group(1) ?? '';
  }
}
