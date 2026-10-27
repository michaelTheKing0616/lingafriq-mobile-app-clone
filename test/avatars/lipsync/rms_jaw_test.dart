import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/lipsync/rms_jaw.dart';
import 'package:lingafriq/avatars/lipsync/timing_sidecar.dart';

void main() {
  test('RmsJawDriver smooths toward target and stays in 0..1', () {
    final driver = RmsJawDriver(
      samples: const [RmsSample(at: Duration.zero, level: 0.9)],
    );
    var jaw = 0.0;
    for (var i = 0; i < 20; i++) {
      jaw = driver.advance(
        Duration(milliseconds: i * 16),
        const Duration(milliseconds: 16),
      );
      expect(jaw, inInclusiveRange(0, 1));
    }
    expect(jaw, greaterThan(0.5));
  });

  test('combineJawOpen adds viseme pose and RMS', () {
    expect(
      combineJawOpen(visemeOpenness: 0.85, smoothedRms: 0.5),
      lessThanOrEqualTo(1),
    );
    expect(
      combineJawOpen(visemeOpenness: 0.85, smoothedRms: 0.5),
      greaterThan(0.85),
    );
  });
}
