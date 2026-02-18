import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/pedagogy/error_classifier.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/pronunciation/phoneme_alignment.dart';

/// Per-phoneme score with continuous confidence (no binary pass/fail).
class PhonemeScore {
  final String phoneme;
  final double confidence;
  final bool isCorrect;

  const PhonemeScore({
    required this.phoneme,
    required this.confidence,
    required this.isCorrect,
  });
}

/// Pronunciation result wrapped in persona feedback and targeted drills.
class PersonaPronunciationResult {
  final double overallScore;
  final List<PhonemeScore> phonemeScores;
  final String personaFeedback;
  final List<String> targetedDrills;
  final Map<String, double> errorsByType;

  const PersonaPronunciationResult({
    required this.overallScore,
    required this.phonemeScores,
    required this.personaFeedback,
    required this.targetedDrills,
    required this.errorsByType,
  });
}

/// Integrates pronunciation scoring with persona roleplay: persona vocabulary,
/// persona-style feedback, and learner model updates.
class PersonaPronunciationService {
  final LearnerModelService _learnerModel;

  PersonaPronunciationService([LearnerModelService? learnerModel])
      : _learnerModel = learnerModel ?? LearnerModelService.instance;

  /// Scores pronunciation in persona context and returns persona-styled feedback and drills.
  Future<PersonaPronunciationResult> scorePronunciation({
    required String learnerId,
    required String personaId,
    required String expectedText,
    required List<Map<String, dynamic>> phonemeResults,
    required String languageCode,
  }) async {
    final _ = HistoricalPersonaRegistry.findById(personaId);

    final expectedPhonemes = _textToPhonemeApproximation(expectedText);
    final actualPhonemes = phonemeResults
        .map((m) => PhonemeResult(
              phoneme: (m['phoneme'] as String?) ?? '',
              confidence: (m['confidence'] as num?)?.toDouble() ?? 0.5,
            ))
        .toList();

    final alignment = PhonemeAlignment.align(
      expected: expectedPhonemes,
      actual: actualPhonemes,
    );

    final phonemeScores = alignment.alignedPairs.map((p) {
      final phoneme = p.expected?.phoneme ?? p.actual?.phoneme ?? '';
      final confidence = p.expected?.confidence ?? p.actual?.confidence ?? 0.5;
      final isCorrect = p.type == AlignmentType.match;
      return PhonemeScore(
        phoneme: phoneme,
        confidence: isCorrect ? confidence : (1.0 - p.cost).clamp(0.0, 1.0),
        isCorrect: isCorrect,
      );
    }).toList();

    // 3. Classify errors; use continuous confidence, never binary.
    final errorsByType = <String, double>{};
    for (final p in alignment.alignedPairs) {
      if (p.type == AlignmentType.substitution) {
        errorsByType['substitution'] =
            (errorsByType['substitution'] ?? 0) + 1.0;
      } else if (p.type == AlignmentType.deletion) {
        errorsByType['deletion'] = (errorsByType['deletion'] ?? 0) + 1.0;
      } else if (p.type == AlignmentType.insertion) {
        errorsByType['insertion'] = (errorsByType['insertion'] ?? 0) + 1.0;
      }
    }
    // Persona's cultural pragmatics inform feedback tone (getPersonaFeedback uses persona).

    final errorTypeList = errorsByType.keys.toList();
    final personaFeedback = getPersonaFeedback(
      personaId: personaId,
      overallScore: alignment.overallScore,
      errorTypes: errorTypeList,
    );

    final weakPhonemes = <String, double>{};
    for (final s in phonemeScores) {
      if (!s.isCorrect && s.confidence < 0.7) {
        weakPhonemes[s.phoneme] = (weakPhonemes[s.phoneme] ?? 0) + (1 - s.confidence);
      }
    }
    final targetedDrills = generatePersonaDrills(
      personaId: personaId,
      languageCode: languageCode,
      weakPhonemes: weakPhonemes,
    );

    final skillId = 'pronunciation_$languageCode';
    final wasCorrect = alignment.overallScore >= 0.8 && errorsByType.isEmpty;
    await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: wasCorrect,
      errorTypeIds: errorTypeList,
    );

