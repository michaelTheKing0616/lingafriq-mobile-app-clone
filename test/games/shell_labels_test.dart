import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/games/shell_labels.dart';

void main() {
  group('roundProgressLabelForRound', () {
    test('returns null when maxRounds is 0', () {
      expect(
        roundProgressLabelForRound(currentRound: 1, maxRounds: 0),
        isNull,
      );
    });

    test('returns Done when round exceeds max', () {
      expect(
        roundProgressLabelForRound(currentRound: 6, maxRounds: 5),
        'Done',
      );
    });

    test('clamps negative round to 0', () {
      expect(
        roundProgressLabelForRound(currentRound: -1, maxRounds: 5),
        '0/5',
      );
    });

    test('shows current over max', () {
      expect(
        roundProgressLabelForRound(currentRound: 3, maxRounds: 10),
        '3/10',
      );
    });
  });

  group('shellScorePointsLabel', () {
    test('formats points', () {
      expect(shellScorePointsLabel(12), '12 pts');
    });
  });

  group('sessionTurnProgressLabel', () {
    test('returns null when maxTurns is 0', () {
      expect(
        sessionTurnProgressLabel(completedTurns: 1, maxTurns: 0),
        isNull,
      );
    });

    test('returns Done when completed reaches max', () {
      expect(
        sessionTurnProgressLabel(completedTurns: 10, maxTurns: 10),
        'Done',
      );
    });

    test('shows completed over max', () {
      expect(
        sessionTurnProgressLabel(completedTurns: 3, maxTurns: 10),
        '3/10',
      );
    });
  });
}
