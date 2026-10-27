import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/gamekit/game_feedback.dart';
import 'package:lingafriq/games/gamekit/game_difficulty.dart';
import 'package:lingafriq/games/gamekit/game_result.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';
import 'package:lingafriq/games/gamekit/game_turn_context.dart';
import 'package:lingafriq/learning/learner_model/error_taxonomy.dart';
import 'package:lingafriq/models/game/game_content_models.dart';

void main() {
  setUp(gameKitResetExplanationAudioCacheForTests);

  test('every error type has GameKit learner copy', () {
    gameKitAssertEveryErrorTypeHasCopy();
  });

  test('error to copy mapping names taxonomy entry', () {
    final line = gameKitLearnerExplanationLine('lexical_choice');
    expect(line, contains('Lexical Choice'));
  });

  test('infers pronunciation tone error on tonal language', () {
    expect(
      gameKitInferWrongAnswerErrorType(
        gameCategory: 'pronunciation',
        languageCode: 'yo',
      ),
      'tone_substitution',
    );
  });

  test('idsForTurn writes typed error on incorrect turn', () {
    final session = GameSession(
      sessionId: 's',
      userId: 'u',
      gameId: 'g',
      language: 'yo',
      startTime: DateTime.now(),
    );
    final context = GameTurnContext(
      content: const {},
      input: const {},
      session: session,
      metadata: const {'gameCategory': 'vocabulary'},
    );
    final result = GameTurnResult(
      score: GameScore(accuracy: 0, isPerfect: false, isFail: true),
      feedback: GameFeedback.neutral(
        message: 'nope',
        animationEvent: AnimationEvent.disappointed,
      ),
      difficultyUpdate: GameDifficultyUpdate.maintain(),
      timestamp: DateTime.now(),
    );
    final ids = GameKitLearnerGraphWriter.idsForTurn(context, result);
    expect(ids.errorTypeIds, ['lexical_choice']);
  });

  testWidgets('explanation audio from warm cache skips loading UI', (tester) async {
    gameKitExplanationAudioWarmCache.add('demo-cached-uri');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameKitWhyWrongPanel(
            errorTypeId: 'lexical_choice',
            correctAnswerText: 'ẹ káàbọ̀',
            audio: const GameKitCorrectItemAudio(uri: 'demo-cached-uri'),
            title: 'Your answer',
            whyWrongLabel: 'Why was I wrong?',
            playAudioLabel: 'Play correct audio',
            noAudioLabel: 'No audio yet',
            loadingLabel: 'Loading…',
            playFn: (_) async {},
          ),
        ),
      ),
    );
    expect(find.text('Loading…'), findsNothing);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
  });

  testWidgets('no audio shows explicit empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameKitWhyWrongPanel(
            errorTypeId: 'lexical_choice',
            correctAnswerText: 'ẹ káàbọ̀',
            audio: GameKitCorrectItemAudio.fromMetadata(
              const {},
              tonalLanguage: true,
            ),
            title: 'Your answer',
            whyWrongLabel: 'Why was I wrong?',
            playAudioLabel: 'Play correct audio',
            noAudioLabel: 'No audio yet for this answer',
            loadingLabel: 'Loading…',
          ),
        ),
      ),
    );
    expect(find.text('No audio yet for this answer'), findsOneWidget);
  });
}
