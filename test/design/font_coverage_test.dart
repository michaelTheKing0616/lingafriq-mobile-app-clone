import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/config/bundled_fonts.dart';
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

  test('runtime font fetch is off and families are pubspec assets', () {
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final family in ['Andika', 'LingAfriqText', 'NotoSansEthiopic', 'NotoSansNKo', 'NotoSansTifinagh', 'NotoSansAdlam']) {
      expect(pubspec, contains('family: $family'), reason: family);
    }
    expect(LingAfriqType.target.fontSize, greaterThanOrEqualTo(18));
    expect(LingAfriqType.target.height, greaterThanOrEqualTo(1.5));
  });

  testWidgets('glyph proof paints with Andika and Noto fallbacks', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text(LingAfriqType.glyphProof, style: LingAfriqType.target),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text(LingAfriqType.glyphProof),
    );
    expect(paragraph.size.width, greaterThan(80));
    expect(paragraph.size.height, greaterThanOrEqualTo(18));
    expect(paragraph.text.style?.fontFamily, 'Andika');
    expect(paragraph.text.style?.height, greaterThanOrEqualTo(1.5));
  });
}
