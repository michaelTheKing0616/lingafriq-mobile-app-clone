import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';
import 'package:lingafriq/games/gamekit/game_turn_context.dart';
import 'package:lingafriq/games/tone_forge/tone_forge_feedback.dart';
import 'package:lingafriq/games/tone_forge/tone_forge_scoring.dart';
import 'package:lingafriq/games/tone_forge/tone_forge_screen.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/my_app.dart';
import 'package:lingafriq/navigation/hub_play.dart';
import 'package:lingafriq/screens/games/game_mastery_results_screen.dart';

const String _unsureCopy =
    'We could not score this clearly. No score is shown.';

const ToneForgeRound _round = ToneForgeRound(
  word: 'E kaaro',
  audioPath: 'tone.wav',
  language: 'yo',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('import walk from lib/main.dart reaches both Play routes', () {
    final Set<String> reached = _reachableFrom('lib/main.dart');
    expect(reached, contains('lib/my_app.dart'));
    expect(reached, contains('lib/games/tone_forge/tone_forge_screen.dart'));
    expect(
      reached,
      contains('lib/screens/games/game_mastery_results_screen.dart'),
    );
    expect(reached, contains('lib/games/tone_forge/tone_forge_scoring.dart'));
    expect(reached, contains('lib/games/tone_forge/tone_forge_feedback.dart'));

    final String mainSource = File('lib/main.dart').readAsStringSync();
    expect(mainSource, contains("import 'my_app.dart'"));
    final String app = File('lib/my_app.dart').readAsStringSync();
    expect(app, contains('onGenerateRoute: generateAppRoute'));
    expect(app, contains('ToneForgeScreen.routeKey'));
    expect(app, contains('const ToneForgeScreen.play()'));
    expect(app, contains('GameMasteryResultsScreen.routeKey'));
    expect(app, contains('const GameMasteryResultsScreen.play()'));
    expect(app, contains("import 'games/tone_forge/tone_forge_screen.dart'"));
    expect(
      app,
      contains("import 'screens/games/game_mastery_results_screen.dart'"),
    );

    expect(ToneForgeScreen.routePath, '/play/tone-forge');
    expect(ToneForgeScreen.routeKey, 'play/tone-forge');
    expect(PlayRoutes.toneForge, ToneForgeScreen.routePath);
    expect(GameMasteryResultsScreen.routePath, '/play/mastery-results');
    expect(GameMasteryResultsScreen.routeKey, 'play/mastery-results');
    expect(PlayRoutes.masteryResults, GameMasteryResultsScreen.routePath);
    expect(PlayRoutes.isRegistered(PlayRoutes.toneForge), isTrue);
    expect(PlayRoutes.isRegistered(PlayRoutes.masteryResults), isTrue);
    expect(
      PlayRoutes.openingFor(PlayRoutes.toneForge),
      isA<PlayToneForgeOpening>(),
    );
    expect(
      PlayRoutes.openingFor(PlayRoutes.masteryResults),
      isA<PlayMasteryResultsOpening>(),
    );

    for (final String path in <String>[
      'lib/games/tone_forge/tone_forge_screen.dart',
      'lib/games/tone_forge/tone_forge_scoring.dart',
      'lib/games/tone_forge/tone_forge_feedback.dart',
      'lib/screens/games/game_mastery_results_screen.dart',
      'lib/navigation/hub_play.dart',
    ]) {
      expect(File(path).readAsStringSync().contains('\u2014'), isFalse);
    }
    expect(
      File('lib/games/tone_forge/tone_forge_scoring.dart').readAsStringSync(),
      contains('RealScorerSpeakingEngine'),
    );
  });

  test('a percent is kept only for a real scorer result', () async {
    final GameScore real = GameScore(
      accuracy: 0.5,
      isPerfect: false,
      isFail: false,
      countsForRewards: true,
      source: GameScoreSource.realScorer,
    );
    expect(toneForgeShownPercent(real), 50);
    expect(toneForgeScoreView(real), ToneForgeScoreView.scored);
    final String realMessage = toneForgeFeedbackMessage(real);
    expect(realMessage, 'The scorer returned 50%.');
    expect(realMessage.contains('\u2014'), isFalse);

    final GameTurnContext context = GameTurnContext(
      content: 'E kaaro',
      input: 'E kaaro',
      session: GameSession(
        sessionId: 'tone_forge',
        userId: 'learner',
        gameId: 'tone_forge',
        language: 'yo',
        startTime: DateTime.utc(2026, 1, 1),
      ),
    );
    final message = (await const ToneForgeFeedbackEngine().generate(
      context,
      real,
    )).message;
    expect(message, realMessage);

    for (final GameScore hidden in <GameScore>[
      GameScore.unsure(message: 'unsure'),
      GameScore.scorerError(message: 'down'),
      GameScore.honestPractice(message: 'practice'),
      GameScore.correct(accuracy: 0),
      GameScore.correct(accuracy: 0.8),
      GameScore.correct(accuracy: 1),
    ]) {
      expect(toneForgeShownPercent(hidden), isNull);
      expect(toneForgeScoreView(hidden), ToneForgeScoreView.unsure);
      final String text = toneForgeFeedbackMessage(hidden);
      expect(text, _unsureCopy);
      expect(RegExp(r'\d').hasMatch(text), isFalse);
      final hiddenMessage = (await const ToneForgeFeedbackEngine().generate(
        context,
        hidden,
      )).message;
      expect(hiddenMessage, _unsureCopy);
    }
  });

  testWidgets('the route table builds Tone Forge and mastery results', (
    tester,
  ) async {
    final Map<String, Type> expected = <String, Type>{
      ToneForgeScreen.routePath: ToneForgeScreen,
      ToneForgeScreen.routeKey: ToneForgeScreen,
      GameMasteryResultsScreen.routePath: GameMasteryResultsScreen,
      GameMasteryResultsScreen.routeKey: GameMasteryResultsScreen,
    };
    for (final MapEntry<String, Type> entry in expected.entries) {
      late Widget built;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              final Route<dynamic>? route = generateAppRoute(
                RouteSettings(name: entry.key),
              );
              expect(route, isA<MaterialPageRoute<dynamic>>());
              built = (route! as MaterialPageRoute<dynamic>).builder(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(built.runtimeType, entry.value);
    }
  });

  testWidgets('Play opens both routes', (tester) async {
    _wide(tester);
    await tester.pumpWidget(_host(const PlayHub()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(PlayHub.toneForgeKey));
    await tester.pumpAndSettle();
    expect(find.byType(ToneForgeScreen), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(ToneForgeScreen)),
      )!.settings.name,
      '/play/tone-forge',
    );
    expect(find.byKey(ToneForgeScreen.emptyKey), findsOneWidget);
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.byKey(ToneForgeScreen.scoreKey), findsNothing);

    await tester.tap(find.text('Back to Play'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayHubPage), findsOneWidget);

    await tester.ensureVisible(find.byKey(PlayHub.masteryResultsKey));
    await tester.tap(find.byKey(PlayHub.masteryResultsKey));
    await tester.pumpAndSettle();
    expect(find.byType(GameMasteryResultsScreen), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(GameMasteryResultsScreen)),
      )!.settings.name,
      '/play/mastery-results',
    );
    expect(find.byKey(GameMasteryResultsScreen.emptyKey), findsOneWidget);
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.byKey(GameMasteryResultsScreen.scoreKey), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.text('80'), findsNothing);
    expect(find.text('100'), findsNothing);
  });

  testWidgets('an empty Tone Forge stays empty and an error clears the score', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(_host(const ToneForgeScreen.play()));
    await tester.pumpAndSettle();
    expect(find.byType(LingEmptyState), findsOneWidget);
    expect(find.text('No word is ready.'), findsOneWidget);
    expect(find.byKey(ToneForgeScreen.scoreKey), findsNothing);
    expect(find.text('E kaaro'), findsNothing);

    await tester.pumpWidget(_host(_scoredForge()));
    await tester.pumpAndSettle();
    expect(find.byKey(ToneForgeScreen.scoreKey), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('E kaaro'), findsOneWidget);
    expect(find.text('80%'), findsNothing);
    expect(find.text('100%'), findsNothing);

    await tester.pumpWidget(
      _host(
        ToneForgeScreen.play(
          loadRound: () async => throw const ToneForgeUnavailable(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('50%'), findsNothing);
    expect(find.text('E kaaro'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(LingErrorState), findsOneWidget);
    expect(find.byKey(ToneForgeScreen.errorKey), findsOneWidget);
    expect(find.byKey(ToneForgeScreen.scoreKey), findsNothing);
    expect(find.text('50%'), findsNothing);
    expect(find.text('E kaaro'), findsNothing);
    expect(find.text('The word did not come back.'), findsOneWidget);
  });

  testWidgets('a real Tone Forge score shows and unsure shows no number', (
    tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(_host(_scoredForge()));
    await tester.pumpAndSettle();
    expect(find.text('Score'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byKey(ToneForgeScreen.unsureKey), findsNothing);

    await tester.pumpWidget(
      _host(
        ToneForgeScreen.play(
          loadRound: () async => _round,
          scoreAttempt: (_) async => GameScore.unsure(message: 'unsure'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('50%'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(ToneForgeScreen.unsureKey), findsOneWidget);
    expect(find.text(_unsureCopy), findsOneWidget);
    expect(find.byKey(ToneForgeScreen.scoreKey), findsNothing);
    _expectNoPlaceholder(tester);

    await tester.pumpWidget(
      _host(
        ToneForgeScreen.play(
          loadRound: () async => _round,
          scoreAttempt: (_) async => GameScore.scorerError(message: 'down'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ToneForgeScreen.unsureKey), findsOneWidget);
    expect(find.text(_unsureCopy), findsOneWidget);
    _expectNoPlaceholder(tester);

    await tester.pumpWidget(
      _host(
        ToneForgeScreen.play(
          loadRound: () async => _round,
          scoreAttempt: (_) async => GameScore.correct(accuracy: 0.8),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ToneForgeScreen.unsureKey), findsOneWidget);
    expect(find.text('80%'), findsNothing);
    expect(find.text('80'), findsNothing);
    _expectNoPlaceholder(tester);
  });

  testWidgets(
    'mastery results stay empty, clear on error, and hide an unsure number',
    (tester) async {
      _wide(tester);
      await tester.pumpWidget(_host(const GameMasteryResultsScreen.play()));
      await tester.pumpAndSettle();
      expect(find.byType(LingEmptyState), findsOneWidget);
      expect(find.text('No round is ready.'), findsOneWidget);
      expect(find.byKey(GameMasteryResultsScreen.scoreKey), findsNothing);

      await tester.pumpWidget(_host(_scoredMastery()));
      await tester.pumpAndSettle();
      expect(find.text('50%'), findsOneWidget);
      expect(find.byKey(GameMasteryResultsScreen.scoreKey), findsOneWidget);

      await tester.pumpWidget(
        _host(
          GameMasteryResultsScreen.play(
            load: () async => throw const MasteryResultsUnavailable(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('50%'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(LingErrorState), findsOneWidget);
      expect(find.byKey(GameMasteryResultsScreen.errorKey), findsOneWidget);
      expect(find.text('50%'), findsNothing);
      expect(find.text('The round did not come back.'), findsOneWidget);
      _expectNoPlaceholder(tester);

      await tester.pumpWidget(
        _host(
          GameMasteryResultsScreen.play(
            load: () async => GameScore.unsure(message: 'unsure'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(GameMasteryResultsScreen.unsureKey), findsOneWidget);
      expect(find.text(_unsureCopy), findsOneWidget);
      expect(find.byKey(GameMasteryResultsScreen.scoreKey), findsNothing);
      _expectNoPlaceholder(tester);

      await tester.pumpWidget(
        _host(
          GameMasteryResultsScreen.play(
            load: () async => GameScore.correct(accuracy: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(GameMasteryResultsScreen.unsureKey), findsOneWidget);
      expect(find.text('100%'), findsNothing);
      expect(find.text('100'), findsNothing);
      _expectNoPlaceholder(tester);
    },
  );
}

ToneForgeScreen _scoredForge() {
  return ToneForgeScreen.play(
    loadRound: () async => _round,
    scoreAttempt: (_) async => GameScore(
      accuracy: 0.5,
      isPerfect: false,
      isFail: false,
      countsForRewards: true,
      source: GameScoreSource.realScorer,
    ),
  );
}

GameMasteryResultsScreen _scoredMastery() {
  return GameMasteryResultsScreen.play(
    load: () async => GameScore(
      accuracy: 0.5,
      isPerfect: false,
      isFail: false,
      countsForRewards: true,
      source: GameScoreSource.realScorer,
    ),
  );
}

void _expectNoPlaceholder(WidgetTester tester) {
  expect(find.text('0'), findsNothing);
  expect(find.text('0%'), findsNothing);
  expect(find.text('80'), findsNothing);
  expect(find.text('80%'), findsNothing);
  expect(find.text('100'), findsNothing);
  expect(find.text('100%'), findsNothing);
}

Set<String> _reachableFrom(String entry) {
  final Set<String> seen = <String>{};
  final List<String> queue = <String>[entry];
  final RegExp importRe = RegExp('''(?:import|export)\\s+['"]([^'"]+)['"]''');
  while (queue.isNotEmpty) {
    final String rel = queue.removeLast();
    if (!seen.add(rel)) continue;
    final File file = File(rel);
    if (!file.existsSync()) continue;
    final String source = file.readAsStringSync();
    for (final RegExpMatch match in importRe.allMatches(source)) {
      final String? next = _resolveImport(rel, match.group(1)!);
      if (next != null && File(next).existsSync()) queue.add(next);
    }
  }
  return seen;
}

String? _resolveImport(String fromRel, String spec) {
  if (spec.startsWith('dart:') || spec.startsWith('package:flutter')) {
    return null;
  }
  if (spec.startsWith('package:lingafriq/')) {
    return 'lib/${spec.substring('package:lingafriq/'.length)}';
  }
  if (spec.startsWith('package:')) return null;
  final String path = Uri.parse(fromRel).resolve(spec).path;
  final String normalized = path.startsWith('/') ? path.substring(1) : path;
  if (!normalized.startsWith('lib/') || !normalized.endsWith('.dart')) {
    return null;
  }
  return normalized;
}

void _wide(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _host(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
