import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/personas/persona_disclosure_badge.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() async {
    await loadPinnedFont();
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/golden/persona_disclosure_badge_test.dart'),
    );
  });

  testWidgets('badge_chat', (tester) async {
    await pinSurface(tester, size: const Size(360, 120));
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 120),
        builder: (_, __) => MaterialApp(
          theme: ThemeData(fontFamily: goldenFontFamily),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Center(
              child: PersonaDisclosureBadge(
                layout: PersonaDisclosureBadgeLayout.chat,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/badge_chat.png'),
    );
  });

  testWidgets('badge_bust', (tester) async {
    await pinSurface(tester, size: const Size(200, 200));
    final persona = HistoricalPersonaRegistry.findById('mandela_nelson');
    expect(persona, isNotNull);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(200, 200),
        builder: (_, __) => MaterialApp(
          theme: ThemeData(fontFamily: goldenFontFamily),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PersonaDisclosureBadge(
                  layout: PersonaDisclosureBadgeLayout.bust,
                ),
                PersonaSessionOpeningDisclosure(
                  facts: PersonaHowBuiltFacts.fromPersona(persona!),
                  layout: PersonaDisclosureBadgeLayout.bust,
                  showSynthLabel: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/badge_bust.png'),
    );
  });
}