    return PersonaPronunciationResult(
      overallScore: alignment.overallScore,
      phonemeScores: phonemeScores,
      personaFeedback: personaFeedback,
      targetedDrills: targetedDrills,
      errorsByType: errorsByType,
    );
  }

  List<PhonemeResult> _textToPhonemeApproximation(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\u0253\u0257\u0283\u0292\u014B\u0272]'), '')
        .split('')
        .where((c) => c.isNotEmpty)
        .map((c) => PhonemeResult(phoneme: c, confidence: 0.7))
        .toList();
  }

  /// Drills from persona vocabulary that practice weak phonemes.
  List<String> generatePersonaDrills({
    required String personaId,
    required String languageCode,
    required Map<String, double> weakPhonemes,
  }) {
    if (weakPhonemes.isEmpty) return [];

    final persona = HistoricalPersonaRegistry.findById(personaId);
    if (persona == null || persona.commonVocabulary.isEmpty) return [];

    final weakSet = weakPhonemes.keys.toSet();
    final candidates = <String>[];
    for (final word in persona.commonVocabulary) {
      final lower = word.toLowerCase();
      for (final phoneme in weakSet) {
        if (lower.contains(phoneme)) {
          candidates.add(word);
          break;
        }
      }
    }
    return candidates.take(10).toList();
  }

  /// Feedback in the persona's tone (e.g. Mandela: calm; Shaka: direct; Achebe: literary).
  String getPersonaFeedback({
    required String personaId,
    required double overallScore,
    required List<String> errorTypes,
  }) {
    final persona = HistoricalPersonaRegistry.findById(personaId);

    if (overallScore >= 0.9 && errorTypes.isEmpty) {
      return _successFeedback(personaId, persona);
    }
    if (overallScore >= 0.7) {
      return _encouragingFeedback(personaId, persona, errorTypes);
    }
    return _correctiveFeedback(personaId, persona, errorTypes);
  }

  String _successFeedback(String personaId, HistoricalPersona? persona) {
    if (persona == null) return 'Well said. Your pronunciation was clear.';
    final id = persona.id.toLowerCase();
    if (id.contains('mandela')) {
      return 'That was clear and confident. Keep speaking with the same care.';
    }
    if (id.contains('shaka')) {
      return 'Precise. Say it again with the same strength.';
    }
    if (id.contains('achebe')) {
      return 'The words landed as they should—like a story well told.';
    }
    if (persona.formality > 0.6) {
      return 'Your pronunciation was correct. Continue in this way.';
    }
    return 'Well done. Your pronunciation was clear.';
  }

  String _encouragingFeedback(
    String personaId,
    HistoricalPersona? persona,
    List<String> errorTypes,
  ) {
    if (persona == null) {
      return 'Good attempt. Focus on the sounds that felt difficult and try again.';
    }
    final id = persona.id.toLowerCase();
    if (id.contains('mandela')) {
      return 'You are nearly there. Listen once more to the difficult sounds and try again—patience brings clarity.';
    }
    if (id.contains('shaka')) {
      return 'Close. The right sounds need more precision. Try again.';
    }
    if (id.contains('achebe')) {
      return 'The meaning is there; a few sounds still need to find their place. Try once more.';
    }
    return 'Good effort. Pay attention to the marked sounds and try again.';
  }

  String _correctiveFeedback(
    String personaId,
    HistoricalPersona? persona,
    List<String> errorTypes,
  ) {
    if (persona == null) {
      return 'Some sounds need work. Practice the words with substitutions, deletions, or insertions and try again.';
    }
    final id = persona.id.toLowerCase();
    if (id.contains('mandela')) {
      return 'Take your time. Some sounds are not yet clear. Practice slowly and we will try again.';
    }
    if (id.contains('shaka')) {
      return 'That was not precise enough. Master each sound, then speak again.';
    }
    if (id.contains('achebe')) {
      return 'The words are not quite right yet. Let the sounds settle—then speak again.';
    }
    if (persona.tone.toLowerCase().contains('direct')) {
      return 'Pronunciation needs work. Focus on the errors and repeat.';
    }
    return 'Some pronunciation errors were detected. Practice and try again.';
  }
}
