import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/screens/language/search_languages_page.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../compliance/golden_kit.dart';

Language _lang(int id, String name, int score, {bool live = true}) => Language(
  id: id,
  total_score: score,
  total_count: 10,
  completed: 0,
  name: name,
  background: '',
  Inrtoduction: '',
  is_published: live,
  is_featured: false,
  level_language: 'beginner',
);

final _catalog = [
  _lang(1, 'Yoruba', 42),
  _lang(2, 'Swahili', 0),
  _lang(3, 'Zulu', 0),
  _lang(4, 'Hausa', 15),
  _lang(5, 'Igbo', 0),
  _lang(6, 'Amharic', 0, live: false),
];

LanguageResponse _resp(List<Language> l) =>
    LanguageResponse(count: l.length, next: null, previous: null, results: l);

List<Override> _o({
  Future<LanguageResponse> Function()? load,
  bool online = true,
  String? tier,
}) => [
  languagesProvider.overrideWith(
    (ref) => load == null ? Future.value(_resp(_catalog)) : load(),
  ),
  languageSearchOnlineProvider.overrideWith((ref) async => online),
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
}) =>
    pumpVariant(
      t,
      v,
      const SearchLanguagesPage(),
      overrides: o,
      settle: settle,
    ).then((_) async {
      if (!settle) await t.pump(const Duration(milliseconds: 50));
    });

void main() {
  setUpAll(
    () => loadComplianceFonts(
      'test/screens/language/search_languages_page_golden_test.dart',
    ),
  );
  final base = goldenVariants.first;

  for (final v in [
    ...goldenVariants,
    const GoldenVariant('fr_390', Size(390, 844), locale: Locale('fr')),
  ]) {
    testWidgets('language search golden ${v.name}', (t) async {
      await _pump(t, v, _o());
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(SearchLanguagesPage),
        matchesGoldenFile('goldens/language_search_${v.name}.png'),
      );
    });
  }

  for (final (name, o, settle) in [
    ('loading', _o(load: () => Completer<LanguageResponse>().future), false),
    ('error', _o(load: () => Future.error(Exception('500'))), true),
    (
      'offline',
      _o(load: () => Future.error(Exception('net')), online: false),
      true,
    ),
    ('empty', _o(load: () => Future.value(_resp(const []))), true),
    ('child', _o(tier: 'child'), true),
  ]) {
    testWidgets('language search state golden $name', (t) async {
      await _pump(t, base, o, settle: settle);
      expectNoLayoutErrors(t);
      await expectLater(
        find.byType(SearchLanguagesPage),
        matchesGoldenFile('goldens/language_search_state_$name.png'),
      );
    });
  }

  testWidgets('groups started courses under Continue learning', (t) async {
    await _pump(t, base, _o());
    expect(find.byKey(const Key('search-section-continue')), findsOneWidget);
    final cont = t.getTopLeft(find.byKey(const Key('search-section-continue')));
    final all = t.getTopLeft(find.byKey(const Key('search-section-all')));
    final yoruba = t.getTopLeft(find.byKey(const Key('search-row-1')));
    final swahili = t.getTopLeft(find.byKey(const Key('search-row-2')));
    expect(cont.dy < yoruba.dy && yoruba.dy < all.dy, isTrue);
    expect(swahili.dy, greaterThan(all.dy));
    expect(find.text('42% done'), findsOneWidget);
  });

  testWidgets('search filters, no-match shows clear, clear restores', (
    t,
  ) async {
    await _pump(t, base, _o());
    await t.enterText(find.byKey(const Key('search-field')), 'zu');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-row-3')), findsOneWidget);
    expect(find.byKey(const Key('search-row-1')), findsNothing);
    await t.enterText(find.byKey(const Key('search-field')), 'klingon');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-empty')), findsOneWidget);
    await t.tap(find.byKey(const Key('search-clear')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-row-1')), findsOneWidget);
  });

  testWidgets('no-match golden', (t) async {
    await _pump(t, base, _o());
    await t.enterText(find.byKey(const Key('search-field')), 'klingon');
    await t.pumpAndSettle();
    await expectLater(
      find.byType(SearchLanguagesPage),
      matchesGoldenFile('goldens/language_search_state_no_match.png'),
    );
  });

  testWidgets('unpublished course is shown but not tappable', (t) async {
    await _pump(t, base, _o());
    final row = find.byKey(const Key('search-row-6'));
    await t.ensureVisible(row);
    await t.pumpAndSettle();
    expect(t.widget<InkWell>(row).onTap, isNull);
    expect(find.text('Coming soon'), findsOneWidget);
    expect(
      t.widget<InkWell>(find.byKey(const Key('search-row-2'))).onTap,
      isNotNull,
    );
  });

  testWidgets('error retries and recovers', (t) async {
    var fail = true;
    await _pump(
      t,
      base,
      _o(
        load: () => fail
            ? Future.error(Exception('500'))
            : Future.value(_resp(_catalog)),
      ),
    );
    expect(find.byKey(const Key('search-error')), findsOneWidget);
    fail = false;
    await t.tap(find.byKey(const Key('search-retry')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-row-1')), findsOneWidget);
  });

  testWidgets('offline shows offline copy, child gets child question', (
    t,
  ) async {
    await _pump(
      t,
      base,
      _o(load: () => Future.error(Exception('net')), online: false),
    );
    expect(find.byKey(const Key('search-offline')), findsOneWidget);
    expect(find.text("You're offline"), findsOneWidget);
  });

  testWidgets('child sees the child question', (t) async {
    await _pump(t, base, _o(tier: 'child'));
    expect(
      find.text('Which language shall we play with today?'),
      findsOneWidget,
    );
  });

  testWidgets('back and rows meet 48dp targets', (t) async {
    await _pump(t, goldenVariants[3], _o());
    expect(
      t.getSize(find.byKey(const Key('search-back'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      t.getSize(find.byKey(const Key('search-row-1'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('arabic and french strings are localised', (t) async {
    await _pump(t, goldenVariants[1], _o());
    expect(find.text('كل اللغات'), findsOneWidget);
    await _pump(
      t,
      const GoldenVariant('fr', Size(390, 844), locale: Locale('fr')),
      _o(),
    );
    expect(find.text('Toutes les langues'), findsOneWidget);
  });
}
