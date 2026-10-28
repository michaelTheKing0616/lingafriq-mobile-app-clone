import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/clip_template.dart';
import 'package:lingafriq/screens/village/clip_templates_screen.dart';

void main() {
  testWidgets('ClipTemplateDetailPanel shows verification and start affordance',
      (tester) async {
    var started = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClipTemplateDetailPanel(
            content: ClipTemplateContent(
              kind: ClipTemplateKind.tongueTwister,
              languageTag: 'yo',
              headline: 'ọkọ́ · ọkọ̀',
              promptLines: const ['Slowly: ọkọ́, then ọkọ̀'],
              suggestedCaption: 'Tone practice',
              verificationStatus: 'expert_reviewed',
              sourceId: 'register:fsi-yoruba',
            ),
            onStartClip: () => started = true,
          ),
        ),
      ),
    );

    expect(find.text('expert reviewed'), findsOneWidget);
    expect(find.textContaining('Slowly'), findsOneWidget);
    await tester.tap(find.text('Start clip'));
    expect(started, isTrue);
  });

  testWidgets('minor gate blocks templates surface', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, __) => ClipTemplatesScreen(
              gateOverride: ClipTemplatesAccessGate.blockedMinor,
              loadCapabilitiesOnInit: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Clips need a guardian'), findsOneWidget);
  });
}
