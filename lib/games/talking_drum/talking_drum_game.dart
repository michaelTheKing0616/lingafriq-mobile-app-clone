/// Talking Drum flagship logic (P8-920): perception, rhythm harvest, production gate.
library;

import 'dart:math';

import '../../learning/pronunciation/tone_models.dart';
import '../drum_rhythm/drum_rhythm_game.dart';
import '../tone_forge/tone_forge_models.dart';

/// One multiple-choice phrase in the perception step.
class TalkingDrumCandidate {
  const TalkingDrumCandidate({
    required this.lexemeId,
    required this.label,
    required this.tonePattern,
  });

  final String lexemeId;
  final String label;
  final List<String> tonePattern;
}

class TalkingDrumPerceptionTurn {
  const TalkingDrumPerceptionTurn({
    required this.correctLexemeId,
    required this.contour,
    required this.candidates,
    required this.rhythmCue,
  });

  final String correctLexemeId;
  final List<double> contour;
  final List<TalkingDrumCandidate> candidates;
  final String rhythmCue;
}

/// Maps inventory tone codes to normalised drum pitch heights (0–1).
List<double> drumContourFromTonePattern(
  List<String> pattern,
  ToneLanguageModel model,
) {
  if (pattern.isEmpty) return const [];
  final heights = <double>[];
  for (final code in pattern) {
    final idx = inventoryIndexForToneCode(model, code);
    if (idx == null) return const [];
    heights.add(_inventoryHeight(model, idx));
  }
  return heights;
}

double _inventoryHeight(ToneLanguageModel model, int index) {
  final n = model.levels.length;
  if (n <= 1) return 0.5;
  return 1.0 - (index / (n - 1));
}

/// Local verdict only — must stay synchronous for ≤160 ms UI feedback (AC2).
bool talkingDrumPerceptionIsCorrect({
  required String selectedLexemeId,
  required String correctLexemeId,
}) {
  return selectedLexemeId.trim() == correctLexemeId.trim();
}

List<TalkingDrumCandidate> buildTalkingDrumCandidates({
  required ToneGameLexeme correct,
  required List<ToneGameLexeme> pool,
  required Random rng,
  int minOptions = 2,
  int maxOptions = 4,
}) {
  final cap = maxOptions.clamp(minOptions, 4);
  final distractors = pool
      .where((l) => l.lexemeId != correct.lexemeId)
      .where((l) => !_samePattern(l.tonePattern, correct.tonePattern))
      .toList();
  distractors.shuffle(rng);
  final want = cap.clamp(minOptions, cap);
  final picks = <ToneGameLexeme>[correct];
  for (final d in distractors) {
    if (picks.length >= want) break;
    if (picks.any((p) => p.lexemeId == d.lexemeId)) continue;
    picks.add(d);
  }
  while (picks.length < minOptions && distractors.isNotEmpty) {
    final extra = distractors[rng.nextInt(distractors.length)];
    if (!picks.any((p) => p.lexemeId == extra.lexemeId)) picks.add(extra);
  }
  picks.shuffle(rng);
  return picks
      .map(
        (l) => TalkingDrumCandidate(
          lexemeId: l.lexemeId,
          label: l.toneMarkedForm,
          tonePattern: l.tonePattern,
        ),
      )
      .toList(growable: false);
}

bool _samePattern(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

TalkingDrumPerceptionTurn? buildTalkingDrumPerceptionTurn({
  required ToneGameLexeme lexeme,
  required List<ToneGameLexeme> pool,
  required ToneLanguageModel inventory,
  required Random rng,
}) {
  final contour = drumContourFromTonePattern(lexeme.tonePattern, inventory);
  if (contour.isEmpty) return null;
  final candidates = buildTalkingDrumCandidates(
    correct: lexeme,
    pool: pool,
    rng: rng,
  );
  if (candidates.length < 2) return null;
  return TalkingDrumPerceptionTurn(
    correctLexemeId: lexeme.lexemeId,
    contour: contour,
    candidates: candidates,
    rhythmCue: drumRhythmShadowPatternForTurn(rng.nextInt(1 << 20)),
  );
}
