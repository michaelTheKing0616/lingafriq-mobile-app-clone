import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/capability_gate.dart';

void main() {
  group('CapabilityGate', () {
    test('parses minor matrix with purchases and ads off', () async {
      final gate = CapabilityGate(
        get: (_) async => {
          'ok': true,
          'capabilities': {
            'is_minor': true,
            'tier': '13_15',
            'social_enabled': true,
            'direct_messages_open': true,
            'snaps': false,
            'public_snap_feed': false,
            'ads': false,
            'purchases': false,
            'guardian_hub_path': '/guardian',
          },
        },
      );
      expect(await gate.mayPurchase(), isFalse);
      expect(await gate.mayRequestAds(), isFalse);
      expect(await gate.mayUseSnaps(), isFalse);
    });

    testWidgets('purchase blocked sheet offers Family hub', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () => CapabilityBlockedSheet.showPurchaseBlocked(context),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(CapabilityBlockedSheet.purchaseBlockedTitle), findsOneWidget);
      expect(find.text('Open Family hub'), findsOneWidget);
    });
  });

  test('LearnerCapabilities.fromJson maps server fields', () {
    final caps = LearnerCapabilities.fromJson({
      'is_minor': false,
      'purchases': true,
      'ads': true,
    });
    expect(caps.isMinor, isFalse);
    expect(caps.purchases, isTrue);
  });
}
