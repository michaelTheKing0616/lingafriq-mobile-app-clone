import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_animation_bridge.dart';
import 'package:lingafriq/games/gamekit/game_difficulty.dart';
import 'package:lingafriq/games/gamekit/game_engine.dart';
import 'package:lingafriq/games/gamekit/game_feedback.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';

class _NoopAnimationBridge extends GameAnimationBridge {
  @override
  void emit(AnimationEvent event, GameScore score) {}
}

void main() {
  setUp(() {
    GameKitCatalog.clear();
  });

  group('GameKit manifest registration', () {
    test('rejects manifest without practice target', () {
      expect(
        () => GameKitCatalog.register(
          const GameManifest(gameId: 'bad_game', practiceTargets: {}),
        ),
        throwsA(isA<GameManifestError>()),
      );
    });

    test('accepts retrieval target', () {
      GameKitCatalog.register(
        const GameManifest(
          gameId: 'tone_trainer',
          practiceTargets: {GamePracticeTarget.perception},
        ),
      );
      expect(GameKitCatalog.isRegistered('tone_trainer'), isTrue);
    });
  });

  group('GameTurnQueuePlanner due-first', () {
    test('serves due items before fallback fillers', () async {
      final learner = LearnerModelService.instance;
      await learner.initialize();
      const userId = 'u_due_first';
      const lang = 'yo';
      await learner.recordAttempt(
        learnerId: userId,
        skillId: 'yo_vocab_weak',
        wasCorrect: false,
      );
      await learner.recordAttempt(
        learnerId: userId,
        skillId: 'yo_vocab_strong',
        wasCorrect: true,
      );

      final planner = GameTurnQueuePlanner(learnerModel: learner);
      planner.dueItemIdsOverride = (_, __) async => ['due_a', 'due_b'];

      final plan = await planner.buildQueue(
        userId: userId,
        languageCode: lang,
        queueLength: 4,
      );

      expect(plan.dueItemsServed, 2);
      expect(plan.itemIds.take(2), ['due_a', 'due_b']);
      expect(plan.itemIds.length, lessThanOrEqualTo(4));
      expect(plan.source, GameQueueSource.due);
    });

    test('zero due uses fallback source', () async {
      final learner = LearnerModelService.instance;
      await learner.initialize();
      const userId = 'u_fallback';
      await learner.recordAttempt(
        learnerId: userId,
        skillId: 'yo_skill_a',
        wasCorrect: false,
      );

      final planner = GameTurnQueuePlanner(learnerModel: learner);
      planner.dueItemIdsOverride = (_, __) async => [];

      final plan = await planner.buildQueue(
        userId: userId,
        languageCode: 'yo',
        queueLength: 3,
      );

      expect(plan.dueItemsServed, 0);
      expect(plan.source, GameQueueSource.fallback);
    });

    test('due query failure returns retry plan', () async {
      final planner = GameTurnQueuePlanner();
      planner.dueItemIdsOverride = (_, __) async {
        throw StateError('offline');
      };

      final plan = await planner.buildQueue(
        userId: 'u_err',
        languageCode: 'yo',
        queueLength: 5,
      );

      expect(plan.loadFailed, isTrue);
      expect(plan.itemIds, isEmpty);
    });
  });

  group('GameEngine.startSessionWithQueue', () {
    test('marks session retry when due query fails', () async {
      GameKitCatalog.register(
        const GameManifest(
          gameId: 'wordmatch_audio',
          practiceTargets: {GamePracticeTarget.retrieval},
        ),
      );
      final planner = GameTurnQueuePlanner();
      planner.dueItemIdsOverride = (_, __) async {
        throw Exception('db down');
      };
      final engine = GameEngine(
        scoring: DefaultGameScoringEngine(),
        difficulty: DefaultGameDifficultyEngine(),
        feedback: DefaultGameFeedbackEngine(),
        animation: _NoopAnimationBridge(),
        queuePlanner: planner,
      );

      final session = await engine.startSessionWithQueue(
        sessionId: 's1',
        userId: 'u1',
        gameId: 'wordmatch_audio',
        languageCode: 'yo',
      );

      expect(session.needsQueueRetry, isTrue);
      expect(session.turnQueue, isEmpty);
    });
  });
}
