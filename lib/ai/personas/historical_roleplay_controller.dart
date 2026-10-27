import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:lingafriq/ai/persona_cognition/groq_two_pass_orchestrator.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/personas/persona_disclosure_badge.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';

/// Engagement type for historical roleplay sessions.
enum HistoricalEngagementType {
  storyMode,
  freeConversation,
  opinionDebate,
}

/// Teaching point in a historical roleplay turn.
class TeachingPoint {
  final String type; // vocabulary | grammar | pragmatics
  final String content;

  const TeachingPoint({required this.type, required this.content});

  factory TeachingPoint.fromJson(Map<String, dynamic> json) {
    return TeachingPoint(
      type: json['type'] as String? ?? 'vocabulary',
      content: json['content'] as String? ?? '',
    );
  }
}

/// Historical citation in a turn.
class HistoricalCitation {
  final String source;
  final String relevance;

  const HistoricalCitation({required this.source, required this.relevance});

  factory HistoricalCitation.fromJson(Map<String, dynamic> json) {
    return HistoricalCitation(
      source: json['source'] as String? ?? '',
      relevance: json['relevance'] as String? ?? '',
    );
  }
}

/// Extended turn with teaching points, citations, and emotion.
class HistoricalRoleplayTurn {
  final String speechText;
  final List<TeachingPoint> teachingPoints;
  final String emotionTone;
  final List<HistoricalCitation> historicalCitations;
  final String nextState;
  final List<String> closureOptions;
  final List<String> detectedErrors;
  /// Persona lines are delivered via server TTS unless native clips are wired.
  final bool usesSynthesisedVoice;

  const HistoricalRoleplayTurn({
    required this.speechText,
    this.teachingPoints = const [],
    this.emotionTone = 'calm',
    this.historicalCitations = const [],
    required this.nextState,
    this.closureOptions = const [],
    this.detectedErrors = const [],
    this.usesSynthesisedVoice = true,
  });
}

/// Opening bundle: how-built preamble must precede the first in-character line (P11-007).
class PersonaSessionStart {
  final PersonaHowBuiltFacts howBuilt;
  final HistoricalRoleplayTurn openingTurn;

  const PersonaSessionStart({
    required this.howBuilt,
    required this.openingTurn,
  });
}

/// Session with context memory for continuity within the session.
class HistoricalRoleplaySession {
  final String sessionId;
  final String learnerId;
  final String languageCode;
  final String personaId;
  final HistoricalEngagementType engagementType;
  final List<HistoricalRoleplayTurn> turns;
  final List<String> contextMemory;
  String currentNodeId;

  HistoricalRoleplaySession({
    required this.sessionId,
    required this.learnerId,
    required this.languageCode,
    required this.personaId,
    required this.engagementType,
    List<HistoricalRoleplayTurn>? turns,
    List<String>? contextMemory,
    this.currentNodeId = 'start',
  })  : turns = turns ?? [],
        contextMemory = contextMemory ?? [];
}

/// Session report for assessment: summary of a completed or active session.
class HistoricalRoleplayReport {
  final String sessionId;
  final String learnerId;
  final String languageCode;
  final String personaId;
  final HistoricalEngagementType engagementType;
  final List<HistoricalRoleplayTurn> turns;
  final List<String> contextMemory;

  const HistoricalRoleplayReport({
    required this.sessionId,
    required this.learnerId,
    required this.languageCode,
    required this.personaId,
    required this.engagementType,
    required this.turns,
    required this.contextMemory,
  });
}

/// Main controller: bridges persona registry with roleplay engine.
///
/// Injects persona behavior, documented positions, and (for opinion_debate)
/// opinion inference matrix into prompts. Enforces JSON response schema
/// and updates learner model after each turn.
/// Single gateway endpoint for historical persona turns (P11-008).
class PersonaHistoricalRoleplayGateway {
  PersonaHistoricalRoleplayGateway(this._dio);

  final Dio _dio;

  static const turnPath = '/api/ai/persona/historical-roleplay/turn';

