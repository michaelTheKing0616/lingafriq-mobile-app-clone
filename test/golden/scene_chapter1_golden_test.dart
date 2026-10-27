import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/ai/personas/quest_runner.dart';
import 'package:lingafriq/ai/personas/quests/yaa_asantewaa/scene_chapter1.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() async {
    await loadPinnedFont();
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/golden/scene_chapter1_golden_test.dart'),
    );
  });

  testWidgets('scene_chapter1_playing', (tester) async {
    final quest = await PersonaQuestRunner.loadYaaAsantewaaQuest();
    await pinSurface(tester, size: const Size(390, 720));
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 720),
        builder: (_, __) => MaterialApp(
          theme: ThemeData(fontFamily: goldenFontFamily),
          home: Scaffold(
            body: YaaQuestChapter1Scene(chapter: quest.chapters.first),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/scene_chapter1_playing.png'),
    );
  });
}
