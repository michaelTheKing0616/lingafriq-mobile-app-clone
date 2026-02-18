import '../../ai/pedagogy/error_classifier.dart';
import '../../learning/learner_model/error_taxonomy.dart';
import '../../learning/learner_model/learner_model_service.dart';
import '../../learning/learner_model/learner_skill_state.dart';
import 'phoneme_alignment.dart';

/// Complete end-to-end pronunciation evaluation pipeline.
///
/// Pipeline stages:
/// 1. Audio input (handled by existing audio services)
/// 2. Speech-to-phoneme conversion (via ASR service / backend)
/// 3. Phoneme alignment (DTW — this module)
/// 4. Error classification (maps alignment to error taxonomy)
/// 5. Learner model update (feeds results back to the model)
/// 6. Feedback generation (heatmap + targeted correction)
///
/// This pipeline integrates with existing pronunciation_analysis_service.dart
/// and enhanced_stt_service.dart, adding the missing layers.
class PronunciationPipeline {
  final LearnerModelService _learnerModel;

  PronunciationPipeline({
    LearnerModelService? learnerModel,
  }) : _learnerModel = learnerModel ?? LearnerModelService.instance;

  /// Evaluates a pronunciation attempt end-to-end.
  ///
  /// Takes the raw phoneme results from ASR and the expected phonemes,
  /// runs alignment, classifies errors, updates the learner model,
  /// and returns structured feedback.
  Future<PronunciationEvaluationResult> evaluate({
    required String learnerId,
    required String skillId,
    required List<PhonemeResult> expectedPhonemes,
    required List<PhonemeResult> actualPhonemes,
    double responseTimeSeconds = 0,
    double expectedTimeSeconds = 5,
    List<ToneResult>? toneResults,
  }) async {
    // 1. Run phoneme alignment (DTW)
    final alignment = PhonemeAlignment.align(
      expected: expectedPhonemes,
      actual: actualPhonemes,
    );

    // 2. Generate heatmap for UI
    final heatmap = PhonemeAlignment.generateHeatmap(alignment);

    // 3. Classify errors
    final errors = _classifyPronunciationErrors(alignment, toneResults);

    // 4. Determine overall correctness
    final isCorrect = alignment.overallScore >= 0.8 &&
        errors.every((e) => e.severity < 0.5);

    // 5. Update learner model
    final errorTypeIds = errors.map((e) => e.errorTypeId).toSet().toList();
    final updatedState = await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: isCorrect,
      errorTypeIds: errorTypeIds,
      responseTimeSeconds: responseTimeSeconds,
      expectedTimeSeconds: expectedTimeSeconds,
    );

    // 6. Generate actionable feedback
    final feedback = _generateFeedback(alignment, errors, heatmap);

