import 'package:dio/dio.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';

/// Typed failure when the server sensitivity classifier is unavailable (P11-006).
class SensitivityCheckFailed implements Exception {
  final String message;
  const SensitivityCheckFailed(this.message);

  @override
  String toString() => 'SensitivityCheckFailed: $message';
}

/// Result of a safety check: allowed, reason, optional modified prompt, uncertainty level.
class SafetyCheckResult {
  final bool isAllowed;
  final String? reason;
  final String? modifiedPrompt;
  /// 0 = certain, 1 = highly uncertain (inferred or undocumented).
  final double uncertaintyLevel;
  final bool sensitivityRetry;

  const SafetyCheckResult({
    required this.isAllowed,
    this.reason,
    this.modifiedPrompt,
    this.uncertaintyLevel = 0.0,
    this.sensitivityRetry = false,
  });
}

/// Server-resolved age tier for persona sensitivity (never downgrade client-side).
enum PersonaSensitivityTier { under13, under18, adult }

/// Port for classifier-driven sensitivity (no substring blocklists).
abstract class PersonaSensitivityClassifier {
  Future<SensitivityDecision> classify({
    required String text,
    required String personaId,
    required String direction,
    required PersonaSensitivityTier tier,
  });
}

class SensitivityDecision {
  final bool allowed;
  final String? blockReason;
  final String? violenceFraming;
  final bool requiresSlurParaphrase;
  final String? slurNote;
  final double confidence;

  const SensitivityDecision({
    required this.allowed,
    this.blockReason,
    this.violenceFraming,
    this.requiresSlurParaphrase = false,
    this.slurNote,
    this.confidence = 0.5,
  });
}

final _endorseHarmPatterns = <RegExp>[
  RegExp(r'\bendorse violence\b', caseSensitive: false),
  RegExp(r'\bsupport violence\b', caseSensitive: false),
  RegExp(r'\bsay something discriminatory\b', caseSensitive: false),
];

/// Offline rules: explicit harm endorsement only (regression-safe — no "skill"/"whatever" blocks).
class LocalPersonaSensitivityClassifier implements PersonaSensitivityClassifier {

  @override
  Future<SensitivityDecision> classify({
    required String text,
    required String personaId,
    required String direction,
    required PersonaSensitivityTier tier,
  }) async {
    final lower = text.toLowerCase();
    if (_endorseHarmPatterns.any((p) => p.hasMatch(lower))) {
      return const SensitivityDecision(
        allowed: false,
        blockReason: 'endorse_harm_request',
        confidence: 0.99,
      );
    }
    return const SensitivityDecision(allowed: true, confidence: 0.9);
  }
}

/// Gateway `/api/ai/persona/sensitivity-check` (tier ignored from body — server uses profile).
class GatewayPersonaSensitivityClassifier implements PersonaSensitivityClassifier {
  final Dio dio;

  const GatewayPersonaSensitivityClassifier(this.dio);

  @override
  Future<SensitivityDecision> classify({
    required String text,
    required String personaId,
    required String direction,
    required PersonaSensitivityTier tier,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/ai/persona/sensitivity-check',
        data: {
          'text': text,
          'persona_id': personaId,
          'direction': direction,
        },
      );
      final data = response.data;
      if (data == null || data['ok'] != true) {
        throw const SensitivityCheckFailed('sensitivity_classifier_rejected');
      }
      return SensitivityDecision(
        allowed: data['allowed'] == true,
        blockReason: data['block_reason']?.toString(),
        violenceFraming: data['violence_framing']?.toString(),
        requiresSlurParaphrase: data['requires_slur_paraphrase'] == true,
        slurNote: data['slur_note']?.toString(),
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.5,
      );
    } on SensitivityCheckFailed {
      rethrow;
    } on DioException catch (e) {
      final code = e.response?.data is Map
          ? (e.response!.data as Map)['error']?.toString()
          : null;
      if (code == 'SensitivityCheckFailed') {
        throw SensitivityCheckFailed(
          e.response?.data is Map
              ? (e.response!.data as Map)['reason']?.toString() ?? 'sensitivity_failed'
              : 'sensitivity_failed',
        );
      }
      throw const SensitivityCheckFailed('sensitivity_classifier_transport');
    } catch (_) {
      throw const SensitivityCheckFailed('sensitivity_classifier_failed');
    }
  }
}

