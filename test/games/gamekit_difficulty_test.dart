import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_difficulty.dart';
import 'package:lingafriq/games/gamekit/game_engine.dart';
import 'package:lingafriq/games/gamekit/game_animation_bridge.dart';
import 'package:lingafriq/games/gamekit/game_feedback.dart';
import 'package:lingafriq/games/gamekit/game_result.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';
import 'package:lingafriq/games/gamekit/game_turn_context.dart';
import 'package:lingafriq/learning/adaptive/difficulty_controller.dart';

void main() {
  final engine = AdaptiveGameDifficultyEngine();
  final base = DateTime(2026, 1, 1);

  GameSession session({List<GameTurnResult> turns = const [], int step = 5}) {
    return GameSession(
      sessionId: 's',
      userId: 'u',
      gameId: 'tone_forge',
      language: 'yo',
      startTime: base,
      turns: turns,
      metadata: {kGameKitDifficultyStepKey: step},
    );
  }

  GameTurnContext ctx(GameSession s) => GameTurnContext(
        content: null,
        input: null,
        session: s,
      );

  GameTurnResult turn({required bool correct}) => GameTurnResult(
        score: correct ? GameScore.correct() : GameScore.incorrect(),
        feedback: GameFeedback(message: 'ok', animationEvent: AnimationEvent.idle),
        difficultyUpdate: GameDifficultyUpdate.maintain(),
        timestamp: base,
      );

  group('AdaptiveGameDifficultyEngine thresholds', () {
    test('holds step inside 80–85% band', () {
      final history = [
        for (var i = 0; i < 9; i++) turn(correct: i < 7),
      ];
      final s = session(turns: history, step: 4);
      final update = engine.adjust(ctx(s), GameScore.correct());
      expect(update.action, 'maintain');
      expect(update.difficultyStep, 4);
    });

    test('steps down below 80%', () {
      final history = [
        for (var i = 0; i < 9; i++) turn(correct: i < 6),
      ];
      final s = session(turns: history, step: 6);
      final update = engine.adjust(ctx(s), GameScore.incorrect());
      expect(update.action, 'decrease');
      expect(update.difficultyStep, 5);
    });

    test('steps up above 85%', () {
      final history = List.generate(9, (_) => turn(correct: true));
      final s = session(turns: history, step: 3);
      final update = engine.adjust(ctx(s), GameScore.correct());
      expect(update.action, 'increase');
      expect(update.difficultyStep, 4);
    });

    test('cold start: no adjust until 5 turns resolved', () {
      final s = session(turns: List.generate(4, (_) => turn(correct: false)), step: 2);
      final update = engine.adjust(ctx(s), GameScore.incorrect());
      expect(update.action, 'maintain');
      expect(update.difficultyStep, 2);
    });
  });

  group('GameEngine resolveWithSession', () {
    test('persists difficulty step on session', () async {
      final gameEngine = GameEngine(
        scoring: DefaultGameScoringEngine(),
        difficulty: DefaultGameDifficultyEngine(),
        feedback: DefaultGameFeedbackEngine(),
        animation: GameAnimationBridge(),
      );
      var s = session(
        turns: List.generate(5, (_) => turn(correct: false)),
        step: 4,
      );
      final resolved = await gameEngine.resolveWithSession(ctx(s));
      expect(resolved.result.difficultyUpdate.action, 'decrease');
      expect(
        GameSessionDifficulty.currentStep(resolved.session),
        lessThan(4),
      );
    });
  });

  group('1000-session simulation', () {
    test('mean success lands in 80–85% for ability bands', () {
      final rng = Random(905);
      const sessionsPerBand = 1000;
      const turnsPerSession = 40;
      final abilities = [0.25, 0.45, 0.55, 0.75];

      for (final ability in abilities) {
        var totalSuccess = 0;
        var totalAttempts = 0;
        for (var s = 0; s < sessionsPerBand; s++) {
          var step = GameSessionDifficulty.stepFromMastery(ability);
          var turns = <GameTurnResult>[];
          for (var t = 0; t < turnsPerSession; t++) {
            final p = gameKitSuccessProbability(
              difficultyStep: step,
              learnerAbility: ability,
            );
            final correct = rng.nextDouble() < p;
            if (t >= kGameKitDifficultyWarmupTurns + kGameKitDifficultyWindow) {
              totalSuccess += correct ? 1 : 0;
              totalAttempts++;
            }

            final sessionState = session(turns: turns, step: step);
            final score =
                correct ? GameScore.correct() : GameScore.incorrect();
            final update = engine.adjust(ctx(sessionState), score);
            step = update.difficultyStep ?? step;
            turns = [
              ...turns,
              turn(correct: correct),
            ];
          }
        }
        final rate = totalSuccess / totalAttempts;
        expect(
          rate,
          inInclusiveRange(kTargetSuccessMin - 0.07, kTargetSuccessMax + 0.05),
          reason: 'ability $ability rate $rate',
        );
      }
    });
  });
}
