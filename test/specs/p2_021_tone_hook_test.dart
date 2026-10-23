import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the tone hook spec names the interface, the budget, the floor, and no score', () {
    final spec = File('docs/build/specs/P2-021-on-device-tone.md').readAsStringSync();
    expect(spec.contains('evaluate(reference, audioPath, language)'), isTrue);
    expect(spec.contains('20 MB'), isTrue);
    expect(spec.contains('90 percent'), isTrue);
    expect(spec.contains('state is unavailable'), isTrue);
    expect(spec.contains('shows no score'), isTrue);
    expect(spec.contains('does not invent'), isTrue);
  });
}