    return PronunciationEvaluationResult(
      alignment: alignment,
      heatmap: heatmap,
      errors: errors,
      feedback: feedback,
      updatedState: updatedState,
      isCorrect: isCorrect,
      overallScore: alignment.overallScore,
    );
  }

  /// Evaluates pronunciation from raw text comparison when phoneme-level
  /// ASR is not available. Falls back to text-based analysis.
  Future<PronunciationEvaluationResult> evaluateFromText({
    required String learnerId,
    required String skillId,
    required String expectedText,
    required String actualText,
    required List<String> expectedPhonemeStrings,
    double responseTimeSeconds = 0,
  }) async {
    // Convert expected phonemes to PhonemeResult with 1.0 confidence
    final expected = expectedPhonemeStrings
        .map((p) => PhonemeResult(phoneme: p, confidence: 1.0))
        .toList();

    // Derive actual phonemes from text (simplified — uses character-level)
    final actual = _textToPhonemeApproximation(actualText);

    return evaluate(
      learnerId: learnerId,
      skillId: skillId,
      expectedPhonemes: expected,
      actualPhonemes: actual,
      responseTimeSeconds: responseTimeSeconds,
    );
  }

  /// Generates targeted drills based on the learner's pronunciation weaknesses.
  ///
  /// Uses the error distribution to identify the most problematic phonemes
  /// and creates minimal-pair exercises.
  List<PronunciationDrill> generateTargetedDrills({
    required String learnerId,
    required String skillId,
    int count = 5,
  }) {
    final state = _learnerModel.getState(
      learnerId: learnerId,
      skillId: skillId,
    );

    final topErrors = ErrorTaxonomy.topErrors(state.errorDistribution.rates);
    final drills = <PronunciationDrill>[];

    for (final error in topErrors) {
      final errorType = ErrorType.byId(error.key);
      if (errorType == null) continue;

      switch (errorType.id) {
        case 'phoneme_substitution':
          drills.add(PronunciationDrill(
            type: DrillType.minimalPair,
            description: 'Practice distinguishing similar sounds.',
            errorTypeId: error.key,
            difficulty: state.mastery.clamp(0.2, 0.8),
          ));
          break;
        case 'tone_flattening':
        case 'tone_substitution':
          drills.add(PronunciationDrill(
            type: DrillType.toneContour,
            description: 'Practice producing correct tone patterns.',
            errorTypeId: error.key,
            difficulty: state.mastery.clamp(0.2, 0.8),
          ));
          break;
        case 'phoneme_deletion':
          drills.add(PronunciationDrill(
            type: DrillType.segmentation,
            description: 'Practice articulating each sound clearly.',
            errorTypeId: error.key,
            difficulty: state.mastery.clamp(0.1, 0.6),
          ));
          break;
        case 'nasalization_missing':
          drills.add(PronunciationDrill(
            type: DrillType.articulatoryFocus,
            description: 'Practice nasal airflow during vowels.',
            errorTypeId: error.key,
            difficulty: state.mastery.clamp(0.2, 0.7),
          ));
          break;
        default:
          drills.add(PronunciationDrill(
            type: DrillType.repetition,
            description: 'Repeat and practice this sound.',
            errorTypeId: error.key,
            difficulty: state.mastery.clamp(0.2, 0.8),
          ));
      }
    }

    return drills.take(count).toList();
  }

  // ─── Private methods ───────────────────────────────────────────────

  List<DetectedError> _classifyPronunciationErrors(
    PhonemeAlignmentResult alignment,
    List<ToneResult>? toneResults,
  ) {
    final errors = <DetectedError>[];

    // Phoneme-level errors from alignment
    for (int i = 0; i < alignment.alignedPairs.length; i++) {
      final pair = alignment.alignedPairs[i];

      switch (pair.type) {
        case AlignmentType.substitution:
          errors.add(DetectedError(
            errorTypeId: 'phoneme_substitution',
            expected: pair.expected?.phoneme ?? '',
            actual: pair.actual?.phoneme ?? '',
            position: i,
            severity: 0.7,
            confidence: pair.actual?.confidence,
          ));
          break;
        case AlignmentType.deletion:
          errors.add(DetectedError(
            errorTypeId: 'phoneme_deletion',
            expected: pair.expected?.phoneme ?? '',
            actual: '',
            position: i,
            severity: 0.8,
          ));
          break;
        case AlignmentType.insertion:
          errors.add(DetectedError(
            errorTypeId: 'phoneme_insertion',
            expected: '',
            actual: pair.actual?.phoneme ?? '',
            position: i,
            severity: 0.5,
          ));
          break;
        case AlignmentType.match:
          // Low-confidence matches are flagged as potential errors
          if (pair.actual != null && pair.actual!.confidence < 0.6) {
            errors.add(DetectedError(
              errorTypeId: 'phoneme_substitution',
              expected: pair.expected?.phoneme ?? '',
              actual: pair.actual?.phoneme ?? '',
              position: i,
              severity: 0.3,
              confidence: pair.actual!.confidence,
            ));
          }
          break;
      }
    }

    // Tone-level errors
    if (toneResults != null) {
      for (final tone in toneResults) {
        if (!tone.isCorrect) {
          errors.add(DetectedError(
            errorTypeId: tone.expectedTone != tone.actualTone
                ? 'tone_substitution'
                : 'tone_flattening',
            expected: tone.expectedTone,
            actual: tone.actualTone,
            position: tone.syllableIndex,
            severity: 0.8,
            confidence: tone.confidence,
          ));
        }
      }
    }

    return errors;
  }

  PronunciationFeedback _generateFeedback(
    PhonemeAlignmentResult alignment,
    List<DetectedError> errors,
    List<PhonemeHeatmapEntry> heatmap,
  ) {
    if (errors.isEmpty) {
      return PronunciationFeedback(
        correction: null,
        heatmap: heatmap,
        shouldRetry: false,
        drillType: null,
      );
    }

    // Find the most severe error for the correction message
    errors.sort((a, b) => b.severity.compareTo(a.severity));
    final worstError = errors.first;
    final errorType = ErrorType.byId(worstError.errorTypeId);

    String correction;
    if (worstError.errorTypeId.startsWith('tone_')) {
      correction = 'The tone on syllable ${worstError.position + 1} should be '
          '${worstError.expected}, but you produced ${worstError.actual}.';
    } else if (worstError.errorTypeId == 'phoneme_substitution') {
      correction = 'You said [${worstError.actual}] instead of [${worstError.expected}].';
    } else if (worstError.errorTypeId == 'phoneme_deletion') {
      correction = 'The sound [${worstError.expected}] is missing.';
    } else if (worstError.errorTypeId == 'phoneme_insertion') {
      correction = 'You added an extra [${worstError.actual}] that should not be there.';
    } else {
      correction = errorType?.description ?? 'Check your pronunciation.';
    }

    return PronunciationFeedback(
      correction: correction,
      heatmap: heatmap,
      shouldRetry: alignment.overallScore < 0.8,
      drillType: errorType?.remediation,
    );
  }

  /// Approximate phoneme extraction from text.
  /// Used as fallback when phoneme-level ASR is unavailable.
  List<PhonemeResult> _textToPhonemeApproximation(String text) {
    // Character-level approximation with mid confidence
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\u0253\u0257\u0283\u0292\u014B\u0272]'), '')
        .split('')
        .where((c) => c.isNotEmpty)
        .map((c) => PhonemeResult(phoneme: c, confidence: 0.7))
        .toList();
  }
}