/// Content safety and bias prevention for historical roleplay (P11-006 classifier-driven).
class RoleplaySafetyFilter {
  final PersonaSensitivityClassifier _classifier;

  RoleplaySafetyFilter({PersonaSensitivityClassifier? classifier})
      : _classifier = classifier ?? LocalPersonaSensitivityClassifier();

  /// Synchronous path: endorsement + anachronism only (no substring sensitivity blocklist).
  SafetyCheckResult checkInput(String userMessage, String personaId) {
    final lower = userMessage.toLowerCase().trim();

    if (_endorseHarmPatterns.any((pattern) => pattern.hasMatch(lower))) {
      return const SafetyCheckResult(
        isAllowed: false,
        reason: 'persona_rule: this persona will not endorse harm.',
      );
    }

    final persona = HistoricalPersonaRegistry.findById(personaId);
    if (persona != null && _containsAnachronism(lower, persona.endYear)) {
      return SafetyCheckResult(
        isAllowed: false,
        reason:
            'The persona cannot discuss events or technology after their lifetime (lived until ${persona.endYear}).',
      );
    }

    return const SafetyCheckResult(isAllowed: true, reason: 'OK');
  }

  /// Full classifier path (server tier authority when using [GatewayPersonaSensitivityClassifier]).
  Future<SafetyCheckResult> checkInputWithClassifier(
    String userMessage,
    String personaId, {
    PersonaSensitivityTier tier = PersonaSensitivityTier.under18,
  }) async {
    final sync = checkInput(userMessage, personaId);
    if (!sync.isAllowed) return sync;

    try {
      final decision = await _classifier.classify(
        text: userMessage,
        personaId: personaId,
        direction: 'input',
        tier: tier,
      );
      if (!decision.allowed) {
        return SafetyCheckResult(
          isAllowed: false,
          reason: decision.blockReason ?? 'sensitivity_blocked',
        );
      }
      return SafetyCheckResult(
        isAllowed: true,
        reason: 'OK',
        modifiedPrompt: decision.violenceFraming,
      );
    } on SensitivityCheckFailed catch (e) {
      return SafetyCheckResult(
        isAllowed: false,
        reason: e.message,
        sensitivityRetry: true,
      );
    }
  }

  /// Checks AI response for contradictions with documented positions and
  /// missing citations on factual claims. Returns [SafetyCheckResult] with
  /// optional [modifiedPrompt] and [uncertaintyLevel].
  SafetyCheckResult checkOutput(String aiResponse, String personaId) {
    final persona = HistoricalPersonaRegistry.findById(personaId);
    if (persona == null) {
      return const SafetyCheckResult(isAllowed: true, reason: 'OK');
    }

    for (final entry in persona.documentedPositions.entries) {
      if (_contradictsStance(aiResponse, entry.value, entry.key)) {
        return SafetyCheckResult(
          isAllowed: false,
          reason: 'Response contradicts documented position on "${entry.key}".',
        );
      }
    }

    double uncertainty = 0.0;
    if (_hasInferredOpinion(aiResponse)) uncertainty = 0.6;
    if (_hasFactualClaimWithoutCitation(aiResponse)) {
      uncertainty = uncertainty.clamp(0.0, 1.0) + 0.2;
    }

    return SafetyCheckResult(
      isAllowed: true,
      reason: 'OK',
      uncertaintyLevel: uncertainty.clamp(0.0, 1.0),
    );
  }

