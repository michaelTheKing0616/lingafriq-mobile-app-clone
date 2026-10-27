import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_animation_bridge.dart';
import 'package:lingafriq/games/gamekit/game_difficulty.dart';
import 'package:lingafriq/games/gamekit/game_engine.dart';
import 'package:lingafriq/games/gamekit/game_feedback.dart';
import 'package:lingafriq/games/gamekit/game_result.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';
import 'package:lingafriq/games/gamekit/game_turn_context.dart';
import 'package:lingafriq/games/learning_game_adapter.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/services/learning/spaced_repetition_service.dart';

class _NoopAnimationBridge extends GameAnimationBridge {
  @override
  void emit(AnimationEvent event, GameScore score) {}
}

void main() {
  late GameEngine engine;
  late GameKitLearnerGraphWriter writer;
  late LearnerModelService learner;
  late SpacedRepetitionService srs;

  setUp(() async {
    engine = GameEngine.defaultEngine(_NoopAnimationBridge());
    learner = LearnerModelService.instance;
    learner.resetPracticeEventStateForTests();
    await learner.initialize();
    srs = SpacedRepetitionService();
    srs.clearUserCards('u_graph');
    writer = GameKitLearnerGraphWriter(
      learnerModel: learner,
      spacedRepetition: srs,
    );
  });

  GameSession baseSession() => GameSession(
        sessionId: 'sess_k',
        userId: 'u_graph',
        gameId: 'tone_trainer',
        language: 'yo',
        startTime: DateTime.now(),
        turnQueue: ['item_a', 'item_b'],
      );

  GameTurnContext ctx(GameSession session, {int queueIndex = 0}) {
    return GameTurnContext(
      content: const {},
      input: const {},
      session: session,
      queueIndex: queueIndex,
      metadata: const {'skillId': 'yo_vocab_weak'},
    );
  }

  test('event shape and session holds K events after K turns', () async {
    var session = baseSession().copyWith(sessionId: 'sess_shape');
    for (var i = 0; i < 3; i++) {
      final resolution = await engine.resolveTurnRecording(
        writer,
        ctx(session, queueIndex: i),
        turnId: 'turn_$i',
      );
      session = resolution.session;
    }
    expect(session.learnerEventsRecorded, 3);
    final events = learner.eventsForSession('sess_shape');
    expect(events.length, 3);
    expect(events.first.itemId, 'item_a');
    expect(events.first.skillId, 'yo_vocab_weak');
    expect(events.first.wasCorrect, isA<bool>());
    expect(events.first.timestamp, isA<DateTime>());
  });

  test('dedupe by turn id on flush', () async {
    var session = baseSession().copyWith(sessionId: 'sess_dup');
    const turnId = 'turn_dup';
    session = await writer.recordTurn(
      session: session,
      context: ctx(session),
      result: GameTurnResult(
        score: GameScore(accuracy: 0.95, isPerfect: true, isFail: false),
        feedback: GameFeedback.success(
          message: 'ok',
          animationEvent: AnimationEvent.happy,
        ),
        difficultyUpdate: GameDifficultyUpdate.maintain(),
        timestamp: DateTime.now(),
      ),
      turnId: turnId,
      queueOnly: true,
    );
    session = await writer.recordTurn(
      session: session,
      context: ctx(session),
      result: GameTurnResult(
        score: GameScore(accuracy: 0.95, isPerfect: true, isFail: false),
        feedback: GameFeedback.success(
          message: 'ok',
          animationEvent: AnimationEvent.happy,
        ),
        difficultyUpdate: GameDifficultyUpdate.maintain(),
        timestamp: DateTime.now(),
      ),
      turnId: turnId,
      queueOnly: true,
    );
    expect(learner.pendingPracticeEventCount(), 1);
    final applied = await writer.flushOfflineQueue();
    expect(applied, 1);
    expect(learner.eventsForSession('sess_dup').length, 1);
    final appliedAgain = await writer.flushOfflineQueue();
    expect(appliedAgain, 0);
  });

  test('SRS parity uses shared quality mapping', () {
    final lessonQ = srs.qualityFromPracticeOutcome(wasCorrect: true, accuracy: 0.92);
    final gameQ = GameKitPracticeRecorder.srsQuality(wasCorrect: true, accuracy: 0.92);
    expect(gameQ, lessonQ);
  });

  test('offline queue then sync applies SRS', () async {
    const userId = 'u_offline_srs';
    srs.clearUserCards(userId);
    final session = baseSession().copyWith(sessionId: 'sess_offline', userId: userId);
    final before = srs.getOrCreateCard(userId, 'item_a');
    await writer.recordTurn(
      session: session,
      context: ctx(session),
      result: GameTurnResult(
        score: GameScore(accuracy: 1.0, isPerfect: true, isFail: false),
        feedback: GameFeedback.success(
          message: 'ok',
          animationEvent: AnimationEvent.happy,
        ),
        difficultyUpdate: GameDifficultyUpdate.maintain(),
        timestamp: DateTime.now(),
      ),
      turnId: 'turn_offline',
      queueOnly: true,
    );
    expect(learner.pendingPracticeEventCount(), 1);
    await writer.flushOfflineQueue();
    final after = srs.getOrCreateCard(userId, 'item_a');
    expect(after.repetitions, greaterThanOrEqualTo(before.repetitions));
  });
}
