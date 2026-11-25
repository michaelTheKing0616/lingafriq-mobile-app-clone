/// Greeting Gauntlet round plan (P8-928).
library;

import 'dart:math';

import 'package:flutter/services.dart';

import 'scenario_matrix.dart';

const int kGauntletRoundSeconds = 18;
const int kGauntletMaxRounds = 6;

Future<List<GauntletRound>> loadGauntletRoundsForLanguage(
  String languageCode, {
  Random? rng,
}) async {
  final lang = languageCode.trim().toLowerCase();
  try {
    final raw = await rootBundle.loadString(
      'assets/data/units/register/$lang.json',
    );
    final matrix = buildVerifiedScenarioMatrix(
      languageCode: lang,
      registerJsonRaw: raw,
      rng: rng,
    );
    if (matrix.isNotEmpty) {
      return matrix.take(kGauntletMaxRounds).toList();
    }
  } catch (_) {
    // Fall through.
  }
  return const [];
}

GauntletRoundScore scoreGauntletPick({
  required GauntletRound round,
  required int? selectedIndex,
  required bool timedOut,
}) {
  if (timedOut || selectedIndex == null) {
    return GauntletRoundScore(
      correct: false,
      timedOut: true,
      selectedGesture: null,
      explanation: round.whyWrongEn,
    );
  }
  final correct = selectedIndex == round.correctIndex;
  final gesture = round.choices[selectedIndex].gesture;
  return GauntletRoundScore(
    correct: correct,
    timedOut: false,
    selectedGesture: gesture,
    explanation: correct ? null : round.whyWrongEn,
  );
}

class GauntletRoundScore {
  const GauntletRoundScore({
    required this.correct,
    required this.timedOut,
    required this.selectedGesture,
    required this.explanation,
  });

  final bool correct;
  final bool timedOut;
  final CulturalGesture? selectedGesture;
  final String? explanation;
}
