import 'package:dio/dio.dart';

import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/validation/response_validator.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';

/// Engagement type for historical roleplay sessions.
enum HistoricalEngagementType {
  story_mode,
  free_conversation,
  opinion_debate,
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

  const HistoricalRoleplayTurn({
    required this.speechText,
    this.teachingPoints = const [],
    this.emotionTone = 'calm',
    this.historicalCitations = const [],
    required this.nextState,
    this.closureOptions = const [],
    this.detectedErrors = const [],
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
class HistoricalRoleplayController {
  final Dio _dio;
  final String _apiKey;
  final String _apiUrl;
  final String _model;
  final LearnerModelService _learnerModel;

  final Map<String, HistoricalRoleplaySession> _sessions = {};

  static const int _maxContextStatements = 10;
  static const int _maxTurnsBeforeClosure = 25;

  HistoricalRoleplayController({
    required Dio dio,
    required String apiKey,
    required String apiUrl,
    String model = 'llama-3.3-70b-versatile',
    LearnerModelService? learnerModel,
  })  : _dio = dio,
        _apiKey = apiKey,
        _apiUrl = apiUrl,
        _model = model,
        _learnerModel = learnerModel ?? LearnerModelService.instance;

  /// Starts a new historical roleplay session. Returns the opening turn.
  Future<HistoricalRoleplayTurn> startPersonaSession({
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
    return turn;
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

    _addToContextMemory(session, response);

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
    final messages =
        _buildMessages(session, persona, state, isOpening, userMessage);

    try {
      final response = await _dio.post(
        _apiUrl,
        options: Options(headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': _model,
          'messages': messages,
          'temperature': 0.35,
          'max_tokens': 500,
          'response_format': {'type': 'json_object'},
        },
      );

      final content =
          response.data['choices'][0]['message']['content'] as String;
      final parsed = ResponseValidator.validateHistoricalRoleplayResponse(content);

      final teachingPoints = (parsed['teaching_points'] as List<dynamic>?)
              ?.map((e) => TeachingPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final citations =
          (parsed['historical_citations'] as List<dynamic>?)
              ?.map((e) =>
                  HistoricalCitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final closureOptions =
          (parsed['closure_options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];

      final nextState = parsed['next_state'] as String? ??
          parsed['conversation_state'] as String? ??
          'turn_${session.turns.length + 1}';

      return HistoricalRoleplayTurn(
        speechText: parsed['speech_text'] as String,
        teachingPoints: teachingPoints,
        emotionTone: parsed['emotion_tone'] as String? ?? 'calm',
        historicalCitations: citations,
        nextState: nextState,
        closureOptions: closureOptions,
        detectedErrors: _parseDetectedErrors(parsed),
      );
    } catch (e) {
      final fallback = isOpening
          ? '${persona.displayName} greets you. (Response unavailable; please try again.)'
          : 'I hear you. Let us continue.';
      return HistoricalRoleplayTurn(
        speechText: fallback,
        nextState: session.currentNodeId,
        detectedErrors: [],
      );
    }
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
- Stay in character. Do not reference being an AI.
- When discussing topics not in your documented positions, indicate uncertainty where appropriate.
- TEACHING POINTS ARE MANDATORY: every response must include at least one teaching_points entry (vocabulary, grammar, or pragmatics).
- Respond with JSON only. Schema:
{
  "speech_text": "your in-character response",
  "teaching_points": [{"type": "vocabulary|grammar|pragmatics", "content": "brief teaching note"}],
  "emotion_tone": "string",
  "historical_citations": [{"source": "string", "relevance": "string"}],
  "next_state": "string",
  "closure_options": ["string"]
}''';

    if (session.engagementType == HistoricalEngagementType.opinion_debate &&
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
