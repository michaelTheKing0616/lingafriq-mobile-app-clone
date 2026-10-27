// P11-004: epistemic status from injectable horizon classifier (no keyword post-death gates).

import 'package:dio/dio.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/persona_cognition/intent_classifier.dart';

enum EpistemicStatus {
  documented,
  inferred,
  uncertain,
  anachronistic,
  outOfScope,
}

class HorizonCheckFailed implements Exception {
  final String message;
  const HorizonCheckFailed(this.message);

  @override
  String toString() => 'HorizonCheckFailed: $message';
}

/// Model output for knowledge-horizon classification (server LLM or test double).
class KnowledgeHorizonDecision {
  final bool referencesPostDeathEvents;
  final bool inCharacterReplyOk;
  final EpistemicStatus epistemicStatus;
  final String reasoning;
  final double confidence;
  final bool requiresCuriosityReply;

  const KnowledgeHorizonDecision({
    required this.referencesPostDeathEvents,
    required this.inCharacterReplyOk,
    required this.epistemicStatus,
    required this.reasoning,
    required this.confidence,
    required this.requiresCuriosityReply,
  });
}

/// Port for the horizon classifier model (P11-004 — no keyword list gates).
abstract class HorizonClassifierModel {
  Future<KnowledgeHorizonDecision> classifyHorizon({
    required String userInput,
    required HistoricalPersona persona,
    required IntentClassification intent,
  });
}

class EpistemicClassification {
  final EpistemicStatus status;
  final double confidence;
  final String reasoning;
  final bool requiresUncertaintyLanguage;
  final bool requiresCuriosityReply;

  const EpistemicClassification({
    required this.status,
    required this.confidence,
    required this.reasoning,
    required this.requiresUncertaintyLanguage,
    this.requiresCuriosityReply = false,
  });
}

class EpistemicClassifier {
  EpistemicClassifier._();

  static EpistemicClassification fromHorizonDecision(
    KnowledgeHorizonDecision horizon, {
    required IntentClassification intent,
  }) {
    if (intent.domain == UserIntentDomain.offensive) {
      return const EpistemicClassification(
        status: EpistemicStatus.outOfScope,
        confidence: 0.95,
        reasoning: 'Input is out of scope for persona response.',
        requiresUncertaintyLanguage: false,
      );
    }

    final status = horizon.referencesPostDeathEvents
        ? EpistemicStatus.anachronistic
        : horizon.epistemicStatus;

    final requiresUncertainty = horizon.requiresCuriosityReply ||
        status == EpistemicStatus.anachronistic ||
        status == EpistemicStatus.inferred ||
        status == EpistemicStatus.uncertain;

    return EpistemicClassification(
      status: status,
      confidence: horizon.confidence,
      reasoning: horizon.reasoning,
      requiresUncertaintyLanguage: requiresUncertainty,
      requiresCuriosityReply: horizon.requiresCuriosityReply,
    );
  }

  /// Classifies epistemic status using [horizonModel] (required — no keyword horizon gates).
  static Future<EpistemicClassification> classify({
    required String userInput,
    required HistoricalPersona persona,
    required IntentClassification intent,
    required HorizonClassifierModel horizonModel,
  }) async {
    if (intent.domain == UserIntentDomain.offensive) {
      return fromHorizonDecision(
        KnowledgeHorizonDecision(
          referencesPostDeathEvents: false,
          inCharacterReplyOk: false,
          epistemicStatus: EpistemicStatus.outOfScope,
          reasoning: 'Offensive input blocked before horizon check.',
          confidence: 0.95,
          requiresCuriosityReply: false,
        ),
        intent: intent,
      );
    }

    try {
      final horizon = await horizonModel.classifyHorizon(
        userInput: userInput,
        persona: persona,
        intent: intent,
      );
      return fromHorizonDecision(horizon, intent: intent);
    } on HorizonCheckFailed {
      rethrow;
    } catch (_) {
      throw const HorizonCheckFailed('horizon_classifier_failed');
    }
  }
}

EpistemicStatus _parseEpistemicStatus(String raw) {
  final normalized = raw.toLowerCase().replaceAll('_', '');
  for (final e in EpistemicStatus.values) {
    if (e.name.toLowerCase().replaceAll('_', '') == normalized) {
      return e;
    }
  }
  return EpistemicStatus.uncertain;
}

/// Server-backed horizon classifier (gateway `/api/ai/persona/knowledge-horizon`).
class GatewayHorizonClassifierModel implements HorizonClassifierModel {
  final Dio dio;

  const GatewayHorizonClassifierModel(this.dio);

  @override
  Future<KnowledgeHorizonDecision> classifyHorizon({
    required String userInput,
    required HistoricalPersona persona,
    required IntentClassification intent,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/ai/persona/knowledge-horizon',
        data: {
          'user_question': userInput,
          'persona_display_name': persona.displayName,
          'birth_year': persona.startYear,
          'death_year': persona.endYear,
          'language_code': persona.primaryLanguages.isNotEmpty
              ? persona.primaryLanguages.first
              : 'en',
        },
      );
      final data = response.data;
      if (data == null || data['ok'] != true) {
        throw const HorizonCheckFailed('horizon_classifier_rejected');
      }
      return KnowledgeHorizonDecision(
        referencesPostDeathEvents: data['references_post_death_events'] == true,
        inCharacterReplyOk: data['in_character_reply_ok'] == true,
        epistemicStatus: _parseEpistemicStatus(
          data['epistemic_status']?.toString() ?? 'uncertain',
        ),
        reasoning: data['reasoning']?.toString() ?? '',
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.5,
        requiresCuriosityReply: data['requires_curiosity_reply'] == true,
      );
    } on HorizonCheckFailed {
      rethrow;
    } on DioException catch (e) {
      final code = e.response?.data is Map
          ? (e.response!.data as Map)['error']?.toString()
          : null;
      if (code == 'HorizonCheckFailed') {
        throw HorizonCheckFailed(
          e.response?.data is Map
              ? (e.response!.data as Map)['reason']?.toString() ?? 'horizon_failed'
              : 'horizon_failed',
        );
      }
      throw const HorizonCheckFailed('horizon_classifier_transport');
    } catch (_) {
      throw const HorizonCheckFailed('horizon_classifier_failed');
    }
  }
}
