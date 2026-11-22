import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/db/app_database.dart';
import 'package:lingafriq/games/gamekit/game_difficulty.dart';
import 'package:lingafriq/games/gamekit/game_feedback.dart';
import 'package:lingafriq/games/gamekit/game_result.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/games/gamekit/game_session.dart' as gamekit;
import 'package:lingafriq/games/learning_game_adapter.dart';
import 'package:lingafriq/games/minimal_pair_duel/minimal_pair_duel_screen.dart';
import 'package:lingafriq/games/tone_forge/tone_forge_screen.dart';
import 'package:lingafriq/games/word_forge/word_forge_screen.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/models/game/game_session_model.dart' show GameType;
import 'package:lingafriq/navigation/practice_formats.dart';
import 'package:lingafriq/services/learning/learning_event_log.dart';
import 'package:lingafriq/services/sync/outbox_service.dart';

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

GameTurnResult _turn(GameScore score) {
  return GameTurnResult(
    score: score,
    feedback: GameFeedback.neutral(
      message: 'recorded',
      animationEvent: AnimationEvent.idle,
    ),
    difficultyUpdate: GameDifficultyUpdate.maintain(),
    timestamp: DateTime.utc(2026, 4, 1, 0, 2),
  );
}

gamekit.GameSession _session({
  List<GameTurnResult>? turns,
  List<String> turnQueue = const <String>['yo-tone-1'],
  String gameId = 'tone_forge',
}) {
  return gamekit.GameSession(
    sessionId: 'session-1',
    userId: 'learner-1',
    gameId: gameId,
    language: 'yo',
    startTime: DateTime.utc(2026, 4, 1),
    turns: turns ?? <GameTurnResult>[_turn(GameScore.correct(accuracy: 0.8))],
    turnQueue: turnQueue,
  );
}

