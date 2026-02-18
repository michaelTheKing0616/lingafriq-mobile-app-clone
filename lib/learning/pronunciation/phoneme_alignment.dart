import 'dart:math';
import '../../ai/pedagogy/error_classifier.dart';

/// Phoneme-level alignment using Dynamic Time Warping (DTW).
///
/// Aligns expected and actual phoneme sequences, accounting for:
/// - Substitutions (wrong sound)
/// - Deletions (missing sound)
/// - Insertions (extra sound)
/// - Timing mismatches
///
/// Each mismatch maps to an error taxonomy entry for diagnostic feedback.
class PhonemeAlignment {
  PhonemeAlignment._();

  /// Aligns two phoneme sequences using DTW with custom cost function.
  ///
  /// Returns an alignment result with per-phoneme scores and
  /// classified errors.
  static PhonemeAlignmentResult align({
    required List<PhonemeResult> expected,
    required List<PhonemeResult> actual,
    PhonemeAlignmentConfig config = const PhonemeAlignmentConfig(),
  }) {
    if (expected.isEmpty && actual.isEmpty) {
      return PhonemeAlignmentResult.perfect();
    }
    if (expected.isEmpty) {
      return PhonemeAlignmentResult(
        alignedPairs: actual
            .map((a) => AlignedPhoneme.insertion(actual: a))
            .toList(),
        overallScore: 0.0,
        alignmentCost: actual.length.toDouble(),
      );
    }
    if (actual.isEmpty) {
      return PhonemeAlignmentResult(
        alignedPairs: expected
            .map((e) => AlignedPhoneme.deletion(expected: e))
            .toList(),
        overallScore: 0.0,
        alignmentCost: expected.length.toDouble(),
      );
    }

    final n = expected.length;
    final m = actual.length;

    // DTW cost matrix
    final cost = List.generate(n + 1, (_) => List.filled(m + 1, double.infinity));
    cost[0][0] = 0;

    // Fill first row and column
    for (int i = 1; i <= n; i++) {
      cost[i][0] = cost[i - 1][0] + config.deletionCost;
    }
    for (int j = 1; j <= m; j++) {
      cost[0][j] = cost[0][j - 1] + config.insertionCost;
    }

    // Fill cost matrix
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final matchCost = _phonemeCost(expected[i - 1], actual[j - 1], config);
        cost[i][j] = [
          cost[i - 1][j - 1] + matchCost,
          cost[i - 1][j] + config.deletionCost,
          cost[i][j - 1] + config.insertionCost,
        ].reduce(min);
      }
    }

    // Backtrace
    final pairs = <AlignedPhoneme>[];
    int i = n, j = m;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final matchCost = _phonemeCost(expected[i - 1], actual[j - 1], config);
        final diagCost = cost[i - 1][j - 1] + matchCost;
        final upCost = cost[i - 1][j] + config.deletionCost;
        final leftCost = cost[i][j - 1] + config.insertionCost;

        if (diagCost <= upCost && diagCost <= leftCost) {
          final isMatch = expected[i - 1].phoneme == actual[j - 1].phoneme;
          pairs.add(AlignedPhoneme(
            expected: expected[i - 1],
            actual: actual[j - 1],
            type: isMatch
                ? AlignmentType.match
                : AlignmentType.substitution,
            cost: matchCost,
          ));
          i--;
          j--;
        } else if (upCost <= leftCost) {
          pairs.add(AlignedPhoneme.deletion(expected: expected[i - 1]));
          i--;
        } else {
          pairs.add(AlignedPhoneme.insertion(actual: actual[j - 1]));
          j--;
        }
      } else if (i > 0) {
        pairs.add(AlignedPhoneme.deletion(expected: expected[i - 1]));
        i--;
      } else {
        pairs.add(AlignedPhoneme.insertion(actual: actual[j - 1]));
        j--;
      }
    }

    final alignedPairs = pairs.reversed.toList();

    // Compute overall score
    final maxCost = n * config.deletionCost + m * config.insertionCost;
    final totalCost = cost[n][m];
    final overallScore = maxCost > 0
        ? (1.0 - totalCost / maxCost).clamp(0.0, 1.0)
        : 1.0;

    return PhonemeAlignmentResult(
      alignedPairs: alignedPairs,
      overallScore: overallScore,
      alignmentCost: totalCost,
    );
  }

  /// Generates an error heatmap from alignment results.
  ///
  /// Returns a list of per-phoneme scores [0, 1] where 1 = perfect
  /// and 0 = missing/wrong. Used for visual feedback in the UI.
  static List<PhonemeHeatmapEntry> generateHeatmap(
    PhonemeAlignmentResult alignment,
  ) {
    return alignment.alignedPairs.map((pair) {
      double score;
      String label;

      switch (pair.type) {
        case AlignmentType.match:
          score = pair.actual?.confidence ?? 1.0;
          label = pair.expected?.phoneme ?? '';
          break;
        case AlignmentType.substitution:
          score = 0.3;
          label = pair.expected?.phoneme ?? '';
          break;
        case AlignmentType.deletion:
          score = 0.0;
          label = pair.expected?.phoneme ?? '';
          break;
        case AlignmentType.insertion:
          score = 0.0;
          label = pair.actual?.phoneme ?? '';
          break;
      }

      return PhonemeHeatmapEntry(
        expectedPhoneme: pair.expected?.phoneme ?? '',
        actualPhoneme: pair.actual?.phoneme ?? '',
        score: score,
        type: pair.type,
      );
    }).toList();
  }

  /// Cost function for aligning two phonemes.
  ///
  /// Takes into account:
  /// - Phoneme identity (exact match = 0 cost)
  /// - Phoneme similarity (similar sounds = lower cost)
  /// - Confidence score (low confidence = higher cost)
  static double _phonemeCost(
    PhonemeResult expected,
    PhonemeResult actual,
    PhonemeAlignmentConfig config,
  ) {
    if (expected.phoneme == actual.phoneme) {
      // Penalize low-confidence matches
      final confidencePenalty = actual.confidence < config.confidenceThreshold
          ? (config.confidenceThreshold - actual.confidence) * config.substitutionCost * 0.5
          : 0.0;
      return confidencePenalty;
    }

    // Check for similar phonemes (reduced cost)
    final similarity = _phonemeSimilarity(expected.phoneme, actual.phoneme);
    return config.substitutionCost * (1.0 - similarity * 0.5);
  }

  /// Computes a similarity score [0, 1] between two phonemes.
  ///
  /// Based on articulatory features — phonemes that share place or
  /// manner of articulation are more similar.
  static double _phonemeSimilarity(String a, String b) {
    if (a == b) return 1.0;

    // Group phonemes by articulatory features
    final featureA = _getFeatures(a);
    final featureB = _getFeatures(b);

    if (featureA == null || featureB == null) return 0.0;

    int shared = 0;
    int total = 0;

    if (featureA.place == featureB.place) shared++;
    total++;
    if (featureA.manner == featureB.manner) shared++;
    total++;
    if (featureA.voiced == featureB.voiced) shared++;
    total++;

    return total > 0 ? shared / total : 0.0;
  }

  static _PhonemeFeatures? _getFeatures(String phoneme) {
    return _featureMap[phoneme];
  }

  /// Articulatory feature map for common phonemes.
  /// Extensible for African language phonemes.
  static final Map<String, _PhonemeFeatures> _featureMap = {
    // Stops
    'p': _PhonemeFeatures(place: 'bilabial', manner: 'stop', voiced: false),
    'b': _PhonemeFeatures(place: 'bilabial', manner: 'stop', voiced: true),
    't': _PhonemeFeatures(place: 'alveolar', manner: 'stop', voiced: false),
    'd': _PhonemeFeatures(place: 'alveolar', manner: 'stop', voiced: true),
    'k': _PhonemeFeatures(place: 'velar', manner: 'stop', voiced: false),
    'g': _PhonemeFeatures(place: 'velar', manner: 'stop', voiced: true),
    // Implosives (common in African languages)
    '\u0253': _PhonemeFeatures(place: 'bilabial', manner: 'implosive', voiced: true), // ɓ
    '\u0257': _PhonemeFeatures(place: 'alveolar', manner: 'implosive', voiced: true), // ɗ
    // Fricatives
    'f': _PhonemeFeatures(place: 'labiodental', manner: 'fricative', voiced: false),
    'v': _PhonemeFeatures(place: 'labiodental', manner: 'fricative', voiced: true),
    's': _PhonemeFeatures(place: 'alveolar', manner: 'fricative', voiced: false),
    'z': _PhonemeFeatures(place: 'alveolar', manner: 'fricative', voiced: true),
    '\u0283': _PhonemeFeatures(place: 'postalveolar', manner: 'fricative', voiced: false), // ʃ
    '\u0292': _PhonemeFeatures(place: 'postalveolar', manner: 'fricative', voiced: true), // ʒ
    'h': _PhonemeFeatures(place: 'glottal', manner: 'fricative', voiced: false),
    // Nasals
    'm': _PhonemeFeatures(place: 'bilabial', manner: 'nasal', voiced: true),
    'n': _PhonemeFeatures(place: 'alveolar', manner: 'nasal', voiced: true),
    '\u014B': _PhonemeFeatures(place: 'velar', manner: 'nasal', voiced: true), // ŋ
    '\u0272': _PhonemeFeatures(place: 'palatal', manner: 'nasal', voiced: true), // ɲ
    // Laterals and rhotics
    'l': _PhonemeFeatures(place: 'alveolar', manner: 'lateral', voiced: true),
    'r': _PhonemeFeatures(place: 'alveolar', manner: 'trill', voiced: true),
    '\u0279': _PhonemeFeatures(place: 'alveolar', manner: 'approximant', voiced: true), // ɹ
    // Approximants
    'w': _PhonemeFeatures(place: 'bilabial', manner: 'approximant', voiced: true),
    'j': _PhonemeFeatures(place: 'palatal', manner: 'approximant', voiced: true),
    // Vowels (simplified)
    'a': _PhonemeFeatures(place: 'open', manner: 'vowel', voiced: true),
    'e': _PhonemeFeatures(place: 'mid-front', manner: 'vowel', voiced: true),
    'i': _PhonemeFeatures(place: 'close-front', manner: 'vowel', voiced: true),
    'o': _PhonemeFeatures(place: 'mid-back', manner: 'vowel', voiced: true),
    'u': _PhonemeFeatures(place: 'close-back', manner: 'vowel', voiced: true),
    '\u025B': _PhonemeFeatures(place: 'open-mid-front', manner: 'vowel', voiced: true), // ɛ
    '\u0254': _PhonemeFeatures(place: 'open-mid-back', manner: 'vowel', voiced: true), // ɔ
    // Click consonants (for Zulu, Xhosa, etc.)
    '\u01C0': _PhonemeFeatures(place: 'dental', manner: 'click', voiced: false), // ǀ
    '\u01C1': _PhonemeFeatures(place: 'lateral', manner: 'click', voiced: false), // ǁ
    '\u01C3': _PhonemeFeatures(place: 'alveolar', manner: 'click', voiced: false), // ǃ
  };
}