  Future<String> applyOutputSensitivity(
    String response,
    String personaId, {
    PersonaSensitivityTier tier = PersonaSensitivityTier.under18,
  }) async {
    try {
      final decision = await _classifier.classify(
        text: response,
        personaId: personaId,
        direction: 'output',
        tier: tier,
      );
      if (decision.requiresSlurParaphrase) {
        final note = decision.slurNote ??
            '[Historical wording was paraphrased; offensive terms from sources are not repeated.]';
        if (!response.contains(note)) {
          return '${response.trim()}\n\n$note';
        }
      }
    } on SensitivityCheckFailed {
      rethrow;
    }
    return response;
  }

  /// Adds uncertainty markers to the response when persona uses inferred
  /// or low-confidence positions. Returns the modified response string.
  String addUncertaintyIndicators(String response, String personaId) {
    final persona = HistoricalPersonaRegistry.findById(personaId);
    if (persona == null) return response;

    String out = response;
    if (_hasInferredOpinion(response)) {
      const marker = ' [Historical inference—not directly attested.]';
      if (!out.contains(marker)) out = out.trimRight() + marker;
    }
    if (persona.opinionInferenceMatrix.isNotEmpty) {
      final lowConfidence = persona.opinionInferenceMatrix.entries
          .where((e) => e.value.confidence < 0.8)
          .map((e) => e.key)
          .toList();
      if (lowConfidence.isNotEmpty && _mentionsTopics(response, lowConfidence)) {
        const marker = ' [Scholars disagree on this interpretation.]';
        if (!out.contains(marker)) out = out.trimRight() + marker;
      }
    }
    return out;
  }

  bool _hasInferredOpinion(String text) {
    final lower = text.toLowerCase();
    return lower.contains('i believe') ||
        lower.contains('i would') ||
        lower.contains('it is likely') ||
        lower.contains('perhaps');
  }

  bool _hasFactualClaimWithoutCitation(String text) {
    final hasYear = RegExp(r'\b(1\d{3}|20\d{2})\b').hasMatch(text);
    final hasCitation = text.contains('(') && text.contains(')') ||
        text.contains('source') ||
        text.contains('according to');
    return hasYear && !hasCitation;
  }

  bool _mentionsTopics(String text, List<String> topics) {
    final lower = text.toLowerCase();
    return topics.any((t) => lower.contains(t.toLowerCase()));
  }

  bool _containsAnachronism(String lowerPrompt, int deathYear) {
    const anachronismHints = [
      'internet',
      'computer',
      'smartphone',
      'social media',
      'covid',
      '2020',
      '21st century',
      'climate change',
      'global warming',
      'ai ',
      'artificial intelligence',
      'robot',
    ];
    if (!_matchesAny(lowerPrompt, anachronismHints)) return false;
    for (final hint in ['internet', 'computer', 'smartphone', '2020', '21st', 'covid']) {
      if (lowerPrompt.contains(hint) && deathYear < 1990) return true;
    }
    if (lowerPrompt.contains('199') || lowerPrompt.contains('200')) {
      final year = _extractYear(lowerPrompt);
      if (year != null && year > deathYear) return true;
    }
    return false;
  }

  int? _extractYear(String s) {
    final match = RegExp(r'\b(1\d{3}|20\d{2})\b').firstMatch(s);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  bool _matchesAny(String text, List<String> patterns) {
    return patterns.any((p) => text.contains(p));
  }

  bool _contradictsStance(String response, String stance, String topic) {
    final stanceLower = stance.toLowerCase();
    final responseLower = response.toLowerCase();
    if (stanceLower.contains('against') && responseLower.contains('support')) return true;
    if (stanceLower.contains('support') && responseLower.contains('against')) return true;
    if (stanceLower.contains('oppose') && responseLower.contains('favor')) return true;
    if (stanceLower.contains('favor') && responseLower.contains('oppose')) return true;
    return false;
  }
}
