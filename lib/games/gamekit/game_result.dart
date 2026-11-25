import 'dart:async';
import 'dart:convert';

import 'game_feedback.dart';
import 'game_difficulty.dart';
import 'game_scoring.dart';
import 'game_engine.dart';
import 'game_session.dart';
import 'game_turn_context.dart';
import '../../models/game/game_session_model.dart' as backend;
import '../../learning/learner_model/learner_model_service.dart';
import '../../learning/learner_model/learner_skill_state.dart';
import '../../learning/learner_model/error_taxonomy.dart';
import '../../services/learning/spaced_repetition_service.dart';
import '../../config/api_contract.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Complete result of a game turn
class GameTurnResult {
  final GameScore score;
  final GameFeedback feedback;
  final GameDifficultyUpdate difficultyUpdate;
  final DateTime timestamp;

  GameTurnResult({
    required this.score,
    required this.feedback,
    required this.difficultyUpdate,
    required this.timestamp,
  });

  /// Convert to backend GameTurn model
  backend.GameTurn toGameTurn({required String cardId}) {
    return backend.GameTurn(
      cardId: cardId,
      result: score.isCorrect ? backend.GameResult.correct : backend.GameResult.incorrect,
      durationMs: 0, // Should be set by caller
      confidence: score.accuracy,
      feedback: {
        'message': feedback.message,
        'animation_event': feedback.animationEvent.name,
        'accuracy': score.accuracy,
        'is_perfect': score.isPerfect,
        'is_fail': score.isFail,
        if (score.isUnsure) 'unsure': true,
        if (score.honestPracticeMode) 'honest_practice': true,
        if (score.scorerVersion != null) 'scorer_version': score.scorerVersion,
        if (score.confidence != null) 'confidence': score.confidence,
      },
    );
  }
}

const _masteryEpsilon = 0.0001;

/// One skill's learner-model mastery before vs after a GameKit session (P8-915).
class GameMasterySkillDelta {
  const GameMasterySkillDelta({
    required this.skillId,
    required this.masteryBefore,
    required this.masteryAfter,
  });

  final String skillId;
  final double masteryBefore;
  final double masteryAfter;

  bool get hasMeasuredChange =>
      (masteryAfter - masteryBefore).abs() > _masteryEpsilon;

  bool get improved => masteryAfter > masteryBefore + _masteryEpsilon;

  bool get declined => masteryBefore > masteryAfter + _masteryEpsilon;

  /// Improved, declined, or flat — never label flat as improved.
  GameMasteryChangeKind get changeKind {
    if (improved) return GameMasteryChangeKind.improved;
    if (declined) return GameMasteryChangeKind.declined;
    return GameMasteryChangeKind.noChange;
  }

  int masteryBeforePercent() => (masteryBefore * 100).round().clamp(0, 100);

  int masteryAfterPercent() => (masteryAfter * 100).round().clamp(0, 100);
}

enum GameMasteryChangeKind { improved, declined, noChange }

/// Reads session metadata written during [GameKitLearnerGraphWriter.recordTurn].
List<GameMasterySkillDelta> skillDeltasFromGameSession(GameSession session) {
  final raw = session.metadata['skill_mastery_snapshots'];
  if (raw is! Map) return const [];
  final deltas = <GameMasterySkillDelta>[];
  for (final entry in raw.entries) {
    final skillId = entry.key.toString();
    final map = entry.value;
    if (map is! Map) continue;
    final before = (map['before'] as num?)?.toDouble();
    final after = (map['after'] as num?)?.toDouble();
    if (before == null || after == null) continue;
    deltas.add(GameMasterySkillDelta(
      skillId: skillId,
      masteryBefore: before,
      masteryAfter: after,
    ));
  }
  deltas.sort((a, b) => a.skillId.compareTo(b.skillId));
  return deltas;
}

/// Payload for [GameMasteryResultsScreen].
class GameMasteryResultsPayload {
  const GameMasteryResultsPayload({
    required this.session,
    required this.skillDeltas,
    this.serverXpAwarded,
    this.practiceNotScored = false,
  });

  final GameSession session;
  final List<GameMasterySkillDelta> skillDeltas;
  final int? serverXpAwarded;
  final bool practiceNotScored;

  factory GameMasteryResultsPayload.fromSession(
    GameSession session, {
    int? serverXpAwarded,
  }) {
    unawaited(archiveGameSessionForMasteryMap(session));
    return GameMasteryResultsPayload(
      session: session,
      skillDeltas: skillDeltasFromGameSession(session),
      serverXpAwarded: serverXpAwarded,
      practiceNotScored: session.practiceNotScored,
    );
  }
}

