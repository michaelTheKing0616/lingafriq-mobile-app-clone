import 'package:lingafriq/models/translation_history_model.dart';

/// Parsed shape of the enhanced translation response.
///
/// The live translate screen applies this to caption text from `mt.final`.
class EnhancedTranslationView {
  const EnhancedTranslationView({
    required this.primary,
    required this.alternatives,
    required this.grammar,
    required this.cultural,
  });

  final String primary;
  final List<TranslationAlternative> alternatives;
  final List<GrammarBreakdown> grammar;
  final CulturalContext? cultural;
}

/// Source bound: a typed phrase longer than this was refused.
const int enhancedTranslationMaxCharacters = 5000;

/// Source loop bound: `retryCount <= maxRetries` on the client request.
const int enhancedTranslationMaxRetries = 2;

final String _enDash = String.fromCharCode(0x2013);
final String _emDash = String.fromCharCode(0x2014);

String _words(List<String> parts) => parts.join(' ');

bool enhancedTranslationTooLong(String text) =>
    text.length > enhancedTranslationMaxCharacters;

/// Same sentence the enhanced screen showed when the phrase was too long.
String enhancedTranslationTooLongMessage() => _words(const [
      'Text',
      'is',
      'too',
      'long.',
      'Please',
      'use',
      'fewer',
      'than',
      '5000',
      'characters.',
    ]);

/// Prompt the enhanced screen sent so the reply had a stable shape.
String enhancedTranslationPrompt({
  required String sourceLanguage,
  required String targetLanguage,
  required String text,
}) {
  return '''Translate the following text from $sourceLanguage to $targetLanguage.

Text to translate: "$text"

Please provide your response in this format:
1. Primary Translation: [your main translation]
2. Alternative Translations:
   - [alternative 1]
   - [alternative 2]
   - [alternative 3]
3. Grammar Breakdown:
   - [word]: [part of speech] - [explanation]
4. Cultural Context: [any relevant cultural notes]
5. Usage Note: [when/how to use this phrase]''';
}

EnhancedTranslationView parseEnhancedTranslation(
  String response,
  String sourceText,
) {
  final primary = _extractPrimaryTranslation(response);
  return EnhancedTranslationView(
    primary: primary.isNotEmpty ? primary : sourceText,
    alternatives: _extractAlternatives(response),
    grammar: _extractGrammarBreakdown(response, sourceText),
    cultural: _extractCulturalContext(response),
  );
}

/// Rows the live screen shows. Source-word fallbacks (part of speech "word",
/// no explanation) stay in [EnhancedTranslationView.grammar] for parity and
/// are hidden so a plain caption does not list every source word.
bool enhancedGrammarRowVisible(GrammarBreakdown item) {
  final note = item.explanation;
  if (note != null && note.isNotEmpty) return true;
  return item.partOfSpeech != 'word';
}

TranslationEntry enhancedTranslationEntry({
  required String id,
  required String sourceText,
  required String sourceLanguage,
  required String targetLanguage,
  required EnhancedTranslationView view,
  DateTime? timestamp,
}) {
  return TranslationEntry(
    id: id,
    sourceText: sourceText,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
    primaryTranslation: view.primary.isNotEmpty ? view.primary : sourceText,
    alternatives: view.alternatives,
    grammarBreakdown: view.grammar,
    culturalContext: view.cultural,
    timestamp: timestamp ?? DateTime.now(),
  );
}

