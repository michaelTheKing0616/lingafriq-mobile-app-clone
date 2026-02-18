import '../../learning/learner_model/error_taxonomy.dart';

/// Classifies errors from learner responses by comparing expected
/// and actual outputs at multiple linguistic levels.
///
/// Works for text responses, phoneme sequences, and grammar structures.
/// Returns structured error classifications tied to the error taxonomy.
class ErrorClassifier {
  ErrorClassifier._();

  /// Classifies errors between expected and actual text responses.
  ///
  /// Analyzes at word level and maps differences to error taxonomy types.
  static ErrorClassificationResult classifyTextErrors({
    required String expected,
    required String actual,
    required List<String> requiredElements,
    String? languageCode,
  }) {
    final detectedErrors = <DetectedError>[];
    double partialCredit = 0.0;

    final expectedWords = _tokenize(expected);
    final actualWords = _tokenize(actual);

    if (expectedWords.isEmpty) {
      return ErrorClassificationResult(
        detectedErrors: [],
        partialCredit: actualWords.isEmpty ? 1.0 : 0.0,
        isCorrect: actual.trim().toLowerCase() == expected.trim().toLowerCase(),
      );
    }

    // Word-level alignment using edit distance
    final alignment = _alignWords(expectedWords, actualWords);

    int matchCount = 0;
    for (final op in alignment) {
      switch (op.type) {
        case AlignmentOpType.match:
          matchCount++;
          break;
        case AlignmentOpType.substitution:
          detectedErrors.add(DetectedError(
            errorTypeId: 'lexical_choice',
            expected: op.expected ?? '',
            actual: op.actual ?? '',
            position: op.position,
            severity: 0.6,
          ));
          break;
        case AlignmentOpType.deletion:
          detectedErrors.add(DetectedError(
            errorTypeId: 'word_order',
            expected: op.expected ?? '',
            actual: '',
            position: op.position,
            severity: 0.7,
          ));
          break;
        case AlignmentOpType.insertion:
          detectedErrors.add(DetectedError(
            errorTypeId: 'word_order',
            expected: '',
            actual: op.actual ?? '',
            position: op.position,
            severity: 0.5,
          ));
          break;
      }
    }

    // Check required elements
    for (final element in requiredElements) {
      if (!actual.toLowerCase().contains(element.toLowerCase())) {
        detectedErrors.add(DetectedError(
          errorTypeId: 'lexical_choice',
          expected: element,
          actual: '',
          position: -1,
          severity: 0.8,
        ));
      }
    }

    // Compute partial credit
    if (expectedWords.isNotEmpty) {
      partialCredit = matchCount / expectedWords.length;
    }

    final isCorrect = detectedErrors.isEmpty ||
        actual.trim().toLowerCase() == expected.trim().toLowerCase();

    return ErrorClassificationResult(
      detectedErrors: detectedErrors,
      partialCredit: isCorrect ? 1.0 : partialCredit,
      isCorrect: isCorrect,
    );
  }

  /// Classifies errors between expected and actual phoneme sequences.
  ///
  /// Uses alignment to detect substitutions, deletions, and insertions
  /// at the phoneme level. Confidence scores affect severity.
  static ErrorClassificationResult classifyPhonemeErrors({
    required List<PhonemeResult> expected,
    required List<PhonemeResult> actual,
  }) {
    if (expected.isEmpty && actual.isEmpty) {
      return const ErrorClassificationResult(
        detectedErrors: [],
        partialCredit: 1.0,
        isCorrect: true,
      );
    }

    final detectedErrors = <DetectedError>[];
    int matchCount = 0;

    // Align phoneme sequences
    final expectedSymbols = expected.map((p) => p.phoneme).toList();
    final actualSymbols = actual.map((p) => p.phoneme).toList();
    final alignment = _alignWords(expectedSymbols, actualSymbols);

    for (final op in alignment) {
      switch (op.type) {
        case AlignmentOpType.match:
          // Check confidence even for matches
          final actualIdx = op.position < actual.length ? op.position : actual.length - 1;
          if (actualIdx >= 0 && actual[actualIdx].confidence < 0.6) {
            detectedErrors.add(DetectedError(
              errorTypeId: 'phoneme_substitution',
              expected: op.expected ?? '',
              actual: op.actual ?? '',
              position: op.position,
              severity: 0.3,
              confidence: actual[actualIdx].confidence,
            ));
          } else {
            matchCount++;
          }
          break;
        case AlignmentOpType.substitution:
          detectedErrors.add(DetectedError(
            errorTypeId: 'phoneme_substitution',
            expected: op.expected ?? '',
            actual: op.actual ?? '',
            position: op.position,
            severity: 0.7,
          ));
          break;
        case AlignmentOpType.deletion:
          detectedErrors.add(DetectedError(
            errorTypeId: 'phoneme_deletion',
            expected: op.expected ?? '',
            actual: '',
            position: op.position,
            severity: 0.8,
          ));
          break;
        case AlignmentOpType.insertion:
          detectedErrors.add(DetectedError(
            errorTypeId: 'phoneme_insertion',
            expected: '',
            actual: op.actual ?? '',
            position: op.position,
            severity: 0.5,
          ));
          break;
      }
    }

    final partialCredit = expected.isNotEmpty
        ? matchCount / expected.length
        : 0.0;

    return ErrorClassificationResult(
      detectedErrors: detectedErrors,
      partialCredit: detectedErrors.isEmpty ? 1.0 : partialCredit,
      isCorrect: detectedErrors.isEmpty,
    );
  }

