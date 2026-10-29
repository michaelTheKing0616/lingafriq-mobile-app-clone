import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/safety/copyright_policy_screen.dart';
import 'package:lingafriq/screens/settings/settings_screen_material3.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_kit.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await loadComplianceFonts(
      'test/compliance/settings_copyright_entry_test.dart',
    );
  });

  for (final v in goldenVariants) {
    testWidgets('settings copyright entry ${v.name}', (t) async {
      await pumpVariant(t, v, const SettingsScreenMaterial3());
      final tile = find.byKey(const ValueKey('settings-copyright'));
      await t.scrollUntilVisible(
        tile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pumpAndSettle();
      expectNoLayoutErrors(t);
      expect(t.getSize(tile).height, greaterThanOrEqualTo(48));
      await expectLater(
        find.byType(SettingsScreenMaterial3),
        matchesGoldenFile('goldens/settings_copyright_${v.name}.png'),
      );
      if (v.name == 'ltr_390') {
        expect(find.text('Copyright & takedown'), findsOneWidget);
        await t.tap(tile);
        await t.pumpAndSettle();
        expect(find.byType(CopyrightPolicyScreen), findsOneWidget);
      }
    });
  }
}
