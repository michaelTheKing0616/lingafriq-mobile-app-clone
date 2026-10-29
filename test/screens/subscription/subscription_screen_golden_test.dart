import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/providers/subscription_provider.dart';
import 'package:lingafriq/screens/subscription/subscription_screen.dart';
import 'package:lingafriq/screens/subscription/subscription_terms_disclosure.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../compliance/golden_kit.dart';

final bought = <SubscriptionTier>[];

class _Sub extends SubscriptionNotifier {
  _Sub(this.initial);
  final SubscriptionState initial;

  @override
  SubscriptionState build() => initial;

  @override
  Future<bool> subscribe(SubscriptionTier tier) async {
    bought.add(tier);
    return true;
  }
}

const _trial = StorePrices(
  premium: r'$4.99',
  family: r'$9.99',
  lifetime: r'$99.99',
  trialDays: 7,
);

List<Override> _o({
  Future<StorePrices> Function()? prices,
  String? tier,
  bool online = true,
  SubscriptionState? state,
}) => [
  subscriptionProvider.overrideWith(
    () => _Sub(
      state ?? SubscriptionState(tier: SubscriptionTier.free, isActive: false),
    ),
  ),
  storePricesProvider.overrideWith(
    (ref) => prices == null ? Future.value(_trial) : prices(),
  ),
  subscriptionOnlineProvider.overrideWith((ref) async => online),
  ageTierStatusProvider.overrideWith(
    (ref) async => tier == null
        ? null
        : AgeTierStatus(assigned: true, tier: tier, status: 'active'),
  ),
];

