import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/games/gamekit/play_shelves.dart';
import 'package:lingafriq/games/tone_forge/tone_forge_screen.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/navigation/hub_play.dart';
import 'package:lingafriq/screens/games/game_mastery_results_screen.dart';
import 'package:lingafriq/services/search_index_service.dart';

Widget _host(Widget child, {double scale = 1, bool reduced = false}) {
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

List<SearchFeature> _playFeatures() {
  final String csv = File('docs/build/design/ROUTE_MAP.csv').readAsStringSync();
  return featuresFromRouteMap(
    csv,
  ).where((SearchFeature feature) => feature.hub == 'Play').toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('play routes are registered and within two taps', () {
    const List<String> required = <String>[
      PlayRoutes.root,
      '/play/tone-and-sound',
      '/play/words',
      '/play/grammar',
      '/play/speaking',
      '/play/culture',
      '/play/traditional',
      '/play/multiplayer',
      PlayRoutes.toneForge,
      PlayRoutes.masteryResults,
    ];
    for (final String path in required) {
      expect(PlayRoutes.isRegistered(path), isTrue, reason: path);
      expect(PlayRoutes.tapsFromRoot(path), inInclusiveRange(0, 2));
    }
    expect(PlayRoutes.paths, containsAll(required));
    expect(PlayRoutes.tapsFromRoot(PlayRoutes.root), 0);
    expect(PlayRoutes.tapsFromRoot('/play/words'), 1);
    expect(PlayRoutes.tapsFromRoot('/play/words/flashcard-focus'), 2);
    expect(PlayRoutes.tapsFromRoot(PlayRoutes.toneForge), 1);
    expect(PlayRoutes.tapsFromRoot(PlayRoutes.masteryResults), 1);
    expect(PlayRoutes.tapsFromRoot('/play/nope'), -1);

    expect(PlayRoutes.openingFor(PlayRoutes.root), isA<PlayHubOpening>());
    expect(PlayRoutes.openingFor('/play/words'), isA<PlayShelfOpening>());
    expect(
      PlayRoutes.openingFor(PlayRoutes.toneForge),
      isA<PlayToneForgeOpening>(),
    );
    expect(
      PlayRoutes.openingFor(PlayRoutes.masteryResults),
      isA<PlayMasteryResultsOpening>(),
    );
    for (final PlayShelfGame game in kPlayShelfGames) {
      expect(PlayRoutes.isRegistered(game.path), isTrue, reason: game.path);
      expect(PlayRoutes.tapsFromRoot(game.path), 2);
      final PlayOpening opening = PlayRoutes.openingFor(game.path);
      expect(opening, isA<PlayGapOpening>());
      expect((opening as PlayGapOpening).gap.placeId, game.key);
    }
    expect(kPlayShelfOrder, hasLength(7));
  });

  test('shelf game count matches the Play games in the route map', () {
    final List<SearchFeature> features = _playFeatures();
    final Set<String> keys = features
        .map((SearchFeature feature) => feature.key)
        .toSet();
    expect(validatePlayShelfCoverage(keys), isEmpty);
    expect(playShelfGameCount, features.length);
    expect(
      kPlayShelfGames.map((PlayShelfGame game) => game.key).toList(),
      <String>[for (final SearchFeature feature in features) feature.key],
    );

    final Map<String, int> shelves = <String, int>{};
    for (final PlayShelfGame game in kPlayShelfGames) {
      shelves.update(game.key, (int count) => count + 1, ifAbsent: () => 1);
    }
    expect(shelves.values.every((int count) => count == 1), isTrue);

    final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));
    for (final SearchFeature feature in features) {
      expect(
        playGameLabel(l10n, feature.key),
        feature.label,
        reason: feature.key,
      );
    }
    const List<String> invented = <String>[
      'Tone Trainer',
      'Word Match',
      'Word Match (audio)',
      'Memory Map',
      'Fill in the Blank',
      'Grammar Detective',
      'Market Bargaining',
      'Pronunciation Duel',
      'Proverb Unlocker',
      'Quiz Chef',
      'Ayo (mancala)',
      'Conversation Relay',
      'Liar Liar',
    ];
    final Set<String> labels = features
        .map((SearchFeature feature) => feature.label)
        .toSet();
    for (final String name in invented) {
      expect(labels.contains(name), isFalse, reason: name);
    }
    expect(labels.contains('Tone Forge'), isFalse);
  });

  testWidgets('every sitemap row opens within two taps', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const PlayHub()));
    await tester.pumpAndSettle();

    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Games sit on skill shelves.'), findsOneWidget);
    const List<(String, String)> shelves = <(String, String)>[
      ('tone-and-sound', 'Tone & Sound'),
      ('words', 'Words'),
      ('grammar', 'Grammar'),
      ('speaking', 'Speaking'),
      ('culture', 'Culture'),
      ('traditional', 'Traditional'),
      ('multiplayer', 'Multiplayer'),
    ];
    for (final (String segment, String label) in shelves) {
      expect(find.text(label), findsOneWidget);
      final PlayShelfId shelf = kPlayShelfOrder.singleWhere(
        (PlayShelfId item) => item.segment == segment,
      );
      await tester.tap(find.byKey(PlayHub.shelfKey(shelf)));
      await tester.pumpAndSettle();
      final String route = ModalRoute.of(
        tester.element(find.byType(PlayShelfPage)),
      )!.settings.name!;
      expect(route, '/play/$segment');
      expect(PlayRoutes.tapsFromRoot(route), lessThanOrEqualTo(2));
      final Finder back = find.text('Back to Play');
      if (back.evaluate().isNotEmpty) {
        await tester.ensureVisible(back);
        await tester.tap(back);
      } else {
        await tester.tap(find.text('Open the Arcade'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(PlayHubPage), findsOneWidget);
    }

    await tester.tap(find.byKey(PlayHub.toneForgeKey));
    await tester.pumpAndSettle();
    expect(find.byType(ToneForgeScreen), findsOneWidget);
    expect(find.byType(PlayNotAvailablePage), findsNothing);
    expect(
      ModalRoute.of(
        tester.element(find.byType(ToneForgeScreen)),
      )!.settings.name,
      PlayRoutes.toneForge,
    );
    expect(PlayRoutes.tapsFromRoot(PlayRoutes.toneForge), lessThanOrEqualTo(2));
    await tester.tap(find.text('Back to Play'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayHubPage), findsOneWidget);

    await tester.tap(find.byKey(PlayHub.masteryResultsKey));
    await tester.pumpAndSettle();
    expect(find.byType(GameMasteryResultsScreen), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(GameMasteryResultsScreen)),
      )!.settings.name,
      PlayRoutes.masteryResults,
    );
    await tester.tap(find.text('Back to Play'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayHubPage), findsOneWidget);
  });

  testWidgets('a words game opens in two taps and shows no sample rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const PlayHub()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(PlayHub.shelfKey(PlayShelfId.words)));
    await tester.pumpAndSettle();
    expect(find.text('Flashcard Focus'), findsOneWidget);
    expect(find.text('Matching Pairs'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
    expect(find.text('Games API Languages'), findsOneWidget);
    expect(find.text('Games Enhanced Catalog'), findsOneWidget);
    expect(find.text('Challenge Friend'), findsNothing);
    expect(find.text('Tone Trainer'), findsNothing);
    expect(find.text('Ọmọ'), findsNothing);

    await tester.tap(find.byKey(PlayHub.gameKey('flashcard-focus')));
    await tester.pumpAndSettle();
    expect(find.byType(PlayNotAvailablePage), findsOneWidget);
    expect(
      PlayRoutes.tapsFromRoot(
        ModalRoute.of(
          tester.element(find.byType(PlayNotAvailablePage)),
        )!.settings.name!,
      ),
      2,
    );
    final Set<String> lines = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text text) => text.data ?? '')
        .toSet();
    expect(lines, <String>{
      'Flashcard Focus',
      'Not available yet',
      'Flashcard Focus is not available yet.',
      'This screen is not built yet.',
      'Go back to Play.',
      'Back to Play',
    });
    expect(lines.contains('Ọmọ'), isFalse);
  });

  testWidgets('tone forge opens with an empty state', (tester) async {
    await tester.pumpWidget(
      _host(const PlayHub(initialRoute: PlayRoutes.toneForge)),
    );
    await tester.pumpAndSettle();
    expect(
      PlayRoutes.openingFor(PlayRoutes.toneForge),
      isA<PlayToneForgeOpening>(),
    );
    expect(find.byType(ToneForgeScreen), findsOneWidget);
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.byKey(ToneForgeScreen.emptyKey), findsOneWidget);
    expect(find.text('No word is ready.'), findsOneWidget);
    expect(find.text('Not available yet'), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.text('80'), findsNothing);
    expect(find.text('100'), findsNothing);
  });

  testWidgets('an empty shelf points back to the arcade', (tester) async {
    await tester.pumpWidget(
      _host(const PlayHub(initialRoute: '/play/grammar')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(PlayHub.shelfEmptyKey), findsOneWidget);
    expect(find.text('This shelf has no game.'), findsOneWidget);
    expect(find.text('No game is listed on this shelf.'), findsOneWidget);
    expect(find.text('Open the Arcade.'), findsOneWidget);
    expect(find.text('Grammar Detective'), findsNothing);
    await tester.tap(find.text('Open the Arcade'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayHubPage), findsOneWidget);
  });

  testWidgets('an empty hub points to a next step', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(PlayHub(status: PlayHubStatus.empty, onRetry: () => retries += 1)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(PlayHub.emptyKey), findsOneWidget);
    expect(find.text('The shelves have no games.'), findsOneWidget);
    expect(find.text('No game came back.'), findsOneWidget);
    expect(find.text('Try again.'), findsOneWidget);
    expect(find.byKey(PlayHub.shelfKey(PlayShelfId.words)), findsNothing);
    expect(find.text('Tone Trainer'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('error and offline name what to do', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(PlayHub(status: PlayHubStatus.error, onRetry: () => retries += 1)),
    );
    await tester.pumpAndSettle();
    expect(find.text('The game list did not open.'), findsOneWidget);
    expect(find.text('The list did not come back.'), findsOneWidget);
    expect(find.text('Try again.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retries, 1);

    await tester.pumpWidget(
      _host(const PlayHub(status: PlayHubStatus.offline)),
    );
    await tester.pumpAndSettle();
    expect(find.text('The phone has no network.'), findsOneWidget);
    expect(
      find.text('These games are not saved on the phone.'),
      findsOneWidget,
    );
    expect(find.text('Connect, then try again.'), findsOneWidget);
  });

  testWidgets('rows stay at least 48 and wrap at 200 percent', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const PlayHub(), scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final PlayShelfId shelf in kPlayShelfOrder) {
      final Size size = tester.getSize(find.byKey(PlayHub.shelfKey(shelf)));
      expect(size.width, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
      expect(size.height, greaterThanOrEqualTo(LingAfriqTokens.spacing48));
    }
    expect(find.text('Tone & Sound'), findsOneWidget);
    expect(find.text('Multiplayer'), findsOneWidget);
  });

  testWidgets('reduced motion still shows the shelves', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const PlayHub(), reduced: true));
    await tester.pumpAndSettle();
    expect(find.text('Tone & Sound'), findsOneWidget);
    expect(find.text('Tone Forge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