String _extractPrimaryTranslation(String response) {
  if (response.trim().isEmpty) return '';

  final lines = response.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) return response.trim();

  final patterns = <RegExp>[
    RegExp(r'(?:primary\s+)?translation\s*:\s*(.+)', caseSensitive: false),
    RegExp(r'result\s*:\s*(.+)', caseSensitive: false),
    RegExp(r'^1[\.\)]\s*(.+)', caseSensitive: false),
    RegExp(r'''["「『]([^"」』]+)["」』]'''),
    RegExp(r'\*\*([^*]+)\*\*'),
  ];

  for (final pattern in patterns) {
    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        final result = match.group(1)?.trim() ?? '';
        if (result.isNotEmpty && result.length > 1) {
          return _cleanTranslation(result);
        }
      }
    }
  }

  final quotePattern = RegExp(r'''["']([^"']+)["']''');
  for (final line in lines) {
    if (line.toLowerCase().contains('translat')) {
      final match = quotePattern.firstMatch(line);
      if (match != null && (match.group(1)?.length ?? 0) > 1) {
        return _cleanTranslation(match.group(1) ?? '');
      }
    }
  }

  final headerKeywords = [
    'alternative',
    'grammar',
    'cultural',
    'context',
    'breakdown',
    'note',
    'usage',
    'example',
  ];
  for (final line in lines) {
    final trimmed = line.trim();
    final lower = trimmed.toLowerCase();
    if (trimmed.length < 2) continue;
    if (headerKeywords.any((k) => lower.startsWith(k))) continue;
    if (lower.startsWith('#') || lower.startsWith('*')) continue;
    if (trimmed.endsWith(':')) continue;
    return _cleanTranslation(trimmed);
  }

  return _cleanTranslation(lines.first);
}

String _cleanTranslation(String text) {
  return text
      .replaceAll(RegExp(r'^[\d\.\)\-\*\#]+\s*'), '')
      .replaceAll(
        RegExp(r'^(translation|primary|result)\s*:\s*', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'\*+'), '')
      .replaceAll(RegExp(r'^\s*["\x27]+|["\x27]+\s*$'), '')
      .trim();
}

List<TranslationAlternative> _extractAlternatives(String response) {
  final alternatives = <TranslationAlternative>[];
  final seen = <String>{};
  final lines = response.split('\n');
  var inAlternativesSection = false;

  final altKeywords = [
    'alternative',
    'variation',
    _words(const ['other', 'ways']),
    _words(const ['also', 'say']),
    _words(const ['other', 'translation']),
    _words(const ['could', 'also', 'be']),
  ];
  final endKeywords = [
    'grammar',
    'cultural',
    'context',
    'breakdown',
    'note',
    'usage',
    'example',
  ];

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final lower = trimmed.toLowerCase();

    if (altKeywords.any((k) => lower.contains(k))) {
      inAlternativesSection = true;
      final colonIndex = trimmed.indexOf(':');
      if (colonIndex > 0 && colonIndex < trimmed.length - 2) {
        final afterColon = trimmed.substring(colonIndex + 1).trim();
        if (afterColon.isNotEmpty && !seen.contains(afterColon.toLowerCase())) {
          seen.add(afterColon.toLowerCase());
          alternatives.add(TranslationAlternative(
            translation: _cleanTranslation(afterColon),
            context: _extractContextFromLine(afterColon),
          ));
        }
      }
      continue;
    }

    if (inAlternativesSection && endKeywords.any((k) => lower.startsWith(k))) {
      break;
    }

    final numberedMatch = RegExp(r'^[\d\-\*\•]+[\.\):\s]+(.+)').firstMatch(trimmed);
    if (numberedMatch != null) {
      final translation = numberedMatch.group(1)?.trim() ?? '';
      if (translation.isNotEmpty && !seen.contains(translation.toLowerCase())) {
        seen.add(translation.toLowerCase());
        alternatives.add(TranslationAlternative(
          translation: _cleanTranslation(translation),
          context: _extractContextFromLine(translation),
        ));
      }
      continue;
    }

    if (inAlternativesSection && !lower.endsWith(':') && trimmed.length > 2) {
      if (!seen.contains(trimmed.toLowerCase())) {
        seen.add(trimmed.toLowerCase());
        alternatives.add(TranslationAlternative(
          translation: _cleanTranslation(trimmed),
          context: _extractContextFromLine(trimmed),
        ));
      }
    }
  }

  if (alternatives.isEmpty) {
    final quotePatterns = <RegExp>[
      RegExp(r'''["']([^"']{2,50})["']'''),
      RegExp(r'''「([^」]{2,50})」'''),
      RegExp(r'\*\*([^*]{2,50})\*\*'),
    ];

    for (final pattern in quotePatterns) {
      final matches = pattern.allMatches(response);
      for (final match in matches.skip(1).take(5)) {
        final text = match.group(1) ?? '';
        if (text.isNotEmpty && !seen.contains(text.toLowerCase())) {
          seen.add(text.toLowerCase());
          alternatives.add(TranslationAlternative(
            translation: _cleanTranslation(text),
          ));
        }
      }
      if (alternatives.isNotEmpty) break;
    }
  }

  return alternatives.take(5).toList();
}

