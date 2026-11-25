import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/daily_goal_model.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/screens/goals/daily_goals_screen.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../compliance/golden_kit.dart';

final _today = DateTime.now();

DailyGoal _g(int id, String type, int cur, int target) => DailyGoal(
  id: id,
  type: type,
  target: target,
  current: cur,
  date: _today,
  completed: cur >= target,
  streak: 5,
);

final _mixed = [
  _g(1, 'lessons', 2, 3),
  _g(2, 'quizzes', 2, 2),
  _g(3, 'games', 0, 1),
  _g(4, 'chat_minutes', 4, 10),
];

Language _lang(int id, String name, {bool published = true}) => Language(
  id: id,
  total_score: 0,
  total_count: 10,
  completed: 0,
  name: name,
  background: '',
  Inrtoduction: '',
  is_published: published,
  is_featured: false,
  level_language: 'A1',
);

List<Override> _o({
  List<DailyGoal>? goals,
  int streak = 5,
  Future<void> Function()? refresh,
  Future<List<Language>> Function()? langs,
}) => [
  dailyGoalsViewProvider.overrideWithValue(
    DailyGoalsView(goals: goals ?? _mixed, streak: streak),
  ),
  dailyGoalsRefreshProvider.overrideWithValue(refresh ?? () async {}),
  goalLanguagesProvider.overrideWithValue(
    langs ??
        () async => [
          _lang(1, 'Yoruba'),
          _lang(2, 'Swahili'),
          _lang(3, 'Zulu', published: false),
        ],
  ),
];

Future<void> _pump(WidgetTester t, GoldenVariant v, List<Override> o) async {
  await pumpVariant(t, v, const DailyGoalsScreen(), overrides: o);
  await t.pumpAndSettle();
}

Future<void> _golden(WidgetTester t, String name) => expectLater(
  find.byType(DailyGoalsScreen),
  matchesGoldenFile('goldens/daily_goals_$name.png'),
);

