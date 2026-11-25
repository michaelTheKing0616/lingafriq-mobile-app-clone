import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/design.dart';
import 'package:lingafriq/design/typography.dart';

import '../../tool/design/gen_tokens.dart';

Map<String, dynamic> _spec() => jsonDecode(
      File('design/tokens/tokens.json').readAsStringSync(),
    ) as Map<String, dynamic>;

void main() {
  test('target-language type stays at or above 18sp and 1.5 leading', () {
    expect(LingAfriqType.target.fontSize, greaterThanOrEqualTo(18));
    expect(LingAfriqType.target.height, greaterThanOrEqualTo(1.5));
    expect(LingAfriqTokens.typeIdTarget, 'type.target');
    expect(LingAfriqTokens.typeRoleBody, 'body');
    expect(LingAfriqTokens.typeIdBody, LingAfriqType.bodyToken);
    expect(LingAfriqType.bodyFamily, 'LingAfriqText');
  });

  test('a target style under the floor fails the generator', () {
    final spec = _spec();
    ((spec['type'] as Map)['target'] as Map)['size'] = 16;
    expect(
      () => generateTokens(spec),
      throwsA(
        predicate((e) => e is TokenGenException && e.message.contains('18sp')),
      ),
    );
  });

  testWidgets('200% scale leaves a gap between tone-marked lines', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            'Ẹ kú àárọ̀\nỌ̀ ṣun',
            style: LingAfriqType.target,
          ),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(find.byType(Text));
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 16),
    );
    expect(boxes.length, greaterThan(1));
    final gap = boxes[1].top - boxes[0].bottom;
    expect(gap, greaterThanOrEqualTo(0));
    expect(boxes[1].top - boxes[0].top, greaterThanOrEqualTo(18 * 1.5));
  });
}
