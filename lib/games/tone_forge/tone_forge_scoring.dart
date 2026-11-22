import '../../learning/pronunciation/tone_models.dart';
import '../../services/lens/lens_scoring_client.dart';
import '../gamekit/game_scoring.dart';
import '../gamekit/game_session.dart';
import '../gamekit/game_turn_context.dart';
import 'tone_forge_models.dart';
import 'tone_forge_audio.dart';

/// Percent from a real scorer result.
///
/// Unsure, unavailable, practice, and local results return null so a screen
/// cannot paint a stand-in such as 0, 80, or 100.
int? toneForgeShownPercent(GameScore score) {
  if (score.source != GameScoreSource.realScorer) return null;
  if (score.isUnsure || score.honestPracticeMode) return null;
  final double accuracy = score.accuracy;
  if (!accuracy.isFinite || accuracy < 0 || accuracy > 1) return null;
  return (accuracy * 100).round();
}

/// Scored only when [toneForgeShownPercent] has a measured value.
/// Anything else, including an unavailable scorer, is unsure.
enum ToneForgeScoreView { scored, unsure }

ToneForgeScoreView toneForgeScoreView(GameScore score) {
  if (toneForgeShownPercent(score) != null) return ToneForgeScoreView.scored;
  return ToneForgeScoreView.unsure;
}

/// Posts one spoken tone attempt to [RealScorerSpeakingEngine].
Future<GameScore> scoreToneForgeAttempt({
  required String word,
  required String audioPath,
  required String language,
  required LensScorePost post,
}) {
  final String expected = word.trim();
  final String lang = language.trim().isEmpty ? 'yo' : language.trim();
  return RealScorerSpeakingEngine(post: post).score(
    GameTurnContext(
      content: <String, String>{'expectedText': expected},
      input: GameSpeakingTurnInput(
        audioPath: audioPath,
        expectedText: expected,
        language: lang,
      ),
      session: GameSession(
        sessionId: 'tone_forge',
        userId: 'learner',
        gameId: 'tone_forge',
        language: lang,
        startTime: DateTime.now(),
        metadata: const <String, dynamic>{'core_verb': 'speak'},
      ),
      metadata: const <String, dynamic>{
        'requiresServerScoring': true,
        'coreVerb': 'speak',
      },
    ),
  );
}

/// Multiple-choice tone level vs lexicon pattern (P8-913).
GameScore scoreToneInventoryChoice({
  required ToneLanguageModel inventory,
  required List<String> lexiconTonePattern,
  required int syllableIndex,
  required int selectedInventoryIndex,
}) {
  if (syllableIndex < 0 || syllableIndex >= lexiconTonePattern.length) {
    return GameScore(
      accuracy: 0,
      isPerfect: false,
      isFail: true,
      details: {'reason': 'syllable_out_of_range'},
    );
  }
  final expectedCode = lexiconTonePattern[syllableIndex];
  final expectedIndex = inventory.levels.indexOf(expectedCode);
  if (expectedIndex < 0) {
    return GameScore(
      accuracy: 0,
      isPerfect: false,
      isFail: true,
      details: {'reason': 'tone_not_in_inventory', 'code': expectedCode},
    );
  }
  final correct = selectedInventoryIndex == expectedIndex;
  return GameScore(
    accuracy: correct ? 1.0 : 0.0,
    isPerfect: correct,
    isFail: !correct,
    details: {
      'expected_level': expectedCode,
      'expected_index': expectedIndex,
      'selected_index': selectedInventoryIndex,
      'inventory': inventory.levels,
    },
  );
}

/// Tone Forge scoring. A number comes only from [RealScorerSpeakingEngine].
///
/// Pitch contours without an audio file do not become an accuracy.
class ToneForgeScoringEngine implements GameScoringEngine {
  ToneForgeScoringEngine({this._post});

  final LensScorePost? _post;
  final ToneForgeAudioAnalyzer audioAnalyzer = ToneForgeAudioAnalyzer();

  @override
  Future<GameScore> score(GameTurnContext context) async {
    final LensScorePost? post = _post;
    final GameSpeakingTurnInput? speaking = _speakingInput(context);
    if (post == null || speaking == null) {
      return GameScore.unsure(message: 'unsure');
    }
    return scoreToneForgeAttempt(
      word: speaking.expectedText,
      audioPath: speaking.audioPath,
      language: speaking.language,
      post: post,
    );
  }

  GameSpeakingTurnInput? _speakingInput(GameTurnContext context) {
    final GameSpeakingTurnInput? direct = GameSpeakingTurnInput.fromContext(
      context,
    );
    if (direct != null) return direct;
    final Map<String, dynamic> meta = context.metadata ?? const {};
    final String? audio =
        meta['audioPath'] as String? ?? meta['audio_path'] as String?;
    if (audio == null || audio.trim().isEmpty) return null;
    final Object? content = context.content;
    String? expected;
    String? language;
    if (content is ToneForgeContent) {
      expected = content.text;
      language = content.languageCode;
    }
    expected ??=
        meta['expectedText'] as String? ?? meta['expected_text'] as String?;
    language ??= context.session.language;
    if (expected == null || expected.trim().isEmpty) return null;
    return GameSpeakingTurnInput(
      audioPath: audio.trim(),
      expectedText: expected.trim(),
      language: language.trim().isEmpty ? context.session.language : language,
    );
  }
}
