import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/design.dart';

import '../../tool/design/gen_tokens.dart';

void main() {
  Map<String, dynamic> spec() => jsonDecode(
        File('design/tokens/tokens.json').readAsStringSync(),
      ) as Map<String, dynamic>;

  test('generator is byte-identical on a second run', () {
    final first = generateTokens(spec());
    final second = generateTokens(spec());
    expect(second.dartSource, first.dartSource);
    expect(second.adminCss, first.adminCss);
    expect(second.riveJson, first.riveJson);
    expect(File('lib/design/tokens.g.dart').readAsStringSync(), first.dartSource);
    expect(File('design/tokens/admin.css').readAsStringSync(), first.adminCss);
    expect(File('design/tokens/rive_tokens.json').readAsStringSync(), first.riveJson);
  });

  test('unknown token reference fails and names the token', () {
    final broken = spec();
    (broken['color'] as Map)['ghost'] = {'value': '{color.missing}', 'rive': 'color/ghost'};
    expect(
      () => generateTokens(broken),
      throwsA(
        predicate((e) => e is TokenGenException && e.message.contains('color.missing')),
      ),
    );
  });

  test('missing Rive binding fails', () {
    final broken = spec();
    (broken['color'] as Map)['navy'] = {'value': '#2E3A87'};
    expect(
      () => generateTokens(broken),
      throwsA(predicate((e) => e is TokenGenException && e.message.contains('color.navy'))),
    );
  });

  test('app and admin.css share navy and spacing 16', () {
    expect(LingAfriqTokens.navy.toARGB32(), 0xFF2E3A87);
    expect(LingAfriqTokens.spacing16, 16);
    final css = File('design/tokens/admin.css').readAsStringSync();
    expect(css, contains('--color-navy: #2E3A87;'));
    expect(css, contains('--spacing-16: 16px;'));
    final rive = jsonDecode(File('design/tokens/rive_tokens.json').readAsStringSync())
        as Map<String, dynamic>;
    expect(rive['color/navy'], '#2E3A87');
  });
}
