/// Grammar-pattern payload for just-in-time coaching (P7-943).
library;

import 'package:lingafriq/lessons/grammar_aha_card.dart';

/// copy_keys: coach.title
abstract final class CoachingCopyKeys {
  static const dismiss = 'coach.dismiss';
  static const defaultDismiss = 'Got it';
}

/// Learner-facing coaching tip derived from the Pattern Library.
class CoachingPattern {
  const CoachingPattern({
    required this.id,
    required this.title,
    required this.body,
    required this.formHint,
  });

  final String id;
  final String title;
  final String body;
  final String formHint;

  factory CoachingPattern.fromGrammarEntry(GrammarPatternEntry entry) {
    final example = entry.examples.isNotEmpty ? entry.examples.first : entry.form;
    return CoachingPattern(
      id: entry.id,
      title: entry.descriptionL1,
      body:
          'You just met this pattern in a lesson. $example is a real example from our library.',
      formHint: entry.form,
    );
  }
}
