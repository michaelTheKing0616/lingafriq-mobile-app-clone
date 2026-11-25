import 'package:dio/dio.dart';

import '../../screens/pronunciation/tone_overlay_view.dart';
import '../../services/lens/lens_scoring_client.dart';
import 'game_turn_context.dart';

/// P8-907 / EP-§10.2-12–13 — GameKit never gates play on energy or hearts, and
/// never issues randomised loot-box rewards; payouts derive from [GameScore] only.
abstract final class GameKitRewardPolicy {
  static const bool allowsEnergyOrHeartGate = false;
  static const bool allowsRandomLootMechanic = false;
}

/// Confidence below this mirrors quiz speaking grader — no score-based rewards.
const double gameKitSpeakingLowConfidence = 0.6;

/// Abstract scoring engine - each game can implement custom scoring
abstract class GameScoringEngine {
  Future<GameScore> score(GameTurnContext context);
}

/// Default scoring engine - non-speaking MCQ/text games only.
class DefaultGameScoringEngine implements GameScoringEngine {
  @override
  Future<GameScore> score(GameTurnContext context) async {
    if (context.requiresRealSpeakingScorer) {
      return GameScore.honestPractice(
        message: 'Speaking needs the real scorer adapter.',
      );
    }
    return GameScore.incorrect(accuracy: 0, fail: false);
  }
}

/// E-P6-SCORER adapter for GameKit speaking turns (P8-910).
class RealScorerSpeakingEngine implements GameScoringEngine {
  RealScorerSpeakingEngine({
    LensScoringClient? client,
    required LensScorePost post,
  })  : _client = client ?? const LensScoringClient(),
        _post = post;

  final LensScoringClient _client;
  final LensScorePost _post;

  @override
  Future<GameScore> score(GameTurnContext context) async {
    final speaking = GameSpeakingTurnInput.fromContext(context);
    if (speaking == null) {
      return GameScore.scorerError(
        message: lensSayErrorCopy,
        retryable: true,
      );
    }

    final response = await _post(
      _client.scorePath,
      await _formData(speaking),
    );
    final statusCode = response.statusCode ?? 0;
    final raw = response.data;
    final body = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    if (statusCode == 503 ||
        body['code'] == 'scorer_unavailable' ||
        body['retryable'] == true) {
      return GameScore.scorerError(
        message: lensSayErrorCopy,
        retryable: true,
      );
    }
    if (statusCode != 200) {
      return GameScore.scorerError(
        message: lensSayErrorCopy,
        retryable: false,
      );
    }

    final outcome = parseScoreBody(body);
    return gameScoreFromScorerResponse(body: body, outcome: outcome);
  }

  Future<dynamic> _formData(GameSpeakingTurnInput speaking) async {
    return FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        speaking.audioPath,
        filename: 'gamekit_speak.wav',
      ),
      'expected_text': speaking.expectedText.trim(),
      'language': speaking.language.trim().toLowerCase(),
    });
  }
}

/// Maps gateway `/api/ai/score/utterance` payload to [GameScore] (no heuristics).
GameScore gameScoreFromScorerResponse({
  required Map<String, dynamic> body,
  required LensScoreOutcome outcome,
}) {
  final version = (body['scorer_version'] ?? body['model_version'])?.toString();
  final confidence = _finiteUnit(body['confidence']);
  final syllableTrace = outcome.syllables
      .map(
        (r) => {
          'label': r.label,
          'expected_tone_label': r.expectedToneLabel,
          'correct': r.correct,
          'unsure': r.isUnsure,
        },
      )
      .toList();
  final phoneTrace = body['phones'] is List
      ? (body['phones'] as List)
          .whereType<Map>()
          .map((p) => Map<String, dynamic>.from(p))
          .toList()
      : const <Map<String, dynamic>>[];

  final trace = <String, dynamic>{
    if (version != null) 'scorer_version': version,
    if (confidence != null) 'confidence': confidence,
    'syllables': syllableTrace,
    if (phoneTrace.isNotEmpty) 'phones': phoneTrace,
  };

  if (outcome.phase == ToneOverlayStatus.unsure) {
    return GameScore.unsure(
      message: outcome.errorMessage ?? lensSayUnsureCopy,
      scorerTrace: trace,
      confidence: confidence,
    );
  }

  if (outcome.phase == ToneOverlayStatus.error) {
    return GameScore.scorerError(
      message: outcome.errorMessage ?? lensSayErrorCopy,
      retryable: outcome.retryable,
      scorerTrace: trace,
    );
  }

  final scored = outcome.syllables.where((s) => !s.isUnsure).toList();
  if (scored.isEmpty) {
    return GameScore.unsure(
      message: lensSayUnsureCopy,
      scorerTrace: trace,
      confidence: confidence,
    );
  }

  final correct = scored.where((s) => s.correct == true).length;
  final accuracy = correct / scored.length;
  final conf = confidence ?? accuracy;

  if (conf < gameKitSpeakingLowConfidence) {
    return GameScore.unsure(
      message: lensSayUnsureCopy,
      scorerTrace: trace,
      confidence: conf,
    );
  }

  final perfect = outcome.celebrate && accuracy >= 1.0;
  return GameScore(
    accuracy: accuracy,
    isPerfect: perfect,
    isFail: accuracy < 0.4,
    confidence: conf,
    scorerVersion: version,
    scorerTrace: trace,
    countsForRewards: true,
    source: GameScoreSource.realScorer,
  );
}

