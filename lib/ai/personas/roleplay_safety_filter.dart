import 'package:lingafriq/ai/personas/historical_persona_registry.dart';

/// Result of a safety check: allowed, reason, optional modified prompt, uncertainty level.
class SafetyCheckResult {
  final bool isAllowed;
  final String? reason;
  final String? modifiedPrompt;
  /// 0 = certain, 1 = highly uncertain (inferred or undocumented).
  final double uncertaintyLevel;

  const SafetyCheckResult({
    required this.isAllowed,
    this.reason,
    this.modifiedPrompt,
    this.uncertaintyLevel = 0.0,
  });
}

/// Content safety and bias prevention for historical roleplay.
///
/// Detects and rejects harmful requests, anachronisms, and position
/// contradictions; adds uncertainty indicators when inference is required.
class RoleplaySafetyFilter {
  static const _violencePatterns = [
    'kill', 'violence', 'attack', 'hurt', 'endorse war', 'support violence',
    'approve murder', 'condone harm', 'weapon', 'destroy',
  ];

  static const _harmfulPatterns = [
    'hate', 'offensive', 'slur', 'discriminat', 'abuse',
  ];

  RoleplaySafetyFilter();

  /// Checks user input before sending to LLM.
  /// Rejects violence endorsement, anachronistic content, offensive/harmful content.
  SafetyCheckResult checkInput(String userMessage, String personaId) {
    final lower = userMessage.toLowerCase().trim();

    if (_matchesAny(lower, _violencePatterns)) {
      return const SafetyCheckResult(
        isAllowed: false,
        reason: 'Requests for the persona to endorse or discuss violence are not allowed.',
      );
    }

    if (_matchesAny(lower, _harmfulPatterns)) {
      return const SafetyCheckResult(
        isAllowed: false,
        reason: 'Harmful or offensive content is not allowed.',
      );
    }

    final persona = HistoricalPersonaRegistry.findById(personaId);
    if (persona != null && _containsAnachronism(lower, persona.endYear)) {
      return SafetyCheckResult(
        isAllowed: false,
        reason: 'The persona cannot discuss events or technology after their lifetime (lived until ${persona.endYear}).',
      );
    }

    return const SafetyCheckResult(isAllowed: true, reason: 'OK');
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
    if (_hasFactualClaimWithoutCitation(aiResponse)) uncertainty = uncertainty.clamp(0.0, 1.0) + 0.2;

    return SafetyCheckResult(
      isAllowed: true,
      reason: 'OK',
      uncertaintyLevel: uncertainty.clamp(0.0, 1.0),
    );
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
    return lower.contains('i believe') || lower.contains('i would') ||
        lower.contains('it is likely') || lower.contains('perhaps');
  }

  bool _hasFactualClaimWithoutCitation(String text) {
    final hasYear = RegExp(r'\b(1\d{3}|20\d{2})\b').hasMatch(text);
    final hasCitation = text.contains('(') && text.contains(')') ||
        text.contains('source') || text.contains('according to');
    return hasYear && !hasCitation;
  }

  bool _mentionsTopics(String text, List<String> topics) {
    final lower = text.toLowerCase();
    return topics.any((t) => lower.contains(t.toLowerCase()));
  }

  /// Returns true if the prompt asks about tech/events after [deathYear].
  bool _containsAnachronism(String lowerPrompt, int deathYear) {
    const anachronismHints = [
      'internet', 'computer', 'smartphone', 'social media', 'covid', '2020', '21st century',
      'climate change', 'global warming', 'ai ', 'artificial intelligence', 'robot',
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
