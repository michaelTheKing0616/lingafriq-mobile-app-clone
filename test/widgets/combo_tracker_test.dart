import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/gamification/combo_tracker.dart';

void main() {
  group('ComboTracker', () {
    late ComboTracker tracker;

    setUp(() {
      tracker = ComboTracker();
    });

    test('should initialize with zero combo', () {
      expect(tracker.consecutiveCorrect, 0);
      expect(tracker.maxCombo, 0);
      expect(tracker.currentMultiplier, 1.0);
      expect(tracker.hasCombo, false);
    });

    test('should increment combo on correct answer', () {
      tracker.recordCorrect();

      expect(tracker.consecutiveCorrect, 1);
      expect(tracker.maxCombo, 1);
      expect(tracker.hasCombo, false); // Need at least 2 for combo
    });

    test('should reset combo on incorrect answer', () {
      tracker.recordCorrect();
      tracker.recordCorrect();
      tracker.recordCorrect();

      expect(tracker.consecutiveCorrect, 3);

      tracker.recordIncorrect();

      expect(tracker.consecutiveCorrect, 0);
      expect(tracker.maxCombo, 3); // Max combo should be preserved
      expect(tracker.hasCombo, false);
    });

    test('should calculate multiplier at threshold 2', () {
      tracker.recordCorrect();
      expect(tracker.currentMultiplier, 1.0);

      tracker.recordCorrect();
      expect(tracker.currentMultiplier, 1.5);
      expect(tracker.hasCombo, true);
    });

    test('should calculate multiplier at threshold 4', () {
      for (int i = 0; i < 4; i++) {
        tracker.recordCorrect();
      }

      expect(tracker.consecutiveCorrect, 4);
      expect(tracker.currentMultiplier, 2.0);
    });

    test('should calculate multiplier at threshold 7', () {
      for (int i = 0; i < 7; i++) {
        tracker.recordCorrect();
      }

      expect(tracker.consecutiveCorrect, 7);
      expect(tracker.currentMultiplier, 3.0);
    });

    test('should calculate multiplier at threshold 10', () {
      for (int i = 0; i < 10; i++) {
        tracker.recordCorrect();
      }

      expect(tracker.consecutiveCorrect, 10);
      expect(tracker.currentMultiplier, 4.0);
    });

    test('should track max combo correctly', () {
      tracker.recordCorrect();
      tracker.recordCorrect();
      tracker.recordCorrect();
      expect(tracker.maxCombo, 3);

      tracker.recordIncorrect();
      expect(tracker.maxCombo, 3); // Should preserve max

      tracker.recordCorrect();
      tracker.recordCorrect();
      expect(tracker.maxCombo, 3); // Still 3, not updated

      tracker.recordCorrect();
      tracker.recordCorrect();
      expect(tracker.maxCombo, 5); // Updated to new max
    });

    test('should reset combo tracker', () {
      for (int i = 0; i < 5; i++) {
        tracker.recordCorrect();
      }

      expect(tracker.consecutiveCorrect, 5);
      expect(tracker.maxCombo, 5);

      tracker.reset();

      expect(tracker.consecutiveCorrect, 0);
      expect(tracker.maxCombo, 0);
      expect(tracker.hasCombo, false);
      expect(tracker.currentMultiplier, 1.0);
    });

    test('should notify listeners on state change', () {
      bool notified = false;
      tracker.addListener(() {
        notified = true;
      });

      tracker.recordCorrect();
      expect(notified, true);
    });

    test('should handle multiplier boundaries correctly', () {
      // Test exact thresholds
      tracker.recordCorrect(); // 1 -> 1.0x
      expect(tracker.currentMultiplier, 1.0);

      tracker.recordCorrect(); // 2 -> 1.5x
      expect(tracker.currentMultiplier, 1.5);

      tracker.recordCorrect(); // 3 -> 1.5x
      expect(tracker.currentMultiplier, 1.5);

      tracker.recordCorrect(); // 4 -> 2.0x
      expect(tracker.currentMultiplier, 2.0);

      tracker.recordCorrect(); // 5 -> 2.0x
      expect(tracker.currentMultiplier, 2.0);

      tracker.recordCorrect(); // 6 -> 2.0x
      expect(tracker.currentMultiplier, 2.0);

      tracker.recordCorrect(); // 7 -> 3.0x
      expect(tracker.currentMultiplier, 3.0);

      tracker.recordCorrect(); // 8 -> 3.0x
      expect(tracker.currentMultiplier, 3.0);

      tracker.recordCorrect(); // 9 -> 3.0x
      expect(tracker.currentMultiplier, 3.0);

      tracker.recordCorrect(); // 10 -> 4.0x
      expect(tracker.currentMultiplier, 4.0);
    });

    test('should handle very high combo counts', () {
      for (int i = 0; i < 20; i++) {
        tracker.recordCorrect();
      }

      expect(tracker.consecutiveCorrect, 20);
      expect(tracker.currentMultiplier, 4.0); // Max multiplier
      expect(tracker.maxCombo, 20);
    });

    test('should maintain combo state across multiple correct answers', () {
      tracker.recordCorrect();
      tracker.recordCorrect();
      tracker.recordCorrect();

      expect(tracker.consecutiveCorrect, 3);
      expect(tracker.hasCombo, true);
      expect(tracker.currentMultiplier, 1.5);

      tracker.recordCorrect();
      expect(tracker.consecutiveCorrect, 4);
      expect(tracker.currentMultiplier, 2.0);
    });

    test('should reset combo but preserve max on incorrect', () {
      for (int i = 0; i < 8; i++) {
        tracker.recordCorrect();
      }

      final maxBefore = tracker.maxCombo;
      tracker.recordIncorrect();

      expect(tracker.consecutiveCorrect, 0);
      expect(tracker.maxCombo, maxBefore);
      expect(tracker.hasCombo, false);
    });
  });
}