void main() {
  setUpAll(
    () => loadComplianceFonts(
      'test/screens/goals/daily_goals_screen_golden_test.dart',
    ),
  );
  final base = goldenVariants.first;
  final rtl = goldenVariants[1];

  for (final v in [
    ...goldenVariants,
    const GoldenVariant('fr_390', Size(390, 844), locale: Locale('fr')),
    const GoldenVariant('tablet_820', Size(820, 1180)),
  ]) {
    testWidgets('daily goals golden ${v.name}', (t) async {
      await _pump(t, v, _o());
      expectNoLayoutErrors(t);
      await _golden(t, v.name);
    });
  }

  testWidgets('shows streak, ring and per-goal progress', (t) async {
    await _pump(t, base, _o());
    expect(find.text('5-day streak'), findsOneWidget);
    expect(find.text('1 of 4 goals done'), findsOneWidget);
    expect(find.text('2 of 3'), findsOneWidget);
    expect(find.text('4 of 10 min'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget, reason: 'only quizzes done');
    expect(find.byKey(const Key('dg-all-done')), findsNothing);
  });

  testWidgets('zero streak invites a first goal', (t) async {
    await _pump(t, base, _o(streak: 0));
    expect(
      find.text('Finish one goal today to start a streak.'),
      findsOneWidget,
    );
  });

  testWidgets('all done: celebration card', (t) async {
    await _pump(
      t,
      base,
      _o(goals: [_g(1, 'lessons', 3, 3), _g(2, 'games', 1, 1)]),
    );
    expect(find.byKey(const Key('dg-all-done')), findsOneWidget);
    expect(find.text('2 of 2 goals done'), findsOneWidget);
    await _golden(t, 'state_all_done');
  });

  testWidgets('empty: refresh prompt', (t) async {
    var calls = 0;
    await _pump(t, base, _o(goals: [], refresh: () async => calls++));
    expect(find.byKey(const Key('dg-empty')), findsOneWidget);
    expect(find.text('0/0'), findsNothing, reason: 'no empty ring');
    expect(find.byKey(const Key('dg-ring')), findsNothing);
    expect(find.byKey(const Key('dg-ring-empty')), findsOneWidget);
    expect(find.textContaining('goals done'), findsNothing);
    final before = calls;
    await t.tap(find.text('Refresh').last);
    await t.pumpAndSettle();
    expect(calls, before + 1);
    await _golden(t, 'state_empty');
  });

  testWidgets('refresh runs on open and shows syncing meanwhile', (t) async {
    var calls = 0;
    final never = Completer<void>();
    await pumpVariant(
      t,
      base,
      const DailyGoalsScreen(),
      settle: false,
      overrides: _o(
        refresh: () {
          calls++;
          return never.future;
        },
      ),
    );
    await t.pump();
    expect(calls, 1);
    expect(find.byKey(const Key('dg-syncing')), findsOneWidget);
    await _golden(t, 'state_syncing');
    never.complete();
    await t.pumpAndSettle();
    expect(find.byKey(const Key('dg-syncing')), findsNothing);
  });

  testWidgets('sync failure keeps local goals and offers retry', (t) async {
    var calls = 0;
    await _pump(
      t,
      base,
      _o(
        refresh: () async {
          calls++;
          if (calls == 1) throw Exception('offline');
        },
      ),
    );
    expect(find.byKey(const Key('dg-error')), findsOneWidget);
    expect(find.text('2 of 3'), findsOneWidget);
    await _golden(t, 'state_error');
    await t.tap(find.byKey(const Key('dg-retry')));
    await t.pumpAndSettle();
    expect(calls, 2);
    expect(find.byKey(const Key('dg-error')), findsNothing);
  });

  testWidgets('error banner fits 320 at 200% RTL', (t) async {
    await _pump(t, goldenVariants[4], _o(refresh: () async => throw 'x'));
    expectNoLayoutErrors(t);
    expect(find.byKey(const Key('dg-error')), findsOneWidget);
  });

  testWidgets('lessons goal opens a language sheet of published languages', (
    t,
  ) async {
    await _pump(t, base, _o());
    await t.tap(find.byKey(const Key('dg-goal-lessons')));
    await t.pumpAndSettle();
    expect(find.text('Choose a language for lessons'), findsOneWidget);
    expect(find.text('Yoruba'), findsOneWidget);
    expect(find.text('Zulu'), findsNothing);
  });

  testWidgets('language load failure is shown with retry', (t) async {
    var n = 0;
    await _pump(
      t,
      base,
      _o(
        langs: () async {
          n++;
          if (n == 1) throw Exception('down');
          return [_lang(1, 'Yoruba')];
        },
      ),
    );
    await t.tap(find.byKey(const Key('dg-goal-quizzes')));
    await t.pumpAndSettle();
    expect(find.text('Choose a language for the quiz'), findsOneWidget);
    expect(find.byKey(const Key('dg-lang-error')), findsOneWidget);
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle();
    expect(find.text('Yoruba'), findsOneWidget);
  });

  testWidgets('RTL: chevrons mirror and language names are isolated', (
    t,
  ) async {
    await _pump(t, rtl, _o());
    final ctx = t.element(find.byKey(const Key('dg-chevron')).first);
    expect(Directionality.of(ctx), TextDirection.rtl);
    expect(Icons.chevron_right_rounded.matchTextDirection, isTrue);
    await t.tap(find.byKey(const Key('dg-goal-lessons')));
    await t.pumpAndSettle();
    expect(find.text('\u2068Yoruba\u2069'), findsOneWidget);
  });

  testWidgets('Arabic and French copy is localized', (t) async {
    await _pump(t, rtl, _o());
    expect(find.text('الأهداف اليومية'), findsOneWidget);
    await _pump(
      t,
      const GoldenVariant('fr', Size(390, 844), locale: Locale('fr')),
      _o(),
    );
    expect(find.text('Objectifs du jour'), findsOneWidget);
  });

  testWidgets('goal cards are labelled buttons at least 48dp tall', (t) async {
    await _pump(t, base, _o());
    for (final k in ['lessons', 'quizzes', 'games', 'chat_minutes']) {
      final f = find.byKey(Key('dg-goal-$k'));
      expect(t.getSize(f).height, greaterThanOrEqualTo(48));
    }
    expect(
      find.bySemanticsLabel(RegExp(r'^Complete lessons, 2 of 3, Start$')),
      findsOneWidget,
    );
  });

  testWidgets('no hearts, paywall or personal data on screen', (t) async {
    await _pump(t, base, _o());
    final all = t
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? '')
        .join(' ')
        .toLowerCase();
    for (final w in ['heart', 'premium', 'upgrade', 'subscribe', '@']) {
      expect(all.contains(w), isFalse, reason: w);
    }
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('navy header with a back arrow that pops', (t) async {
    await pumpVariant(
      t,
      base,
      Scaffold(
        body: Builder(
          builder: (c) => TextButton(
            onPressed: () => Navigator.of(
              c,
            ).push(MaterialPageRoute(builder: (_) => const DailyGoalsScreen())),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: _o(),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    final bar = t.widget<AppBar>(find.byType(AppBar));
    expect(bar.backgroundColor, const Color(0xFF2E3A87));
    expect(bar.foregroundColor, Colors.white);
    await t.tap(find.byKey(const Key('dg-back')));
    await t.pumpAndSettle();
    expect(find.byType(DailyGoalsScreen), findsNothing);
  });

  testWidgets('French and Arabic counts agree in number', (t) async {
    await _pump(
      t,
      const GoldenVariant('fr', Size(390, 844), locale: Locale('fr')),
      _o(streak: 1),
    );
    expect(find.text('Série de 1 jour'), findsOneWidget);
    await _pump(t, rtl, _o(streak: 2));
    expect(find.text('سلسلة يومين'), findsOneWidget);
  });
}
