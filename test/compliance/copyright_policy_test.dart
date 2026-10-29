import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/config/copyright_agent.dart';
import 'package:lingafriq/screens/safety/copyright_policy_screen.dart';

import 'golden_kit.dart';

const _en = GoldenVariant('ltr_390', Size(390, 844));
const _tall = GoldenVariant('tall', Size(390, 3200));

Future<void> _fillNotice(WidgetTester t) async {
  await t.scrollUntilVisible(
    find.byKey(const ValueKey('cp-work')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await t.enterText(
    find.byKey(const ValueKey('cp-work')),
    'My song Ayo, recorded 2024',
  );
  await t.scrollUntilVisible(
    find.byKey(const ValueKey('cp-name')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await t.enterText(find.byKey(const ValueKey('cp-name')), 'Ada Obi');
  await t.scrollUntilVisible(
    find.byKey(const ValueKey('cp-email')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await t.enterText(find.byKey(const ValueKey('cp-email')), 'ada@example.com');
  await t.scrollUntilVisible(
    find.byKey(const ValueKey('cp-signature')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await t.enterText(find.byKey(const ValueKey('cp-signature')), 'Ada Obi');
}

Future<void> _tapSend(WidgetTester t) async {
  await t.scrollUntilVisible(
    find.byKey(const ValueKey('copyright-send')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await t.ensureVisible(find.byKey(const ValueKey('copyright-send')));
  await t.tap(find.byKey(const ValueKey('copyright-send')));
}

void main() {
  setUpAll(
    () => loadComplianceFonts('test/compliance/copyright_policy_test.dart'),
  );

  for (final v in goldenVariants) {
    testWidgets('renders ${v.name} without overflow', (t) async {
      await pumpVariant(t, v, const CopyrightPolicyScreen(targetId: 'c9'));
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(CopyrightPolicyScreen),
        matchesGoldenFile('goldens/copyright_policy_${v.name}.png'),
      );
      final send = find.byKey(const ValueKey('copyright-send'));
      await t.scrollUntilVisible(
        send,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pumpAndSettle();
      expectNoLayoutErrors(t);
      expect(t.getSize(send).height, greaterThanOrEqualTo(48));
      await expectLater(
        find.byType(CopyrightPolicyScreen),
        matchesGoldenFile('goldens/copyright_policy_form_${v.name}.png'),
      );
    });
  }

  testWidgets('per-field validation, then statements, then a 512 payload', (
    t,
  ) async {
    Map<String, dynamic>? sent;
    await pumpVariant(
      t,
      _tall,
      CopyrightPolicyScreen(
        targetType: 'clip',
        targetId: 'c9',
        submit: (b) async {
          sent = b;
          return 'REF1';
        },
      ),
    );
    await _tapSend(t);
    await t.pump();
    expect(sent, isNull);
    expect(find.text('Required'), findsWidgets);
    expect(find.byKey(const ValueKey('cp-statements-error')), findsOneWidget);

    await t.scrollUntilVisible(
      find.byKey(const ValueKey('cp-email')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.enterText(find.byKey(const ValueKey('cp-email')), 'not-an-email');
    await _tapSend(t);
    await t.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);

    await _fillNotice(t);
    for (final k in ['good_faith', 'accurate_and_authorised']) {
      await t.tap(find.byKey(ValueKey('stmt-$k')));
      await t.pump();
    }
    expect(find.byKey(const ValueKey('cp-statements-error')), findsNothing);
    await _tapSend(t);
    await t.pumpAndSettle();
    expect(sent, containsPair('kind', 'notice'));
    expect(sent, containsPair('targetType', 'clip'));
    expect(sent, containsPair('targetId', 'c9'));
    expect(sent!['statements'], ['good_faith', 'accurate_and_authorised']);
    expect(find.byKey(const ValueKey('copyright-success')), findsOneWidget);
    expect(find.textContaining('REF1'), findsOneWidget);
    await expectLater(
      find.byType(CopyrightPolicyScreen),
      matchesGoldenFile('goldens/copyright_policy_success_ltr_390.png'),
    );
  });

  testWidgets('counter-notice switches statements and copy', (t) async {
    Map<String, dynamic>? sent;
    await pumpVariant(
      t,
      _tall,
      CopyrightPolicyScreen(
        targetId: 'c9',
        submit: (b) async {
          sent = b;
          return 'R2';
        },
      ),
    );
    await t.tap(find.byKey(const ValueKey('cp-kind-counter')));
    await t.pump();
    expect(find.byKey(const ValueKey('stmt-good_faith')), findsNothing);
    await _fillNotice(t);
    for (final k in [
      'mistake_or_misidentification',
      'consent_to_jurisdiction',
    ]) {
      await t.tap(find.byKey(ValueKey('stmt-$k')));
      await t.pump();
    }
    await _tapSend(t);
    await t.pumpAndSettle();
    expect(sent, containsPair('kind', 'counter'));
  });

  testWidgets('sending state, then error banner with working retry', (t) async {
    var calls = 0;
    await pumpVariant(
      t,
      _en,
      CopyrightPolicyScreen(
        targetId: 'c9',
        submit: (b) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          if (calls == 1) throw Exception('offline');
          return 'R3';
        },
      ),
    );
    await _fillNotice(t);
    for (final k in ['good_faith', 'accurate_and_authorised']) {
      await t.scrollUntilVisible(
        find.byKey(ValueKey('stmt-$k')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.byKey(ValueKey('stmt-$k')));
      await t.pump();
    }
    await _tapSend(t);
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sending…'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 60));
    await t.pumpAndSettle();
    final err = find.byKey(const ValueKey('copyright-error'));
    expect(err, findsOneWidget);
    await t.ensureVisible(err);
    await t.pumpAndSettle();
    await expectLater(
      find.byType(CopyrightPolicyScreen),
      matchesGoldenFile('goldens/copyright_policy_error_ltr_390.png'),
    );
    await t.tap(find.descendant(of: err, matching: find.byType(TextButton)));
    await t.pump(const Duration(milliseconds: 60));
    await t.pumpAndSettle();
    expect(calls, 2);
    expect(find.byKey(const ValueKey('copyright-success')), findsOneWidget);
  });

  testWidgets('designated agent: placeholder until configured', (t) async {
    await pumpVariant(t, _tall, const CopyrightPolicyScreen());
    expect(
      find.textContaining('Agent registration in progress'),
      findsOneWidget,
    );
    await pumpVariant(
      t,
      _tall,
      const CopyrightPolicyScreen(
        agent: CopyrightAgent(
          name: 'Copyright Agent, LingAfriq',
          email: 'dmca@example.com',
        ),
      ),
    );
    expect(find.text('dmca@example.com'), findsOneWidget);
    expect(find.textContaining('Agent registration in progress'), findsNothing);
  });

  test('copyright is reachable from report flow and settings', () {
    expect(
      File('lib/widgets/safety/safety_actions_sheet.dart').readAsStringSync(),
      allOf(contains("'copyright'"), contains('CopyrightPolicyScreen(')),
    );
    expect(
      File(
        'lib/screens/settings/settings_screen_material3.dart',
      ).readAsStringSync(),
      contains('CopyrightPolicyScreen()'),
    );
  });
}
