import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/placement/cat_engine.dart';

double _normal(math.Random random) {
  return math.sqrt(-2 * math.log(random.nextDouble())) * math.cos(2 * math.pi * random.nextDouble());
}

double _probability(double ability, CatItem item) {
  final eta = item.a * (ability - item.b);
  if (eta >= 0) {
    final z = math.exp(-eta);
    return 1 / (1 + z);
  }
  final z = math.exp(eta);
  return z / (1 + z);
}

void main() {
  test('simulated learners finish in 8 to 15 items', () {
    const engine = CatEngine();
    final bank = [
      for (var index = 0; index < 30; index++)
        CatItem(
          id: 'sim-${index.toString().padLeft(2, '0')}',
          a: 0.8 + (index % 5) * 0.3,
          b: -2 + 4 * index / 29,
          calibrated: true,
        ),
    ];
    final random = math.Random(20261023);
    var inWindow = 0;
    const runs = 1000;
    for (var run = 0; run < runs; run++) {
      final ability = _normal(random);
      final placement = engine.run(
        bank: bank,
        respond: (item) => random.nextDouble() < _probability(ability, item),
      );
      expect(placement.provisional, isFalse);
      expect(placement.ability, isNotNull);
      expect(placement.intervalLow, isNotNull);
      expect(placement.intervalHigh, isNotNull);
      expect(placement.intervalLow!, lessThan(placement.ability!));
      expect(placement.intervalHigh!, greaterThan(placement.ability!));
      expect(placement.administered, inInclusiveRange(8, 15));
      if (placement.administered >= 8 && placement.administered <= 15) inWindow += 1;
    }
    expect(inWindow / runs, greaterThanOrEqualTo(0.95));
  });
}