/// Configuration for phoneme alignment.
class PhonemeAlignmentConfig {
  final double substitutionCost;
  final double deletionCost;
  final double insertionCost;
  final double confidenceThreshold;

  const PhonemeAlignmentConfig({
    this.substitutionCost = 1.0,
    this.deletionCost = 1.5,
    this.insertionCost = 1.0,
    this.confidenceThreshold = 0.6,
  });
}

/// Result of aligning two phoneme sequences.
class PhonemeAlignmentResult {
  final List<AlignedPhoneme> alignedPairs;
  final double overallScore;
  final double alignmentCost;

  const PhonemeAlignmentResult({
    required this.alignedPairs,
    required this.overallScore,
    required this.alignmentCost,
  });

  factory PhonemeAlignmentResult.perfect() => const PhonemeAlignmentResult(
        alignedPairs: [],
        overallScore: 1.0,
        alignmentCost: 0.0,
      );

  /// Number of correct phonemes.
  int get matchCount =>
      alignedPairs.where((p) => p.type == AlignmentType.match).length;

  /// Number of substitution errors.
  int get substitutionCount =>
      alignedPairs.where((p) => p.type == AlignmentType.substitution).length;

  /// Number of deletion errors.
  int get deletionCount =>
      alignedPairs.where((p) => p.type == AlignmentType.deletion).length;

