import 'dart:math' show log;

/// Language-agnostic error classification system for diagnostic feedback.
///
/// Errors are NOT binary (right/wrong). Each error is classified by category,
/// severity, and linguistic domain. Error probability vectors drive AI feedback
/// and curriculum adaptation.
///
/// Supports language-family extensions (tonal, agglutinative, click, etc.)
/// while maintaining a universal base taxonomy.
class ErrorTaxonomy {
  ErrorTaxonomy._();

  /// Returns all error types applicable to a given language family.
  static List<ErrorType> errorsForLanguageFamily(LanguageFamily family) {
    final errors = <ErrorType>[...ErrorType.universal];

    switch (family) {
      case LanguageFamily.tonal:
        errors.addAll(ErrorType.tonal);
        break;
      case LanguageFamily.agglutinative:
        errors.addAll(ErrorType.agglutinative);
        break;
      case LanguageFamily.clickConsonant:
        errors.addAll(ErrorType.clickConsonant);
        break;
      case LanguageFamily.nounClass:
        errors.addAll(ErrorType.nounClass);
        break;
      case LanguageFamily.bantu:
        errors.addAll(ErrorType.tonal);
        errors.addAll(ErrorType.nounClass);
        errors.addAll(ErrorType.bantu);
        break;
    }

    return errors;
  }

  /// Computes the weighted severity of an error distribution vector.
  ///
  /// Returns 0.0 for no errors, up to 1.0 for maximally severe errors.
  static double weightedSeverity(Map<String, double> errorRates) {
    if (errorRates.isEmpty) return 0.0;

    double totalWeight = 0;
    double totalSeverity = 0;

    for (final entry in errorRates.entries) {
      final errorType = ErrorType.byId(entry.key);
      if (errorType == null) continue;

      totalSeverity += entry.value * errorType.severity;
      totalWeight += errorType.severity;
    }

    if (totalWeight == 0) return 0.0;
    return (totalSeverity / totalWeight).clamp(0.0, 1.0);
  }

  /// Identifies the top N most frequent error types from an error vector.
  static List<MapEntry<String, double>> topErrors(
    Map<String, double> errorRates, {
    int count = 3,
  }) {
    final sorted = errorRates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).toList();
  }

  /// Computes the entropy of an error distribution.
  ///
  /// High entropy = errors spread across many types (general confusion).
  /// Low entropy = errors concentrated on few types (targeted weakness).
  ///
  /// Lower entropy is better for targeted intervention.
  static double errorEntropy(Map<String, double> errorRates) {
    if (errorRates.isEmpty) return 0.0;

    final total = errorRates.values.fold(0.0, (sum, v) => sum + v);
    if (total == 0) return 0.0;

    double entropy = 0.0;
    for (final rate in errorRates.values) {
      if (rate <= 0) continue;
      final p = rate / total;
      entropy -= p * _log2(p);
    }

    return entropy;
  }

  static double _log2(double x) {
    if (x <= 0) return 0;
    return log(x) / _ln2;
  }

  static const double _ln2 = 0.6931471805599453;
}

/// Represents a specific type of error that can occur during language learning.
class ErrorType {
  final String id;
  final String name;
  final String description;
  final ErrorDomain domain;

  /// Severity weight in [0, 1]. Higher = more impactful on learning.
  final double severity;

  /// Suggested remediation approach.
  final RemediationType remediation;

  const ErrorType({
    required this.id,
    required this.name,
    required this.description,
    required this.domain,
    required this.severity,
    this.remediation = RemediationType.targetedDrill,
  });

  /// Look up an error type by its ID.
  static ErrorType? byId(String id) {
    return _allErrors[id];
  }

  static final Map<String, ErrorType> _allErrors = {
    for (final e in [...universal, ...tonal, ...agglutinative, ...clickConsonant, ...nounClass, ...bantu])
      e.id: e,
  };

  // ─── Universal error types (all languages) ─────────────────────────

