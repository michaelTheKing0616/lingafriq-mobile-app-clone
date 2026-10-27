/// Departure timer and call pacing for Danfo / Matatu Rush (P8-923).
library;

/// Milliseconds learners have to tap the matching bus before it leaves.
Duration danfoDecisionWindowMs(int level) {
  final clamped = level.clamp(1, 12);
  final ms = 5200 - (clamped - 1) * 280;
  return Duration(milliseconds: ms.clamp(2200, 5200));
}

/// Gap between conductor calls at a given difficulty level.
Duration danfoCallGapMs(int level) {
  final clamped = level.clamp(1, 12);
  final ms = 2800 - (clamped - 1) * 160;
  return Duration(milliseconds: ms.clamp(1200, 2800));
}

/// Rotates accent tags as level rises (AC2).
String danfoAccentForLevel(int level, List<String> accents, int roundIndex) {
  if (accents.isEmpty) return 'standard';
  final idx = (level + roundIndex) % accents.length;
  return accents[idx];
}
