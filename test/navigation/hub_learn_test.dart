import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/navigation/hub_learn.dart';
import 'package:lingafriq/screens/learning/learn_hub_pages.dart';

Future<void> _loadFont(String family, String asset) async {
  final Future<ByteData> data = File(
    asset,
  ).readAsBytes().then(ByteData.sublistView);
  final FontLoader loader = FontLoader(family)..addFont(data);
  await loader.load();
}

Widget _host(Widget child, {bool reduced = false, double scale = 1}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) {
      final MediaQueryData data = MediaQuery.of(context);
      return MediaQuery(
        data: data.copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(scale),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}

const List<String> _sitemapRoutes = <String>[
  LearnRoutes.hub,
  LearnRoutes.path,
  LearnRoutes.lesson,
  LearnRoutes.recap,
  LearnRoutes.words,
  LearnRoutes.reviewRush,
  LearnRoutes.grammar,
  LearnRoutes.phraseDna,
  LearnRoutes.listening,
  LearnRoutes.writing,
  LearnRoutes.toneGym,
  LearnRoutes.culture,
  LearnRoutes.magazine,
  LearnRoutes.heritage,
  LearnRoutes.history,
  LearnRoutes.mannerisms,
  LearnRoutes.culturalHub,
  LearnRoutes.passport,
  LearnRoutes.downloads,
];

Future<void> _tapRow(WidgetTester tester, LearnPlace place) async {
  final Finder row = find.byKey(LearnHubKeys.row(place), skipOffstage: false);
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Future<void> _backToRoot(WidgetTester tester, AppLocalizations l10n) async {
  final Finder back = find.text(l10n.hubLearnBack);
  await tester.ensureVisible(back.first);
  await tester.tap(back.first);
  await tester.pumpAndSettle();
  expect(find.byKey(LearnHubKeys.route(LearnRoutes.hub)), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
  });

  test('route table registers every Learn sitemap item', () {
    final Set<String> routes = learnDestinations
        .map((LearnDestination destination) => destination.route)
        .toSet();
    expect(routes.length, learnDestinations.length);
    expect(routes, containsAll(_sitemapRoutes));
    for (final String route in _sitemapRoutes) {
      expect(learnRouteIsRegistered(route), isTrue);
      expect(learnTapDepth(learnPlaceFor(route)!), lessThanOrEqualTo(2));
    }
    expect(learnRouteIsRegistered('/learn/made-up'), isFalse);
  });

  test('path groups real units by CEFR and adds none', () {
    final List<LearnUnit> units = <LearnUnit>[
      const LearnUnit(id: 'b', title: 'Market', cefr: 'B1'),
      const LearnUnit(id: 'a', title: 'Greetings', cefr: 'a1'),
      const LearnUnit(
        id: 'a2',
        title: 'Family',
        cefr: 'A1',
        lessons: <LearnLesson>[LearnLesson(id: 'l1', title: 'Hello')],
      ),
      const LearnUnit(id: 'x', title: 'Town', cefr: ''),
      const LearnUnit(id: 'z', title: 'Custom', cefr: 'Heritage'),
    ];

    final List<LearnCefrGroup> groups = groupLearnUnitsByCefr(units);

    expect(groups.map((LearnCefrGroup group) => group.level), <String>[
      'A1',
      'B1',
      'Heritage',
      '',
    ]);
    expect(groups[0].units.map((LearnUnit unit) => unit.id), <String>[
      'a',
      'a2',
    ]);
    expect(
      groups.fold<int>(
        0,
        (int count, LearnCefrGroup group) => count + group.units.length,
      ),
      units.length,
    );
    expect(groups.any((LearnCefrGroup group) => group.level == 'A2'), isFalse);
    expect(groups.any((LearnCefrGroup group) => group.level == 'C2'), isFalse);
  });

  testWidgets('every sitemap item opens in two taps or fewer', (
    WidgetTester tester,
  ) async {
    final AppLocalizations l10n = l10nEn();
    const LearnLesson lesson = LearnLesson(id: 'l1', title: 'Hello');
    const List<LearnUnit> units = <LearnUnit>[
      LearnUnit(
        id: 'a',
        title: 'Greetings',
        cefr: 'A1',
        lessons: <LearnLesson>[lesson],
      ),
    ];
    await tester.pumpWidget(_host(const LearnHub(units: units), reduced: true));
    await tester.pumpAndSettle();
    expect(find.byKey(LearnHubKeys.route(LearnRoutes.hub)), findsOneWidget);

    for (final LearnDestination destination in learnRootDestinations()) {
      expect(learnTapDepth(destination.place), 1);
      await _tapRow(tester, destination.place);
      expect(find.byKey(LearnHubKeys.route(destination.route)), findsOneWidget);
      await _backToRoot(tester, l10n);
    }

    expect(learnTapDepth(LearnPlace.phraseDna), 2);
    await _tapRow(tester, LearnPlace.grammar);
    await _tapRow(tester, LearnPlace.phraseDna);
    expect(
      find.byKey(LearnHubKeys.route(LearnRoutes.phraseDna)),
      findsOneWidget,
    );
    expect(find.byType(LearnNotAvailablePage), findsOneWidget);
    await _backToRoot(tester, l10n);
    expect(find.byKey(LearnHubKeys.row(LearnPlace.phraseDna)), findsNothing);

    expect(learnTapDepth(LearnPlace.lesson), 2);
    await _tapRow(tester, LearnPlace.path);
    final Finder lessonRow = find.byKey(
      LearnHubKeys.lesson(lesson.id),
      skipOffstage: false,
    );
    await tester.ensureVisible(lessonRow);
    await tester.pumpAndSettle();
    await tester.tap(lessonRow);
    await tester.pumpAndSettle();
    expect(find.byKey(LearnHubKeys.route(LearnRoutes.lesson)), findsOneWidget);
    await _backToRoot(tester, l10n);

    for (final LearnDestination destination in learnStaticChildren(
      LearnPlace.culture,
    )) {
      expect(learnTapDepth(destination.place), 2);
      await _tapRow(tester, LearnPlace.culture);
      await _tapRow(tester, destination.place);
      expect(find.byKey(LearnHubKeys.route(destination.route)), findsOneWidget);
      expect(find.byType(LearnNotAvailablePage), findsOneWidget);
      await _backToRoot(tester, l10n);
    }
  });

  testWidgets('an unbuilt destination shows not-available and no fake data', (
    WidgetTester tester,
  ) async {
    final AppLocalizations l10n = l10nEn();
    const LearnUnit unit = LearnUnit(
      id: 'a',
      title: 'Greetings',
      cefr: 'A1',
      lessons: <LearnLesson>[LearnLesson(id: 'l1', title: 'Hello')],
    );
    await tester.pumpWidget(_host(const LearnHub(units: <LearnUnit>[unit])));
    await tester.pumpAndSettle();
    await _tapRow(tester, LearnPlace.recap);

    final LearnNotAvailablePage page = tester.widget<LearnNotAvailablePage>(
      find.byType(LearnNotAvailablePage),
    );
    expect(page.place, LearnPlace.recap);
    final Set<String?> texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text widget) => widget.data)
        .toSet();
    expect(texts, <String?>{
      l10n.hubLearnBack,
      l10n.shellNotAvailableYet,
      l10n.hubLearnNotAvailableWhat,
      l10n.hubLearnNotAvailableWhy,
      l10n.hubLearnNotAvailableNext,
    });
    expect(find.text(unit.title), findsNothing);
    expect(find.text('Hello'), findsNothing);
    expect(find.text('Unit 1'), findsNothing);
  });

  testWidgets('an empty hub points to a next step', (
    WidgetTester tester,
  ) async {
    final AppLocalizations l10n = l10nEn();
    await tester.pumpWidget(_host(const LearnHub()));
    await tester.pumpAndSettle();

    expect(find.byKey(LearnHubKeys.empty), findsOneWidget);
    expect(find.text(l10n.hubLearnEmptyNext), findsOneWidget);
    expect(find.text(l10n.hubLearnOpenPath), findsOneWidget);
    expect(find.text('Unit 1'), findsNothing);

    await tester.tap(find.text(l10n.hubLearnOpenPath));
    await tester.pumpAndSettle();
    expect(find.byKey(LearnHubKeys.route(LearnRoutes.path)), findsOneWidget);
    expect(find.text(l10n.hubLearnPathEmptyNext), findsOneWidget);
    expect(find.byKey(LearnHubKeys.unit('invented')), findsNothing);
  });

  testWidgets('the path groups units by CEFR level', (
    WidgetTester tester,
  ) async {
    final AppLocalizations l10n = l10nEn();
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const List<LearnUnit> units = <LearnUnit>[
      LearnUnit(id: 'b', title: 'Market', cefr: 'B1'),
      LearnUnit(id: 'a', title: 'Greetings', cefr: 'A1'),
      LearnUnit(id: 'a2', title: 'Family', cefr: 'A1'),
    ];
    await tester.pumpWidget(_host(const LearnHub(units: units)));
    await tester.pumpAndSettle();
    expect(find.byType(LingEmptyState), findsNothing);

    await _tapRow(tester, LearnPlace.path);
    expect(find.text(l10n.hubLearnLevel('A1')), findsOneWidget);
    expect(find.text(l10n.hubLearnLevel('B1')), findsOneWidget);
    expect(find.text(l10n.hubLearnLevel('A2')), findsNothing);
    expect(find.text('Greetings'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);

    final double a1 = tester
        .getTopLeft(find.byKey(LearnHubKeys.level('A1')))
        .dy;
    final double family = tester
        .getTopLeft(find.byKey(LearnHubKeys.unit('a2')))
        .dy;
    final double b1 = tester
        .getTopLeft(find.byKey(LearnHubKeys.level('B1')))
        .dy;
    expect(a1, lessThan(family));
    expect(family, lessThan(b1));
  });

  testWidgets('an error hub does not render path units', (
    WidgetTester tester,
  ) async {
    const List<LearnUnit> units = <LearnUnit>[
      LearnUnit(id: 'a', title: 'Greetings', cefr: 'A1'),
    ];
    await tester.pumpWidget(
      _host(const LearnHub(units: units, status: LearnHubStatus.error)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.text('Greetings'), findsNothing);
    expect(find.byKey(LearnHubKeys.row(LearnPlace.path)), findsNothing);
  });

  testWidgets('an offline hub does not render path units', (
    WidgetTester tester,
  ) async {
    const List<LearnUnit> units = <LearnUnit>[
      LearnUnit(id: 'a', title: 'Greetings', cefr: 'A1'),
    ];
    await tester.pumpWidget(
      _host(const LearnHub(units: units, status: LearnHubStatus.offline)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LingOfflineState), findsOneWidget);
    expect(find.text('Greetings'), findsNothing);
    expect(find.byKey(LearnHubKeys.row(LearnPlace.path)), findsNothing);
  });

  testWidgets('labels stay visible at 200 percent text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const LearnHub(), scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final Finder path = find.byKey(
      LearnHubKeys.row(LearnPlace.path),
      skipOffstage: false,
    );
    await tester.ensureVisible(path);
    await tester.pumpAndSettle();
    final Size size = tester.getSize(path);
    expect(size.height, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
    expect(size.width, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
  });
}