  Future<Map<String, dynamic>> runTurn({
    required String personaId,
    required String languageCode,
    required HistoricalEngagementType engagementType,
    required bool isOpening,
    required HistoricalPersona persona,
    required double learnerMastery,
    String? userMessage,
    String? dominantErrorType,
    List<String> turnHistory = const [],
    List<String> contextMemory = const [],
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        turnPath,
        data: {
          'persona_id': personaId,
          'language_code': languageCode,
          'engagement_type': engagementType.name,
          'is_opening': isOpening,
          if (userMessage != null) 'user_message': userMessage,
          'learner_mastery': learnerMastery,
          if (dominantErrorType != null) 'dominant_error_type': dominantErrorType,
          'turn_history': turnHistory,
          'context_memory': contextMemory,
          'persona': _personaPayload(persona),
        },
        options: Options(contentType: Headers.jsonContentType),
      );
      if (response.statusCode != 200) {
        throw PersonaTurnGatewayError.fromResponse(
          response.statusCode,
          response.data,
        );
      }
      final data = response.data;
      if (data == null || data['ok'] != true) {
        throw PersonaTurnGatewayError.fromResponse(response.statusCode, data);
      }
      return data;
    } on DioException catch (e) {
      throw PersonaTurnGatewayError.fromDio(e);
    }
  }

  static Map<String, dynamic> _personaPayload(HistoricalPersona persona) {
    return {
      'display_name': persona.displayName,
      'start_year': persona.startYear,
      'end_year': persona.endYear,
      'short_bio': persona.shortBio,
      'primary_language': persona.primaryLanguages.isNotEmpty
          ? persona.primaryLanguages.first
          : 'English',
      'voice_style': persona.voiceStyle,
      'pace': persona.pace,
      'tone': persona.tone,
      'openness': persona.openness,
      'formality': persona.formality,
      'humor_level': persona.humorLevel,
      'emotion_range': persona.emotionRange,
      'core_events': persona.coreEvents
          .take(10)
          .map((e) => {'year': e.year, 'event': e.event})
          .toList(),
      'documented_positions': persona.documentedPositions,
      'common_vocabulary': persona.commonVocabulary.take(12).toList(),
      'grammar_patterns': persona.grammarPatterns.take(8).toList(),
      'cultural_pragmatics': persona.culturalPragmatics.take(8).toList(),
      'opinion_inference_matrix': persona.opinionInferenceMatrix.map(
        (k, v) => MapEntry(k, {
          'inference_basis': v.inferenceBasis,
          'confidence': v.confidence,
        }),
      ),
    };
  }
}

class HistoricalRoleplayController {
  final PersonaHistoricalRoleplayGateway _turnGateway;
  final LearnerModelService _learnerModel;

  final Map<String, HistoricalRoleplaySession> _sessions = {};

  static const int _maxContextStatements = 10;
  static const int _maxTurnsBeforeClosure = 25;

  HistoricalRoleplayController({
    required Dio dio,
    LearnerModelService? learnerModel,
  })  : _turnGateway = PersonaHistoricalRoleplayGateway(dio),
        _learnerModel = learnerModel ?? LearnerModelService.instance;

  /// Starts a new historical roleplay session. Returns how-built facts plus opening turn.
  Future<PersonaSessionStart> startPersonaSession({
    required String learnerId,
    required String languageCode,
    required String personaId,
    required HistoricalEngagementType engagementType,
  }) async {
    final persona = HistoricalPersonaRegistry.findById(personaId);
    if (persona == null) {
      throw StateError('Persona not found: $personaId');
    }

    final sessionId =
        '${learnerId}_${personaId}_${DateTime.now().millisecondsSinceEpoch}';
    final session = HistoricalRoleplaySession(
      sessionId: sessionId,
      learnerId: learnerId,
      languageCode: languageCode,
      personaId: personaId,
      engagementType: engagementType,
      turns: [],
      contextMemory: [],
      currentNodeId: 'start',
    );
    _sessions[learnerId] = session;

    final language = persona.primaryLanguages.isNotEmpty
        ? persona.primaryLanguages.first
        : languageCode;
    final skillId = 'historical_roleplay_$language';
    final state =
        _learnerModel.getState(learnerId: learnerId, skillId: skillId);

    final turn = await _generateTurn(
      session: session,
      persona: persona,
      state: state,
      isOpening: true,
      userMessage: null,
    );
    session.turns.add(turn);
    return PersonaSessionStart(
      howBuilt: PersonaHowBuiltFacts.fromPersona(persona),
      openingTurn: turn,
    );
  }

