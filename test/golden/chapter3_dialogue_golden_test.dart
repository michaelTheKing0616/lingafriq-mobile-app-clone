import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/ai/personas/quests/yaa_asantewaa/chapter3.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() async {
    await loadPinnedFont();
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/golden/chapter3_dialogue_golden_test.dart'),
    );
  });

  testWidgets('dialogue_subtitles', (tester) async {
    await pinSurface(tester, size: const Size(390, 420));
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 420),
        builder: (_, __) => MaterialApp(
          theme: ThemeData(fontFamily: goldenFontFamily),
          home: const Scaffold(
            body: YaaQuestDialogueSubtitlesFixture(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/dialogue_subtitles.png'),
    );
  });
}
