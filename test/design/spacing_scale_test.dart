import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/design/gen_tokens.dart';

void main() {
  test('every spacing token is a multiple of 4', () {
    final spec = jsonDecode(File('design/tokens/tokens.json').readAsStringSync())
        as Map<String, dynamic>;
    final spacing = spec['spacing'] as Map<String, dynamic>;
    for (final entry in spacing.entries) {
      expect(entry.value % 4, 0, reason: 'spacing.${entry.key}');
    }
  });

  test('a non-multiple fails the generator', () {
    final spec = jsonDecode(File('design/tokens/tokens.json').readAsStringSync())
        as Map<String, dynamic>;
    (spec['spacing'] as Map)['6'] = 6;
    expect(
      () => generateTokens(spec),
      throwsA(predicate((e) => e is TokenGenException && e.message.contains('spacing.6'))),
    );
  });

  test('radius, elevation and stroke have named steps including dark elevation', () {
    final spec = jsonDecode(File('design/tokens/tokens.json').readAsStringSync())
        as Map<String, dynamic>;
    expect((spec['radius'] as Map).keys, isNotEmpty);
    expect((spec['stroke'] as Map).keys, isNotEmpty);
    final elevation = spec['elevation'] as Map<String, dynamic>;
    expect(
      (elevation['light'] as Map).keys,
      (elevation['dark'] as Map).keys,
    );
  });

  test('padding literal that is not a multiple of 4 reports file and line', () {
    const source = 'padding: EdgeInsets.all(10),\n';
    expect(reportPaddingLiterals(source, 'fixture.dart'), ['fixture.dart:1']);
    expect(reportPaddingLiterals('padding: EdgeInsets.all(16),', 'ok.dart'), isEmpty);
  });
}
