import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/games/game_catalog.dart';
import 'package:lingafriq/screens/games/games_screen_material3.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../compliance/golden_kit.dart';

List<Override> _o({
  Future<List<GameCatalogEntry>> Function()? remote,
  String lang = 'yoruba',
}) => [
  gamesRemoteCatalogProvider.overrideWith(
    (ref) => (remote ?? () async => GameCatalog.entries)(),
  ),
  gamesHubLanguageProvider.overrideWith((ref) async => lang),
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
    const GamesScreenMaterial3(),
    overrides: o,
    settle: settle,
  );
  if (!settle) await t.pump(const Duration(milliseconds: 50));
}

String _texts(WidgetTester t) => t
    .widgetList<Text>(find.byType(Text))
    .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
    .join('\n');

final _core = GameCatalog.entries
    .where((e) => e.section == GameCatalogSection.core)
    .toList();

void main() {
  setUpAll(
    () => loadComplianceFonts('test/screens/games/games_hub_golden_test.dart'),
  );
  final base = goldenVariants.first;

  for (final v in [
    ...goldenVariants,
    const GoldenVariant('fr_390', Size(390, 844), locale: Locale('fr')),
    const GoldenVariant('tablet_820', Size(820, 1180)),
  ]) {
    testWidgets('games hub golden ${v.name}', (t) async {
      await _pump(t, v, _o());
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(GamesScreenMaterial3),
        matchesGoldenFile('goldens/games_hub_${v.name}.png'),
      );
    });
  }

  testWidgets('loading: bundled games show at once with a syncing hint', (
    t,
  ) async {
    await _pump(
      t,
      base,
      _o(remote: () => Completer<List<GameCatalogEntry>>().future),
      settle: false,
    );
    expect(find.byKey(const Key('gm-syncing')), findsOneWidget);
    expect(find.byKey(const Key('gm-featured')), findsOneWidget);
    await expectLater(
      find.byType(GamesScreenMaterial3),
      matchesGoldenFile('goldens/games_hub_state_loading.png'),
    );
  });

  testWidgets('offline: bundled catalog plus an honest note', (t) async {
    await _pump(t, base, _o(remote: () async => throw StateError('offline')));
    expect(find.byKey(const Key('gm-offline')), findsOneWidget);
    expect(find.byKey(const Key('gm-syncing')), findsNothing);
    expect(find.byKey(const Key('gm-featured')), findsOneWidget);
    await expectLater(
      find.byType(GamesScreenMaterial3),
      matchesGoldenFile('goldens/games_hub_state_offline.png'),
    );
  });

  testWidgets('empty section shows empty state and recovers', (t) async {
    await _pump(t, base, _o(remote: () async => _core));
    await t.tap(find.byKey(const Key('gm-cultural')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('gm-empty')), findsOneWidget);
    expect(find.byKey(const Key('gm-featured')), findsNothing);
    await expectLater(
      find.byType(GamesScreenMaterial3),
      matchesGoldenFile('goldens/games_hub_state_empty.png'),
    );
  });

  testWidgets('server catalog replaces the bundled one', (t) async {
    await _pump(t, base, _o(remote: () async => _core.take(3).toList()));
    expect(_texts(t), contains('3 games'));
    expect(find.text(_core.first.name), findsOneWidget);
  });

  testWidgets('category filter narrows the list and All restores it', (
    t,
  ) async {
    await _pump(t, base, _o());
    final all = _core.length;
    expect(_texts(t), contains('$all games'));
    await t.tap(find.byKey(const Key('gm-cat-Grammar')));
    await t.pumpAndSettle();
    final grammar = _core.where((g) => g.category == 'Grammar').length;
    expect(grammar, greaterThan(0));
    expect(_texts(t), contains(grammar == 1 ? '1 game' : '$grammar games'));
    await t.tap(find.byKey(const Key('gm-cat-all')));
    await t.pumpAndSettle();
    expect(_texts(t), contains('$all games'));
  });

  testWidgets('cultural section lists traditional games', (t) async {
    await _pump(t, base, _o());
    await t.tap(find.byKey(const Key('gm-cultural')));
    await t.pumpAndSettle();
    final n = GameCatalog.entries
        .where((e) => e.section == GameCatalogSection.cultural)
        .length;
    expect(_texts(t), contains('$n games'));
    expect(find.byKey(const Key('gm-cat-Traditional')), findsOneWidget);
  });

  testWidgets('saved language is selected; tapping another switches copy', (
    t,
  ) async {
    await _pump(t, base, _o(lang: 'hausa'));
    expect(_texts(t), contains('Every game practises Hausa.'));
    await t.tap(find.byKey(const Key('gm-lang-yoruba')));
    await t.pumpAndSettle();
    expect(_texts(t), contains('Every game practises Yoruba.'));
  });

  testWidgets('no hearts, lives or paywall locks on the hub', (t) async {
    await _pump(t, base, _o());
    final s = _texts(t).toLowerCase();
    for (final w in ['heart', 'lives', 'premium', 'unlock', 'plus']) {
      expect(s, isNot(contains(w)), reason: w);
    }
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('tiles announce name, category and description', (t) async {
    await _pump(t, base, _o());
    final g = _core.first;
    expect(
      find.bySemanticsLabel('${g.name}, Vocabulary. ${g.description}'),
      findsOneWidget,
    );
  });

  testWidgets('RTL: back arrow on the right, catalog text isolated', (t) async {
    await _pump(t, goldenVariants[1], _o());
    expect(
      t.getRect(find.byKey(const Key('gm-back'))).center.dx,
      greaterThan(195),
    );
    final s = _texts(t);
    expect(s, contains('\u2066${_core.first.name}\u2069'));
    expect(s, contains('\u2066Yoruba\u2069'));
    expect(s, contains('الألعاب'));
  });

  testWidgets('French chrome', (t) async {
    await _pump(
      t,
      const GoldenVariant('fr', Size(390, 844), locale: Locale('fr')),
      _o(),
    );
    final s = _texts(t);
    expect(s, contains('Jeux'));
    expect(s, contains('Le choix du jour'.toUpperCase()));
  });

  testWidgets('large text: one column, no layout errors', (t) async {
    await _pump(t, goldenVariants[2], _o());
    expectNoLayoutErrors(t);
    await t.scrollUntilVisible(
      find.byKey(Key('gm-game-${_core[2].type.name}')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('gm-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final a = t.getRect(find.byKey(Key('gm-game-${_core[1].type.name}')));
    final b = t.getRect(find.byKey(Key('gm-game-${_core[2].type.name}')));
    expect(b.top, greaterThan(a.bottom - 1));
  });

  testWidgets('tablet: four columns', (t) async {
    await _pump(t, const GoldenVariant('tab', Size(820, 1180)), _o());
    final tops = [
      for (var i = 1; i <= 4; i++)
        t.getRect(find.byKey(Key('gm-game-${_core[i].type.name}'))).top,
    ];
    expect(tops.toSet().length, 1);
  });

  testWidgets('chips meet 48dp targets', (t) async {
    await _pump(t, base, _o());
    for (final k in ['gm-lang-yoruba', 'gm-cat-all', 'gm-back']) {
      expect(
        t.getSize(find.byKey(Key(k))).height,
        greaterThanOrEqualTo(48),
        reason: k,
      );
    }
  });
}
