import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/safety/copyright_policy_screen.dart';

void main() {
  testWidgets('policy covers takedown, counter-notice and repeat infringers', (
    t,
  ) async {
    await t.pumpWidget(const MaterialApp(home: CopyrightPolicyScreen()));
    expect(find.textContaining('counter-notice'), findsWidgets);
    expect(find.textContaining('Repeat infringers'), findsOneWidget);
  });

  testWidgets('notice requires statements, then submits a 512 payload', (
    t,
  ) async {
    t.view.physicalSize = const Size(1000, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    Map<String, dynamic>? sent;
    await t.pumpWidget(
      MaterialApp(
        home: CopyrightPolicyScreen(
          targetType: 'clip',
          targetId: 'c9',
          submit: (b) async {
            sent = b;
            return 'REF1';
          },
        ),
      ),
    );
    final fields = find.byType(TextField);
    await t.enterText(fields.at(1), 'My song Ayo, recorded 2024');
    await t.enterText(fields.at(2), 'Ada Obi');
    await t.enterText(fields.at(3), 'ada@example.com');
    await t.enterText(fields.at(4), 'Ada Obi');
    await t.ensureVisible(find.byKey(const ValueKey('copyright-send')));
    await t.tap(find.byKey(const ValueKey('copyright-send')));
    await t.pump();
    expect(sent, isNull);
    expect(find.textContaining('tick each statement'), findsOneWidget);
    for (final k in ['good_faith', 'accurate_and_authorised']) {
      await t.ensureVisible(find.byKey(ValueKey('stmt-$k')));
      await t.tap(find.byKey(ValueKey('stmt-$k')));
      await t.pump();
    }
    await t.ensureVisible(find.byKey(const ValueKey('copyright-send')));
    await t.tap(find.byKey(const ValueKey('copyright-send')));
    await t.pumpAndSettle();
    expect(sent, containsPair('kind', 'notice'));
    expect(sent, containsPair('targetType', 'clip'));
    expect(sent, containsPair('targetId', 'c9'));
    expect(sent!['statements'], ['good_faith', 'accurate_and_authorised']);
    expect(find.text('Sent. Reference: REF1.'), findsOneWidget);
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
