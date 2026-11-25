import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/quests/yaa_asantewaa/debrief.dart';
import 'package:google_fonts/google_fonts.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() async {
    await loadPinnedFont();
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/golden/primary_source_card_golden_test.dart'),
    );
  });

  testWidgets('primary source card golden', (tester) async {
    final json = File(kYaaQuestPrimarySourcePath).readAsStringSync();
    final card = parsePrimarySourceJson(json).copyWithNetworkImageDisabled();

    await pinSurface(tester, size: const Size(390, 720));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 720),
        builder: (_, __) => MaterialApp(
          theme: ThemeData(fontFamily: goldenFontFamily),
          home: Scaffold(
            body: QuestPrimarySourceDisplay(card: card),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(QuestPrimarySourceDisplay),
      matchesGoldenFile('primary_source_card.png'),
    );
  });
}

extension on QuestPrimarySourceCard {
  QuestPrimarySourceCard copyWithNetworkImageDisabled() {
    return QuestPrimarySourceCard(
      sourceId: sourceId,
      title: title,
      captionEn: captionEn,
      provenanceEn: provenanceEn,
      licenceId: licenceId,
      licenceLabel: licenceLabel,
      year: year,
      imageUrl: null,
      imageAltEn: imageAltEn,
    );
  }
}
