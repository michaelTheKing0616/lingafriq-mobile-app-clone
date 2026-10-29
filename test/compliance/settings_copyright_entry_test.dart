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

  for (final v in [
    ...goldenVariants,
    const GoldenVariant('fr_390', Size(390, 844), locale: Locale('fr')),
  ]) {
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

  for (final (locale, expected) in [
    (
      const Locale('ar'),
      [
        'حول التطبيق',
        'شروط الخدمة',
        'سياسة الخصوصية',
        'دليل الميزات',
        'كيف تعمل الألعاب',
        'المساعدة والدعم',
        'حقوق النشر والإزالة',
      ],
    ),
    (
      const Locale('fr'),
      [
        'À propos',
        "Conditions d'utilisation",
        'Politique de confidentialité',
        'Guide des fonctionnalités',
        'Fonctionnement des jeux',
        'Aide et assistance',
      ],
    ),
  ]) {
    testWidgets('About rows are translated (${locale.languageCode})', (
      t,
    ) async {
      await pumpVariant(
        t,
        GoldenVariant('l10n', const Size(390, 3000), locale: locale),
        const SettingsScreenMaterial3(),
      );
      for (final text in expected) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      for (final english in [
        'Terms of Service',
        'Privacy Policy',
        'Help & Support',
        'Log Out',
        'About',
        'Game onboarding overlay',
        'Low bandwidth',
      ]) {
        expect(find.text(english), findsNothing, reason: english);
      }
    });
  }

  // In French, settingsSecNotifications and settingsSecAudio are both spelled
  // "Notifications"/"Audio" exactly as in English, which is correct French.
  testWidgets('fr section headings are genuine French', (t) async {
    await pumpVariant(
      t,
      const GoldenVariant('fr', Size(390, 3000), locale: Locale('fr')),
      const SettingsScreenMaterial3(),
    );
    await t.pumpAndSettle();
    expect(find.text('Déconnexion'), findsWidgets);
    expect(find.text('Logout'), findsNothing);
  });
}
