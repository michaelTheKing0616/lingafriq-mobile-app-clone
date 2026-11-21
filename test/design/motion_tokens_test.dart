import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/design.dart';

import '../../tool/design/gen_tokens.dart';

Map<String, dynamic> _spec() => jsonDecode(
      File('design/tokens/tokens.json').readAsStringSync(),
    ) as Map<String, dynamic>;

void main() {
  test('product easing is ease-out and every duration is at most 300ms', () {
    expect(LingAfriqTokens.motionProductEasing, 'cubic-bezier(0.23,1,0.32,1)');
    expect(LingAfriqTokens.motionProductInstant, lessThanOrEqualTo(300));
    expect(LingAfriqTokens.motionProductFast, lessThanOrEqualTo(300));
    expect(LingAfriqTokens.motionProductBase, lessThanOrEqualTo(300));
    expect(LingAfriqTokens.motionProductSlow, 300);
    final css = File('design/tokens/admin.css').readAsStringSync();
    expect(css, contains('--motion-product-easing: cubic-bezier(0.23,1,0.32,1);'));
    expect(css, contains('--motion-product-slow: 300ms;'));
  });

  test('a product duration above 300ms fails', () {
    final spec = _spec();
    ((spec['motion'] as Map)['product'] as Map)['durationMs'] = {'slow': 301};
    expect(
      () => generateTokens(spec),
      throwsA(
        predicate((e) => e is TokenGenException && e.message.contains('above 300ms')),
      ),
    );
  });

  test('rare motion is a separate group limited to lesson-complete and level-up', () {
    expect(LingAfriqTokens.motionRareLessonComplete, greaterThan(300));
    expect(LingAfriqTokens.motionRareLevelUp, greaterThan(300));
    final uses = ((_spec()['motion'] as Map)['rare'] as Map)['allowedUses'] as List;
    expect(uses, ['lesson-complete', 'level-up']);
    final spec = _spec();
    ((spec['motion'] as Map)['rare'] as Map)['allowedUses'] = ['splash'];
    expect(
      () => generateTokens(spec),
      throwsA(predicate((e) => e is TokenGenException && e.message.contains('rare motion'))),
    );
  });
}