PracticePlanItem _gameItem({String gameId = 'tone_forge'}) {
  return PracticePlanItem(
    id: 'plan-1',
    type: PracticePlanItemType.game,
    gameId: gameId,
    itemIds: const <String>['yo-tone-1'],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Today and Path open the same GameKit game as Play', () {
    const PracticePlanItem lesson = PracticePlanItem(
      id: 'lesson-1',
      type: PracticePlanItemType.lesson,
    );
    expect(
      openPracticeGame(
        item: lesson,
        origin: PracticeOrigin.today,
        language: 'yo',
        enqueue: _unusedEnqueue,
        clientEventId: 'evt-lesson',
      ),
      isNull,
    );

    for (final PracticeOrigin origin in PracticeOrigin.values) {
      final PracticeGameHost? opened = openPracticeGame(
        item: _gameItem(),
        origin: origin,
        language: 'yo',
        enqueue: _unusedEnqueue,
        clientEventId: 'evt-tone',
      );
      final Widget? play = playGameWidget(gameId: 'tone_forge', language: 'yo');
      expect(opened, isNotNull);
      expect(play, isA<ToneForgeScreen>());
      expect(opened!.game, isA<ToneForgeScreen>());
      expect(opened.game.runtimeType, play.runtimeType);
      expect((opened.game as ToneForgeScreen).language, 'yo');
      expect((play as ToneForgeScreen).language, 'yo');
    }

    final PracticeGameHost? jam = openPracticeGame(
      item: _gameItem(gameId: 'grammar_jam'),
      origin: PracticeOrigin.path,
      language: 'sw',
      enqueue: _unusedEnqueue,
      clientEventId: 'evt-jam',
    );
    final Widget? playJam = playGameWidget(
      gameId: 'grammar_jam',
      language: 'sw',
    );
    expect(jam!.game, isA<WordForgeScreen>());
    expect(jam.game.runtimeType, playJam.runtimeType);
    expect((jam.game as WordForgeScreen).language, 'sw');

    final PracticeGameHost? duel = openPracticeGame(
      item: _gameItem(gameId: 'minimal_pair_duel'),
      origin: PracticeOrigin.today,
      language: 'yo',
      enqueue: _unusedEnqueue,
      clientEventId: 'evt-duel',
    );
    expect(duel!.game, isA<MinimalPairDuelScreen>());
    expect(
      duel.game.runtimeType,
      playGameWidget(gameId: 'minimal_pair_duel', language: 'yo').runtimeType,
    );

    final PracticeGameHost? routed = openPracticeGame(
      item: _gameItem(gameId: 'speed_round'),
      origin: PracticeOrigin.path,
      language: 'yo',
      enqueue: _unusedEnqueue,
      clientEventId: 'evt-speed',
    );
    final Widget? playRouted = playGameWidget(
      gameId: 'speed_round_remix',
      language: 'yo',
    );
    expect(routed!.game, isA<PlayRoutedGame>());
    expect(routed.game.runtimeType, playRouted.runtimeType);
    expect((routed.game as PlayRoutedGame).gameType, GameType.speedRoundRemix);
    expect((playRouted as PlayRoutedGame).gameType, GameType.speedRoundRemix);

    expect(playGameWidget(gameId: 'not-a-game', language: 'yo'), isNull);
    expect(
      openPracticeGame(
        item: _gameItem(gameId: 'script_sprint'),
        origin: PracticeOrigin.today,
        language: 'yo',
        enqueue: _unusedEnqueue,
        clientEventId: 'evt-script',
      ),
      isNull,
    );
  });

  test('a finished game writes item ids and outcome to the outbox', () async {
    final db = LingAfriqDatabase.memory();
    addTearDown(db.close);
    final OutboxService outbox = OutboxService(
      clock: () => DateTime.utc(2026, 4, 1),
      newId: () => 'op-practice',
    );
    await outbox.open(db);

    final gamekit.GameSession session = _session(
      turns: <GameTurnResult>[
        _turn(GameScore.correct(accuracy: 0.8, perfect: false)),
        _turn(GameScore.unsure(message: 'unclear')),
      ],
      turnQueue: const <String>['yo-tone-1', 'yo-tone-2'],
    );
    final PracticeLearnerEvent? event = practiceLearnerEventFromSession(
      session: session,
      clientEventId: 'evt-1',
      planItemId: 'plan-1',
      planItemIds: const <String>['yo-tone-1', 'yo-tone-2'],
      origin: PracticeOrigin.today.name,
    );
    expect(event, isNotNull);

    final Map<String, dynamic> payload = event!.toOutboxPayload();
    expect(payload['source'], practiceLearnerEventSource);
    expect(payload['clientEventId'], 'evt-1');
    expect(payload['language'], 'yo');
    final Map<String, dynamic> body =
        payload['payload'] as Map<String, dynamic>;
    expect(body['itemIds'], <String>['yo-tone-1', 'yo-tone-2']);
    expect(body['gameId'], 'tone_forge');
    expect(body['learnerId'], 'learner-1');
    expect(body['planItemId'], 'plan-1');
    expect(body['origin'], 'today');
    final List<dynamic> items =
        (body['outcome'] as Map<String, dynamic>)['items'] as List<dynamic>;
    final Map<String, dynamic> scored = items[0] as Map<String, dynamic>;
    final Map<String, dynamic> unsure = items[1] as Map<String, dynamic>;
    expect(scored['itemId'], 'yo-tone-1');
    expect(scored['scored'], isTrue);
    expect(scored['wasCorrect'], isTrue);
    expect(scored['accuracy'], 0.8);
    expect(unsure['itemId'], 'yo-tone-2');
    expect(unsure['scored'], isFalse);
    expect(unsure.containsKey('wasCorrect'), isFalse);
    expect(unsure.containsKey('accuracy'), isFalse);
    expect(body.containsKey('score'), isFalse);
    final LearningEventLog log = LearningEventLog();
    expect(log.apply(event.toLearningEvent()), isTrue);
    expect(log.apply(event.toLearningEvent()), isFalse);

    final PracticeOutboxSave save = await writePracticeLearnerEventToOutbox(
      outbox: outbox,
      event: event,
    );
    expect(save.saved, isTrue);
    expect(save.operationId, 'op-practice');
    expect(outbox.pendingCount, 1);
    final OutboxRecord? row = outbox.byId('op-practice');
    expect(row, isNotNull);
    expect(row!.type, practiceLearnerOutboxType);
    expect(row.idempotencyKey, 'evt-1');
    expect(row.payload['source'], 'game');
    final Map<String, dynamic> stored =
        row.payload['payload'] as Map<String, dynamic>;
    expect(stored['itemIds'], <String>['yo-tone-1', 'yo-tone-2']);
    expect(
      ((stored['outcome'] as Map)['items'] as List).first['wasCorrect'],
      isTrue,
    );
  });

  test('a session with no real item ids is not saved', () async {
    final PracticeLearnerEvent? event = practiceLearnerEventFromSession(
      session: _session(turns: <GameTurnResult>[], turnQueue: const <String>[]),
      clientEventId: 'evt-empty',
    );
    expect(event, isNull);

    final PracticeLearnerEvent? missing = practiceLearnerEventFromSession(
      session: _session(turnQueue: const <String>[]),
      clientEventId: 'evt-missing',
      planItemIds: const <String>[],
    );
    expect(missing, isNull);
  });

  testWidgets('a failed outbox write shows retry and does not claim success', (
    WidgetTester tester,
  ) async {
    final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));
    var calls = 0;
    Map<String, dynamic>? written;
    final PracticeGameHost? page = openPracticeGame(
      item: _gameItem(),
      origin: PracticeOrigin.path,
      language: 'yo',
      clientEventId: 'evt-retry',
      endedSession: _session(),
      enqueue:
          ({
            required String type,
            required Map<String, dynamic> payload,
            String? idempotencyKey,
          }) async {
            calls += 1;
            written = payload;
            if (calls == 1) throw StateError('disk');
            return 'op-retry';
          },
    );

    await tester.pumpWidget(_host(page!, scale: 2, reduced: true));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.byKey(PracticeGameMarks.saveFailed), findsOneWidget);
    expect(find.text(l10n.practiceGameSaveFailedWhat), findsWidgets);
    expect(find.text(l10n.practiceGameRetry), findsOneWidget);
    expect(find.text(l10n.practiceGameSaved), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(
      find.bySemanticsLabel(l10n.practiceGameSaveFailedWhat),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
    final Map<String, dynamic> body =
        written!['payload'] as Map<String, dynamic>;
    expect(body['itemIds'], <String>['yo-tone-1']);
    expect(body['origin'], 'path');
    expect(((body['outcome'] as Map)['items'] as List).first['accuracy'], 0.8);

    await tester.tap(find.text(l10n.practiceGameRetry));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.byKey(PracticeGameMarks.saved), findsOneWidget);
    expect(find.text(l10n.practiceGameSaved), findsOneWidget);
    expect(find.byKey(PracticeGameMarks.saveFailed), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a game that is still playing does not claim a save', (
    WidgetTester tester,
  ) async {
    final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));
    const Key gameKey = ValueKey<String>('practice-game-screen');
    final PracticeGameHost page = PracticeGameHost(
      game: const SizedBox.shrink(key: gameKey),
      item: _gameItem(),
      origin: PracticeOrigin.today,
      clientEventId: 'evt-playing',
      enqueue: _unusedEnqueue,
    );

    await tester.pumpWidget(_host(page, scale: 2, reduced: true));
    await tester.pumpAndSettle();

    expect(find.byKey(PracticeGameMarks.playing), findsOneWidget);
    expect(find.byKey(gameKey), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.practiceGamePlayingLabel),
      findsOneWidget,
    );
    expect(find.byKey(PracticeGameMarks.saved), findsNothing);
    expect(find.byKey(PracticeGameMarks.saveFailed), findsNothing);
    expect(find.text(l10n.practiceGameSaved), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an ended game with nothing to record does not claim a save', (
    WidgetTester tester,
  ) async {
    final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));
    var calls = 0;
    final PracticeGameHost page = PracticeGameHost(
      game: const SizedBox.shrink(),
      item: _gameItem(),
      origin: PracticeOrigin.today,
      clientEventId: 'evt-none',
      endedSession: _session(
        turns: const <GameTurnResult>[],
        turnQueue: const <String>[],
      ),
      enqueue:
          ({
            required String type,
            required Map<String, dynamic> payload,
            String? idempotencyKey,
          }) async {
            calls += 1;
            return 'should-not-run';
          },
    );

    await tester.pumpWidget(_host(page));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.byKey(PracticeGameMarks.saveFailed), findsOneWidget);
    expect(find.text(l10n.practiceGameSaved), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });
}

Future<String> _unusedEnqueue({
  required String type,
  required Map<String, dynamic> payload,
  String? idempotencyKey,
}) async {
  return 'unused';
}
