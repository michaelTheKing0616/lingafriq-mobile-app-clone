import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/feature_flag_service.dart';

void main() {
  test('a failed evaluation uses the safe default and logs it', () {
    final lines = <String>[];
    final flags = FeatureFlagService(log: lines.add);
    final now = DateTime.utc(2026, 10, 23, 12);

    flags.apply({'polie': true}, now);
    expect(flags.isOn('polie', now), isTrue);

    flags.failed(StateError('network'), now);
    expect(flags.isOn('polie', now), isFalse);
    expect(lines.single, contains('feature flag evaluation failed'));
  });

  test('a kill switch is off after the cache TTL', () {
    final flags = FeatureFlagService();
    final now = DateTime.utc(2026, 10, 23, 12);
    flags.apply({'polie': true}, now);
    expect(flags.isOn('polie', now.add(const Duration(seconds: 60))), isTrue);
    expect(flags.isOn('polie', now.add(const Duration(seconds: 61))), isFalse);
  });
}