  /// Processes the learner's message and returns the next persona turn.
  /// Updates learner model via [LearnerModelService.recordAttempt].
  Future<HistoricalRoleplayTurn> processLearnerResponse({
    required String learnerId,
    required String response,
    double responseTimeSeconds = 0,
  }) async {
    final session = _sessions[learnerId];
    if (session == null) {
      throw StateError(
          'No active historical roleplay session for learner $learnerId');
    }

    final persona = HistoricalPersonaRegistry.findById(session.personaId);
    if (persona == null) {
      throw StateError('Persona not found: ${session.personaId}');
    }

    final language = persona.primaryLanguages.isNotEmpty
        ? persona.primaryLanguages.first
        : session.languageCode;
    final skillId = 'historical_roleplay_$language';
    final state =
        _learnerModel.getState(learnerId: learnerId, skillId: skillId);

    final turn = await _generateTurn(
      session: session,
      persona: persona,
      state: state,
      isOpening: false,
      userMessage: response,
    );
    _addToContextMemory(session, response);
    session.turns.add(turn);
    session.currentNodeId = turn.nextState;

    await _learnerModel.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: turn.detectedErrors.isEmpty,
      errorTypeIds: turn.detectedErrors,
      responseTimeSeconds: responseTimeSeconds,
    );

    if (session.turns.length >= _maxTurnsBeforeClosure) {
      _sessions.remove(learnerId);
    }

