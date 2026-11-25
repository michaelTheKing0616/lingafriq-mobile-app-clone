import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/hearts_system_model.dart';

void main() {
  group('HeartsState', () {
    test('core lessons never enforce hearts when challenge run inactive', () {
      final state = HeartsState(
        currentHearts: 0,
        challengeModeEnabled: true,
        challengeRunActive: false,
      );
      expect(state.heartsApply, isFalse);
      expect(state.hasHearts, isTrue);
      expect(state.showHeartsUi, isFalse);
    });

    test('hearts apply only during active challenge run', () {
      final state = HeartsState(
        currentHearts: 2,
        challengeModeEnabled: true,
        challengeRunActive: true,
      );
      expect(state.heartsApply, isTrue);
      expect(state.showHeartsUi, isTrue);
      expect(state.hasHearts, isTrue);
    });

    test('zero hearts still allows core lessons when run inactive', () {
      final state = HeartsState(
        currentHearts: 0,
        challengeModeEnabled: true,
        challengeRunActive: false,
      );
      expect(state.hasHearts, isTrue);
    });
  });
}