String? _extractContextFromLine(String line) {
  final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(line);
  if (parenMatch != null) {
    return parenMatch.group(1);
  }
  final dashMatch = RegExp('${RegExp.escape(_emDash)}\\s*(.+)').firstMatch(line);
  if (dashMatch != null) {
    return dashMatch.group(1);
  }
  return null;
}

List<GrammarBreakdown> _extractGrammarBreakdown(String response, String sourceText) {
  final breakdown = <GrammarBreakdown>[];
  final seen = <String>{};
  final lines = response.split('\n');
  var inGrammarSection = false;

  final grammarKeywords = [
    'grammar',
    'grammatical',
    'breakdown',
    'analysis',
    'structure',
    'morpholog',
    _words(const ['word-by-word']),
  ];
  final endKeywords = ['cultural', 'context', 'alternative', 'note', 'usage'];
  final posPattern = RegExp(
    r'\b(noun|verb|adjective|adverb|pronoun|preposition|conjunction|interjection|'
    r'particle|prefix|suffix|root|stem|tense|aspect|marker|copula|determiner|'
    r'auxiliary|modal|gerund|infinitive|imperative|subjunctive)\b',
    caseSensitive: false,
  );

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final lower = trimmed.toLowerCase();

    if (grammarKeywords.any((k) => lower.contains(k))) {
      inGrammarSection = true;
      continue;
    }

    if (inGrammarSection && endKeywords.any((k) => lower.startsWith(k))) {
      break;
    }

    if (trimmed.endsWith(':') && trimmed.length < 30) continue;

    final entry = _parseGrammarLine(trimmed, posPattern);
    if (entry != null && !seen.contains(entry.word.toLowerCase())) {
      seen.add(entry.word.toLowerCase());
      breakdown.add(entry);
    }
  }

  if (breakdown.isEmpty && sourceText.isNotEmpty) {
    final words = sourceText.split(RegExp(r'\s+')).where((w) => w.trim().length > 1).take(8);
    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w\u0080-\uFFFF]'), '');
      if (cleanWord.isNotEmpty && !seen.contains(cleanWord.toLowerCase())) {
        seen.add(cleanWord.toLowerCase());
        breakdown.add(GrammarBreakdown(
          word: cleanWord,
          partOfSpeech: 'word',
          root: _extractRoot(cleanWord),
          explanation: null,
        ));
      }
    }
  }

  return breakdown.take(15).toList();
}

GrammarBreakdown? _parseGrammarLine(String line, RegExp posPattern) {
  final colonMatch = RegExp(r'^[\*\-\•]?\s*([^:]+):\s*(.+)').firstMatch(line);
  if (colonMatch != null) {
    final word = colonMatch.group(1)?.trim() ?? '';
    final rest = colonMatch.group(2)?.trim() ?? '';
    if (word.isEmpty || word.length > 50) return null;

    final posMatch = posPattern.firstMatch(rest);
    final pos = posMatch?.group(1)?.toLowerCase() ?? 'word';
    final explanation = posMatch != null
        ? rest
            .replaceFirst(posMatch.group(0) ?? '', '')
            .replaceAll(RegExp('^[\\s$_enDash$_emDash-]+'), '')
            .trim()
        : rest;

    return GrammarBreakdown(
      word: _cleanTranslation(word),
      partOfSpeech: pos,
      root: _extractRoot(word),
      explanation: explanation.isNotEmpty ? explanation : null,
    );
  }

  final parenMatch = RegExp(r'^[\*\-\•]?\s*([^\(]+)\(([^)]+)\):?\s*(.*)').firstMatch(line);
  if (parenMatch != null) {
    final word = parenMatch.group(1)?.trim() ?? '';
    final posText = parenMatch.group(2)?.trim() ?? '';
    final explanation = parenMatch.group(3)?.trim();
    if (word.isEmpty || word.length > 50) return null;

    final posMatch = posPattern.firstMatch(posText);
    final pos = posMatch?.group(1)?.toLowerCase() ?? posText.toLowerCase();

    return GrammarBreakdown(
      word: _cleanTranslation(word),
      partOfSpeech: pos.length <= 20 ? pos : 'word',
      root: _extractRoot(word),
      explanation: explanation?.isNotEmpty == true ? explanation : null,
    );
  }

  final numberedMatch = RegExp(
    '^\\d+[\\.)]\\s*([^$_enDash$_emDash-]+)[$_enDash$_emDash-]\\s*(.*)',
  ).firstMatch(line);
  if (numberedMatch != null) {
    final word = numberedMatch.group(1)?.trim() ?? '';
    final rest = numberedMatch.group(2)?.trim() ?? '';
    if (word.isEmpty || word.length > 50) return null;

    final posMatch = posPattern.firstMatch(rest);
    final pos = posMatch?.group(1)?.toLowerCase() ?? 'word';

    return GrammarBreakdown(
      word: _cleanTranslation(word),
      partOfSpeech: pos,
      root: _extractRoot(word),
      explanation: rest.isNotEmpty ? rest : null,
    );
  }

  return null;
}