/// Archived completed session for mastery-map indexing (P8-932).
class GameMasterySessionRecord {
  const GameMasterySessionRecord({
    required this.sessionId,
    required this.gameId,
    required this.learnerId,
    required this.language,
    required this.completedAt,
    required this.practiceNotScored,
    required this.skillIdsTouched,
    required this.skillDeltas,
    this.scorerBySkill = const {},
  });

  final String sessionId;
  final String gameId;
  final String learnerId;
  final String language;
  final DateTime completedAt;
  final bool practiceNotScored;
  final List<String> skillIdsTouched;
  final List<GameMasterySkillDelta> skillDeltas;
  final Map<String, ScorerSkillSnapshot> scorerBySkill;

  bool touchedSkill(String skillId) => skillIdsTouched.contains(skillId);

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'gameId': gameId,
        'learnerId': learnerId,
        'language': language,
        'completedAt': completedAt.toIso8601String(),
        'practiceNotScored': practiceNotScored,
        'skillIdsTouched': skillIdsTouched,
        'skillDeltas': skillDeltas
            .map(
              (d) => {
                'skillId': d.skillId,
                'before': d.masteryBefore,
                'after': d.masteryAfter,
              },
            )
            .toList(),
        'scorerBySkill': scorerBySkill.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
      };

  factory GameMasterySessionRecord.fromJson(Map<String, dynamic> json) {
    final deltasRaw = json['skillDeltas'] as List<dynamic>? ?? const [];
    return GameMasterySessionRecord(
      sessionId: json['sessionId'] as String,
      gameId: json['gameId'] as String,
      learnerId: json['learnerId'] as String,
      language: json['language'] as String? ?? '',
      completedAt: DateTime.parse(json['completedAt'] as String),
      practiceNotScored: json['practiceNotScored'] == true,
      skillIdsTouched: (json['skillIdsTouched'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      skillDeltas: deltasRaw.map((e) {
        final m = e as Map<String, dynamic>;
        return GameMasterySkillDelta(
          skillId: m['skillId'] as String,
          masteryBefore: (m['before'] as num).toDouble(),
          masteryAfter: (m['after'] as num).toDouble(),
        );
      }).toList(),
      scorerBySkill: (json['scorerBySkill'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              ScorerSkillSnapshot.fromJson(Map<String, dynamic>.from(v as Map)),
            ),
          ) ??
          const {},
    );
  }

  factory GameMasterySessionRecord.fromSession(GameSession session) {
    final deltas = skillDeltasFromGameSession(session);
    final scorerBySkill = scorerSnapshotsFromSession(session);
    final touched = <String>{
      ...deltas.where((d) => d.hasMeasuredChange).map((d) => d.skillId),
      for (final e in LearnerModelService.instance.eventsForSession(session.sessionId))
        e.skillId,
    };
    return GameMasterySessionRecord(
      sessionId: session.sessionId,
      gameId: session.gameId,
      learnerId: session.userId,
      language: session.language,
      completedAt: DateTime.now().toUtc(),
      practiceNotScored: session.practiceNotScored,
      skillIdsTouched: touched.toList()..sort(),
      skillDeltas: deltas,
      scorerBySkill: scorerBySkill,
    );
  }
}

class ScorerSkillSnapshot {
  const ScorerSkillSnapshot({
    this.accuracyPercent,
    this.unsure = false,
    this.fromPractice = false,
  });

  final int? accuracyPercent;
  final bool unsure;
  final bool fromPractice;

  Map<String, dynamic> toJson() => {
        if (accuracyPercent != null) 'accuracyPercent': accuracyPercent,
        'unsure': unsure,
        'fromPractice': fromPractice,
      };

  factory ScorerSkillSnapshot.fromJson(Map<String, dynamic> json) {
    return ScorerSkillSnapshot(
      accuracyPercent: (json['accuracyPercent'] as num?)?.toInt(),
      unsure: json['unsure'] == true,
      fromPractice: json['fromPractice'] == true,
    );
  }
}

Map<String, ScorerSkillSnapshot> scorerSnapshotsFromSession(GameSession session) {
  final traces = session.metadata['learner_scorer_traces'] as List<dynamic>? ?? const [];
  final out = <String, ScorerSkillSnapshot>{};
  for (final raw in traces) {
    if (raw is! Map) continue;
    final map = Map<String, dynamic>.from(raw);
    final skillId = map['skillId'] as String?;
    if (skillId == null) continue;
    final confidence = (map['confidence'] as num?)?.toDouble();
    final unsureFlag = map['unsure'] == true;
    final lowConfidence = confidence != null && confidence < gameKitSpeakingLowConfidence;
    final unsure = unsureFlag || lowConfidence || confidence == null;
    final accuracy = (map['accuracy'] as num?)?.toDouble();
    out[skillId] = ScorerSkillSnapshot(
      accuracyPercent: unsure ? null : ((accuracy ?? confidence) * 100).round().clamp(0, 100),
      unsure: unsure,
      fromPractice: session.practiceNotScored,
    );
  }
  return out;
}

String _masteryMapPrefsKey(String learnerId) => 'game_mastery_map_sessions_$learnerId';

Future<void> archiveGameSessionForMasteryMap(GameSession session) async {
  final record = GameMasterySessionRecord.fromSession(session);
  if (record.skillIdsTouched.isEmpty && record.skillDeltas.isEmpty) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = _masteryMapPrefsKey(session.userId);
    final existing = prefs.getStringList(key) ?? const [];
    final encoded = jsonEncode(record.toJson());
    final withoutDup = existing.where((e) {
      try {
        final m = jsonDecode(e) as Map<String, dynamic>;
        return m['sessionId'] != session.sessionId;
      } catch (_) {
        return true;
      }
    }).toList();
    withoutDup.add(encoded);
    const cap = 200;
    final trimmed = withoutDup.length > cap
        ? withoutDup.sublist(withoutDup.length - cap)
        : withoutDup;
    await prefs.setStringList(key, trimmed);
  } catch (_) {
    // Map degrades to live learner-model events only.
  }
}

