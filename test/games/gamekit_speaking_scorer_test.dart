import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_difficulty.dart';
import 'package:lingafriq/games/gamekit/game_feedback.dart';
import 'package:lingafriq/games/gamekit/game_result.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';
import 'package:lingafriq/games/gamekit/game_turn_context.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/screens/pronunciation/tone_overlay_view.dart';
import 'package:lingafriq/services/lens/lens_scoring_client.dart';

void main() {
  group('gameScoreFromScorerResponse', () {
    test('unsure offers retry and no reward eligibility', () {
      final score = gameScoreFromScorerResponse(
        body: {'scorer_version': 'p6-038', 'confidence': 0.55},
        outcome: LensScoreOutcome(
          phase: ToneOverlayStatus.unsure,
          errorMessage: 'retry',
        ),
      );
      expect(score.isUnsure, isTrue);
      expect(score.countsForRewards, isFalse);
      expect(score.isCorrect, isFalse);
      expect(score.scorerTrace?['scorer_version'], 'p6-038');
    });

    test('scored turn uses syllable correctness only', () {
      final score = gameScoreFromScorerResponse(
        body: {
          'scorer_version': 'p6-038',
          'confidence': 0.82,
          'phones': [
            {'phone': 'o', 'gop': 0.9},
          ],
        },
        outcome: LensScoreOutcome(
          phase: ToneOverlayStatus.scored,
          syllables: [
            SyllableToneOverlayRow(
              label: 'ọ',
              expectedToneLabel: 'M',
              correct: true,
              nativeContour: const [0, 1],
              learnerContour: const [0, 1],
            ),
            SyllableToneOverlayRow(
              label: 'kọ̀',
              expectedToneLabel: 'L',
              correct: false,
              nativeContour: const [1, 0],
              learnerContour: const [0, 0],
            ),
          ],
          celebrate: false,
        ),
      );
      expect(score.accuracy, 0.5);
      expect(score.isCorrect, isFalse);
      expect(score.countsForRewards, isTrue);
      expect(score.scorerTrace?['phones'], isNotEmpty);
    });

    test('unavailable scorer enables honest practice', () {
      final score = gameScoreFromScorerResponse(
        body: const {},
        outcome: LensScoreOutcome(
          phase: ToneOverlayStatus.error,
          errorMessage: 'down',
          retryable: true,
        ),
      );
      expect(score.honestPracticeMode, isTrue);
      expect(score.countsForRewards, isFalse);
    });
  });

  group('RealScorerSpeakingEngine', () {
    late File audioFile;

    setUp(() async {
      audioFile = File(
        '${Directory.systemTemp.path}/gamekit_speak_test_${DateTime.now().microsecondsSinceEpoch}.wav',
      );
      await audioFile.writeAsBytes(const [0, 1, 2]);
    });

    tearDown(() async {
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    });

    GameTurnContext speakingContext() {
      return GameTurnContext(
        content: const {'expectedText': 'ẹ kú'},
        input: GameSpeakingTurnInput(
          audioPath: audioFile.path,
          expectedText: 'ẹ kú',
          language: 'yo',
        ),
        session: GameSession(
          sessionId: 's',
          userId: 'u',
          gameId: 'speak_game',
          language: 'yo',
          startTime: DateTime.now(),
          metadata: const {'core_verb': 'speak'},
        ),
        metadata: const {'requiresServerScoring': true, 'coreVerb': 'speak'},
      );
    }

    test('adapter contract uses gateway body only', () async {
      final engine = RealScorerSpeakingEngine(
        post: (path, data) async {
          expect(path, '/api/ai/score/utterance');
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {
              'scorer_version': 'p6-038',
              'confidence': 0.9,
              'syllables': [
                {
                  'label': 'ẹ',
                  'expected_tone_label': 'M',
                  'correct': true,
                  'native_contour': [0, 1],
                  'learner_contour': [0, 1],
                },
              ],
            },
          );
        },
      );
      final score = await engine.score(speakingContext());
      expect(score.source, GameScoreSource.realScorer);
      expect(score.isCorrect, isTrue);
      expect(score.scorerVersion, 'p6-038');
    });
  });

  test('learner graph stores scorer trace with turn', () async {
    final learner = LearnerModelService.instance;
    learner.resetPracticeEventStateForTests();
    await learner.initialize();
    final writer = GameKitLearnerGraphWriter(learnerModel: learner);
    var session = GameSession(
      sessionId: 'sess_scorer',
      userId: 'u1',
      gameId: 'g',
      language: 'yo',
      startTime: DateTime.now(),
    );
    final result = GameTurnResult(
      score: GameScore(
        accuracy: 1,
        isPerfect: true,
        isFail: false,
        scorerVersion: 'p6-038',
        confidence: 0.91,
        scorerTrace: const {'scorer_version': 'p6-038', 'confidence': 0.91},
        source: GameScoreSource.realScorer,
      ),
      feedback: GameFeedback.success(
        message: 'ok',
        animationEvent: AnimationEvent.happy,
      ),
      difficultyUpdate: GameDifficultyUpdate.maintain(),
      timestamp: DateTime.now(),
    );
    session = await writer.recordTurn(
      session: session,
      context: GameTurnContext(
        content: const {},
        input: const {},
        session: session,
        metadata: const {'itemId': 'lex_1'},
      ),
      result: result,
      turnId: 't1',
    );
    final traces = session.metadata['learner_scorer_traces'] as List;
    expect(traces, hasLength(1));
    expect(traces.first['turnId'], 't1');
    expect(traces.first['scorer_version'], 'p6-038');
  });

  test('speaking scorer sources pass forbidden-pattern lint', () {
    final forbidden = RegExp(r'\bRandom\s*\(|accuracy:\s*0\.5|\.hashCode');
    for (final rel in gameKitSpeakingScorerLintTargets) {
      final file = File(rel);
      expect(file.existsSync(), isTrue, reason: rel);
      final text = file.readAsStringSync();
      expect(
        forbidden.hasMatch(text),
        isFalse,
        reason: '$rel must not use random/heuristic speaking scores',
      );
    }
  });
}
