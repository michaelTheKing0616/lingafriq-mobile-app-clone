// Determines what a historical persona can plausibly know.
// Uses persona's documented positions, inference matrix, and era bounds.

import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/persona_cognition/intent_classifier.dart';

enum EpistemicStatus {
  documented,
  inferred,
  uncertain,
  anachronistic,
  outOfScope,
}

class EpistemicClassification {
  final EpistemicStatus status;
  final double confidence;
  final String reasoning;
  final bool requiresUncertaintyLanguage;

  const EpistemicClassification({
    required this.status,
    required this.confidence,
    required this.reasoning,
    required this.requiresUncertaintyLanguage,
  });
}

class EpistemicClassifier {
  EpistemicClassifier._();

  /// Classifies epistemic status for [userInput] given [persona] and [intent].
  static EpistemicClassification classify({
    required String userInput,
    required HistoricalPersona persona,
    required IntentClassification intent,
  }) {
    final lower = userInput.trim().toLowerCase();
    final words = lower.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();

    // Anachronistic: references events after persona.endYear
    final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(lower);
    if (yearMatch != null) {
      final year = int.tryParse(yearMatch.group(0) ?? '');
      if (year != null && year > persona.endYear) {
        return EpistemicClassification(
          status: EpistemicStatus.anachronistic,
          confidence: 0.95,
          reasoning: 'User referenced year $year; persona lived until ${persona.endYear}.',
          requiresUncertaintyLanguage: true,
        );
      }
    }

    // Modern/anachronistic domain from intent
    if (intent.domain == UserIntentDomain.anachronistic ||
        intent.domain == UserIntentDomain.modern) {
      return EpistemicClassification(
        status: EpistemicStatus.anachronistic,
        confidence: intent.confidence,
        reasoning: 'Topic appears modern or anachronistic for persona era.',
        requiresUncertaintyLanguage: true,
      );
    }

    // Documented: topic matches persona.documentedPositions
    for (final entry in persona.documentedPositions.entries) {
      final key = entry.key.toLowerCase();
      if (lower.contains(key) || words.any((w) => key.contains(w))) {
        return EpistemicClassification(
          status: EpistemicStatus.documented,
          confidence: 0.95,
          reasoning: 'Topic aligns with documented position: $key.',
          requiresUncertaintyLanguage: false,
        );
      }
    }

    // Core events: user asks about events in persona's life
    for (final ev in persona.coreEvents) {
      final eventLower = ev.event.toLowerCase();
      if (lower.contains(eventLower.split(' ').take(3).join(' ')) ||
          words.any((w) => eventLower.contains(w))) {
        return EpistemicClassification(
          status: EpistemicStatus.documented,
          confidence: 0.9,
          reasoning: 'Topic relates to persona core event.',
          requiresUncertaintyLanguage: false,
        );
      }
    }

    // Inferred: topic in opinionInferenceMatrix
    for (final entry in persona.opinionInferenceMatrix.entries) {
      final key = entry.key.toLowerCase();
      if (lower.contains(key) || words.any((w) => key.contains(w))) {
        final conf = entry.value.confidence;
        return EpistemicClassification(
          status: EpistemicStatus.inferred,
          confidence: conf,
          reasoning:
              'Topic in inference matrix (${entry.value.inferenceBasis.join(", ")}).',
          requiresUncertaintyLanguage: true,
        );
      }
    }

    // Out of scope: offensive or clearly outside persona knowledge
    if (intent.domain == UserIntentDomain.offensive) {
      return const EpistemicClassification(
        status: EpistemicStatus.outOfScope,
        confidence: 0.95,
        reasoning: 'Input is out of scope for persona response.',
        requiresUncertaintyLanguage: false,
      );
    }

    // Default: uncertain
    return const EpistemicClassification(
      status: EpistemicStatus.uncertain,
      confidence: 0.5,
      reasoning: 'Topic not in documented positions or inference matrix.',
      requiresUncertaintyLanguage: true,
    );
  }
}
