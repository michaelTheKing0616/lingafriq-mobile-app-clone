import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/subscription/subscription_terms_disclosure.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'golden_kit.dart';

Widget _host(Widget w) => Scaffold(
  body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: w),
);

Package _pkg(String id, String price, {IntroductoryPrice? intro}) => Package(
  id,
  PackageType.monthly,
  StoreProduct(id, '', '', 0, price, 'EUR', introductoryPrice: intro),
  const PresentedOfferingContext('default', null, null),
);

final _euro = StorePrices.fromPackages(
  premium: _pkg(
    'p',
    '€5,49',
    intro: const IntroductoryPrice(0, '€0', 'P1W', 1, PeriodUnit.week, 1),
  ),
  family: _pkg('f', '€10,99'),
  lifetime: _pkg('l', '€109,99'),
);

/// Text containing [s] once bidi isolates (U+2068/U+2069) are removed.
Finder _plain(String s) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      (w.data ?? '')
          .replaceAll(RegExp('[\u2066\u2068\u2069]'), '')
          .replaceAll('\u00A0', ' ')
          .contains(s),
);

const _en = GoldenVariant('ltr_390', Size(390, 844));

void main() {
  setUpAll(
    () => loadComplianceFonts('test/compliance/paywall_disclosure_test.dart'),
  );

  for (final v in goldenVariants) {
    testWidgets('renders ${v.name}: labelled rows, no overflow', (t) async {
      await pumpVariant(
        t,
        v,
        _host(
          SubscriptionTermsDisclosure(
            renewsOn: DateTime(2026, 11, 29),
            isApple: true,
          ),
        ),
        overrides: [
          storePricesProvider.overrideWith((ref) async => StorePrices.fallback),
        ],
      );
      expectNoLayoutErrors(t);
      for (final k in [
        'row-price',
        'row-renews',
        'row-trial',
        'how-to-cancel',
      ]) {
        expect(find.byKey(ValueKey(k)), findsOneWidget);
      }
      for (final k in ['manage-subscription', 'terms-link', 'privacy-link']) {
        expect(
          t.getSize(find.byKey(ValueKey(k))).height,
          greaterThanOrEqualTo(48),
        );
      }
      // Each link label stays on one line (no orphaned word) at every variant.
      for (final k in ['terms-link', 'privacy-link']) {
        final text = find.descendant(
          of: find.byKey(ValueKey(k)),
          matching: find.byType(Text),
        );
        final lineH = t.getSize(text).height;
        final style = t.widget<Text>(text).style!;
        expect(lineH, lessThan(style.fontSize! * v.scale * 1.8));
      }
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/paywall_terms_${v.name}.png'),
      );
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('privacy-link')),
        200,
      );
      await t.pumpAndSettle();
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/paywall_terms_links_${v.name}.png'),
      );
    });
  }

  testWidgets('labelled rows carry date, prices and Apple cancel path', (
    t,
  ) async {
    await pumpVariant(
      t,
      _en,
      _host(
        SubscriptionTermsDisclosure(
          renewsOn: DateTime(2026, 11, 29),
          isApple: true,
        ),
      ),
      overrides: [
        storePricesProvider.overrideWith((ref) async => StorePrices.fallback),
      ],
    );
    expect(find.text('Your plan renews on Nov 29, 2026.'), findsOneWidget);
    expect(_plain(r'Plus Monthly $4.99/month'), findsOneWidget);
    expect(
      find.textContaining('Settings › your name › Subscriptions'),
      findsOneWidget,
    );
    expect(_plain('App Store'), findsOneWidget);
  });

  testWidgets('store prices and trial come from RevenueCat packages (Play)', (
    t,
  ) async {
    await pumpVariant(
      t,
      _en,
      _host(const SubscriptionTermsDisclosure(isApple: false)),
      overrides: [storePricesProvider.overrideWith((ref) async => _euro)],
    );
    expect(_plain('Plus Monthly €5,49/month'), findsOneWidget);
    expect(_plain('Plus Lifetime €109,99'), findsOneWidget);
    expect(_plain('7-day free trial of Plus Monthly, then €5,49/month'), findsOneWidget);
    expect(find.textContaining('Google Play › Payments'), findsOneWidget);
    expect(find.textContaining('Your plan renews on'), findsNothing);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/paywall_terms_store_prices_ltr_390.png'),
    );
  });

  for (final apple in [true, false]) {
    testWidgets('Arabic: Latin brands are LTR-isolated and unbreakable '
        '(${apple ? 'App Store' : 'Google Play'})', (t) async {
      await pumpVariant(
        t,
        goldenVariants[1],
        _host(SubscriptionTermsDisclosure(isApple: apple)),
        overrides: [
          storePricesProvider.overrideWith((ref) async => StorePrices.fallback),
        ],
      );
      final texts = t
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .where((d) => RegExp(r'App|Google|Store|Play').hasMatch(d))
          .toList();
      expect(texts, isNotEmpty);
      for (final d in texts) {
        expect(
          d,
          isNot(matches(RegExp(r'(App|Google) (Store|Play)'))),
          reason: 'breakable space in "$d"',
        );
        expect(
          d,
          matches(RegExp('\u2066(App|Google)\u00A0(Store|Play)\u2069')),
          reason: 'brand not LTR-isolated in "$d"',
        );
      }
      if (!apple) {
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/paywall_terms_google_rtl_390.png'),
        );
      }
      // Prices too.
      expect(
        t.widgetList<Text>(find.byType(Text)).map((w) => w.data ?? '').join(),
        contains('\u2066\$4.99\u2069'),
      );
    });
  }

  test('fromPackages falls back per field and ignores paid intro offers', () {
    final p = StorePrices.fromPackages(
      premium: _pkg(
        'p',
        '£4.49',
        intro: const IntroductoryPrice(
          0.99,
          '£0.99',
          'P1M',
          1,
          PeriodUnit.month,
          1,
        ),
      ),
    );
    expect(p.premium, '£4.49');
    expect(p.family, StorePrices.fallback.family);
    expect(p.lifetime, StorePrices.fallback.lifetime);
    expect(p.trialDays, isNull);
    expect(_euro.trialDays, 7);
  });

  test('provider falls back when RevenueCat is unavailable', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final p = await c.read(storePricesProvider.future);
    expect(p.premium, StorePrices.fallback.premium);
  });

  test('paywall wires disclosure beside restore and keeps free tier', () {
    final src = File(
      'lib/screens/subscription/subscription_screen.dart',
    ).readAsStringSync();
    expect(src, contains('SubscriptionTermsDisclosure('));
    expect(src, contains('restorePurchases()'));
    expect(src, contains('SubscriptionTier.free'));
    expect(src, contains("Key('sub-restore')"));
    expect(
      src.indexOf('SubscriptionTermsDisclosure('),
      lessThan(src.indexOf("Key('sub-restore')")),
    );
  });
}
