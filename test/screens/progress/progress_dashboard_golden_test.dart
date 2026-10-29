import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/progress_metrics_model.dart';
import 'package:lingafriq/screens/progress/progress_dashboard_data.dart';
import 'package:lingafriq/screens/progress/progress_dashboard_screen.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../compliance/golden_kit.dart';

final _today = DateTime(2026, 10, 29, 18);

ProgressMetrics _m(double minutes, DateTime at, {bool empty = false}) =>
    ProgressMetrics(
      wordsLearned: empty ? 0 : 214,
      listeningHours: empty ? 0 : 3.5,
      speakingHours: empty ? 0 : 1.25,
      readingWords: 0,
      writtenWords: 0,
      knownWords: empty ? 0 : 156,
      timeSpentMinutes: minutes,
      lastUpdated: at,
      timeByActivity: empty
          ? const {}
          : const {'lessons': 4.0, 'games': 1.5, 'chat': 0.75, 'quizzes': 1.0},
    );

/// Cumulative daily rows: day offset -> minutes that day.
ProgressSnapshot _snap({Map<int, int>? perDay, bool empty = false}) {
  final days =
      perDay ?? {13: 10, 11: 20, 9: 15, 6: 12, 5: 25, 3: 8, 1: 30, 0: 18};
  final rows = <ProgressMetrics>[];
  var total = 0.0;
  for (final off in days.keys.toList()..sort((a, b) => b.compareTo(a))) {
    total += days[off]!;
    rows.add(_m(total, _today.subtract(Duration(days: off)), empty: empty));
  }
  return ProgressSnapshot(
    metrics: _m(total, _today, empty: empty),
    history: rows,
    today: _today,
  );
}

List<Override> _o({
  FutureOr<ProgressSnapshot> Function()? snap,
  bool online = true,
  String? tier,
}) => [
  progressSnapshotProvider.overrideWith((ref) async => (snap ?? _snap).call()),
  progressOnlineProvider.overrideWith((ref) async => online),
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
  t.view.devicePixelRatio = 1;
  await pumpVariant(t, v, const ProgressDashboardScreen(), overrides: o);
  settle
      ? await t.pumpAndSettle()
      : await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(
    () => loadComplianceFonts(
      'test/screens/progress/progress_dashboard_golden_test.dart',
    ),
  );

  group('ProgressSnapshot', () {
    test('per-day minutes come from cumulative rows', () {
      final s = _snap();
      expect(s.dailyMinutes.length, 28);
      expect(s.dailyMinutes.last, 18);
      expect(s.thisWeek, [0, 12, 25, 0, 8, 0, 30, 18].sublist(1));
      expect(s.thisWeekTotal, 93);
      expect(s.lastWeekTotal, 45);
      expect(s.activeDays, 8);
      expect(s.isEmpty, isFalse);
    });

    test('a counter reset never yields negative minutes', () {
      final s = ProgressSnapshot(
        metrics: _m(5, _today),
        history: [
          _m(50, _today.subtract(const Duration(days: 1))),
          _m(5, _today),
        ],
        today: _today,
      );
      expect(s.dailyMinutes.last, 0);
      expect(s.dailyMinutes[26], 50);
    });

    test('activities sort largest first and drop zeros', () {
      expect(_snap().activities.map((e) => e.key), [
        'lessons',
        'games',
        'quizzes',
        'chat',
      ]);
    });

    test('no activity at all is empty', () {
      expect(_snap(perDay: {}, empty: true).isEmpty, isTrue);
    });
  });

  for (final v in [
    ...goldenVariants,
    const GoldenVariant('fr_390', Size(390, 844), locale: Locale('fr')),
  ]) {
    testWidgets('progress golden ${v.name}', (t) async {
      await _pump(t, v, _o());
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(ProgressDashboardScreen),
        matchesGoldenFile('goldens/progress_${v.name}.png'),
      );
    });
  }

  final base = goldenVariants.first;
  for (final (name, o, settle) in [
    ('loading', _o(snap: () => Completer<ProgressSnapshot>().future), false),
    ('error', _o(snap: () => throw Exception('disk')), true),
    ('offline', _o(online: false), true),
    ('child', _o(tier: 'child'), true),
    ('empty', _o(snap: () => _snap(perDay: {}, empty: true)), true),
  ]) {
    testWidgets('progress state golden $name', (t) async {
      await _pump(t, base, o, settle: settle);
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(ProgressDashboardScreen),
        matchesGoldenFile('goldens/progress_state_$name.png'),
      );
    });
  }

  testWidgets('week hero shows total and trend vs last week', (t) async {
    await _pump(t, base, _o());
    expect(find.text('93 min'), findsOneWidget);
    expect(find.text('48 min more than last week'), findsOneWidget);
    expect(find.text('8 active days'), findsOneWidget);
    expect(find.text('214'), findsOneWidget);
    expect(find.text('3.5 h'), findsOneWidget);
  });

  testWidgets('activity rows use friendly names', (t) async {
    await _pump(t, base, _o());
    await t.scrollUntilVisible(find.text('Chat practice'), 100);
    expect(find.text('Lessons'), findsOneWidget);
    expect(find.text('Chat practice'), findsOneWidget);
  });

  testWidgets('empty: encouragement card, no week hero', (t) async {
    await _pump(t, base, _o(snap: () => _snap(perDay: {}, empty: true)));
    expect(find.byKey(const Key('pg-empty')), findsOneWidget);
    expect(find.byKey(const Key('pg-week')), findsNothing);
    expect(find.text('No active days yet'), findsOneWidget);
  });

  testWidgets('offline note only when offline', (t) async {
    await _pump(t, base, _o(online: false));
    expect(find.byKey(const Key('pg-offline')), findsOneWidget);
  });

  testWidgets('online: no offline note, offline-days reminder shown', (
    t,
  ) async {
    await _pump(t, base, _o());
    expect(find.byKey(const Key('pg-offline')), findsNothing);
    expect(find.text('Offline days count too.'), findsOneWidget);
  });

  testWidgets('child and teen see the private note', (t) async {
    for (final tier in ['child', 'teen']) {
      await t.pumpWidget(const SizedBox());
      await _pump(t, base, _o(tier: tier));
      expect(find.byKey(const Key('pg-private')), findsOneWidget, reason: tier);
    }
  });

  testWidgets('error retry reloads', (t) async {
    var calls = 0;
    await _pump(
      t,
      base,
      _o(
        snap: () {
          calls++;
          throw Exception('disk');
        },
      ),
    );
    expect(find.byKey(const Key('pg-error')), findsOneWidget);
    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('loading is announced', (t) async {
    final h = t.ensureSemantics();
    await _pump(
      t,
      base,
      _o(snap: () => Completer<ProgressSnapshot>().future),
      settle: false,
    );
    expect(find.bySemanticsLabel('Loading your progress…'), findsOneWidget);
    h.dispose();
  });

  testWidgets('bars and calendar have spoken summaries', (t) async {
    final h = t.ensureSemantics();
    await _pump(t, base, _o());
    expect(find.bySemanticsLabel('Thu: 18 minutes'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Activity calendar: 8 active days'),
      findsOneWidget,
    );
    h.dispose();
  });

  testWidgets('Arabic + a11y guidelines', (t) async {
    final h = t.ensureSemantics();
    await _pump(t, goldenVariants[1], _o());
    expect(find.text('هذا الأسبوع'), findsOneWidget);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(textContrastGuideline));
    h.dispose();
  });
}
