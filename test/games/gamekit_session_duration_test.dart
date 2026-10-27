import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/all_games_registry.dart';
import 'package:lingafriq/games/gamekit/game_engine.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';

void main() {
  setUp(() {
    GameKitCatalog.clear();
  });

  group('GameKitSessionDuration', () {
    test('clamps planned duration into 60–180 s', () {
      expect(GameKitSessionDuration.clampPlanned(null), 120);
      expect(GameKitSessionDuration.clampPlanned(30), 60);
      expect(GameKitSessionDuration.clampPlanned(90), 90);
      expect(GameKitSessionDuration.clampPlanned(240), 180);
    });
  });

  group('GameManifest core verb', () {
    test('rejects manifest without practice target', () {
      expect(
        () => GameKitCatalog.register(
          GameManifest(
            gameId: 'x',
            practiceTargets: {},
            coreVerb: GameCoreVerb.choose,
          ),
        ),
        throwsA(isA<GameManifestError>()),
      );
    });

    test('requires exactly one allowed core verb', () {
      GameKitCatalog.register(
        GameManifest(
          gameId: 'minimal_pair',
          practiceTargets: {GamePracticeTarget.perception},
          coreVerb: GameCoreVerb.choose,
        ),
      );
      expect(
        GameKitCatalog.manifestFor('minimal_pair')?.coreVerb,
        GameCoreVerb.choose,
      );
    });
  });

  group('GameSessionClock', () {
    final base = DateTime(2026, 1, 1, 12, 0, 0);

    GameSession session({required int plannedSeconds}) => GameSession(
          sessionId: 's',
          userId: 'u',
          gameId: 'g',
          language: 'yo',
          startTime: base,
          plannedDurationSeconds: plannedSeconds,
        );

    test('allows turn before planned end', () {
      final s = session(plannedSeconds: 90);
      expect(GameSessionClock.mayBeginTurn(s, base.add(const Duration(seconds: 30))),
          isTrue);
    });

    test('blocks new turn after planned end but finishes in-flight turn', () {
      final s = session(plannedSeconds: 60);
      final afterPlanned = base.add(const Duration(seconds: 61));
      expect(GameSessionClock.mayBeginTurn(s, afterPlanned), isFalse);
      expect(
        GameSessionClock.mayBeginTurn(s, afterPlanned, turnInProgress: true),
        isTrue,
      );
      expect(GameSessionClock.shouldShowResultsAfterTurn(s, afterPlanned), isTrue);
    });

    test('hard-stops new turns at 180 s', () {
      final s = session(plannedSeconds: 180);
      final t = base.add(const Duration(seconds: 181));
      expect(GameSessionClock.mayBeginTurn(s, t), isFalse);
    });
  });

  group('GameSessionDurationReport', () {
    test('flags games whose median session is outside 60–180 s', () {
      final report = GameSessionDurationReport.fromSamples([
        (gameId: 'good_game', durationSeconds: 90),
        (gameId: 'good_game', durationSeconds: 100),
        (gameId: 'short_game', durationSeconds: 40),
        (gameId: 'short_game', durationSeconds: 50),
        (gameId: 'long_game', durationSeconds: 200),
        (gameId: 'long_game', durationSeconds: 210),
      ]);
      expect(report.flaggedGameIds, containsAll(['short_game', 'long_game']));
      expect(report.flaggedGameIds, isNot(contains('good_game')));
    });
  });

  group('AllGamesRegistry manifests', () {
    test('every catalog game registers with one core verb', () {
      AllGamesRegistry.registerGameKitManifests();
      for (final id in AllGamesRegistry.getAllGameIds()) {
        final def = AllGamesRegistry.getGame(id);
        if (def == null) continue;
        final manifest = GameKitCatalog.manifestFor(def.gameId);
        expect(manifest, isNotNull, reason: def.gameId);
        expect(GameManifest.allowedCoreVerbs.contains(manifest!.coreVerb), isTrue);
      }
    });
  });
}
