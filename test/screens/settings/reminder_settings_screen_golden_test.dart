import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/learning/reminders/reminder_policy.dart';
import 'package:lingafriq/providers/notification_provider.dart';
import 'package:lingafriq/screens/settings/reminder_settings_screen.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../compliance/golden_kit.dart';

/// Fake notifier: no plugin, no network; records every change.
class _Fake extends NotificationNotifier {
  _Fake({this.on = true, this.time = const (7, 30)});
  final bool on;
  final (int, int) time;
  final calls = <String>[];

  @override
  NotificationState build() => NotificationState(
    studyRemindersEnabled: on,
    streakRemindersEnabled: true,
    dailyGoalRemindersEnabled: true,
    achievementAlertsEnabled: true,
    reminderTime: Time(time.$1, time.$2),
    timezone: 'Africa/Lagos',
    hasCustomWindow: false,
  );

  @override
  Future<void> updateReminderTime(Time t) async {
    calls.add('time ${t.hour}:${t.minute}');
    state = state.copyWith(reminderTime: t);
  }

  @override
  Future<void> updateTimezone(String tz) async => calls.add('tz');

  @override
  Future<void> setStudyRemindersEnabled(bool v) async {
    calls.add('master $v');
    state = state.copyWith(studyRemindersEnabled: v);
  }

  @override
  void toggleDailyGoalReminders(bool v) {
    calls.add('goal $v');
    state = state.copyWith(dailyGoalRemindersEnabled: v);
  }

  @override
  void toggleStreakReminders(bool v) {
    calls.add('rhythm $v');
    state = state.copyWith(streakRemindersEnabled: v);
  }
}

List<Override> _o({
  _Fake? fake,
  Future<bool> Function()? perm,
  bool online = true,
  String? tier,
  Future<bool> Function()? openSettings,
}) => [
  notificationProvider.overrideWith(() => fake ?? _Fake()),
  reminderPermissionProvider.overrideWith(
    (ref) => (perm ?? () async => true)(),
  ),
  reminderOnlineProvider.overrideWith((ref) async => online),
  reminderOpenSettingsProvider.overrideWithValue(
    openSettings ?? () async => true,
  ),
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
    const ReminderSettingsScreen(),
    overrides: o,
    settle: settle,
  );
  if (!settle) await t.pump(const Duration(milliseconds: 50));
}

String _texts(WidgetTester t) => t
    .widgetList<Text>(find.byType(Text))
    .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
    .join('\n');

