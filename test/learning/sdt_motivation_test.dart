import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/learning/motivation/sdt_motivation_policy.dart';

void main() {
  group('resolveSessionTheme', () {
    test('uses first learner choice in catalog', () {
      expect(
        resolveSessionTheme(
          catalogThemeIds: ['market', 'family', 'travel'],
          learnerThemeIds: ['travel', 'market'],
          blockedThemeIds: {},
          curriculumDefaultThemeId: 'market',
        ),
        'travel',
      );
    });

    test('skips blocked and unknown themes', () {
      expect(
        resolveSessionTheme(
          catalogThemeIds: ['market', 'family'],
          learnerThemeIds: ['unknown', 'family'],
          blockedThemeIds: {'family'},
          curriculumDefaultThemeId: 'market',
        ),
        'market',
      );
    });
  });

  group('competenceHeroCopy', () {
    test('prioritises new can-dos', () {
      final copy = competenceHeroCopy(
        const CompetenceGrowthSnapshot(
          newCanDosThisWeek: 2,
          unitsMasteredCount: 1,
        ),
      );
      expect(copy.headline, contains('2 new can-dos'));
      expect(copy.detail, isNot(contains('streak')));
    });
  });

  group('rankHomeModules', () {
    test('never places streak as hero', () {
      final ranked = rankHomeModules(
        competence: const CompetenceGrowthSnapshot(
          newCanDosThisWeek: 0,
          unitsMasteredCount: 0,
        ),
        relatednessAvailable: true,
        streakDays: 30,
      );
      final hero = ranked.where((r) => r.prominence == HomeProminence.hero).toList();
      expect(hero.length, 1);
      expect(hero.first.module, MotivationModule.competenceGrowth);
      expect(streakMayBeHero(), isFalse);
    });

    test('includes relatedness as supporting only', () {
      final ranked = rankHomeModules(
        competence: const CompetenceGrowthSnapshot(
          newCanDosThisWeek: 1,
          unitsMasteredCount: 0,
        ),
        relatednessAvailable: true,
        streakDays: 5,
      );
      final related = ranked.firstWhere((r) => r.module == MotivationModule.relatedness);
      expect(related.prominence, HomeProminence.supporting);
    });
  });

  group('experiment guardrail', () {
    test('rejects streak-only success metrics', () {
      expect(experimentMayUseMetricAlone('streak_length'), isFalse);
      expect(experimentMayUseMetricAlone('new_can_do'), isTrue);
    });
  });

  test('spec documents autonomy, competence, relatedness, and streak guardrail', () {
    final spec = File('docs/build/specs/P5-037-motivation-sdt.md').readAsStringSync();
    expect(spec.contains('resolveSessionTheme'), isTrue);
    expect(spec.contains('competenceHeroCopy'), isTrue);
    expect(spec.contains('rankHomeModules'), isTrue);
    expect(spec.contains('streakMayBeHero'), isTrue);
    expect(spec.contains('not the primary home driver'), isTrue);
  });
}
