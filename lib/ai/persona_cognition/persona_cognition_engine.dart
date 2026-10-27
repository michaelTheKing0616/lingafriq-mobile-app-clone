// Core reasoning engine: local classifiers, server two-pass cognition via gateway.

import 'package:dio/dio.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/persona_cognition/epistemic_classifier.dart';
import 'package:lingafriq/ai/persona_cognition/intent_classifier.dart';
import 'package:lingafriq/ai/persona_cognition/persona_cognition_gateway.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';

class TeachingPoint {
  final String type; // grammar, vocabulary, pragmatics
  final String note;

  const TeachingPoint({required this.type, required this.note});
}

class HistoricalCitation {
  final String source;
  final String relevance;

  const HistoricalCitation({required this.source, required this.relevance});
}

class PersonaCognitionResult {
  final String personaReply;
  final EpistemicStatus epistemicStatus;
  final double confidence;
  final List<TeachingPoint> languageFeedback;
  final String? culturalNote;
  final List<HistoricalCitation> citations;
  final String emotionTone;

  const PersonaCognitionResult({
    required this.personaReply,
    required this.epistemicStatus,
    required this.confidence,
    this.languageFeedback = const [],
    this.culturalNote,
    this.citations = const [],
    this.emotionTone = 'calm',
  });
}

class PersonaCognitionEngine {
  final PersonaCognitionGateway _gateway;
  final LearnerModelService _learnerModel;

  PersonaCognitionEngine({
    required Dio dio,
    LearnerModelService? learnerModel,
  })  : _gateway = PersonaCognitionGateway(dio),
        _learnerModel = learnerModel ?? LearnerModelService.instance;

  /// Processes user input through intent → epistemic → gateway turn → learner update.
  Future<PersonaCognitionResult> processInput({
    required String userInput,
    required String personaId,
    required String learnerId,
    required String languageCode,
    List<String> conversationHistory = const [],
  }) async {
    final persona = HistoricalPersonaRegistry.findById(personaId);
    if (persona == null) {
      throw StateError('Persona not found: $personaId');
    }

    final intent = IntentClassifier.classify(userInput, personaId);
    final epistemic =
        EpistemicClassifier.classify(userInput: userInput, persona: persona, intent: intent);

    if (epistemic.status == EpistemicStatus.outOfScope) {
      return PersonaCognitionResult(
        personaReply:
            '${persona.displayName} would prefer to speak of matters within their time and experience.',
        epistemicStatus: EpistemicStatus.outOfScope,
        confidence: epistemic.confidence,
        emotionTone: 'calm',
      );
    }

    final language = persona.primaryLanguages.isNotEmpty
        ? persona.primaryLanguages.first
        : languageCode;
    final skillId = 'historical_roleplay_$language';
    final state = _learnerModel.getState(learnerId: learnerId, skillId: skillId);
    final learnerMastery = state.mastery;

    final turn = await _gateway.runTurn(
      personaId: personaId,
      userInput: userInput,
      languageCode: languageCode,
      learnerMastery: learnerMastery,
      epistemicStatus: epistemic.status.name,
      epistemicReasoning: epistemic.reasoning,
      epistemicConfidence: epistemic.confidence,
      persona: persona,
      intentDomain: intent.domain.name,
      intentType: intent.type.name,
      conversationHistory: conversationHistory,
    );

    EpistemicStatus resultStatus = epistemic.status;
    final normalized = turn.epistemicStatus.toLowerCase().replaceAll('_', '');
    for (final e in EpistemicStatus.values) {
      if (e.name.toLowerCase().replaceAll('_', '') == normalized) {
        resultStatus = e;
        break;
      }
    }

    final languageFeedback = turn.languageFeedback
        .map((e) => TeachingPoint(type: e['type'] ?? 'vocabulary', note: e['note'] ?? ''))
        .toList();
    final citations = turn.historicalCitations
        .map((e) => HistoricalCitation(source: e['source'] ?? '', relevance: e['relevance'] ?? ''))
        .toList();

    await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: turn.critiquePassed && turn.critiqueIssues.isEmpty,
      errorTypeIds: turn.critiqueIssues,
      responseTimeSeconds: 0,
    );

    return PersonaCognitionResult(
      personaReply: turn.personaReply,
      epistemicStatus: resultStatus,
      confidence: turn.confidence,
      languageFeedback: languageFeedback,
      culturalNote: turn.culturalNote?.isNotEmpty == true ? turn.culturalNote : null,
      citations: citations,
      emotionTone: turn.emotionTone,
    );
  }
}