Future<void> _pump(
  WidgetTester t,
  GoldenVariant v,
  List<Override> o, {
  bool settle = true,
}) async {
  await pumpVariant(
    t,
    v,
    const SubscriptionScreen(),
    overrides: o,
    settle: settle,
  );
  if (settle) {
    await t.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/cast_still_Amara.png'),
        t.element(find.byType(SubscriptionScreen)),
      );
    });
    await t.pumpAndSettle();
  } else {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(
    () => loadComplianceFonts(
      'test/screens/subscription/subscription_screen_golden_test.dart',
    ),
  );
  setUp(bought.clear);
  final base = goldenVariants.first;

  for (final v in [
    ...goldenVariants,
    const GoldenVariant('fr_390', Size(390, 844), locale: Locale('fr')),
  ]) {
    testWidgets('subscription golden ${v.name}', (t) async {
      await _pump(t, v, _o());
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(SubscriptionScreen),
        matchesGoldenFile('goldens/subscription_${v.name}.png'),
      );
    });
  }

  for (final (name, o, settle) in [
    ('loading', _o(prices: () => Completer<StorePrices>().future), false),
    ('error', _o(prices: () => Future.error(Exception('store'))), true),
    ('offline', _o(online: false), true),
    ('child', _o(tier: 'child'), true),
    (
      'plus',
      _o(
        state: SubscriptionState(
          tier: SubscriptionTier.premium,
          isActive: true,
          expiresAt: DateTime(2026, 11, 29),
        ),
      ),
      true,
    ),
  ]) {
    testWidgets('subscription state golden $name', (t) async {
      await _pump(t, base, o, settle: settle);
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(SubscriptionScreen),
        matchesGoldenFile('goldens/subscription_state_$name.png'),
      );
    });
  }

  testWidgets('close is visible at once and free path is offered', (t) async {
    await _pump(t, base, _o());
    final close = find.byKey(const Key('sub-close'));
    expect(close, findsOneWidget);
    expect(t.getSize(close).width, greaterThanOrEqualTo(44));
    expect(find.byKey(const Key('sub-free-forever')), findsOneWidget);
    expect(find.text('Keep learning for free'), findsOneWidget);
  });

  testWidgets('compliance disclosure block and restore are kept', (t) async {
    await _pump(t, base, _o());
    await t.scrollUntilVisible(find.byKey(const Key('sub-restore')), 200);
    expect(find.byKey(const ValueKey('subscription-terms')), findsOneWidget);
    expect(find.byKey(const ValueKey('how-to-cancel')), findsOneWidget);
  });

  testWidgets('trial: CTA, timeline and fine print show the full price', (
    t,
  ) async {
    await _pump(t, base, _o());
    expect(find.text('Start 7-day free trial'), findsOneWidget);
    final fine = t.widget<Text>(find.byKey(const Key('sub-fine'))).data!;
    expect(
      fine.replaceAll(RegExp('[\u2066\u2069]'), ''),
      r'Free for 7 days, then $4.99/month. Cancel anytime in your store settings.',
    );
    await t.scrollUntilVisible(find.byKey(const Key('sub-timeline')), 200);
    expect(find.text('Day 5'), findsOneWidget);
    expect(find.text('Day 7'), findsOneWidget);
  });

  testWidgets('picking a plan updates CTA and buys that plan', (t) async {
    await _pump(t, base, _o());
    await t.ensureVisible(find.byKey(const Key('plan-lifetime')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('plan-lifetime')));
    await t.pumpAndSettle();
    expect(find.text('Get Plus Lifetime'), findsOneWidget);
    expect(find.byKey(const Key('sub-timeline')), findsNothing);
    await t.tap(find.byKey(const Key('sub-cta')));
    await t.pump();
    expect(bought, [SubscriptionTier.lifetime]);
  });

  testWidgets('offline: buying disabled with a reason, learning promise kept', (
    t,
  ) async {
    await _pump(t, base, _o(online: false));
    expect(find.byKey(const Key('sub-offline')), findsOneWidget);
    await t.tap(find.byKey(const Key('sub-cta')));
    await t.pump();
    expect(bought, isEmpty);
  });

  testWidgets('price error falls back to standard prices with a note', (
    t,
  ) async {
    await _pump(t, base, _o(prices: () => Future.error(Exception('x'))));
    expect(find.byKey(const Key('sub-price-error')), findsOneWidget);
    expect(find.byKey(const Key('plan-premium')), findsOneWidget);
  });

  testWidgets('loading shows plan skeleton and no CTA', (t) async {
    await _pump(
      t,
      base,
      _o(prices: () => Completer<StorePrices>().future),
      settle: false,
    );
    expect(find.byKey(const Key('sub-loading')), findsOneWidget);
    expect(find.byKey(const Key('sub-cta')), findsNothing);
  });

  for (final tier in ['child', 'teen']) {
    testWidgets('$tier: no prices until a grown-up passes the gate', (t) async {
      await _pump(t, base, _o(tier: tier));
      expect(find.byKey(const Key('plan-premium')), findsNothing);
      expect(find.byKey(const Key('sub-cta')), findsNothing);
      await t.tap(find.byKey(const Key('sub-ask-parent')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('sub-gate-answer')), '100');
      await t.tap(find.byKey(const Key('sub-gate-ok')));
      await t.pumpAndSettle();
      expect(find.text("That's not right. Try again."), findsOneWidget);
      await t.enterText(find.byKey(const Key('sub-gate-answer')), '102');
      await t.tap(find.byKey(const Key('sub-gate-ok')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('plan-premium')), findsOneWidget);
    });
  }

  testWidgets('Plus member sees thanks, not plans', (t) async {
    await _pump(
      t,
      base,
      _o(
        state: SubscriptionState(tier: SubscriptionTier.family, isActive: true),
      ),
    );
    expect(find.byKey(const Key('sub-current')), findsOneWidget);
    expect(find.byKey(const Key('plan-premium')), findsNothing);
  });

  testWidgets('short screen + 200% text: CTA scrolls inline, not pinned', (
    t,
  ) async {
    await _pump(t, goldenVariants[4], _o());
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byKey(const Key('sub-cta')),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    await _pump(t, base, _o());
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byKey(const Key('sub-cta')),
        skipOffstage: false,
      ),
      findsNothing,
    );
  });

  testWidgets('Arabic: RTL, localized, a11y guidelines', (t) async {
    final h = t.ensureSemantics();
    await _pump(t, goldenVariants[1], _o());
    expect(find.text('LingAfriq Plus'), findsOneWidget);
    expect(find.text('اختر خطة'), findsOneWidget);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(textContrastGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
  });
}
