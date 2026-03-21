/// Pure helpers for [GameTemplateShell] chips — unit-tested, no Flutter imports.

/// Progress chip for discrete rounds (1-based or current index after increment).
String? roundProgressLabelForRound({
  required int currentRound,
  required int maxRounds,
}) {
  if (maxRounds <= 0) return null;
  if (currentRound > maxRounds) return 'Done';
  return '${currentRound.clamp(0, maxRounds)}/$maxRounds';
}

/// Score chip used with round-based games.
String shellScorePointsLabel(int score) => '$score pts';

/// Progress from completed session turns vs expected card/round count.
String? sessionTurnProgressLabel({
  required int completedTurns,
  required int maxTurns,
}) {
  if (maxTurns <= 0) return null;
  if (completedTurns >= maxTurns) return 'Done';
  return '${completedTurns.clamp(0, maxTurns)}/$maxTurns';
}
