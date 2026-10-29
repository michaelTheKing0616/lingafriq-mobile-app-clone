import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/subscription/subscription_terms_disclosure.dart';

Future<void> _pump(WidgetTester t, Widget w) => t.pumpWidget(
  MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: w)),
  ),
);

void main() {
  testWidgets('shows renewal date, post-trial price, how to cancel (Apple)', (
    t,
  ) async {
    await _pump(
      t,
      SubscriptionTermsDisclosure(
        renewsOn: DateTime(2026, 11, 29),
        isApple: true,
      ),
    );
    expect(
      find.text('Your plan renews automatically on 29 Nov 2026.'),
      findsOneWidget,
    );
    expect(find.textContaining('\$4.99/month'), findsOneWidget);
    expect(
      find.textContaining('charged the plan price when the trial ends'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Settings > your name > Subscriptions'),
      findsOneWidget,
    );
    expect(find.text('Manage or cancel subscription'), findsOneWidget);
    expect(find.text('Terms'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
  });

  testWidgets('Play wording and no renewal line without an active plan', (
    t,
  ) async {
    await _pump(t, const SubscriptionTermsDisclosure(isApple: false));
    expect(find.byKey(const ValueKey('renewal-date')), findsNothing);
    expect(find.textContaining('Google Play > Profile'), findsOneWidget);
  });

  test('paywall wires disclosure beside restore and keeps free tier', () {
    final src = File(
      'lib/screens/subscription/subscription_screen.dart',
    ).readAsStringSync();
    expect(src, contains('SubscriptionTermsDisclosure('));
    expect(src, contains('restorePurchases()'));
    expect(src, contains('SubscriptionTier.free'));
    expect(
      src.indexOf('SubscriptionTermsDisclosure('),
      lessThan(src.indexOf("label: 'Restore purchases'")),
    );
  });
}
