/// Word Forge session logic (P8-926).
library;

import 'dart:math';

import 'morphology_slots.dart';

class WordForgeRound {
  const WordForgeRound({
    required this.template,
    required this.selection,
    required this.roundIndex,
  });

  final WordForgeTemplate template;
  final WordForgeSelection selection;
  final int roundIndex;
}

class WordForgeSessionPlan {
  const WordForgeSessionPlan({
    required this.languageCode,
    required this.rounds,
    required this.practiceNotScored,
  });

  final String languageCode;
  final List<WordForgeRound> rounds;
  final bool practiceNotScored;
}

WordForgeSessionPlan buildWordForgeSession({
  required String languageCode,
  required Random rng,
  int maxRounds = 3,
  bool practiceNotScored = true,
}) {
  final templates = wordForgeTemplatesForLanguage(languageCode);
  if (templates.isEmpty) {
    throw StateError('word_forge_no_templates');
  }
  final rounds = <WordForgeRound>[];
  for (var i = 0; i < maxRounds; i++) {
    final template = templates[rng.nextInt(templates.length)];
    rounds.add(
      WordForgeRound(
        template: template,
        selection: emptySelection(template),
        roundIndex: i,
      ),
    );
  }
  return WordForgeSessionPlan(
    languageCode: languageCode,
    rounds: rounds,
    practiceNotScored: practiceNotScored,
  );
}

WordForgeRound withSelection(WordForgeRound round, WordForgeSelection selection) {
  return WordForgeRound(
    template: round.template,
    selection: selection,
    roundIndex: round.roundIndex,
  );
}

WordForgeSelection setSlotOption({
  required WordForgeSelection current,
  required WordForgeSlotKind kind,
  required MorphemeOption? option,
}) {
  final next = Map<WordForgeSlotKind, MorphemeOption?>.from(current.byKind);
  next[kind] = option;
  return WordForgeSelection(next);
}

int scoreWordForgeSession(List<WordForgeRound> rounds) {
  var correct = 0;
  for (final round in rounds) {
    final v = validateWordForge(
      template: round.template,
      selection: round.selection,
    );
    if (v.isCorrect) correct++;
  }
  return correct;
}
