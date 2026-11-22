import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/a11y/text_scale.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/navigation/feature_directory.dart';
import 'package:lingafriq/screens/tabs_view/all_features_screen.dart';
import 'package:lingafriq/services/search_index_service.dart';

String _routeMapFile() {
  return File('docs/build/design/ROUTE_MAP.csv').readAsStringSync();
}

/// Route keys read from the file, not from the directory parser.
List<String> _routeKeys(String csv) {
  final List<String> keys = <String>[];
  for (final String line in csv.split('\n').skip(1)) {
    if (!line.startsWith('route,')) continue;
    final String rest = line.substring('route,'.length);
    final int comma = rest.indexOf(',');
    if (comma <= 0) continue;
    keys.add(rest.substring(0, comma));
  }
  return keys;
}

List<String> _drawerKeys(String csv) {
  final List<String> keys = <String>[];
  final Set<String> seen = <String>{};
  for (final String line in csv.split('\n').skip(1)) {
    if (!line.startsWith('drawer,')) continue;
    final String rest = line.substring('drawer,'.length);
    final int comma = rest.indexOf(',');
    if (comma <= 0) continue;
    final String key = rest.substring(0, comma);
    if (seen.add(key)) keys.add(key);
  }
  return keys;
}

Set<String> _labels(String csv) {
  final Set<String> labels = <String>{};
  for (final String line in csv.split('\n').skip(1)) {
    if (line.trim().isEmpty) continue;
    final int quote = line.indexOf('"');
    final String head = quote < 0 ? line : line.substring(0, quote);
    final List<String> parts = head.split(',');
    if (parts.length < 3) continue;
    labels.add(parts[2]);
  }
  return labels;
}

Widget _host(Widget child, {bool reduced = false, double scale = 1}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    onGenerateRoute: (RouteSettings settings) {
      final String name = settings.name ?? '';
      final String key = name.startsWith('/') ? name.substring(1) : name;
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) {
          return Scaffold(body: SafeArea(child: Text(key)));
        },
      );
    },
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

