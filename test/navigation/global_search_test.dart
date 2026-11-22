import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/a11y/text_scale.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/navigation/app_shell.dart';
import 'package:lingafriq/navigation/global_search.dart';
import 'package:lingafriq/services/search_index_service.dart';
import 'package:lingafriq/widgets/word_card_sheet.dart';

Future<void> _loadFont(String family, String asset) async {
  final Future<ByteData> data = File(
    asset,
  ).readAsBytes().then(ByteData.sublistView);
  final FontLoader loader = FontLoader(family)..addFont(data);
  await loader.load();
}

String _routeMapFile() {
  return File('docs/build/design/ROUTE_MAP.csv').readAsStringSync();
}

SearchIndexService _catalog({
  List<SearchWord> words = const <SearchWord>[],
  List<SearchContent> content = const <SearchContent>[],
  Set<String>? builtRouteKeys,
}) {
  return SearchIndexService.fromRouteMap(
    _routeMapFile(),
    words: words,
    content: content,
    builtRouteKeys: builtRouteKeys,
  );
}

SearchFeature _feature(SearchIndexService service, String label) {
  return service.features.singleWhere(
    (SearchFeature feature) => feature.label == label,
  );
}

Widget _host(Widget child, {bool reduced = false}) {
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
        data: data.copyWith(disableAnimations: reduced),
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

  setUpAll(() async {
    await _loadFont(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
  });

  test('feature names are the route map labels', () {
    final String file = _routeMapFile();
    expect(kRouteMapCsv, file);
    final String sources =
        File('lib/services/search_index_service.dart').readAsStringSync() +
        File('lib/navigation/global_search.dart').readAsStringSync();
    expect(sources.contains('Tone Forge'), isFalse);

    final SearchIndexService service = SearchIndexService.routeMapCatalog();
    final Set<String> labels = service.features
        .map((SearchFeature feature) => feature.label)
        .toSet();
    expect(labels.length, service.features.length);
    expect(labels.contains('Tone Forge'), isFalse);
    expect(labels.contains('Grammar Hub'), isTrue);
    expect(labels.contains('Tone Rhythm Trainer'), isTrue);
    expect(labels.contains('Tone & Rhythm'), isTrue);
    expect(labels.contains('Live translate'), isTrue);

    final Set<String> fileLabels = <String>{};
    for (final String line in File(
      'docs/build/design/ROUTE_MAP.csv',
    ).readAsLinesSync().skip(1)) {
      if (line.trim().isEmpty) continue;
      fileLabels.add(_csvLabel(line));
    }
    String fold(String value) => value.trim().toLowerCase();
    expect(labels.map(fold).toSet(), fileLabels.map(fold).toSet());
    for (final String label in labels) {
      expect(
        fileLabels.any((String raw) => fold(raw) == fold(label)),
        isTrue,
        reason: label,
      );
    }

    expect(_feature(service, 'Grammar Hub').key, 'grammar-hub');
    expect(_feature(service, 'Grammar Hub').routeBuilt, isTrue);
    expect(_feature(service, 'Tone Rhythm Trainer').key, 'tone-rhythm-trainer');
    expect(_feature(service, 'Tone Rhythm Trainer').routeBuilt, isTrue);
    expect(_feature(service, 'Tone & Rhythm').routeBuilt, isFalse);
    expect(_feature(service, 'Live translate').key, 'shellLiveTranslate');
    expect(_feature(service, 'Live translate').routeBuilt, isFalse);
    expect(_feature(service, 'Live translate').unlockStage, 'Day 1');
    expect(
      _feature(service, 'Live translate').learningLoop,
      'Conversation Bridge',
    );
    expect(_feature(service, 'Badges').key, 'badges');
    expect(_feature(service, 'Badges').routeBuilt, isTrue);

    final SearchIndexService limited = _catalog(builtRouteKeys: <String>{});
    expect(_feature(limited, 'Grammar Hub').routeBuilt, isFalse);
    expect(_feature(limited, 'Live translate').routeBuilt, isFalse);
  });

  test('ranking prefers an exact word over a longer prefix', () {
    const SearchIndexService service = SearchIndexService(
      words: <SearchWord>[
        SearchWord(id: 'exact', surface: 'market'),
        SearchWord(id: 'word', surface: 'the market day'),
        SearchWord(id: 'prefix', surface: 'marketplace'),
      ],
      features: <SearchFeature>[],
      content: <SearchContent>[],
    );
    final SearchResults result = service.search('market');
    expect(result.words.map((SearchWordHit hit) => hit.word.id), <String>[
      'exact',
      'word',
      'prefix',
    ]);
    expect(result.words.map((SearchWordHit hit) => hit.rank), <int>[0, 1, 2]);
    expect(service.search('  ').isEmpty, isTrue);
    expect(searchMatchRank('tone', 'Heritage milestones'), 99);

    final SearchResults folded = const SearchIndexService(
      words: <SearchWord>[
        SearchWord(id: 'yo', surface: 'sànnú', gloss: 'hello'),
      ],
      features: <SearchFeature>[],
      content: <SearchContent>[],
    ).search('sannu');
    expect(folded.words.single.word.id, 'yo');
  });

  test('a query keeps words, features, and content in separate groups', () {
    final SearchIndexService service = _catalog(
      words: const <SearchWord>[
        SearchWord(id: 'note', surface: 'note', gloss: 'a short record'),
      ],
      content: const <SearchContent>[
        SearchContent(
          id: 'class-note',
          title: 'Class note',
          detail: 'Saved on this phone',
        ),
      ],
    );
    final SearchResults result = service.search('note');
    expect(result.words.map((SearchWordHit hit) => hit.word.surface), <String>[
      'note',
    ]);
    expect(
      result.features.map((SearchFeatureHit hit) => hit.feature.label),
      <String>['Classroom Notes'],
    );
    expect(
      result.content.map((SearchContentHit hit) => hit.content.title),
      <String>['Class note'],
    );
    expect(service.search('Tone Forge').isEmpty, isTrue);
  });

  testWidgets('the Search control opens the search page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (BuildContext context) {
            return AppShell(onSearch: () => GlobalSearchPage.open(context));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppShell.toolKey(ShellTool.search)));
    await tester.pumpAndSettle();

    expect(find.byType(GlobalSearchPage), findsOneWidget);
    expect(find.text('Search is ready.'), findsOneWidget);
    expect(find.text('Type a word or a feature name.'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(GlobalSearchPage), findsNothing);
    expect(find.byKey(AppShell.toolKey(ShellTool.search)), findsOneWidget);
  });

  testWidgets('a query groups results and a word opens its Word Card', (
    WidgetTester tester,
  ) async {
    final SearchIndexService service = _catalog(
      words: const <SearchWord>[
        SearchWord(id: 'note', surface: 'note', gloss: 'a short record'),
        SearchWord(id: 'yo', surface: 'sànnú', gloss: 'hello'),
      ],
      content: const <SearchContent>[
        SearchContent(
          id: 'class-note',
          title: 'Class note',
          detail: 'Saved on this phone',
        ),
      ],
    );
    await tester.pumpWidget(_host(GlobalSearchPage(service: service)));
    await tester.pumpAndSettle();
    await _type(tester, 'note');

    expect(find.text('Words'), findsOneWidget);
    expect(find.text('Features'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
    expect(find.text('note'), findsWidgets);
    expect(find.text('Classroom Notes'), findsOneWidget);
    expect(find.text('Class note'), findsOneWidget);
    final double words = tester
        .getTopLeft(find.byKey(GlobalSearchPage.groupKey(SearchBucket.words)))
        .dy;
    final double features = tester
        .getTopLeft(
          find.byKey(GlobalSearchPage.groupKey(SearchBucket.features)),
        )
        .dy;
    final double content = tester
        .getTopLeft(find.byKey(GlobalSearchPage.groupKey(SearchBucket.content)))
        .dy;
    expect(words, lessThan(features));
    expect(features, lessThan(content));

    final SemanticsHandle handle = tester.ensureSemantics();
    await _type(tester, 'sannu');
    expect(find.text('Words'), findsOneWidget);
    expect(find.text('Features'), findsNothing);
    expect(find.byKey(GlobalSearchPage.hitKey('yo')), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(GlobalSearchPage.hitKey('yo'))).label,
      'Open Word Card for sànnú',
    );
    await tester.tap(find.byKey(GlobalSearchPage.hitKey('yo')));
    await tester.pumpAndSettle();
    expect(find.byType(WordCardSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(WordCardSheet),
        matching: find.text('sànnú'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('a built feature opens its route', (WidgetTester tester) async {
    await tester.pumpWidget(_host(GlobalSearchPage(service: _catalog())));
    await tester.pumpAndSettle();
    await _type(tester, 'Tone Rhythm Trainer');
    expect(
      find.byKey(GlobalSearchPage.hitKey('tone-rhythm-trainer')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(GlobalSearchPage.hitKey('tone-rhythm-trainer')),
    );
    await tester.pumpAndSettle();
    expect(find.text('tone-rhythm-trainer'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await _type(tester, 'Grammar Hub');
    await tester.tap(find.byKey(GlobalSearchPage.hitKey('grammar-hub')));
    await tester.pumpAndSettle();
    expect(find.text('grammar-hub'), findsOneWidget);
  });

  testWidgets('an unbuilt feature opens its unlock preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(GlobalSearchPage(service: _catalog())));
    await tester.pumpAndSettle();
    await _type(tester, 'Live translate');
    expect(find.text('Features'), findsOneWidget);
    expect(
      find.byKey(GlobalSearchPage.hitKey('shellLiveTranslate')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(GlobalSearchPage.hitKey('shellLiveTranslate')));
    await tester.pumpAndSettle();

    expect(find.byType(GlobalSearchUnlockPage), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Live translate is not open yet.'), findsOneWidget);
    expect(find.text('It unlocks at Day 1.'), findsOneWidget);
    expect(find.text('Conversation Bridge'), findsOneWidget);
    expect(find.text('Read this preview, then go back.'), findsOneWidget);
  });

  testWidgets('a route marked unbuilt opens the unlock preview', (
    WidgetTester tester,
  ) async {
    final SearchIndexService blocked = _catalog(
      builtRouteKeys: <String>{'games'},
    );
    await tester.pumpWidget(_host(GlobalSearchPage(service: blocked)));
    await tester.pumpAndSettle();
    await _type(tester, 'Grammar Hub');
    await tester.tap(find.byKey(GlobalSearchPage.hitKey('grammar-hub')));
    await tester.pumpAndSettle();
    expect(find.byType(GlobalSearchUnlockPage), findsOneWidget);
    expect(find.text('Grammar Hub is not open yet.'), findsOneWidget);
    expect(find.text('It unlocks at Day 1.'), findsOneWidget);
    expect(find.text('Grammar drill'), findsOneWidget);
  });

  testWidgets('no match offers the directory', (WidgetTester tester) async {
    var opened = false;
    await tester.pumpWidget(
      _host(
        GlobalSearchPage(
          service: _catalog(),
          onOpenDirectory: () {
            opened = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _type(tester, 'Tone Forge');
    expect(find.text('No match'), findsOneWidget);
    expect(find.text('Nothing matches Tone Forge.'), findsOneWidget);
    expect(
      find.text(
        'That name is not in words, features, or content on this phone.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Open the directory to see every feature.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Open the directory'));
    await tester.pump();
    expect(opened, isTrue);

    await tester.pumpWidget(_host(const GlobalSearchPage()));
    await tester.pumpAndSettle();
    await _type(tester, 'Tone Forge');
    await tester.tap(find.text('Open the directory'));
    await tester.pumpAndSettle();
    expect(find.text('features_guide'), findsOneWidget);
  });

  testWidgets('offline search shows local results with an offline label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(GlobalSearchPage(service: _catalog(), offline: true)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(GlobalSearchPage.offlineKey), findsNothing);
    await _type(tester, 'Grammar Hub');
    expect(
      find.text('Offline. Showing results saved on this phone.'),
      findsOneWidget,
    );
    expect(find.byKey(GlobalSearchPage.hitKey('grammar-hub')), findsOneWidget);
    expect(find.text('Words'), findsNothing);
    expect(find.text('Features'), findsOneWidget);
  });

  testWidgets('reduced motion still searches', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(GlobalSearchPage(service: _catalog()), reduced: true),
    );
    await tester.pumpAndSettle();
    await _type(tester, 'Games');
    expect(find.text('Games'), findsWidgets);
    expect(find.text('Features'), findsOneWidget);
  });

  testWidgets('search copy does not clip at 200 percent text', (
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

    await tester.pumpWidget(const LingTextScale(child: GlobalSearchPage()));
    await tester.pumpAndSettle();
    final LingTextScaleReport idle = LingTextScale.report(
      tester.renderObject(find.byType(LingTextScale)),
    );
    expect(idle.isClean, isTrue, reason: idle.failure('search-idle-200'));

    await tester.enterText(find.byType(TextField), 'Classroom Notes');
    await tester.pumpAndSettle();
    final LingTextScaleReport results = LingTextScale.report(
      tester.renderObject(find.byType(LingTextScale)),
    );
    expect(
      results.isClean,
      isTrue,
      reason: results.failure('search-results-200'),
    );
    expect(
      find.byKey(GlobalSearchPage.hitKey('classroom-notes')),
      findsOneWidget,
    );
  });
}

String _csvLabel(String line) {
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
  return cells[2];
}
