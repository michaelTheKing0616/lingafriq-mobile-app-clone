/// Self-determination motivation surfaces (P5-037, EP-§6.2-25/26).
///
/// Autonomy: learner-chosen themes from catalog.
/// Competence: visible can-do and mastery growth (P5-015).
/// Relatedness: social modules without streak as the primary driver (ADR-021).
library;

/// Where a home module may appear.
enum HomeProminence { hero, supporting, hidden }

/// Motivation modules the home shell may rank.
enum MotivationModule {
  competenceGrowth,
  themePicker,
  relatedness,
  dailyStreak,
}

/// Demonstrated skill growth for competence copy (AC2).
class CompetenceGrowthSnapshot {
  const CompetenceGrowthSnapshot({
    required this.newCanDosThisWeek,
    required this.unitsMasteredCount,
    this.masteryDelta,
  });

  final int newCanDosThisWeek;
  final int unitsMasteredCount;

  /// Change in aggregate mastery vs prior window; null when unknown.
  final double? masteryDelta;

  bool get hasVisibleGrowth =>
      newCanDosThisWeek > 0 || unitsMasteredCount > 0 || (masteryDelta ?? 0) > 0;
}

/// User-facing competence hero strings (AC2).
class CompetenceHeroCopy {
  const CompetenceHeroCopy({required this.headline, required this.detail});

  final String headline;
  final String detail;
}

/// Resolved slot for one module after ranking.
class RankedHomeModule {
  const RankedHomeModule({
    required this.module,
    required this.prominence,
  });

  final MotivationModule module;
  final HomeProminence prominence;
}

/// Streak is never the home hero (EP-§6.2-26, ADR-021).
bool streakMayBeHero() => false;

/// Picks the learner theme when autonomy is enabled (AC1).
///
/// Uses the first learner choice that is in the catalog and not blocked.
/// Falls back to [curriculumDefaultThemeId] when none qualify.
String resolveSessionTheme({
  required List<String> catalogThemeIds,
  required List<String> learnerThemeIds,
  required Set<String> blockedThemeIds,
  required String curriculumDefaultThemeId,
}) {
  final catalog = catalogThemeIds.toSet();
  for (final id in learnerThemeIds) {
    if (catalog.contains(id) && !blockedThemeIds.contains(id)) {
      return id;
    }
  }
  if (catalog.contains(curriculumDefaultThemeId) &&
      !blockedThemeIds.contains(curriculumDefaultThemeId)) {
    return curriculumDefaultThemeId;
  }
  if (catalog.isEmpty) {
    return curriculumDefaultThemeId;
  }
  final allowed = catalog.difference(blockedThemeIds);
  if (allowed.isEmpty) {
    return curriculumDefaultThemeId;
  }
  return allowed.first;
}

/// Builds competence-first hero copy from demonstrated growth (AC2).
CompetenceHeroCopy competenceHeroCopy(CompetenceGrowthSnapshot snapshot) {
  if (snapshot.newCanDosThisWeek > 0) {
    final n = snapshot.newCanDosThisWeek;
    return CompetenceHeroCopy(
      headline: n == 1 ? 'You demonstrated a new can-do' : 'You demonstrated $n new can-dos',
      detail: 'This week’s practice counted toward real skills.',
    );
  }
  if (snapshot.unitsMasteredCount > 0) {
    final n = snapshot.unitsMasteredCount;
    return CompetenceHeroCopy(
      headline: n == 1 ? 'One unit mastered' : '$n units mastered',
      detail: 'Mastery follows can-do evidence, not streaks.',
    );
  }
  if (snapshot.masteryDelta != null && snapshot.masteryDelta! > 0) {
    final pct = (snapshot.masteryDelta! * 100).round();
    return CompetenceHeroCopy(
      headline: 'Skills strengthened',
      detail: 'Overall mastery up about $pct% this week.',
    );
  }
  return const CompetenceHeroCopy(
    headline: 'Keep building skills',
    detail: 'Your next session adds can-do evidence.',
  );
}

/// Orders home modules; streak cannot be hero (AC3).
List<RankedHomeModule> rankHomeModules({
  required CompetenceGrowthSnapshot competence,
  required bool relatednessAvailable,
  required int streakDays,
}) {
  final ranked = <RankedHomeModule>[
    const RankedHomeModule(
      module: MotivationModule.competenceGrowth,
      prominence: HomeProminence.hero,
    ),
    const RankedHomeModule(
      module: MotivationModule.themePicker,
      prominence: HomeProminence.supporting,
    ),
  ];

  if (relatednessAvailable) {
    ranked.add(
      const RankedHomeModule(
        module: MotivationModule.relatedness,
        prominence: HomeProminence.supporting,
      ),
    );
  }

  final streakProminence = _streakProminence(
    streakDays: streakDays,
    competenceHasData: competence.hasVisibleGrowth || competence.masteryDelta != null,
  );
  ranked.add(
    RankedHomeModule(
      module: MotivationModule.dailyStreak,
      prominence: streakProminence,
    ),
  );

  assert(!ranked.any(
    (r) => r.module == MotivationModule.dailyStreak && r.prominence == HomeProminence.hero,
  ));
  return ranked;
}

HomeProminence _streakProminence({
  required int streakDays,
  required bool competenceHasData,
}) {
  if (streakMayBeHero()) {
    return HomeProminence.hero;
  }
  if (streakDays <= 0) {
    return HomeProminence.hidden;
  }
  if (competenceHasData) {
    return HomeProminence.supporting;
  }
  return HomeProminence.supporting;
}

/// Whether [metricName] may be the only experiment success metric (ADR-021).
bool experimentMayUseMetricAlone(String metricName) {
  final normalized = metricName.trim().toLowerCase();
  if (normalized == 'streak_length' ||
      normalized == 'daily_streak' ||
      normalized == 'streak') {
    return false;
  }
  return true;
}
