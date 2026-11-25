import 'package:dio/dio.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/error/typed_errors.dart';

class PersonaCognitionGatewayTurn {
  final String personaReply;
  final String epistemicStatus;
  final double confidence;
  final List<Map<String, String>> languageFeedback;
  final String? culturalNote;
  final List<Map<String, String>> historicalCitations;
  final String emotionTone;
  final bool critiquePassed;
  final List<String> critiqueIssues;

  const PersonaCognitionGatewayTurn({
    required this.personaReply,
    required this.epistemicStatus,
    required this.confidence,
    this.languageFeedback = const [],
    this.culturalNote,
    this.historicalCitations = const [],
    this.emotionTone = 'calm',
    this.critiquePassed = true,
    this.critiqueIssues = const [],
  });

  factory PersonaCognitionGatewayTurn.fromJson(Map<String, dynamic> json) {
    final feedback = <Map<String, String>>[];
    final rawFeedback = json['language_feedback'];
    if (rawFeedback is List) {
      for (final row in rawFeedback) {
        if (row is Map) {
          feedback.add({
            'type': row['type']?.toString() ?? 'vocabulary',
            'note': row['note']?.toString() ?? '',
          });
        }
      }
    }
    final citations = <Map<String, String>>[];
    final rawCitations = json['historical_citations'];
    if (rawCitations is List) {
      for (final row in rawCitations) {
        if (row is Map) {
          citations.add({
            'source': row['source']?.toString() ?? '',
            'relevance': row['relevance']?.toString() ?? '',
          });
        }
      }
    }
    final issuesRaw = json['critique_issues'];
    final issues = issuesRaw is List
        ? issuesRaw.map((e) => e.toString()).toList()
        : <String>[];

    return PersonaCognitionGatewayTurn(
      personaReply: json['persona_reply']?.toString() ?? '',
      epistemicStatus: json['epistemic_status']?.toString() ?? 'uncertain',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      languageFeedback: feedback,
      culturalNote: json['cultural_note']?.toString(),
      historicalCitations: citations,
      emotionTone: json['emotion_tone']?.toString() ?? 'calm',
      critiquePassed: json['critique_passed'] == true,
      critiqueIssues: issues,
    );
  }
}

Map<String, dynamic> personaFactsPayload(HistoricalPersona persona) {
  return {
    'display_name': persona.displayName,
    'start_year': persona.startYear,
    'end_year': persona.endYear,
    'short_bio': persona.shortBio,
    'primary_language':
        persona.primaryLanguages.isNotEmpty ? persona.primaryLanguages.first : 'English',
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
  };
}

class PersonaCognitionGateway {
  PersonaCognitionGateway(this._dio);

  final Dio _dio;

  Future<PersonaCognitionGatewayTurn> runTurn({
    required String personaId,
    required String userInput,
    required String languageCode,
    required double learnerMastery,
    required String epistemicStatus,
    required String epistemicReasoning,
    required double epistemicConfidence,
    required HistoricalPersona persona,
    String? intentDomain,
    String? intentType,
    List<String> conversationHistory = const [],
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiContract.ai.personaCognitionTurn,
      data: {
        'persona_id': personaId,
        'user_input': userInput,
        'language_code': languageCode,
        'learner_mastery': learnerMastery,
        'conversation_history': conversationHistory,
        'epistemic_status': epistemicStatus,
        'epistemic_reasoning': epistemicReasoning,
        'epistemic_confidence': epistemicConfidence,
        if (intentDomain != null) 'intent_domain': intentDomain,
        if (intentType != null) 'intent_type': intentType,
        'persona': personaFactsPayload(persona),
      },
      options: Options(contentType: Headers.jsonContentType),
    );

    if (response.statusCode != 200) {
      throw personaUnavailable;
    }
    final data = response.data;
    if (data == null || data['ok'] != true) {
      throw personaUnavailable;
    }
    final turn = PersonaCognitionGatewayTurn.fromJson(data);
    if (turn.personaReply.trim().isEmpty) {
      throw personaUnavailable;
    }
    return turn;
  }
}