  /// Classifies grammar-level errors from a structured analysis.
  static ErrorClassificationResult classifyGrammarErrors({
    required List<GrammarCheck> checks,
  }) {
    final detectedErrors = <DetectedError>[];
    int passed = 0;

    for (final check in checks) {
      if (check.passed) {
        passed++;
      } else {
        detectedErrors.add(DetectedError(
          errorTypeId: check.errorTypeId,
          expected: check.expected,
          actual: check.actual,
          position: check.position,
          severity: check.severity,
        ));
      }
    }

    final partialCredit = checks.isNotEmpty ? passed / checks.length : 0.0;

    return ErrorClassificationResult(
      detectedErrors: detectedErrors,
      partialCredit: detectedErrors.isEmpty ? 1.0 : partialCredit,
      isCorrect: detectedErrors.isEmpty,
    );
  }

  /// Maps detected errors to error taxonomy IDs.
  static List<String> getErrorTypeIds(List<DetectedError> errors) {
    return errors.map((e) => e.errorTypeId).toSet().toList();
  }

  // ─── Internal alignment logic ──────────────────────────────────────

  static List<String> _tokenize(String text) {
    return text.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  /// Minimum edit distance alignment using dynamic programming.
  static List<AlignmentOp> _alignWords(List<String> expected, List<String> actual) {
    final n = expected.length;
    final m = actual.length;

    // DP table
    final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));

    for (int i = 0; i <= n; i++) dp[i][0] = i;
    for (int j = 0; j <= m; j++) dp[0][j] = j;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        if (expected[i - 1] == actual[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 +
              [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
                  .reduce((a, b) => a < b ? a : b);
        }
      }
    }

    // Backtrace to find alignment
    final ops = <AlignmentOp>[];
    int i = n, j = m;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && expected[i - 1] == actual[j - 1]) {
        ops.add(AlignmentOp(
          type: AlignmentOpType.match,
          expected: expected[i - 1],
          actual: actual[j - 1],
          position: i - 1,
        ));
        i--;
        j--;
      } else if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1) {
        ops.add(AlignmentOp(
          type: AlignmentOpType.substitution,
          expected: expected[i - 1],
          actual: actual[j - 1],
          position: i - 1,
        ));
        i--;
        j--;
      } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        ops.add(AlignmentOp(
          type: AlignmentOpType.deletion,
          expected: expected[i - 1],
          position: i - 1,
        ));
        i--;
      } else {
        ops.add(AlignmentOp(
          type: AlignmentOpType.insertion,
          actual: j > 0 ? actual[j - 1] : '',
          position: j - 1,
        ));
        j--;
      }
    }

    return ops.reversed.toList();
  }
}

/// Result of error classification.
class ErrorClassificationResult {
  final List<DetectedError> detectedErrors;
  final double partialCredit;
  final bool isCorrect;

  const ErrorClassificationResult({
    required this.detectedErrors,
    required this.partialCredit,
    required this.isCorrect,
  });

  /// Error type IDs from this result.
  List<String> get errorTypeIds =>
      detectedErrors.map((e) => e.errorTypeId).toSet().toList();

  Map<String, dynamic> toJson() => {
        'detectedErrors': detectedErrors.map((e) => e.toJson()).toList(),
        'partialCredit': partialCredit,
        'isCorrect': isCorrect,
      };
}

/// A single detected error instance.
class DetectedError {
  final String errorTypeId;
  final String expected;
  final String actual;
  final int position;
  final double severity;
  final double? confidence;

  const DetectedError({
    required this.errorTypeId,
    required this.expected,
    required this.actual,
    required this.position,
    required this.severity,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'errorTypeId': errorTypeId,
        'expected': expected,
        'actual': actual,
        'position': position,
        'severity': severity,
        if (confidence != null) 'confidence': confidence,
      };
}

/// A phoneme with its ASR confidence score.
class PhonemeResult {
  final String phoneme;
  final double confidence;

  const PhonemeResult({
    required this.phoneme,
    required this.confidence,
  });

  factory PhonemeResult.fromJson(Map<String, dynamic> json) {
    return PhonemeResult(
      phoneme: json['phoneme'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'phoneme': phoneme,
        'confidence': confidence,
      };
}

/// A grammar check result.
class GrammarCheck {
  final String checkName;
  final String errorTypeId;
  final bool passed;
  final String expected;
  final String actual;
  final int position;
  final double severity;

  const GrammarCheck({
    required this.checkName,
    required this.errorTypeId,
    required this.passed,
    required this.expected,
    required this.actual,
    this.position = 0,
    this.severity = 0.5,
  });
}

/// Alignment operation types.
enum AlignmentOpType { match, substitution, deletion, insertion }

/// A single alignment operation.
class AlignmentOp {
  final AlignmentOpType type;
  final String? expected;
  final String? actual;
  final int position;

  const AlignmentOp({
    required this.type,
    this.expected,
    this.actual,
    required this.position,
  });
}