    return turn;
  }

  /// Returns a report for the current session, or null if none.
  HistoricalRoleplayReport? getSessionReport(String learnerId) {
    final session = _sessions[learnerId];
    if (session == null) return null;
    return HistoricalRoleplayReport(
      sessionId: session.sessionId,
      learnerId: session.learnerId,
      languageCode: session.languageCode,
      personaId: session.personaId,
      engagementType: session.engagementType,
      turns: List.from(session.turns),
      contextMemory: List.from(session.contextMemory),
    );
  }

  /// Ends the session for the learner.
  void endSession(String learnerId) {
    _sessions.remove(learnerId);
  }

  void _addToContextMemory(HistoricalRoleplaySession session, String statement) {
    session.contextMemory.add(statement);
    while (session.contextMemory.length > _maxContextStatements) {
      session.contextMemory.removeAt(0);
    }
  }

  Future<HistoricalRoleplayTurn> _generateTurn({
    required HistoricalRoleplaySession session,
    required HistoricalPersona persona,
    required LearnerSkillState state,
    required bool isOpening,
    String? userMessage,
  }) async {
    final language = persona.primaryLanguages.isNotEmpty
        ? persona.primaryLanguages.first
        : session.languageCode;
    final historyLines = <String>[];
    for (final t in session.turns) {
      historyLines.add('Persona: ${t.speechText}');
    }

    final data = await _turnGateway.runTurn(
      personaId: session.personaId,
      languageCode: language,
      engagementType: session.engagementType,
      isOpening: isOpening,
      persona: persona,
      learnerMastery: state.mastery,
      userMessage: userMessage,
      dominantErrorType: state.dominantErrorType,
      turnHistory: historyLines,
      contextMemory: session.contextMemory,
    );

    final parsed = Map<String, dynamic>.from(data);

    final teachingRaw = parsed['language_teaching_points'] as List<dynamic>? ??
        parsed['teaching_points'] as List<dynamic>?;
    final teachingPoints = teachingRaw
            ?.map((e) => TeachingPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final citations = (parsed['historical_citations'] as List<dynamic>?)
            ?.map((e) => HistoricalCitation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final closureOptions = (parsed['closure_options'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    final nextState = parsed['next_beat'] as String? ??
        parsed['next_state'] as String? ??
        parsed['conversation_state'] as String? ??
        'turn_${session.turns.length + 1}';

    final emotion = parsed['emotion'] as String? ??
        parsed['emotion_tone'] as String? ??
        'neutral';

    return HistoricalRoleplayTurn(
      speechText: parsed['speech_text'] as String,
      teachingPoints: teachingPoints,
      emotionTone: emotion,
      historicalCitations: citations,
      nextState: nextState,
      closureOptions: closureOptions,
      detectedErrors: _parseDetectedErrors(parsed),
      usesSynthesisedVoice: true,
    );
  }

  /// Exposes the roleplay system prompt for compliance scans (P11-007 AC4).
  @visibleForTesting
  String buildRoleplaySystemPromptForTest({
    required HistoricalPersona persona,
    required String languageCode,
    required HistoricalEngagementType engagementType,
  }) {
    final session = HistoricalRoleplaySession(
      sessionId: 'scan',
      learnerId: 'scan',
      languageCode: languageCode,
      personaId: persona.id,
      engagementType: engagementType,
    );
    final state = LearnerSkillState.initial(
      skillId: 'historical_roleplay_scan',
      learnerId: 'scan',
    );
    final messages = _buildMessages(session, persona, state, true, null);
    return messages.firstWhere((m) => m['role'] == 'system')['content']!;
  }

  List<String> _parseDetectedErrors(Map<String, dynamic> parsed) {
    final list = parsed['detectedErrors'] ?? parsed['detected_errors'];
    if (list == null || list is! List) return [];
    return list.map((e) => e.toString()).toList();
  }

  List<Map<String, String>> _buildMessages(
    HistoricalRoleplaySession session,
    HistoricalPersona persona,
    LearnerSkillState state,
    bool isOpening,
    String? userMessage,
  ) {
    final language = persona.primaryLanguages.isNotEmpty
        ? persona.primaryLanguages.first
        : session.languageCode;
    final coreEventsStr = persona.coreEvents
        .take(10)
        .map((e) => '${e.year}: ${e.event}')
        .join('; ');
    final positionsStr = persona.documentedPositions.entries
        .take(10)
        .map((e) => '${e.key}: ${e.value}')
        .join('; ');
    final behaviorProfile =
        'openness ${persona.openness}, formality ${persona.formality}, humor ${persona.humorLevel}. '
        'Voice: ${persona.voiceStyle}, pace ${persona.pace}, tone ${persona.tone}. '
        'Emotion range: ${persona.emotionRange.join(", ")}.';

    String systemContent = '''You are ${persona.displayName} in a historical roleplay. Target language: $language.
Bio: ${persona.shortBio}

BEHAVIOR AND TONE: $behaviorProfile
CORE EVENTS YOU KNOW: $coreEventsStr
DOCUMENTED POSITIONS (stay consistent): $positionsStr

LANGUAGE TEACHING: Use vocabulary: ${persona.commonVocabulary.take(8).join(", ")}. Grammar patterns: ${persona.grammarPatterns.take(5).join("; ")}. Cultural pragmatics: ${persona.culturalPragmatics.take(5).join("; ")}.

Engagement mode: ${session.engagementType.name}.

RULES:
- You are an AI recreation grounded in dossier sources. Stay in character for teaching dialogue; never claim to be the living historical person.
- If the learner asks whether you are real, human, or AI, answer honestly that you are an AI recreation based on sources, then continue in character.
- When discussing topics not in your documented positions, indicate uncertainty where appropriate.
- TEACHING POINTS ARE MANDATORY: every response must include at least one teaching_points entry (vocabulary, grammar, or pragmatics).
- Respond with JSON only. Schema (P11-003):
{
  "speech_text": "your in-character response",
  "language_teaching_points": [{"type": "vocabulary|grammar|pragmatics", "content": "brief teaching note"}],
  "claims": [{"text": "factual claim", "support": "documented|inferred|legend", "source_ids": []}],
  "emotion": "neutral|happy|proud|curious|concerned|surprised|thinking|encouraging|playful|focused",
  "next_beat": "string"
}''';

    if (session.engagementType == HistoricalEngagementType.opinionDebate &&
        persona.opinionInferenceMatrix.isNotEmpty) {
      final matrixStr = persona.opinionInferenceMatrix.entries
          .map((e) =>
              '${e.key}: basis ${e.value.inferenceBasis.join(", ")} (confidence ${e.value.confidence})')
          .join('; ');
      systemContent += '\n\nOPINION DEBATE — infer only from documented positions. Opinion inference matrix (use confidence): $matrixStr';
    }

    final historyLines = <String>[];
    for (final t in session.turns) {
      historyLines.add('Persona: ${t.speechText}');
    }
    if (session.contextMemory.isNotEmpty) {
      historyLines
          .add('Learner earlier: ${session.contextMemory.take(10).join("; ")}');
    }
    final learnerMastery = (state.mastery * 100).toStringAsFixed(0);
    final errorSummary = state.dominantErrorType != null
        ? 'Dominant error type: ${state.dominantErrorType}'
        : '';

    final contextPrompt =
        'Learner mastery (this skill): $learnerMastery%. $errorSummary';

    final userContent = isOpening
        ? 'Start the ${session.engagementType.name} roleplay. Greet the learner and set the scene in $language. $contextPrompt'
        : 'Conversation so far:\n${historyLines.join("\n")}\n\n$contextPrompt\n\nLearner just said: "$userMessage"';

    return [
      {'role': 'system', 'content': systemContent},
      {'role': 'user', 'content': userContent},
    ];
  }
}