Future<void> _type(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every route keeps an entry point and drawer coverage differs by 0', () {
    final String file = _routeMapFile();
    expect(kRouteMapCsv, file);
    final FeatureDirectory directory = FeatureDirectory.fromRouteMap(file);
    final List<String> routes = _routeKeys(file);
    final List<String> drawerKeys = _drawerKeys(file);

    expect(routes, isNotEmpty);
    expect(drawerKeys, isNotEmpty);
    for (final String key in routes) {
      expect(directory.hasEntryPoint(key), isTrue, reason: key);
    }
    for (final String key in drawerKeys) {
      expect(
        directory.entries.any(
          (FeatureEntry entry) => entry.coversDrawerKey(key),
        ),
        isTrue,
        reason: key,
      );
    }
    expect(directory.coveredDrawerCount, directory.drawerCount);
    expect(directory.countDifference, 0);
    expect(directory.drawerCount, drawerKeys.length);
    String fold(String value) => value.trim().toLowerCase();
    expect(
      directory.entries.map((FeatureEntry entry) => fold(entry.label)).toSet(),
      _labels(file).map(fold).toSet(),
    );
    expect(
      directory.entries.any(
        (FeatureEntry entry) => entry.label == 'Tone Forge',
      ),
      isFalse,
    );

    expect(directory.hasEntryPoint('tribe-selection'), isTrue);
    expect(directory.hasEntryPoint('tribe_selection'), isTrue);
    final FeatureEntry point = directory.entries.singleWhere(
      (FeatureEntry entry) => entry.key == 'shellPointSay',
    );
    expect(point.learningLoop, 'Point, hear, and say');
    expect(point.locked, isFalse);

    final FeatureEntry create = directory.entries.singleWhere(
      (FeatureEntry entry) => entry.label == 'Create Content',
    );
    expect(create.locked, isTrue);
    expect(create.unlockStage, 'B1');
    expect(create.learningLoop, 'Create a mini-lesson');
    expect(create.hub, 'Village');

    final FeatureEntry grammar = directory.entries.singleWhere(
      (FeatureEntry entry) => entry.key == 'grammar-hub',
    );
    expect(grammar.locked, isFalse);
    expect(grammar.routeKey, 'grammar-hub');
  });

  test('removing the drawer widget still requires every route entry point', () {
    final String file = _routeMapFile();
    final FeatureDirectory directory = FeatureDirectory.fromRouteMap(file);
    final File drawer = File('lib/widgets/pan_african_drawer.dart');
    final String source = drawer.existsSync() ? drawer.readAsStringSync() : '';
    for (final String key in _routeKeys(file)) {
      expect(directory.hasEntryPoint(key), isTrue, reason: key);
      if (!source.contains(key)) {
        expect(directory.hasEntryPoint(key), isTrue, reason: key);
      }
    }
    expect(directory.countDifference, 0);
  });

  test('features group by hub in A to Z order', () {
    final FeatureDirectory directory = FeatureDirectory.fromRouteMap(
      _routeMapFile(),
    );
    final List<FeatureHubGroup> groups = directory.groupsFor('');
    expect(groups.map((FeatureHubGroup group) => group.hub), <String>[
      'Today',
      'Learn',
      'Speak',
      'Play',
      'Village',
      'Me',
    ]);
    for (final FeatureHubGroup group in groups) {
      final List<String> labels = group.entries
          .map((FeatureEntry entry) => entry.label.toLowerCase())
          .toList();
      final List<String> sorted = List<String>.from(labels)..sort();
      expect(labels, sorted, reason: group.hub);
    }

    final List<FeatureHubGroup> grammar = directory.groupsFor('Grammar');
    expect(grammar, hasLength(1));
    expect(grammar.single.hub, 'Learn');
    expect(
      grammar.single.entries.map((FeatureEntry entry) => entry.label),
      <String>['Grammar Exercise', 'Grammar Hub', 'Grammar Lesson'],
    );
    expect(directory.groupsFor('Tone Forge'), isEmpty);

    final List<FeatureHubGroup> hidden = directory.groupsFor(
      '',
      hiddenKeys: kGlobalChatFeatureKeys,
    );
    expect(
      hidden
          .expand((FeatureHubGroup group) => group.entries)
          .any((FeatureEntry entry) => entry.label == 'Global Chat'),
      isFalse,
    );
    expect(
      groups
          .expand((FeatureHubGroup group) => group.entries)
          .any((FeatureEntry entry) => entry.key == 'global_chat'),
      isTrue,
    );
  });

  testWidgets('Me then All features opens an A to Z list grouped by hub', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(const AllFeaturesButton(), reduced: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AllFeaturesButton.buttonKey));
    await tester.pumpAndSettle();

    expect(find.byType(AllFeaturesScreen), findsOneWidget);
    expect(find.text('All features'), findsWidgets);
    expect(find.text('Search features'), findsOneWidget);

    double? previous;
    for (final String hub in kFeatureHubOrder) {
      final double dy = tester
          .getTopLeft(find.byKey(AllFeaturesScreen.hubKey(hub)))
          .dy;
      if (previous != null) {
        expect(previous, lessThan(dy), reason: hub);
      }
      previous = dy;
    }

    await _type(tester, 'Grammar');
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Grammar Exercise')).dy,
      lessThan(tester.getTopLeft(find.text('Grammar Hub')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Grammar Hub')).dy,
      lessThan(tester.getTopLeft(find.text('Grammar Lesson')).dy),
    );
    expect(find.text('Locked'), findsNothing);

    await tester.tap(find.byKey(AllFeaturesScreen.entryKey('grammar-hub')));
    await tester.pumpAndSettle();
    expect(find.text('grammar-hub'), findsOneWidget);
  });

  testWidgets('a locked feature lists the unlock line and a preview', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(const AllFeaturesScreen(), reduced: true));
    await tester.pumpAndSettle();
    await _type(tester, 'Create Content');

    expect(
      find.descendant(
        of: find.byKey(AllFeaturesScreen.entryKey('shellCreateContent')),
        matching: find.text('Create Content'),
      ),
      findsOneWidget,
    );
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('Unlocks at B1.'), findsOneWidget);
    expect(find.text('Create a mini-lesson'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);

    final SemanticsHandle handle = tester.ensureSemantics();
    expect(
      tester
          .getSemantics(
            find.byKey(AllFeaturesScreen.entryKey('shellCreateContent')),
          )
          .label,
      'Create Content, Locked. Unlocks at B1. Create a mini-lesson',
    );
    handle.dispose();

    await tester.tap(
      find.byKey(AllFeaturesScreen.previewKey('shellCreateContent')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FeaturePreviewPage), findsOneWidget);
    expect(find.text('Unlocks at B1.'), findsWidgets);
    expect(find.text('Create a mini-lesson'), findsWidgets);
    expect(find.text('Back to Me'), findsWidgets);

    await tester.tap(
      find.descendant(
        of: find.byType(FeaturePreviewPage),
        matching: find.text('Back to Me'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FeaturePreviewPage), findsNothing);
  });

  testWidgets('search with no match shows the empty state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(const AllFeaturesScreen(), reduced: true));
    await tester.pumpAndSettle();
    await _type(tester, 'Tone Forge');

    expect(find.byKey(AllFeaturesScreen.emptyKey), findsOneWidget);
    expect(find.text('No match'), findsOneWidget);
    expect(find.text('Nothing matches Tone Forge.'), findsOneWidget);
    expect(find.text('That name is not in the directory.'), findsOneWidget);
    expect(find.text('Try another name.'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pump();
    expect(find.byKey(AllFeaturesScreen.hubKey('Today')), findsOneWidget);
    expect(find.text('Tone Forge'), findsNothing);
  });

  testWidgets('200 percent text does not clip a locked row', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(const AllFeaturesScreen(), reduced: true, scale: 2),
    );
    await tester.pumpAndSettle();
    await _type(tester, 'Create Content');
    expect(tester.takeException(), isNull);
    final LingTextScaleReport report = LingTextScale.report(
      tester.renderObject(find.byType(AllFeaturesScreen)),
    );
    expect(report.overflows, isEmpty);
    expect(report.clipped, isEmpty);
    expect(find.text('Unlocks at B1.'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
  });
}