double? _finiteUnit(Object? value) {
  if (value is! num) return null;
  final n = value.toDouble();
  if (!n.isFinite || n < 0 || n > 1) return null;
  return n;
}

enum GameScoreSource { local, realScorer, honestPractice, scorerUnavailable }

/// Game score result
class GameScore {
  final double accuracy; // 0.0 to 1.0
  final bool isPerfect;
  final bool isFail;
  final Map<String, dynamic>? details;
  final bool isUnsure;
  final bool honestPracticeMode;
  final bool countsForRewards;
  final double? confidence;
  final String? scorerVersion;
  final Map<String, dynamic>? scorerTrace;
  final GameScoreSource source;

  GameScore({
    required this.accuracy,
    required this.isPerfect,
    required this.isFail,
    this.details,
    this.isUnsure = false,
    this.honestPracticeMode = false,
    this.countsForRewards = true,
    this.confidence,
    this.scorerVersion,
    this.scorerTrace,
    this.source = GameScoreSource.local,
  });

  bool get isCorrect =>
      countsForRewards && !isUnsure && !honestPracticeMode && accuracy >= 0.6;

  bool get isPartial =>
      countsForRewards &&
      !isUnsure &&
      !honestPracticeMode &&
      accuracy >= 0.4 &&
      accuracy < 0.6;

  factory GameScore.correct({double accuracy = 1.0, bool perfect = true}) {
    return GameScore(
      accuracy: accuracy,
      isPerfect: perfect,
      isFail: false,
    );
  }

  factory GameScore.incorrect({double accuracy = 0.0, bool fail = true}) {
    return GameScore(
      accuracy: accuracy,
      isPerfect: false,
      isFail: fail,
    );
  }

  factory GameScore.unsure({
    required String message,
    Map<String, dynamic>? scorerTrace,
    double? confidence,
  }) {
    return GameScore(
      accuracy: 0,
      isPerfect: false,
      isFail: false,
      isUnsure: true,
      countsForRewards: false,
      confidence: confidence,
      scorerTrace: scorerTrace,
      source: GameScoreSource.realScorer,
      details: {'message': message, 'phase': 'unsure'},
    );
  }

  factory GameScore.scorerError({
    required String message,
    bool retryable = true,
    Map<String, dynamic>? scorerTrace,
  }) {
    return GameScore(
      accuracy: 0,
      isPerfect: false,
      isFail: false,
      honestPracticeMode: true,
      countsForRewards: false,
      scorerTrace: scorerTrace,
      source: GameScoreSource.scorerUnavailable,
      details: {
        'message': message,
        'phase': 'unavailable',
        'retryable': retryable,
        'honest_practice': true,
      },
    );
  }

  factory GameScore.honestPractice({required String message}) {
    return GameScore(
      accuracy: 0,
      isPerfect: false,
      isFail: false,
      honestPracticeMode: true,
      countsForRewards: false,
      source: GameScoreSource.honestPractice,
      details: {'message': message, 'honest_practice': true},
    );
  }
}

/// Remote flag: when on, speaking games with a passing adapter use [RealScorerSpeakingEngine].
const String gameKitRealSpeakingScorerFlagKey = 'gamekit_real_speaking_scorer';

/// Adapter contract pass list (P8-910); only these IDs leave practice when the flag is on.
const Set<String> gameKitRealScorerAdapterPassingGameIds = {
  'tone_trainer',
  'call_and_response',
  'rapid_tongue_twister_race',
  'cultural_etiquette_scenarios',
  'market_bargaining_simulator',
};

bool gameKitRealScorerAdapterTestPasses(String gameId) {
  return gameKitRealScorerAdapterPassingGameIds.contains(gameId.trim());
}

bool gameKitRealScorerLiveForGame({
  required bool featureFlagOn,
  required String gameId,
  required bool isSpeakingGame,
}) {
  if (!isSpeakingGame) return false;
  return featureFlagOn && gameKitRealScorerAdapterTestPasses(gameId);
}

/// Practice when a speaking game opens without a live scorer (P8-911 AC1–AC4).
bool gameKitPracticeNotScoredMode({
  required bool isSpeakingGame,
  required bool realScorerLive,
}) {
  return isSpeakingGame && !realScorerLive;
}

/// Server-parity preview for GameKit session rewards (P8-909; authoritative value is claim response).
int previewGameSessionXp({
  required int correctCount,
  required int totalTurns,
  required int durationMs,
  bool practiceNotScored = false,
}) {
  if (practiceNotScored || totalTurns <= 0) return 0;
  final accuracy = correctCount / totalTurns;
  const baseXp = 10;
  final accuracyBonus = (accuracy * 20).round();
  final speedBonus = durationMs < 30000 ? 10 : (durationMs < 60000 ? 5 : 0);
  final perfectBonus = accuracy >= 1.0 ? 25 : 0;
  return baseXp + accuracyBonus + speedBonus + perfectBonus;
}

/// CI guard targets for speaking-scorer lint tests (P8-910 AC5).
const gameKitSpeakingScorerLintTargets = <String>[
  'lib/games/gamekit/game_scoring.dart',
  'lib/games/learning_game_adapter.dart',
];
