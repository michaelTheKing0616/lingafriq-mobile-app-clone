import 'package:dio/dio.dart';

import '../../config/api_contract.dart';
import '../../learning/core/bkt_mastery.dart';
import '../gamekit/game_result.dart';
import '../gamekit/game_session.dart';

/// Server-backed circle co-op word goals (P8-933).
class CircleGoalService {
  CircleGoalService({Dio? client}) : _client = client;

  Dio? _client;

  void bindClient(Dio client) {
    _client = client;
  }

  static const weekFrozenCode = 'WEEK_FROZEN';

  Future<CircleWordGoalSnapshot> fetchGoal(String groupId) async {
    final dio = _client;
    if (dio == null) {
      throw StateError('CircleGoalService client not bound');
    }
    final res = await dio.get<Map<String, dynamic>>(
      ApiContract.url('/api/gamification/advanced/circle-goals?groupId=$groupId'),
    );
    return CircleWordGoalSnapshot.fromJson(res.data ?? {});
  }

  Future<CircleWordGoalSnapshot> setGoal({
    required String groupId,
    required int goalWords,
  }) async {
    final dio = _client;
    if (dio == null) {
      throw StateError('CircleGoalService client not bound');
    }
    final res = await dio.post<Map<String, dynamic>>(
      ApiContract.url('/api/gamification/advanced/circle-goals'),
      data: {'groupId': groupId, 'goalWords': goalWords},
    );
    final body = res.data ?? {};
    return CircleWordGoalSnapshot(
      empty: false,
      goalWords: (body['goalWords'] as num?)?.toInt() ?? goalWords,
      progressWords: (body['progressWords'] as num?)?.toInt() ?? 0,
      members: const [],
      complete: false,
    );
  }

  Future<int> claimSessionLearnedWords({
    required String groupId,
    required GameSession session,
  }) async {
    if (session.practiceNotScored) return 0;
    final newlyLearned = newlyLearnedSkillIdsFromSession(session);
    if (newlyLearned.isEmpty) return 0;

    final dio = _client;
    if (dio == null) return 0;

    try {
      final res = await dio.post<Map<String, dynamic>>(
        ApiContract.url('/api/gamification/advanced/circle-goals/claim-session'),
        data: {'groupId': groupId, 'sessionId': session.sessionId},
      );
      return (res.data?['recorded'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      final code = e.response?.data is Map
          ? (e.response!.data as Map)['code']?.toString()
          : null;
      if (code == weekFrozenCode) rethrow;
      return 0;
    }
  }
}

/// Skills that crossed the learned threshold during a scored GameKit session.
List<String> newlyLearnedSkillIdsFromSession(GameSession session) {
  final deltas = skillDeltasFromGameSession(session);
  return deltas
      .where(
        (d) =>
            !BktMastery.isMastered(d.masteryBefore) &&
            BktMastery.isMastered(d.masteryAfter),
      )
      .map((d) => d.skillId)
      .toList();
}

class CircleWordGoalMemberLabel {
  const CircleWordGoalMemberLabel({
    required this.slot,
    required this.isViewer,
  });

  final String slot;
  final bool isViewer;

  factory CircleWordGoalMemberLabel.fromJson(Map<String, dynamic> json) {
    return CircleWordGoalMemberLabel(
      slot: json['slot']?.toString() ?? 'Circle learner',
      isViewer: json['isViewer'] == true,
    );
  }
}

class CircleWordGoalSnapshot {
  const CircleWordGoalSnapshot({
    required this.empty,
    required this.goalWords,
    required this.progressWords,
    required this.members,
    this.complete = false,
  });

  final bool empty;
  final int goalWords;
  final int progressWords;
  final List<CircleWordGoalMemberLabel> members;
  final bool complete;

  double get progressFraction =>
      goalWords > 0 ? (progressWords / goalWords).clamp(0.0, 1.0) : 0.0;

  factory CircleWordGoalSnapshot.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['members'] as List<dynamic>? ?? [];
    return CircleWordGoalSnapshot(
      empty: json['empty'] == true,
      goalWords: (json['goalWords'] as num?)?.toInt() ?? 0,
      progressWords: (json['progressWords'] as num?)?.toInt() ?? 0,
      complete: json['complete'] == true,
      members: membersRaw
          .map((e) => CircleWordGoalMemberLabel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