void main() {
  setUpAll(
    () => loadComplianceFonts(
      'test/screens/settings/reminder_settings_screen_golden_test.dart',
    ),
  );
  final base = goldenVariants.first;

  for (final v in [
    ...goldenVariants,
    const GoldenVariant('fr_390', Size(390, 844), locale: Locale('fr')),
    const GoldenVariant('tablet_820', Size(820, 1180)),
  ]) {
    testWidgets('reminders golden ${v.name}', (t) async {
      await _pump(t, v, _o());
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(ReminderSettingsScreen),
        matchesGoldenFile('goldens/reminders_${v.name}.png'),
      );
    });
  }

  for (final (name, make, settle) in [
    ('loading', () => _o(perm: () => Completer<bool>().future), false),
    ('error', () => _o(perm: () async => throw StateError('x')), true),
    ('blocked', () => _o(perm: () async => false), true),
    ('offline', () => _o(online: false), true),
    ('off', () => _o(fake: _Fake(on: false)), true),
    ('child', () => _o(tier: 'child'), true),
  ]) {
    testWidgets('reminders state $name', (t) async {
      await _pump(t, base, make(), settle: settle);
      if (name == 'offline') {
        expect(find.byKey(const Key('rm-offline')), findsNothing);
        await t.tap(find.byKey(const Key('rm-slot-1')));
        await t.pumpAndSettle();
      }
      expectNoLayoutErrors(t);
      expect(
        find.byKey(Key('rm-${name == 'error' ? 'check-error' : name}')),
        name == 'off' ? findsNothing : findsOneWidget,
      );
      await expectLater(
        find.byType(ReminderSettingsScreen),
        matchesGoldenFile('goldens/reminders_state_$name.png'),
      );
    });
  }

  testWidgets('loading shows skeleton, no permission banner', (t) async {
    await _pump(
      t,
      base,
      _o(perm: () => Completer<bool>().future),
      settle: false,
    );
    expect(find.byKey(const Key('rm-loading')), findsOneWidget);
    expect(find.byKey(const Key('rm-blocked')), findsNothing);
  });

  testWidgets('error retry re-checks permission', (t) async {
    var n = 0;
    await _pump(
      t,
      base,
      _o(
        perm: () async {
          n++;
          if (n == 1) throw StateError('x');
          return true;
        },
      ),
    );
    expect(find.byKey(const Key('rm-check-error')), findsOneWidget);
    await t.tap(find.byKey(const Key('rm-retry')));
    await t.pumpAndSettle();
    expect(n, 2);
    expect(find.byKey(const Key('rm-check-error')), findsNothing);
  });

  testWidgets('blocked banner opens OS settings', (t) async {
    var opened = 0;
    await _pump(
      t,
      base,
      _o(
        perm: () async => false,
        openSettings: () async {
          opened++;
          return true;
        },
      ),
    );
    await t.tap(find.byKey(const Key('rm-open-settings')));
    expect(opened, 1);
  });

  testWidgets(
    'master switch off: preview says off, chips and toggles disabled',
    (t) async {
      final f = _Fake();
      await _pump(t, base, _o(fake: f));
      expect(find.byKey(const Key('rm-preview-time')), findsOneWidget);
      await t.tap(find.byKey(const Key('rm-master')));
      await t.pumpAndSettle();
      expect(f.calls, ['master false']);
      expect(find.byKey(const Key('rm-preview-time')), findsNothing);
      await t.tap(find.byKey(const Key('rm-slot-2')));
      await t.pumpAndSettle();
      expect(f.calls, ['master false'], reason: 'chips inert when off');
      final goal = t.widget<SwitchListTile>(find.byKey(const Key('rm-goal')));
      expect(goal.onChanged, isNull);
    },
  );

  testWidgets('preset chip sets time and preview follows', (t) async {
    final f = _Fake();
    await _pump(t, base, _o(fake: f));
    await t.tap(find.byKey(const Key('rm-slot-2')));
    await t.pumpAndSettle();
    expect(f.calls, ['time 18:30']);
    expect(
      find.descendant(
        of: find.byKey(const Key('rm-preview-time')),
        matching: find.text('18:30'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('non-preset time shows on the Other time chip', (t) async {
    await _pump(t, base, _o(fake: _Fake(time: (14, 5))));
    expect(
      find.descendant(
        of: find.byKey(const Key('rm-custom')),
        matching: find.text('14:05'),
      ),
      findsOneWidget,
    );
  });

  test('quiet-hour times are moved out of quiet hours', () {
    expect(clampOutOfQuietHours(23, 15), (21, 30));
    expect(clampOutOfQuietHours(5, 0), (7, 0));
    expect(clampOutOfQuietHours(9, 45), (9, 45));
    for (var h = 0; h < 24; h++) {
      expect(
        ReminderPolicy.inQuietHours(clampOutOfQuietHours(h, 0).$1),
        isFalse,
      );
    }
  });

  testWidgets('custom time in quiet hours is clamped and explained', (t) async {
    final f = _Fake();
    await _pump(t, base, _o(fake: f));
    await t.tap(find.byKey(const Key('rm-custom')));
    await t.pumpAndSettle();
    // Switch the picker to text input and type 11:15 PM.
    await t.tap(find.byIcon(Icons.keyboard_outlined));
    await t.pumpAndSettle();
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), '11');
    await t.enterText(fields.at(1), '15');
    await t.tap(find.text('PM'));
    await t.pump();
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(f.calls, ['time 21:30']);
    expect(find.byKey(const Key('rm-clash')), findsOneWidget);
    expect(_texts(t), contains('21:30'));
  });

  testWidgets('topic toggles call the notifier', (t) async {
    final f = _Fake();
    await _pump(t, base, _o(fake: f));
    await t.scrollUntilVisible(
      find.byKey(const Key('rm-rhythm')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('rm-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await t.tap(find.byKey(const Key('rm-goal')));
    await t.tap(find.byKey(const Key('rm-rhythm')));
    await t.pumpAndSettle();
    expect(f.calls, ['goal false', 'rhythm false']);
  });

  testWidgets('copy never guilts or uses streak-loss language (en/ar/fr)', (
    t,
  ) async {
    for (final v in [
      base,
      goldenVariants[1],
      const GoldenVariant('fr', Size(390, 844), locale: Locale('fr')),
    ]) {
      await _pump(t, v, _o(fake: _Fake(on: false)));
      final s = _texts(t);
      expect(ReminderPolicy.containsLossAversion(s), isFalse);
      expect(s.toLowerCase(), isNot(contains('heart')));
    }
  });

  testWidgets('RTL: back arrow points right, day strip stays clockwise', (
    t,
  ) async {
    await _pump(t, goldenVariants[1], _o());
    final back = t.getRect(find.byKey(const Key('rm-back')));
    expect(back.center.dx, greaterThan(390 / 2));
    expect(
      Directionality.of(t.element(find.byKey(const Key('rm-back')))),
      TextDirection.rtl,
    );
    expect(
      Directionality.of(t.element(find.byKey(const Key('rm-strip')))),
      TextDirection.ltr,
    );
    expect(_texts(t), contains('ساعات الهدوء'));
  });

  testWidgets('Arabic keeps times and timezone LTR', (t) async {
    await _pump(t, goldenVariants[1], _o());
    for (final s in ['07:30', 'Africa/Lagos']) {
      final w = t.widget<Text>(find.text(s).first);
      expect(w.textDirection, TextDirection.ltr, reason: s);
    }
  });

  testWidgets('Arabic isolates Latin text (Yoruba sample, brand, times)', (
    t,
  ) async {
    await _pump(t, goldenVariants[1], _o());
    final s = _texts(t);
    expect(s, contains('\u2066Ẹ kú àárọ̀!\u2069'));
    expect(s, contains('\u2066LingAfriq\u2069'));
    expect(s, contains('\u206622:00–07:00\u2069'));
  });

  testWidgets('chips and actions meet 48dp targets', (t) async {
    await _pump(t, base, _o());
    for (final k in ['rm-slot-0', 'rm-custom', 'rm-tz', 'rm-back']) {
      final r = t.getSize(find.byKey(Key(k)));
      expect(r.height, greaterThanOrEqualTo(48), reason: k);
    }
  });

  testWidgets('child sees guardian note, adult does not', (t) async {
    await _pump(t, base, _o(tier: 'child'));
    expect(find.byKey(const Key('rm-child')), findsOneWidget);
  });

  testWidgets('adult sees no guardian note', (t) async {
    await _pump(t, base, _o(tier: 'adult'));
    expect(find.byKey(const Key('rm-child')), findsNothing);
  });
}