Future<List<GameMasterySessionRecord>> loadMasteryMapSessionRecords(
  String learnerId,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_masteryMapPrefsKey(learnerId)) ?? const [];
    return raw
        .map((e) => GameMasterySessionRecord.fromJson(
              jsonDecode(e) as Map<String, dynamic>,
            ))
        .toList();
  } catch (_) {
    return const [];
  }
}

/// Builds mastery-map rows from archived sessions + learner-model states (P8-932).
List<MasteryMapSkillRow> buildMasteryMapSkillRows({
  required String learnerId,
  required List<GameMasterySessionRecord> records,
  required LearnerModelService learnerModel,
}) {
  final bySkill = <String, Set<String>>{};
  final gamesBySkill = <String, Set<String>>{};
  final sessionsBySkill = <String, Set<String>>{};

  for (final record in records) {
    if (record.learnerId != learnerId) continue;
    for (final skillId in record.skillIdsTouched) {
      bySkill.putIfAbsent(skillId, () => {}).add(record.sessionId);
      gamesBySkill.putIfAbsent(skillId, () => {}).add(record.gameId);
      sessionsBySkill.putIfAbsent(skillId, () => {}).add(record.sessionId);
    }
    for (final event in learnerModel.eventsForSession(record.sessionId)) {
      if (event.source != 'gamekit') continue;
      gamesBySkill.putIfAbsent(event.skillId, () => {}).add(record.gameId);
      sessionsBySkill.putIfAbsent(event.skillId, () => {}).add(record.sessionId);
    }
  }

  final skillIds = {...bySkill.keys, ...gamesBySkill.keys}.toList()..sort();
  final rows = <MasteryMapSkillRow>[];

  for (final skillId in skillIds) {
    final sessions = sessionsBySkill[skillId] ?? const {};
    final games = (gamesBySkill[skillId] ?? const {}).toList()..sort();
    if (sessions.isEmpty) {
      rows.add(MasteryMapSkillRow(
        skillId: skillId,
        valueKind: MasteryMapSkillValueKind.notMeasured,
        gameIds: games,
        sessionIds: const [],
      ));
      continue;
    }

    final expectsScorer = learnerSkillIdExpectsScorerMeasurement(skillId);
    if (expectsScorer) {
      ScorerSkillSnapshot? best;
      for (final record in records) {
        if (!record.touchedSkill(skillId)) continue;
        final snap = record.scorerBySkill[skillId];
        if (snap == null) continue;
        if (snap.fromPractice || record.practiceNotScored) continue;
        if (snap.unsure) {
          best = const ScorerSkillSnapshot(unsure: true);
          break;
        }
        best = snap;
      }
      if (best == null) {
        rows.add(MasteryMapSkillRow(
          skillId: skillId,
          valueKind: MasteryMapSkillValueKind.notMeasured,
          gameIds: games,
          sessionIds: sessions.toList()..sort(),
        ));
      } else if (best.unsure) {
        rows.add(MasteryMapSkillRow(
          skillId: skillId,
          valueKind: MasteryMapSkillValueKind.unsure,
          gameIds: games,
          sessionIds: sessions.toList()..sort(),
        ));
      } else {
        rows.add(MasteryMapSkillRow(
          skillId: skillId,
          valueKind: MasteryMapSkillValueKind.scorerPercent,
          masteryPercent: best.accuracyPercent,
          gameIds: games,
          sessionIds: sessions.toList()..sort(),
        ));
      }
      continue;
    }

    final state = learnerModel.getState(learnerId: learnerId, skillId: skillId);
    final hasEvents = sessions.isNotEmpty && state.totalAttempts > 0;
    rows.add(MasteryMapSkillRow(
      skillId: skillId,
      valueKind:
          hasEvents ? MasteryMapSkillValueKind.masteryPercent : MasteryMapSkillValueKind.notMeasured,
      masteryPercent: hasEvents ? state.masteryPercentRounded() : null,
      gameIds: games,
      sessionIds: sessions.toList()..sort(),
    ));
  }

  return rows;
}

