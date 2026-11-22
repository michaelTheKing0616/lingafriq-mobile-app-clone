import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/a11y/text_scale.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/navigation/app_shell.dart';
import 'package:lingafriq/navigation/tab_routes.dart';

Future<void> _loadFont(String family, String asset) async {
  final Future<ByteData> data = File(
    asset,
  ).readAsBytes().then(ByteData.sublistView);
  final FontLoader loader = FontLoader(family)..addFont(data);
  await loader.load();
}

Widget _host(Widget child, {bool reduced = false}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) {
      final MediaQueryData data = MediaQuery.of(context);
      return MediaQuery(
        data: data.copyWith(disableAnimations: reduced),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
  });

  testWidgets('five tabs show and Word Card is not a tab', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const AppShell()));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Speak'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Village'), findsOneWidget);
    expect(find.text('Word Card'), findsNothing);
    expect(find.bySemanticsLabel('Word Card'), findsNothing);

    for (final ShellTab tab in ShellTab.values) {
      expect(find.byKey(AppShell.tabKey(tab)), findsOneWidget);
    }
    expect(
      tester.getSemantics(find.byKey(AppShell.toolKey(ShellTool.me))).label,
      'Me',
    );
    expect(
      tester.getSemantics(find.byKey(AppShell.toolKey(ShellTool.search))).label,
      'Search',
    );
    expect(
      tester.getSemantics(find.byKey(AppShell.toolKey(ShellTool.lens))).label,
      'Lens',
    );
    await tester.tap(find.byKey(AppShell.toolKey(ShellTool.me)));
    await tester.pumpAndSettle();
    expect(find.text('Me'), findsOneWidget);
    expect(find.byKey(AppShell.tabKey(ShellTab.play)), findsOneWidget);
    expect(find.text('Word Card'), findsNothing);

    for (final ShellTool tool in ShellTool.values) {
      final Size size = tester.getSize(find.byKey(AppShell.toolKey(tool)));
      expect(size.width, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
      expect(size.height, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
    }
    handle.dispose();
  });

  testWidgets('tab scroll and stack survive a tab change', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const AppShell()));
    await tester.pumpAndSettle();
    final AppShellState state = tester.state<AppShellState>(
      find.byType(AppShell),
    );
    final NavigatorState todayNav = state.navigatorOf(ShellTab.today);
    final int builds = state.rootBuilds(ShellTab.today);
    final ScrollController scroll = state.scrollOf(ShellTab.today);

    expect(scroll.position.maxScrollExtent, greaterThan(200));
    await tester.tap(find.text('Open Today'));
    await tester.pumpAndSettle();
    expect(state.routeNameOf(ShellTab.today), ShellRoutes.section);
    expect(find.text('Today is open'), findsOneWidget);
    todayNav.pop();
    await tester.pumpAndSettle();
    scroll.jumpTo(200);
    await tester.pump();
    todayNav.pushNamed(ShellRoutes.section);
    await tester.pumpAndSettle();
    expect(state.routeNameOf(ShellTab.today), ShellRoutes.section);

    await tester.tap(find.byKey(AppShell.tabKey(ShellTab.learn)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppShell.tabKey(ShellTab.today)));
    await tester.pumpAndSettle();

    expect(identical(state.navigatorOf(ShellTab.today), todayNav), isTrue);
    expect(state.rootBuilds(ShellTab.today), builds);
    expect(state.scrollOf(ShellTab.today).position.pixels, 200);
    expect(state.routeNameOf(ShellTab.today), ShellRoutes.section);
    expect(find.text('Today is open'), findsOneWidget);
  });

  testWidgets('a deep link opens the matching tab', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const AppShell(initialLink: 'https://lingafriq.app/speak')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.byKey(AppShell.tabKey(ShellTab.speak)))
          .hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );

    final AppShellState state = tester.state<AppShellState>(
      find.byType(AppShell),
    );
    state.openLink('/play');
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.byKey(AppShell.tabKey(ShellTab.play)))
          .hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('an unknown link shows what, why, and what to do', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(const AppShell(initialLink: '/no-such-place')),
    );
    await tester.pumpAndSettle();
    expect(find.text('This link did not open.'), findsOneWidget);
    expect(
      find.text('Nothing in the app matches /no-such-place.'),
      findsOneWidget,
    );
    expect(find.text('Go back to Today.'), findsOneWidget);

    await tester.tap(find.text('Go to Today'));
    await tester.pumpAndSettle();
    expect(find.text('This link did not open.'), findsNothing);
    expect(find.text('Today'), findsOneWidget);

    String detail = '';
    try {
      Uri.parse('http://[');
    } on FormatException catch (error) {
      detail = error.message;
    }
    final AppShellState state = tester.state<AppShellState>(
      find.byType(AppShell),
    );
    state.openLink('http://[');
    await tester.pumpAndSettle();
    expect(find.text('This link did not open.'), findsOneWidget);
    expect(
      find.text('Nothing in the app matches http://[. $detail'),
      findsOneWidget,
    );
    expect(find.text('Go back to Today.'), findsOneWidget);
    expect(detail, isNotEmpty);
  });

  testWidgets('offline state names what happened, why, and what to do', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const AppShell(offline: true)));
    await tester.pumpAndSettle();
    expect(find.text('The phone has no network.'), findsOneWidget);
    expect(find.text('These tabs are not saved offline.'), findsOneWidget);
    expect(find.text('Connect, then try again.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('reduced motion does not fade to a blank frame', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const AppShell(), reduced: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppShell.tabKey(ShellTab.village)));
    await tester.pump();

    final Opacity fade = tester.widget<Opacity>(find.byKey(AppShell.fadeKey));
    expect(fade.opacity, greaterThan(0));
    expect(find.text('Village'), findsOneWidget);
    expect(find.text('Open Village'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    final Opacity settled = tester.widget<Opacity>(
      find.byKey(AppShell.fadeKey),
    );
    expect(settled.opacity, 1);
    expect(find.text('Open Village'), findsOneWidget);
  });

  testWidgets('tab labels do not clip at 200 percent text', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(
      const Size(textScaleCatalogueWidth, textScaleSurfaceHeight),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(
      textScaleCatalogueWidth,
      textScaleSurfaceHeight,
    );
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LingTextScale(child: AppShell()));
    await tester.pumpAndSettle();

    final LingTextScaleReport report = LingTextScale.report(
      tester.renderObject(find.byType(LingTextScale)),
    );
    expect(report.isClean, isTrue, reason: report.failure('shell-tabs-200'));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Speak'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Village'), findsOneWidget);
  });

  test('tab link parser keeps a format failure', () {
    final TabLink speak = TabRoutes.resolve('lingafriq://open/speak');
    expect(speak.tab, ShellTab.speak);
    final TabLink missing = TabRoutes.resolve('/word-card');
    expect(missing.tab, isNull);
    expect(missing.known, isFalse);

    final String source = File(
      'lib/navigation/tab_routes.dart',
    ).readAsStringSync();
    expect(RegExp(r'catch\s*\([^)]*\)\s*\{\s*\}').hasMatch(source), isFalse);
    expect(source.contains('error.message'), isTrue);
  });

  test('no route from the route map is removed', () {
    final List<String> lines = File(
      'docs/build/design/ROUTE_MAP.csv',
    ).readAsLinesSync();
    final String app = File('lib/my_app.dart').readAsStringSync();
    final Map<String, String> sources = <String, String>{};
    for (final String line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final List<String> cells = _csv(line);
      expect(cells.length, greaterThanOrEqualTo(9), reason: line);
      final String kind = cells[0];
      final String key = cells[1];
      final String source = cells[8].split(':').first;
      if (kind == 'route') {
        expect(app.contains("'$key':"), isTrue, reason: key);
      } else if (kind == 'drawer') {
        sources.putIfAbsent(source, () => File(source).readAsStringSync());
        expect(
          _sameRoute(sources[source]!, key),
          isTrue,
          reason: '$key in $source',
        );
      }
    }
  });
}

String _fold(String value) {
  return value
      .replaceAll('\u2010', '-')
      .replaceAll('\u2011', '-')
      .replaceAll('\u2012', '-')
      .replaceAll('\u2013', '-')
      .replaceAll('\u2014', '-');
}

bool _sameRoute(String source, String key) {
  return _fold(source).contains(_fold(key));
}

List<String> _csv(String line) {
  final List<String> cells = <String>[];
  final StringBuffer current = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final String char = line[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i += 1;
        } else {
          quoted = false;
        }
      } else {
        current.write(char);
      }
    } else if (char == '"') {
      quoted = true;
    } else if (char == ',') {
      cells.add(current.toString());
      current.clear();
    } else {
      current.write(char);
    }
  }
  cells.add(current.toString());
  return cells;
}
