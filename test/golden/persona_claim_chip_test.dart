import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/persona_claim_chip.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadPinnedFont();
    goldenFileComparator = ThresholdGoldenComparator(
      Uri.parse('test/golden/persona_claim_chip_test.dart'),
    );
  });

  testWidgets('claim_chip_documented', (tester) async {
    await pinSurface(tester, size: const Size(360, 140));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: goldenFontFamily),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: PersonaClaimRow(
            claimText: 'Independence was declared in Accra.',
            support: PersonaClaimSupport.documented,
            sourceIds: ['culture-accra-1957'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/claim_chip_documented.png'),
    );
  });

  testWidgets('claim_chip_inferred', (tester) async {
    await pinSurface(tester, size: const Size(360, 140));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: goldenFontFamily),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: PersonaClaimRow(
            claimText: 'The crowd likely sang freedom songs that night.',
            support: PersonaClaimSupport.inferred,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/claim_chip_inferred.png'),
    );
  });
}
