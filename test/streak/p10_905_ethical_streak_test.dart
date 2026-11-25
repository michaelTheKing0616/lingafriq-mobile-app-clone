import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/game_streak.dart';

void main() {
  group('P10-905 ethical streak policy', () {
    test('weekly practice does not break mid-week after one missed day', () {
      var state = const EthicalStreakState(cadence: StreakCadence.weekly);
      final mon = DateTime.utc(2026, 1, 5, 12);
      final wed = DateTime.utc(2026, 1, 7, 12);
      state = EthicalStreakPolicy.recordPractice(state, mon).state;
      state = EthicalStreakPolicy.recordPractice(state, wed).state;
      expect(state.practiceDaysThisWeek.length, 2);
      expect(state.brokenAt, isNull);
    });

    test('freeze holds daily streak across a skipped day', () {
      final d1 = DateTime.utc(2026, 2, 1, 9);
      final d3 = DateTime.utc(2026, 2, 3, 9);
      var state = EthicalStreakPolicy.recordPractice(
        const EthicalStreakState(
          cadence: StreakCadence.daily,
          freezeTokens: 1,
        ),
        d1,
      ).state;
      state = state.copyWith(currentStreak: 4);
      final result = EthicalStreakPolicy.recordPractice(state, d3);
      expect(result.freezeSpent, isTrue);
      expect(result.state.currentStreak, 4);
    });

    test('repair offer respects configured window', () {
      final brokenAt = DateTime.utc(2026, 3, 1, 10);
      final state = EthicalStreakState(
        cadence: StreakCadence.daily,
        brokenAt: brokenAt,
      );
      final inside = DateTime.utc(2026, 3, 2, 8);
      expect(EthicalStreakPolicy.repairOfferVisible(state, inside), isTrue);
      expect(
        EthicalStreakPolicy.repairWindowHoursRemaining(state, inside),
        greaterThan(0),
      );
    });

    test('neutral streak copy only', () {
      expect(
        EthicalStreakPolicy.streakCopyIsNeutral(
          'Your streak paused. You can repair it today.',
        ),
        isTrue,
      );
      expect(
        EthicalStreakPolicy.streakCopyIsNeutral('Your streak is at risk!'),
        isFalse,
      );
    });
  });
}