String _extractRoot(String word) {
  return word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
}

CulturalContext? _extractCulturalContext(String response) {
  final lines = response.split('\n');
  var inCulturalSection = false;
  final contextParts = <String>[];
  String? usageNote;

  final culturalKeywords = [
    'cultural',
    'culture',
    'significance',
    'meaning',
    'background',
    'tradition',
  ];
  final usageKeywords = [
    'usage',
    'note',
    'tip',
    'remember',
    'important',
    'caution',
    'warning',
    'polite',
    'formal',
    'informal',
  ];
  final endKeywords = ['alternative', 'grammar', 'breakdown'];
  final culturalTopics = [
    'tradition',
    'custom',
    'practice',
    'etiquette',
    'respect',
    'honor',
    'ceremony',
    'ritual',
    'elder',
    'greeting',
    'ancestor',
    'community',
    'family',
    'blessing',
    'proverb',
    'saying',
    'wisdom',
    'social',
    'polite',
    'formal',
    'informal',
    'appropriate',
  ];

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final lower = trimmed.toLowerCase();

    if (culturalKeywords.any((k) => lower.contains(k) && trimmed.endsWith(':'))) {
      inCulturalSection = true;
      continue;
    }
    if (culturalKeywords.any((k) => lower.startsWith(k))) {
      inCulturalSection = true;
      final colonIndex = trimmed.indexOf(':');
      if (colonIndex > 0 && colonIndex < trimmed.length - 2) {
        final content = trimmed.substring(colonIndex + 1).trim();
        if (content.isNotEmpty) contextParts.add(content);
      }
      continue;
    }

    if (inCulturalSection && endKeywords.any((k) => lower.startsWith(k))) {
      break;
    }

    if (inCulturalSection) {
      if (usageKeywords.any((k) => lower.contains(k)) && usageNote == null) {
        final colonIndex = trimmed.indexOf(':');
        if (colonIndex > 0) {
          usageNote = trimmed.substring(colonIndex + 1).trim();
        } else {
          usageNote = trimmed;
        }
      } else if (!trimmed.endsWith(':') && trimmed.length > 10) {
        contextParts.add(_cleanTranslation(trimmed));
      }
    }
  }

  if (contextParts.isEmpty) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (culturalTopics.any((topic) => lower.contains(topic))) {
        final trimmed = line.trim();
        if (trimmed.length > 20 && trimmed.length < 500) {
          contextParts.add(_cleanTranslation(trimmed));
          if (contextParts.length >= 3) break;
        }
      }
    }
  }

  final context = contextParts.isNotEmpty ? contextParts.take(5).join(' ').trim() : null;

  if (usageNote != null) {
    usageNote = usageNote
        .replaceAll(
          RegExp(r'^(usage|note|tip|remember)[:\s]*', caseSensitive: false),
          '',
        )
        .trim();
    if (usageNote.isEmpty) usageNote = null;
  }

  if (context != null || usageNote != null) {
    return CulturalContext(
      context: context,
      usageNote: usageNote,
    );
  }
  return null;
}
