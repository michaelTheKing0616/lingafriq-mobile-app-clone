import 'dart:io';
import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/config/bundled_fonts.dart';
import 'package:lingafriq/design/text/target_text.dart';
import 'package:lingafriq/design/typography.dart';

Future<void> _load(String family, String asset) async {
  final data = File(asset).readAsBytes().then(ByteData.sublistView);
  final loader = FontLoader(family)..addFont(data);
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    configureBundledFonts();
    await _load('Andika', 'assets/google_fonts/Andika-Regular.ttf');
    await _load('LingAfriqText', 'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf');
    await _load('NotoSansEthiopic', 'assets/fonts/lingafriq/NotoSansEthiopic-Regular.ttf');
    await _load('NotoSansNKo', 'assets/fonts/lingafriq/NotoSansNKo-Regular.ttf');
    await _load('NotoSansTifinagh', 'assets/fonts/lingafriq/NotoSansTifinagh-Regular.ttf');
    await _load('NotoSansAdlam', 'assets/fonts/lingafriq/NotoSansAdlam-Regular.ttf');
  });

  testWidgets('glyph proof uses Andika, 18sp, leading 1.5 and the Noto fallbacks', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: TargetText(text: LingAfriqType.glyphProof),
        ),
      ),
    );

    final widget = tester.widget<Text>(find.text(LingAfriqType.glyphProof));
    expect(widget.style?.fontFamily, LingAfriqType.targetFamily);
    expect(widget.style?.fontSize, greaterThanOrEqualTo(18));
    expect(widget.style?.height, greaterThanOrEqualTo(1.5));
    expect(widget.style?.fontFamilyFallback, containsAll(LingAfriqType.scriptFallback));
    expect(widget.strutStyle?.forceStrutHeight, isTrue);

    final paragraph = tester.renderObject<RenderParagraph>(find.text(LingAfriqType.glyphProof));
    expect(paragraph.size.width, greaterThan(80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('200% text scale keeps each line box at least fontSize times height', (tester) async {
    const scale = 2.0;
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 800,
              child: TargetText(text: LingAfriqType.glyphProof),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(LingAfriqType.glyphProof));
    final style = paragraph.text.style!;
    final fontSize = style.fontSize!;
    final height = style.height!;
    final minLine = fontSize * height * scale;
    expect(fontSize, greaterThanOrEqualTo(18));
    expect(height, greaterThanOrEqualTo(1.5));

    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: LingAfriqType.glyphProof.length),
      boxHeightStyle: BoxHeightStyle.includeLineSpacingMiddle,
    );
    expect(boxes, isNotEmpty);
    for (final box in boxes) {
      expect(box.bottom - box.top, greaterThanOrEqualTo(minLine - 0.01));
    }
    expect(
      paragraph.getFullHeightForCaret(const TextPosition(offset: 0)),
      greaterThanOrEqualTo(minLine - 0.01),
    );
    expect(paragraph.size.height, greaterThanOrEqualTo(minLine - 0.01));
    if (paragraph.constraints.hasBoundedHeight) {
      expect(paragraph.size.height, lessThanOrEqualTo(paragraph.constraints.maxHeight + 0.01));
    }
    if (paragraph.constraints.hasBoundedWidth) {
      expect(paragraph.size.width, lessThanOrEqualTo(paragraph.constraints.maxWidth + 0.01));
    }
    expect(tester.takeException(), isNull);
  });
}