  static const List<ErrorType> universal = [
    ErrorType(
      id: 'phoneme_substitution',
      name: 'Phoneme Substitution',
      description: 'Replacing one sound with another.',
      domain: ErrorDomain.phonetic,
      severity: 0.6,
    ),
    ErrorType(
      id: 'phoneme_deletion',
      name: 'Phoneme Deletion',
      description: 'Omitting a required sound.',
      domain: ErrorDomain.phonetic,
      severity: 0.7,
    ),
    ErrorType(
      id: 'phoneme_insertion',
      name: 'Phoneme Insertion',
      description: 'Adding a sound that should not be present.',
      domain: ErrorDomain.phonetic,
      severity: 0.5,
    ),
    ErrorType(
      id: 'vowel_length',
      name: 'Vowel Length Error',
      description: 'Incorrect vowel duration (short vs long).',
      domain: ErrorDomain.phonetic,
      severity: 0.5,
    ),
    ErrorType(
      id: 'stress_placement',
      name: 'Stress Placement',
      description: 'Incorrect syllable stress.',
      domain: ErrorDomain.phonetic,
      severity: 0.4,
    ),
    ErrorType(
      id: 'word_order',
      name: 'Word Order Error',
      description: 'Incorrect position of words in a sentence.',
      domain: ErrorDomain.syntactic,
      severity: 0.7,
    ),
    ErrorType(
      id: 'verb_conjugation',
      name: 'Verb Conjugation Error',
      description: 'Incorrect verb form for tense, aspect, or agreement.',
      domain: ErrorDomain.morphological,
      severity: 0.6,
    ),
    ErrorType(
      id: 'lexical_choice',
      name: 'Lexical Choice Error',
      description: 'Using the wrong word for the intended meaning.',
      domain: ErrorDomain.semantic,
      severity: 0.5,
    ),
    ErrorType(
      id: 'formality_mismatch',
      name: 'Formality Mismatch',
      description: 'Using incorrect register for the social context.',
      domain: ErrorDomain.pragmatic,
      severity: 0.4,
    ),
    ErrorType(
      id: 'agreement_error',
      name: 'Agreement Error',
      description: 'Subject-verb or noun-adjective agreement mismatch.',
      domain: ErrorDomain.syntactic,
      severity: 0.6,
    ),
    ErrorType(
      id: 'timing_error',
      name: 'Response Timing Error',
      description: 'Excessively slow response indicating weak automaticity.',
      domain: ErrorDomain.cognitive,
      severity: 0.3,
      remediation: RemediationType.speedDrill,
    ),
  ];

  // ─── Tonal language errors ─────────────────────────────────────────

  static const List<ErrorType> tonal = [
    ErrorType(
      id: 'tone_flattening',
      name: 'Tone Flattening',
      description: 'Failing to produce required pitch contour.',
      domain: ErrorDomain.phonetic,
      severity: 0.8,
    ),
    ErrorType(
      id: 'tone_substitution',
      name: 'Tone Substitution',
      description: 'Producing the wrong tone (e.g., high instead of low).',
      domain: ErrorDomain.phonetic,
      severity: 0.8,
    ),
    ErrorType(
      id: 'tone_sandhi_error',
      name: 'Tone Sandhi Error',
      description: 'Failing to apply tone change rules in context.',
      domain: ErrorDomain.phonetic,
      severity: 0.7,
    ),
    ErrorType(
      id: 'nasalization_missing',
      name: 'Nasalization Missing',
      description: 'Omitting required nasal quality on vowels.',
      domain: ErrorDomain.phonetic,
      severity: 0.6,
    ),
  ];

  // ─── Agglutinative language errors ─────────────────────────────────

  static const List<ErrorType> agglutinative = [
    ErrorType(
      id: 'affix_order',
      name: 'Affix Order Error',
      description: 'Incorrect ordering of prefixes or suffixes.',
      domain: ErrorDomain.morphological,
      severity: 0.7,
    ),
    ErrorType(
      id: 'affix_selection',
      name: 'Affix Selection Error',
      description: 'Using the wrong affix for the intended meaning.',
      domain: ErrorDomain.morphological,
      severity: 0.6,
    ),
    ErrorType(
      id: 'vowel_harmony',
      name: 'Vowel Harmony Error',
      description: 'Violating vowel harmony constraints in affixation.',
      domain: ErrorDomain.phonetic,
      severity: 0.5,
    ),
  ];

  // ─── Click consonant language errors ───────────────────────────────

  static const List<ErrorType> clickConsonant = [
    ErrorType(
      id: 'click_type_confusion',
      name: 'Click Type Confusion',
      description: 'Confusing dental, lateral, palatal, or alveolar clicks.',
      domain: ErrorDomain.phonetic,
      severity: 0.8,
    ),
    ErrorType(
      id: 'click_airstream',
      name: 'Click Airstream Error',
      description: 'Incorrect airstream mechanism for click production.',
      domain: ErrorDomain.phonetic,
      severity: 0.9,
    ),
  ];

