import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/safety/copyright_policy_screen.dart';
import 'package:lingafriq/widgets/safety/safety_actions_sheet.dart';

import 'golden_kit.dart';

const _target = SafetyActionTarget(
  kind: SafetyTargetKind.clip,
  targetId: 'clip-7',
  peerUserId: 'u1',
  peerDisplayName: 'Ada',
);

void main() {
  setUpAll(
    () => loadComplianceFonts('test/compliance/report_reasons_test.dart'),
  );

  for (final v in goldenVariants) {
    testWidgets('reason picker ${v.name}: localised, helper, no overflow', (
      t,
    ) async {
      String? picked;
      await pumpVariant(
        t,
        v,
        Scaffold(body: ReportReasonPicker(onPicked: (r) => picked = r)),
      );
      expectNoLayoutErrors(t);
      for (final r in reportReasons) {
        final tile = find.byKey(ValueKey('reason-$r'));
        expect(tile, findsOneWidget);
        expect(t.getSize(tile).height, greaterThanOrEqualTo(48));
      }
      // No raw API slugs are shown to people.
      for (final r in reportReasons) {
        expect(find.text(r), findsNothing);
        expect(find.text(r[0].toUpperCase() + r.substring(1)), findsNothing);
      }
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/report_reasons_${v.name}.png'),
      );
      await t.tap(find.byKey(const ValueKey('reason-spam')));
      expect(picked, 'spam');
    });
  }

  testWidgets('English copy and copyright helper line', (t) async {
    await pumpVariant(
      t,
      goldenVariants.first,
      Scaffold(body: ReportReasonPicker(onPicked: (_) {})),
    );
    expect(find.text('Why are you reporting this?'), findsOneWidget);
    expect(find.text('Harassment or bullying'), findsOneWidget);
    expect(find.text('Copyright infringement'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reason-copyright')),
        matching: find.text('Someone posted your work without permission'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'inside ProviderScope + l10n: Report > Copyright opens the notice form '
    'prefilled with the reported target',
    (t) async {
      await pumpVariant(
        t,
        goldenVariants.first,
        Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: FilledButton(
                onPressed: () => showSafetyActionsSheet(ctx, target: _target),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.tap(find.text(SafetyCopy.report));
      await t.pumpAndSettle();
      expect(find.byType(ReportReasonPicker), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('reason-copyright')));
      await t.pumpAndSettle();
      final screen = t.widget<CopyrightPolicyScreen>(
        find.byType(CopyrightPolicyScreen),
      );
      expect(screen.targetType, 'clip');
      expect(screen.targetId, 'clip-7');
      expect(find.byType(SafetyActionsSheet), findsNothing);
      expectNoLayoutErrors(t);
    },
  );
}
