/// League standings for Minimal Pair Duel (P8-921): accuracy first, speed tiebreak.
library;

class MinimalPairDuelLeagueScore {
  const MinimalPairDuelLeagueScore({
    required this.correctCount,
    required this.totalCount,
    required this.totalTimeMs,
  }) : assert(totalCount >= 0),
       assert(correctCount >= 0 && correctCount <= totalCount),
       assert(totalTimeMs >= 0);

  final int correctCount;
  final int totalCount;
  final int totalTimeMs;

  double get accuracy =>
      totalCount == 0 ? 0.0 : correctCount / totalCount;
}

/// Returns negative if [a] ranks above [b], positive if below, zero if tied.
int compareMinimalPairDuelLeagueScores(
  MinimalPairDuelLeagueScore a,
  MinimalPairDuelLeagueScore b,
) {
  final accA = a.accuracy;
  final accB = b.accuracy;
  if (accA != accB) {
    return accB.compareTo(accA);
  }
  if (a.totalTimeMs != b.totalTimeMs) {
    return a.totalTimeMs.compareTo(b.totalTimeMs);
  }
  return 0;
}

MinimalPairDuelLeagueScore mergeDuelSessionScores(
  Iterable<MinimalPairDuelLeagueScore> rounds,
) {
  var correct = 0;
  var total = 0;
  var timeMs = 0;
  for (final r in rounds) {
    correct += r.correctCount;
    total += r.totalCount;
    timeMs += r.totalTimeMs;
  }
  return MinimalPairDuelLeagueScore(
    correctCount: correct,
    totalCount: total,
    totalTimeMs: timeMs,
  );
}