  // ─── Noun class language errors ────────────────────────────────────

  static const List<ErrorType> nounClass = [
    ErrorType(
      id: 'noun_class_assignment',
      name: 'Noun Class Assignment Error',
      description: 'Assigning a noun to the wrong grammatical class.',
      domain: ErrorDomain.morphological,
      severity: 0.6,
    ),
    ErrorType(
      id: 'noun_class_agreement',
      name: 'Noun Class Agreement Error',
      description: 'Failing to agree adjectives/verbs with noun class.',
      domain: ErrorDomain.syntactic,
      severity: 0.7,
    ),
    ErrorType(
      id: 'noun_class_prefix',
      name: 'Noun Class Prefix Error',
      description: 'Using the wrong prefix for the noun class.',
      domain: ErrorDomain.morphological,
      severity: 0.6,
    ),
  ];

  // ─── Bantu-specific errors ─────────────────────────────────────────

  static const List<ErrorType> bantu = [
    ErrorType(
      id: 'verb_extension',
      name: 'Verb Extension Error',
      description: 'Incorrect use of verbal extensions (applicative, causative, etc.).',
      domain: ErrorDomain.morphological,
      severity: 0.6,
    ),
    ErrorType(
      id: 'aspect_confusion',
      name: 'Tense-Aspect Confusion',
      description: 'Confusing tense and aspect markers in Bantu verb morphology.',
      domain: ErrorDomain.morphological,
      severity: 0.7,
    ),
  ];
}

/// Linguistic domain of the error.
enum ErrorDomain {
  phonetic,
  morphological,
  syntactic,
  semantic,
  pragmatic,
  cognitive,
}

/// Language family classification for error taxonomy extension.
enum LanguageFamily {
  tonal,
  agglutinative,
  clickConsonant,
  nounClass,
  bantu,
}

/// How to remediate this type of error.
enum RemediationType {
  /// Focused practice on the specific error pattern.
  targetedDrill,

  /// Minimal pair discrimination exercises.
  minimalPairDrill,

  /// Speed-focused practice for automaticity.
  speedDrill,

  /// Explicit rule explanation followed by practice.
  ruleExplanation,

  /// Contextual exposure through reading/listening.
  contextualExposure,
}

/// Tracks error occurrences and rates for a specific skill.
///
/// This is the error probability vector stored per learner per skill.
class ErrorDistribution {
  /// Error type ID -> occurrence probability in [0, 1].
  final Map<String, double> rates;

  /// Total number of observations that contributed to these rates.
  final int totalObservations;

  const ErrorDistribution({
    required this.rates,
    this.totalObservations = 0,
  });

  factory ErrorDistribution.empty() =>
      const ErrorDistribution(rates: {}, totalObservations: 0);

  /// Updates the error distribution with a new observation.
  ///
  /// Uses exponential moving average to weight recent observations more heavily.
  ErrorDistribution recordError(String errorTypeId, {double alpha = 0.3}) {
    final newRates = Map<String, double>.from(rates);

    // Increase rate for observed error
    final currentRate = newRates[errorTypeId] ?? 0.0;
    newRates[errorTypeId] = currentRate + alpha * (1.0 - currentRate);

    // Decay rates for non-observed errors (they become less likely)
    for (final key in newRates.keys) {
      if (key != errorTypeId) {
        newRates[key] = newRates[key]! * (1.0 - alpha * 0.1);
      }
    }

    return ErrorDistribution(
      rates: newRates,
      totalObservations: totalObservations + 1,
    );
  }

  /// Records a clean observation (no errors), decaying all error rates.
  ErrorDistribution recordClean({double alpha = 0.3}) {
    final newRates = Map<String, double>.from(rates);

    for (final key in newRates.keys) {
      newRates[key] = newRates[key]! * (1.0 - alpha * 0.5);
    }

    // Remove negligible error rates
    newRates.removeWhere((_, v) => v < 0.01);

    return ErrorDistribution(
      rates: newRates,
      totalObservations: totalObservations + 1,
    );
  }

  /// Returns the most problematic error type ID, or null if clean.
  String? get dominantError {
    if (rates.isEmpty) return null;
    return rates.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  factory ErrorDistribution.fromJson(Map<String, dynamic> json) {
    return ErrorDistribution(
      rates: (json['rates'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      totalObservations: json['totalObservations'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'rates': rates,
        'totalObservations': totalObservations,
      };
}
