import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/pronunciation/pronunciation_pipeline.dart';
import 'package:lingafriq/ai/pedagogy/error_classifier.dart';

/// Integrates pronunciation scoring with historical personas.
///
/// When a learner is in a persona roleplay session, pronunciation drills
/// are contextualised to the persona's language, vocabulary, and cultural
/// pragmatics. Feedback is delivered in the persona's voice/style.
class PersonaPronunciationService {
  final PronunciationPipeline _pipeline;
  final LearnerModelService _learnerModel;

  PersonaPronunciationService({
    PronunciationPipeline? pipeline,
    LearnerModelService? learnerModel,
  })  : _pipeline = pipeline ?? PronunciationPipeline(),
        _learnerModel = learnerModel ?? LearnerModelService.instance;

  /// Generates pronunciation drills from a persona's language teaching focus.
  List<PersonaPronunciationDrill> generateDrills({
    required String personaId,
    required String learnerId,
    int maxDrills = 5,
  }) {
    final persona = HistoricalPersonaRegistry.findById(personaId);
    if (persona == null) return [];

    final vocabulary = persona.commonVocabulary;
    final patterns = persona.grammarPatterns;
    final pragmatics = persona.culturalPragmatics;

    final drills = <PersonaPronunciationDrill>[];

    for (final word in vocabulary.take(maxDrills)) {
      final skillId = 'pronunciation_${persona.primaryLanguages.first.toLowerCase()}_$word'
          .replaceAll(' ', '_');

      final state = _learnerModel.getState(
        learnerId: learnerId,
        skillId: skillId,
      );

      drills.add(PersonaPronunciationDrill(
        personaId: personaId,
        targetText: word,
        skillId: skillId,
        contextSentence: _buildContextSentence(word, persona),
        difficulty: state.mastery < 0.3 ? 0.3 : state.mastery,
        category: DrillCategory.vocabulary,
        personaFeedbackPrefix: _feedbackPrefix(persona),
      ));
    }

    for (final pattern in patterns.take(2)) {
      final skillId = 'pronunciation_pattern_${pattern.hashCode.abs()}';
      drills.add(PersonaPronunciationDrill(
        personaId: personaId,
        targetText: pattern,
        skillId: skillId,
        contextSentence: 'Practice this pattern from ${persona.displayName}\'s speech.',
        difficulty: 0.5,
        category: DrillCategory.grammar,
        personaFeedbackPrefix: _feedbackPrefix(persona),
      ));
    }

    for (final pragmatic in pragmatics.take(1)) {
      final skillId = 'pronunciation_pragmatic_${pragmatic.hashCode.abs()}';
      drills.add(PersonaPronunciationDrill(
        personaId: personaId,
        targetText: pragmatic,
        skillId: skillId,
        contextSentence: 'Cultural expression used in ${persona.region}.',
        difficulty: 0.6,
        category: DrillCategory.pragmatic,
        personaFeedbackPrefix: _feedbackPrefix(persona),
      ));
    }

    return drills.take(maxDrills).toList();
  }

  /// Evaluates a pronunciation attempt within a persona context.
  ///
  /// Wraps the standard pipeline but adds persona-contextual feedback
  /// and returns a persona-styled correction message.
  Future<PersonaPronunciationResult> evaluateInPersonaContext({
    required String personaId,
    required String learnerId,
    required String skillId,
    required List<PhonemeResult> expectedPhonemes,
    required List<PhonemeResult> actualPhonemes,
    double responseTimeSeconds = 0,
  }) async {
    final persona = HistoricalPersonaRegistry.findById(personaId);

    final result = await _pipeline.evaluate(
      learnerId: learnerId,
      skillId: skillId,
      expectedPhonemes: expectedPhonemes,
      actualPhonemes: actualPhonemes,
      responseTimeSeconds: responseTimeSeconds,
    );

    final personaFeedback = _generatePersonaFeedback(result, persona);

    return PersonaPronunciationResult(
      baseResult: result,
      personaFeedback: personaFeedback,
      personaId: personaId,
      suggestedRetry: !result.isCorrect,
      culturalNote: _culturalNote(result, persona),
    );
  }