  /// Number of insertion errors.
  int get insertionCount =>
      alignedPairs.where((p) => p.type == AlignmentType.insertion).length;

  Map<String, dynamic> toJson() => {
        'overallScore': overallScore,
        'alignmentCost': alignmentCost,
        'matchCount': matchCount,
        'substitutionCount': substitutionCount,
        'deletionCount': deletionCount,
        'insertionCount': insertionCount,
        'pairs': alignedPairs.map((p) => p.toJson()).toList(),
      };
}

/// A single aligned phoneme pair.
class AlignedPhoneme {
  final PhonemeResult? expected;
  final PhonemeResult? actual;
  final AlignmentType type;
  final double cost;

  const AlignedPhoneme({
    this.expected,
    this.actual,
    required this.type,
    this.cost = 0.0,
  });

  factory AlignedPhoneme.deletion({required PhonemeResult expected}) =>
      AlignedPhoneme(
        expected: expected,
        type: AlignmentType.deletion,
        cost: 1.5,
      );

  factory AlignedPhoneme.insertion({required PhonemeResult actual}) =>
      AlignedPhoneme(
        actual: actual,
        type: AlignmentType.insertion,
        cost: 1.0,
      );

  Map<String, dynamic> toJson() => {
        'expected': expected?.toJson(),
        'actual': actual?.toJson(),
        'type': type.name,
        'cost': cost,
      };
}

/// Type of alignment between expected and actual phonemes.
enum AlignmentType {
  match,
  substitution,
  deletion,
  insertion,
}

/// A single entry in a phoneme heatmap for UI display.
class PhonemeHeatmapEntry {
  final String expectedPhoneme;
  final String actualPhoneme;
  final double score;
  final AlignmentType type;

  const PhonemeHeatmapEntry({
    required this.expectedPhoneme,
    required this.actualPhoneme,
    required this.score,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'expectedPhoneme': expectedPhoneme,
        'actualPhoneme': actualPhoneme,
        'score': score,
        'type': type.name,
      };
}

/// Articulatory features of a phoneme.
class _PhonemeFeatures {
  final String place;
  final String manner;
  final bool voiced;

  const _PhonemeFeatures({
    required this.place,
    required this.manner,
    required this.voiced,
  });
}