List<GameMasterySessionRecord> sessionsForGameAndSkill({
  required List<GameMasterySessionRecord> records,
  required String learnerId,
  required String gameId,
  required String skillId,
}) {
  return records
      .where(
        (r) =>
            r.learnerId == learnerId &&
            r.gameId == gameId &&
            r.touchedSkill(skillId),
      )
      .toList()
    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
}

/// Writes GameKit turn outcomes to the learner graph and SRS (P8-901).
class GameKitLearnerGraphWriter {
  GameKitLearnerGraphWriter({
    LearnerModelService? learnerModel,
    SpacedRepetitionService? spacedRepetition,
  })  : _learnerModel = learnerModel ?? LearnerModelService.instance,
        _spacedRepetition = spacedRepetition ?? SpacedRepetitionService();

  final LearnerModelService _learnerModel;
  final SpacedRepetitionService _spacedRepetition;

  final List<({String userId, String itemId, bool wasCorrect, double accuracy})>
      _pendingSrs = [];

  /// Resolves item and skill ids for a turn.
  static ({String itemId, String skillId, List<String> errorTypeIds}) idsForTurn(
    GameTurnContext context,
    GameTurnResult result,
  ) {
    final meta = context.metadata ?? {};
    final itemId = (meta['itemId'] as String?) ??
        context.queuedItemId ??
        (meta['skillId'] as String?) ??
        'unknown_item';
    final skillId = (meta['skillId'] as String?) ?? itemId;
    final errorTypeIds = (meta['errorTypeIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((id) => ErrorType.byId(id) != null)
            .toList() ??
        (result.score.isCorrect
            ? const <String>[]
            : [
                gameKitInferWrongAnswerErrorType(
                  metadata: meta,
                  gameCategory: meta['gameCategory'] as String?,
                  languageCode: context.session.language,
                ),
              ]);
    return (itemId: itemId, skillId: skillId, errorTypeIds: errorTypeIds);
  }

  /// Records learner-graph + SRS updates before the next turn may start.
  Future<GameSession> recordTurn({
    required GameSession session,
    required GameTurnContext context,
    required GameTurnResult result,
    required String turnId,
    bool queueOnly = false,
  }) async {
    final alreadyRecorded = (session.metadata['recorded_turn_ids'] as List<dynamic>?)
            ?.map((e) => e as String)
            .contains(turnId) ??
        false;
    if (alreadyRecorded) {
      return session;
    }

    final ids = idsForTurn(context, result);
    final snapshots = Map<String, dynamic>.from(
      session.metadata['skill_mastery_snapshots'] as Map? ?? const {},
    );
    final prior = snapshots[ids.skillId];
    final masteryBefore = prior is Map && prior['before'] is num
        ? (prior['before'] as num).toDouble()
        : _learnerModel
            .getState(learnerId: session.userId, skillId: ids.skillId)
            .mastery;

    await _learnerModel.recordPracticeEvent(
      turnId: turnId,
      sessionId: session.sessionId,
      learnerId: session.userId,
      itemId: ids.itemId,
      skillId: ids.skillId,
      wasCorrect: result.score.isCorrect,
      errorTypeIds: ids.errorTypeIds,
      timestamp: result.timestamp,
      queueOnly: queueOnly,
    );

    final masteryAfter = _learnerModel
        .getState(learnerId: session.userId, skillId: ids.skillId)
        .mastery;
    snapshots[ids.skillId] = {
      'before': masteryBefore,
      'after': masteryAfter,
    };

    if (queueOnly) {
      _pendingSrs.add((
        userId: session.userId,
        itemId: ids.itemId,
        wasCorrect: result.score.isCorrect,
        accuracy: result.score.accuracy,
      ));
    } else {
      _spacedRepetition.reviewFromPracticeOutcome(
        userId: session.userId,
        lessonItemId: ids.itemId,
        wasCorrect: result.score.isCorrect,
        accuracy: result.score.accuracy,
      );
    }

    final updatedTurns = [...session.turns, result];
    final recorded = [
      ...(session.metadata['recorded_turn_ids'] as List<dynamic>? ?? const [])
          .map((e) => e as String),
      turnId,
    ];

    final scorerTraces = <Map<String, dynamic>>[
      ...((session.metadata['learner_scorer_traces'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e)) ??
          const []),
    ];
    if (result.score.scorerTrace != null) {
      scorerTraces.add({
        'turnId': turnId,
        'itemId': ids.itemId,
        'skillId': ids.skillId,
        ...result.score.scorerTrace!,
      });
    }

    return session.copyWith(
      turns: updatedTurns,
      metadata: {
        ...session.metadata,
        'recorded_turn_ids': recorded,
        'learner_events_recorded': recorded.length,
        'skill_mastery_snapshots': snapshots,
        if (scorerTraces.isNotEmpty) 'learner_scorer_traces': scorerTraces,
      },
    );
  }

  /// Applies queued learner events and matching SRS updates in order.
  Future<int> flushOfflineQueue() async {
    final applied = await _learnerModel.flushPendingPracticeEvents();
    for (final entry in _pendingSrs) {
      _spacedRepetition.reviewFromPracticeOutcome(
        userId: entry.userId,
        lessonItemId: entry.itemId,
        wasCorrect: entry.wasCorrect,
        accuracy: entry.accuracy,
      );
    }
    _pendingSrs.clear();
    return applied;
  }
}

/// Server-verified GameKit session reward (P8-909).
class GameSessionRewardClaim {
  final String sessionId;
  final int xpAwarded;
  final bool practice;
  final bool duplicate;
  final int? xpTotal;

  const GameSessionRewardClaim({
    required this.sessionId,
    required this.xpAwarded,
    required this.practice,
    required this.duplicate,
    this.xpTotal,
  });

  factory GameSessionRewardClaim.fromJson(Map<String, dynamic> json) {
    return GameSessionRewardClaim(
      sessionId: json['session_id'] as String? ?? '',
      xpAwarded: (json['xp_awarded'] as num?)?.toInt() ?? 0,
      practice: json['practice'] == true,
      duplicate: json['duplicate'] == true,
      xpTotal: (json['xp_total'] as num?)?.toInt(),
    );
  }
}

/// POST /api/games/session/:id/claim-reward/ — never sends client XP totals.
Future<GameSessionRewardClaim?> claimGameSessionRewardVerified({
  required Dio dio,
  required backend.GameSession session,
}) async {
  final response = await dio.post<Map<String, dynamic>>(
    ApiContract.url('/api/games/session/${session.sessionId}/claim-reward/'),
    data: const <String, dynamic>{},
    options: Options(
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  final status = response.statusCode ?? 0;
  if (status == 401 || status == 403) {
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      message: 'game_reward_auth_failed',
    );
  }
  if (status >= 400) {
    return null;
  }
  final data = response.data?['data'];
  if (data is! Map<String, dynamic>) return null;
  return GameSessionRewardClaim.fromJson(data);
}

/// Result of resolving a turn and recording it on the learner graph.
class GameTurnResolution {
  final GameTurnResult result;
  final GameSession session;

  const GameTurnResolution(this.result, this.session);
}

/// Mandatory GameKit path: resolve scoring, then write learner graph + SRS.
extension GameEngineLearnerGraph on GameEngine {
  Future<GameTurnResolution> resolveTurnRecording(
    GameKitLearnerGraphWriter writer,
    GameTurnContext context, {
    required String turnId,
    bool queueOnly = false,
  }) async {
    final result = await resolve(context);
    final session = await writer.recordTurn(
      session: context.session,
      context: context,
      result: result,
      turnId: turnId,
      queueOnly: queueOnly,
    );
    return GameTurnResolution(result, session);
  }
}
