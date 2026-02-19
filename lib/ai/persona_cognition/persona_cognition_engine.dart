// Core reasoning engine that applies persona as a cognition lens.
// Orchestrates intent → epistemic → Pass 1 → Pass 2 → self-critique → learner update.

import 'package:dio/dio.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/persona_cognition/epistemic_classifier.dart';
import 'package:lingafriq/ai/persona_cognition/groq_two_pass_orchestrator.dart';
import 'package:lingafriq/ai/persona_cognition/intent_classifier.dart';
import 'package:lingafriq/ai/persona_cognition/self_critique.dart';
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
  final Dio _dio;
  final String _apiKey;
  final String _apiUrl;
  final String _model;
  final LearnerModelService _learnerModel;
  late final GroqTwoPassOrchestrator _orchestrator;
  late final SelfCritique _selfCritique;

  PersonaCognitionEngine({
    required Dio dio,
    required String apiKey,
    required String apiUrl,
    String model = 'llama-3.3-70b-versatile',
    LearnerModelService? learnerModel,
  })  : _dio = dio,
        _apiKey = apiKey,
        _apiUrl = apiUrl,
        _model = model,
        _learnerModel = learnerModel ?? LearnerModelService.instance {
    _orchestrator = GroqTwoPassOrchestrator(
      dio: _dio,
      apiKey: _apiKey,
      apiUrl: _apiUrl,
      model: _model,
    );
    _selfCritique = SelfCritique(
      dio: _dio,
      apiKey: _apiKey,
      apiUrl: _apiUrl,
      model: _model,
    );
  }

  /// Processes user input through intent → epistemic → two-pass LLM → critique → learner update.
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

    // 1. Classify intent
    final intent = IntentClassifier.classify(userInput, personaId);

    // 2. Classify epistemic status
    final epistemic =
        EpistemicClassifier.classify(userInput: userInput, persona: persona, intent: intent);

    // Out of scope: return short safe response without LLM
    if (epistemic.status == EpistemicStatus.outOfScope) {
      return PersonaCognitionResult(
        personaReply:
            '${persona.displayName} would prefer to speak of matters within their time and experience.',
        epistemicStatus: EpistemicStatus.outOfScope,
        confidence: epistemic.confidence,
        emotionTone: 'calm',
      );
    }

    // 3. Pass 1: hidden reasoning
    final pass1 = await _orchestrator.runPass1(
      userInput: userInput,
      persona: persona,
      epistemic: epistemic,
      intent: intent,
    );

    // 4. Learner state for Pass 2
    final language = persona.primaryLanguages.isNotEmpty
        ? persona.primaryLanguages.first
        : languageCode;
    final skillId = 'historical_roleplay_$language';
    final state = _learnerModel.getState(learnerId: learnerId, skillId: skillId);
    final learnerMastery = state.mastery;

    // 5. Pass 2: user-facing response
    final pass2Result = await _orchestrator.runPass2(
      userInput: userInput,
      persona: persona,
      pass1: pass1,
      learnerMastery: learnerMastery,
      conversationHistory: conversationHistory,
    );

    String personaReply =
        pass2Result['persona_reply'] as String? ?? persona.displayName;
    final statusStr = pass2Result['epistemic_status'] as String?;
    EpistemicStatus resultStatus = pass1.epistemicStatus;
    if (statusStr != null) {
      final normalized = statusStr.toLowerCase().replaceAll('_', '');
      for (final e in EpistemicStatus.values) {
        if (e.name.toLowerCase().replaceAll('_', '') == normalized) {
          resultStatus = e;
          break;
        }
      }
    }
    final confidence =
        (pass2Result['confidence'] as num?)?.toDouble() ?? pass1.confidence;

    // 6. Self-critique
    final critique = await _selfCritique.critique(
      personaReply: personaReply,
      persona: persona,
      epistemicStatus: resultStatus,
    );
    if (!critique.passedCritique && critique.revisedReply != null) {
      personaReply = critique.revisedReply!;
    }

    // Parse language_feedback and historical_citations
    final feedbackRaw = pass2Result['language_feedback'] as List<dynamic>?;
    final languageFeedback = <TeachingPoint>[];
    if (feedbackRaw != null) {
      for (final e in feedbackRaw) {
        if (e is Map<String, dynamic>) {
          final type = e['type'] as String? ?? 'vocabulary';
          final note = e['note'] as String? ?? e['content'] as String? ?? '';
          languageFeedback.add(TeachingPoint(type: type, note: note));
        }
      }
    }

    final citationsRaw = pass2Result['historical_citations'] as List<dynamic>?;
    final citations = <HistoricalCitation>[];
    if (citationsRaw != null) {
      for (final e in citationsRaw) {
        if (e is Map<String, dynamic>) {
          citations.add(HistoricalCitation(
            source: e['source'] as String? ?? '',
            relevance: e['relevance'] as String? ?? '',
          ));
        }
      }
    }

    final emotionTone =
        pass2Result['emotion_tone'] as String? ?? 'calm';
    final culturalNote = pass2Result['cultural_note'] as String?;

    // 7. Update learner model
    await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: critique.passedCritique && critique.issues.isEmpty,
      errorTypeIds: critique.issues,
      responseTimeSeconds: 0,
    );

    return PersonaCognitionResult(
      personaReply: personaReply,
      epistemicStatus: resultStatus,
      confidence: confidence,
      languageFeedback: languageFeedback,
      culturalNote: culturalNote?.isNotEmpty == true ? culturalNote : null,
      citations: citations,
      emotionTone: emotionTone,
    );
  }
}