/// Complete result of a pronunciation evaluation.
class PronunciationEvaluationResult {
  final PhonemeAlignmentResult alignment;
  final List<PhonemeHeatmapEntry> heatmap;
  final List<DetectedError> errors;
  final PronunciationFeedback feedback;
  final LearnerSkillState updatedState;
  final bool isCorrect;
  final double overallScore;

  const PronunciationEvaluationResult({
    required this.alignment,
    required this.heatmap,
    required this.errors,
    required this.feedback,
    required this.updatedState,
    required this.isCorrect,
    required this.overallScore,
  });

  Map<String, dynamic> toJson() => {
        'alignment': alignment.toJson(),
        'heatmap': heatmap.map((h) => h.toJson()).toList(),
        'errors': errors.map((e) => e.toJson()).toList(),
        'isCorrect': isCorrect,
        'overallScore': overallScore,
      };
}

/// Pronunciation feedback for the UI.
class PronunciationFeedback {
  /// Single actionable correction (null if perfect).
  final String? correction;

  /// Per-phoneme heatmap scores for visual display.
  final List<PhonemeHeatmapEntry> heatmap;

  /// Whether the learner should retry.
  final bool shouldRetry;

  /// Suggested drill type for remediation.
  final RemediationType? drillType;

  const PronunciationFeedback({
    required this.correction,
    required this.heatmap,
    required this.shouldRetry,
    required this.drillType,
  });
}

/// Result of a tone analysis for a single syllable.
class ToneResult {
  final int syllableIndex;
  final String expectedTone;
  final String actualTone;
  final double confidence;
  final bool isCorrect;

  const ToneResult({
    required this.syllableIndex,
    required this.expectedTone,
    required this.actualTone,
    required this.confidence,
    required this.isCorrect,
  });
}

/// A targeted pronunciation drill.
class PronunciationDrill {
  final DrillType type;
  final String description;
  final String errorTypeId;
  final double difficulty;

  const PronunciationDrill({
    required this.type,
    required this.description,
    required this.errorTypeId,
    required this.difficulty,
  });
}

/// Types of pronunciation drills.
enum DrillType {
  minimalPair,
  toneContour,
  segmentation,
  articulatoryFocus,
  repetition,
  shadowing,
}
