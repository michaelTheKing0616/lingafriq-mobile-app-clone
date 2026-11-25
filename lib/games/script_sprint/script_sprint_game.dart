/// Fidel Flight session logic (P8-927).
library;

import 'dart:math';

import 'script_sets.dart';

class ScriptSprintRound {
  const ScriptSprintRound({
    required this.glyph,
    required this.roundIndex,
  });

  final ScriptSprintGlyph glyph;
  final int roundIndex;
}

class ScriptSprintSessionPlan {
  const ScriptSprintSessionPlan({
    required this.set,
    required this.rounds,
    required this.practiceNotScored,
  });

  final ScriptSprintSet set;
  final List<ScriptSprintRound> rounds;
  final bool practiceNotScored;
}

ScriptSprintSessionPlan buildScriptSprintSession({
  required ScriptSprintSet set,
  required Random rng,
  int maxRounds = 3,
  bool practiceNotScored = true,
}) {
  if (!set.isPlayable) {
    throw StateError('script_sprint_not_playable');
  }
  final pool = List<ScriptSprintGlyph>.from(set.glyphs);
  pool.shuffle(rng);
  final rounds = <ScriptSprintRound>[];
  for (var i = 0; i < maxRounds; i++) {
    rounds.add(
      ScriptSprintRound(
        glyph: pool[i % pool.length],
        roundIndex: i,
      ),
    );
  }
  return ScriptSprintSessionPlan(
    set: set,
    rounds: rounds,
    practiceNotScored: practiceNotScored,
  );
}

int scoreScriptSprintSession({
  required List<ScriptSprintRound> rounds,
  required List<bool> results,
}) {
  var correct = 0;
  for (var i = 0; i < rounds.length; i++) {
    if (i < results.length && results[i]) correct++;
  }
  return correct;
}