  /// Evaluates text-based pronunciation when phoneme ASR unavailable.
  Future<PersonaPronunciationResult> evaluateTextInPersonaContext({
    required String personaId,
    required String learnerId,
    required String skillId,
    required String expectedText,
    required String actualText,
    required List<String> expectedPhonemeStrings,
    double responseTimeSeconds = 0,
  }) async {
    final persona = HistoricalPersonaRegistry.findById(personaId);

    final result = await _pipeline.evaluateFromText(
      learnerId: learnerId,
      skillId: skillId,
      expectedText: expectedText,
      actualText: actualText,
      expectedPhonemeStrings: expectedPhonemeStrings,
      responseTimeSeconds: responseTimeSeconds,
    );

    final personaFeedback = _generatePersonaFeedback(result, persona);

    return PersonaPronunciationResult(
      baseResult: result,
      personaFeedback: personaFeedback,
      personaId: personaId,
      suggestedRetry: !result.isCorrect,
      culturalNote: _culturalNote(result, persona),
    );
  }

  String _feedbackPrefix(HistoricalPersona persona) {
    switch (persona.tone) {
      case 'calm':
        return 'Gently now —';
      case 'authoritative':
        return 'Listen carefully —';
      case 'passionate':
        return 'With feeling —';
      case 'poetic':
        return 'Let the rhythm guide you —';
      case 'pragmatic':
        return 'Practically speaking —';
      default:
        return 'Try again —';
    }
  }

  String _buildContextSentence(String word, HistoricalPersona persona) {
    if (persona.coreEvents.isNotEmpty) {
      return 'A word from the era of ${persona.coreEvents.first.event}.';
    }
    return 'A word important to ${persona.displayName}.';
  }

  String _generatePersonaFeedback(
    PronunciationEvaluationResult result,
    HistoricalPersona? persona,
  ) {
    if (persona == null) return result.feedback.summary;

    final prefix = _feedbackPrefix(persona);
    if (result.isCorrect) {
      return '$prefix well spoken. ${persona.displayName} would approve.';
    }

    final errorSummary = result.errors.isNotEmpty
        ? result.errors.first.description
        : 'some sounds need attention';

    return '$prefix $errorSummary. In ${persona.region}, '
        'this sound carries meaning. Try once more.';
  }

  String? _culturalNote(
    PronunciationEvaluationResult result,
    HistoricalPersona? persona,
  ) {
    if (persona == null) return null;
    if (persona.culturalPragmatics.isEmpty) return null;
    if (result.overallScore > 0.8) return null;

    return 'In ${persona.region}, ${persona.culturalPragmatics.first}. '
        'Pronunciation carries cultural respect.';
  }
}

enum DrillCategory { vocabulary, grammar, pragmatic }

class PersonaPronunciationDrill {
  final String personaId;
  final String targetText;
  final String skillId;
  final String contextSentence;
  final double difficulty;
  final DrillCategory category;
  final String personaFeedbackPrefix;

  const PersonaPronunciationDrill({
    required this.personaId,
    required this.targetText,
    required this.skillId,
    required this.contextSentence,
    required this.difficulty,
    required this.category,
    required this.personaFeedbackPrefix,
  });
}

class PersonaPronunciationResult {
  final PronunciationEvaluationResult baseResult;
  final String personaFeedback;
  final String personaId;
  final bool suggestedRetry;
  final String? culturalNote;

  const PersonaPronunciationResult({
    required this.baseResult,
    required this.personaFeedback,
    required this.personaId,
    required this.suggestedRetry,
    this.culturalNote,
  });

  double get overallScore => baseResult.overallScore;
  bool get isCorrect => baseResult.isCorrect;
}
