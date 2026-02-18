import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/bkt_mastery.dart';
import '../skill_graph/skill_node.dart';
import '../skill_graph/skill_registry.dart';
import 'error_taxonomy.dart';
import 'learner_skill_state.dart';

/// Central service for managing the learner model.
///
/// This is THE product. Everything else (UI, games, AI, social)
/// reads from and writes to this service. It is the single source
/// of truth for what a learner knows, how well they know it,
/// and what they should practice next.
///
/// Responsibilities:
/// - CRUD operations for learner skill states
/// - Adaptive item selection (what to practice next)
/// - Curriculum sequencing (respecting skill dependencies)
/// - Cross-skill insights (transfer, interference, patterns)
/// - Persistence (offline-safe, conflict-aware)
class LearnerModelService {
  static LearnerModelService? _instance;
  static LearnerModelService get instance => _instance ??= LearnerModelService._();

  LearnerModelService._();

  /// In-memory cache: learnerId -> skillId -> state
  final Map<String, Map<String, LearnerSkillState>> _states = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes the service, loading cached learner data.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().where((k) => k.startsWith('learner_state_'));

      for (final key in allKeys) {
        final jsonStr = prefs.getString(key);
        if (jsonStr == null) continue;

        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final state = LearnerSkillState.fromJson(data);
        _states
            .putIfAbsent(state.learnerId, () => {})
            [state.skillId] = state;
      }
    } catch (_) {
      // Will be rebuilt as learner interacts
    }

    _isInitialized = true;
  }

  /// Gets the state for a specific skill, creating it if needed.
  LearnerSkillState getState({
    required String learnerId,
    required String skillId,
  }) {
    return _states[learnerId]?[skillId] ??
        LearnerSkillState.initial(
          skillId: skillId,
          learnerId: learnerId,
          bktParams: _getBktParamsForSkill(skillId),
        );
  }

  /// Gets all skill states for a learner.
  Map<String, LearnerSkillState> getAllStates(String learnerId) {
    return Map.unmodifiable(_states[learnerId] ?? {});
  }

  /// Gets all mastered skill IDs for a learner in a specific language.
  Set<String> getMasteredSkillIds(String learnerId, String languageCode) {
    final states = _states[learnerId] ?? {};
    return states.entries
        .where((e) => e.value.isMastered)
        .where((e) {
          final skill = SkillRegistry.instance.findSkill(e.key);
          return skill?.languageCode == languageCode;
        })
        .map((e) => e.key)
        .toSet();
  }

  /// Records a practice attempt and updates all related state.
  ///
  /// This is the primary write operation. All learning interactions
  /// flow through this method.
  Future<LearnerSkillState> recordAttempt({
    required String learnerId,
    required String skillId,
    required bool wasCorrect,
    List<String> errorTypeIds = const [],
    double responseTimeSeconds = 0,
    double expectedTimeSeconds = 5,
  }) async {
    final current = getState(learnerId: learnerId, skillId: skillId);

    final updated = current.recordAttempt(
      wasCorrect: wasCorrect,
      errorTypeIds: errorTypeIds,
      responseTimeSeconds: responseTimeSeconds,
      expectedTimeSeconds: expectedTimeSeconds,
    );

    // Update in-memory cache
    _states.putIfAbsent(learnerId, () => {})[skillId] = updated;

    // Persist asynchronously
    await _persistState(updated);

    // Propagate mastery changes to dependent skills
    _propagateMasteryChange(learnerId, skillId, updated);

    return updated;
  }

  /// Returns the next optimal skills to practice, ordered by priority.
  ///
  /// Priority is determined by:
  /// 1. Skills due for review (recall dropping below threshold)
  /// 2. Available skills not yet practiced (new learning)
  /// 3. Skills with high error concentration (targeted remediation)
  ///
  /// Respects skill dependencies — never recommends a locked skill.
  List<SkillRecommendation> getRecommendations({
    required String learnerId,
    required String languageCode,
    int count = 5,
  }) {
    final graph = SkillRegistry.instance.getGraph(languageCode);
    if (graph == null) return [];

    final mastered = getMasteredSkillIds(learnerId, languageCode);
    final available = graph.getAvailableSkills(mastered);
    final states = _states[learnerId] ?? {};

    final recommendations = <SkillRecommendation>[];

    // 1. Due for review (highest priority)
    for (final entry in states.entries) {
      final skill = SkillRegistry.instance.findSkill(entry.key);
      if (skill == null || skill.languageCode != languageCode) continue;

      final state = entry.value;
      if (state.isDueForReview && !state.isMastered) {
        recommendations.add(SkillRecommendation(
          skillId: entry.key,
          reason: RecommendationReason.dueForReview,
          priority: state.reviewUrgency,
          state: state,
        ));
      }
    }

    // 2. New skills available
    for (final skill in available) {
      if (!states.containsKey(skill.id)) {
        recommendations.add(SkillRecommendation(
          skillId: skill.id,
          reason: RecommendationReason.newSkill,
          priority: 0.5 + (skill.isRootSkill ? 0.2 : 0.0),
          state: null,
        ));
      }
    }

    // 3. Error-concentrated skills (targeted remediation)
    for (final entry in states.entries) {
      final state = entry.value;
      final errorSeverity = ErrorTaxonomy.weightedSeverity(
        state.errorDistribution.rates,
      );
      if (errorSeverity > 0.3 && !state.isMastered) {
        final skill = SkillRegistry.instance.findSkill(entry.key);
        if (skill?.languageCode != languageCode) continue;

        // Don't duplicate if already recommended for review
        if (recommendations.any((r) => r.skillId == entry.key)) continue;

        recommendations.add(SkillRecommendation(
          skillId: entry.key,
          reason: RecommendationReason.errorRemediation,
          priority: errorSeverity * 0.8,
          state: state,
        ));
      }
    }

    // Sort by priority (highest first) and return top N
    recommendations.sort((a, b) => b.priority.compareTo(a.priority));
    return recommendations.take(count).toList();
  }

  /// Returns cognitive metrics for the learner across all skills in a language.
  LearnerCognitiveMetrics getCognitiveMetrics({
    required String learnerId,
    required String languageCode,
  }) {
    final states = (_states[learnerId] ?? {}).values.where((s) {
      final skill = SkillRegistry.instance.findSkill(s.skillId);
      return skill?.languageCode == languageCode;
    }).toList();

    if (states.isEmpty) {
      return LearnerCognitiveMetrics.empty();
    }

    // Average mastery
    final avgMastery = states.fold<double>(0, (sum, s) => sum + s.mastery) / states.length;

    // Average half-life (memory stability)
    final avgHalfLife = states.fold<double>(0, (sum, s) => sum + s.halfLifeDays) / states.length;

    // Average recall probability right now
    final avgRecall = states.fold<double>(
          0,
          (sum, s) => sum + s.currentRecallProbability,
        ) /
        states.length;

    // Weakest skills
    final weakest = states.toList()
      ..sort((a, b) => a.mastery.compareTo(b.mastery));

    // Most volatile skills (lowest half-life relative to mastery)
    final volatile_ = states.where((s) => s.mastery > 0.3).toList()
      ..sort((a, b) => a.halfLifeDays.compareTo(b.halfLifeDays));

    // Error entropy across all skills
    final allErrors = <String, double>{};
    for (final state in states) {
      for (final entry in state.errorDistribution.rates.entries) {
        allErrors[entry.key] = (allErrors[entry.key] ?? 0) + entry.value;
      }
    }
    final errorEntropy = ErrorTaxonomy.errorEntropy(allErrors);

    // Skills mastered vs total
    final masteredCount = states.where((s) => s.isMastered).length;

    // Time pressure (automaticity)
    final avgTimePressure =
        states.fold<double>(0, (sum, s) => sum + s.timePressureScore) / states.length;

    return LearnerCognitiveMetrics(
      averageMastery: avgMastery,
      averageHalfLifeDays: avgHalfLife,
      averageRecallProbability: avgRecall,
      skillsMastered: masteredCount,
      skillsTotal: states.length,
      errorEntropy: errorEntropy,
      averageTimePressure: avgTimePressure,
      weakestSkillIds: weakest.take(5).map((s) => s.skillId).toList(),
      mostVolatileSkillIds: volatile_.take(5).map((s) => s.skillId).toList(),
      topErrors: ErrorTaxonomy.topErrors(allErrors),
    );
  }

  /// Exports all learner data for sync.
  Map<String, dynamic> exportForSync(String learnerId) {
    final states = _states[learnerId] ?? {};
    return {
      'learnerId': learnerId,
      'exportedAt': DateTime.now().toIso8601String(),
      'states': states.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  /// Imports learner data from sync, using learning-aware conflict resolution.
  ///
  /// Conflicts are resolved by most recent successful recall, not last write.
  Future<void> importFromSync(Map<String, dynamic> data) async {
    final learnerId = data['learnerId'] as String;
    final remoteStates = (data['states'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, LearnerSkillState.fromJson(v as Map<String, dynamic>)),
    );

    final localStates = _states[learnerId] ?? {};

    for (final entry in remoteStates.entries) {
      final local = localStates[entry.key];
      final remote = entry.value;

      if (local == null) {
        // No local state — accept remote
        _states.putIfAbsent(learnerId, () => {})[entry.key] = remote;
      } else {
        // Resolve conflict: prefer the state with the most recent successful recall
        final resolved = _resolveConflict(local, remote);
        _states[learnerId]![entry.key] = resolved;
      }

      await _persistState(_states[learnerId]![entry.key]!);
    }
  }

  /// Learning-aware conflict resolution.
  ///
  /// Priority: most recent successful recall > higher mastery > more attempts.
  LearnerSkillState _resolveConflict(
    LearnerSkillState local,
    LearnerSkillState remote,
  ) {
    // Most recent successful recall wins (learning-aware, not last-write-wins)
    if (local.lastRecall.isAfter(remote.lastRecall)) return local;
    if (remote.lastRecall.isAfter(local.lastRecall)) return remote;

    // Tie-break: higher mastery
    if (local.mastery > remote.mastery) return local;
    if (remote.mastery > local.mastery) return remote;

    // Tie-break: more attempts (more data)
    return local.totalAttempts >= remote.totalAttempts ? local : remote;
  }

  /// Propagates mastery changes to dependent skills.
  ///
  /// When a prerequisite becomes mastered, dependent skills may
  /// receive a slight mastery boost (transfer learning effect).
  void _propagateMasteryChange(
    String learnerId,
    String skillId,
    LearnerSkillState updatedState,
  ) {
    if (!updatedState.isMastered) return;

    final skill = SkillRegistry.instance.findSkill(skillId);
    if (skill == null) return;

    final graph = SkillRegistry.instance.getGraph(skill.languageCode);
    if (graph == null) return;

    final dependents = graph.getDependents(skillId);
    for (final dependent in dependents) {
      final depState = getState(learnerId: learnerId, skillId: dependent.id);

      // Small mastery boost from prerequisite completion (transfer effect)
      if (depState.mastery < 0.2) {
        final boosted = depState.copyWith(
          mastery: depState.mastery + 0.05,
        );
        _states.putIfAbsent(learnerId, () => {})[dependent.id] = boosted;
      }
    }
  }

  /// Retrieves tuned BKT params for a skill, falling back to type defaults.
  BktParams? _getBktParamsForSkill(String skillId) {
    final skill = SkillRegistry.instance.findSkill(skillId);
    if (skill == null) return null;

    // Check for skill-specific overrides
    if (skill.bktParamsOverride != null) {
      return BktParams(
        pL0: skill.bktParamsOverride!['pL0'] ?? BktMastery.defaultParams.pL0,
        pT: skill.bktParamsOverride!['pT'] ?? BktMastery.defaultParams.pT,
        pS: skill.bktParamsOverride!['pS'] ?? BktMastery.defaultParams.pS,
        pG: skill.bktParamsOverride!['pG'] ?? BktMastery.defaultParams.pG,
      );
    }

    // Type-based defaults: phonetic skills are harder to guess
    switch (skill.type) {
      case SkillType.phonetic:
        return const BktParams(pL0: 0.05, pT: 0.08, pS: 0.15, pG: 0.10);
      case SkillType.lexical:
        return const BktParams(pL0: 0.10, pT: 0.12, pS: 0.10, pG: 0.25);
      case SkillType.morphological:
        return const BktParams(pL0: 0.08, pT: 0.09, pS: 0.12, pG: 0.15);
      case SkillType.syntactic:
        return const BktParams(pL0: 0.08, pT: 0.10, pS: 0.10, pG: 0.20);
      case SkillType.semantic:
        return const BktParams(pL0: 0.10, pT: 0.11, pS: 0.08, pG: 0.30);
      case SkillType.pragmatic:
        return const BktParams(pL0: 0.05, pT: 0.07, pS: 0.12, pG: 0.15);
    }
  }

  Future<void> _persistState(LearnerSkillState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'learner_state_${state.learnerId}_${state.skillId}';
      await prefs.setString(key, jsonEncode(state.toJson()));
    } catch (_) {
      // Non-critical — state is in memory and will be retried
    }
  }
}

/// A skill recommendation with reasoning and priority.
class SkillRecommendation {
  final String skillId;
  final RecommendationReason reason;

  /// Priority score in [0, 1]. Higher = more urgent.
  final double priority;

  /// Current learner state for this skill (null for never-practiced skills).
  final LearnerSkillState? state;

  const SkillRecommendation({
    required this.skillId,
    required this.reason,
    required this.priority,
    this.state,
  });

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'reason': reason.name,
        'priority': priority,
        if (state != null) 'state': state!.toJson(),
      };
}

/// Why a skill was recommended.
enum RecommendationReason {
  /// Memory is decaying — needs review to maintain.
  dueForReview,

  /// New skill that is now unlocked by prerequisites.
  newSkill,

  /// Has concentrated errors that need targeted practice.
  errorRemediation,

  /// Prerequisite for a learner's goal skill.
  prerequisiteForGoal,

  /// Balances practice across skill types.
  diversification,
}

/// Aggregated cognitive metrics for a learner in a language.
class LearnerCognitiveMetrics {
  final double averageMastery;
  final double averageHalfLifeDays;
  final double averageRecallProbability;
  final int skillsMastered;
  final int skillsTotal;
  final double errorEntropy;
  final double averageTimePressure;
  final List<String> weakestSkillIds;
  final List<String> mostVolatileSkillIds;
  final List<MapEntry<String, double>> topErrors;

  const LearnerCognitiveMetrics({
    required this.averageMastery,
    required this.averageHalfLifeDays,
    required this.averageRecallProbability,
    required this.skillsMastered,
    required this.skillsTotal,
    required this.errorEntropy,
    required this.averageTimePressure,
    required this.weakestSkillIds,
    required this.mostVolatileSkillIds,
    required this.topErrors,
  });

  factory LearnerCognitiveMetrics.empty() => const LearnerCognitiveMetrics(
        averageMastery: 0,
        averageHalfLifeDays: 0,
        averageRecallProbability: 0,
        skillsMastered: 0,
        skillsTotal: 0,
        errorEntropy: 0,
        averageTimePressure: 0,
        weakestSkillIds: [],
        mostVolatileSkillIds: [],
        topErrors: [],
      );

  /// Skill mastery ratio.
  double get masteryRatio =>
      skillsTotal > 0 ? skillsMastered / skillsTotal : 0;

  /// Whether error distribution is concentrated (targetable) or diffuse.
  bool get hasTargetableErrors => errorEntropy < 2.0 && topErrors.isNotEmpty;

  /// Human-readable insight about weakest area.
  String? get weakestAreaInsight {
    if (topErrors.isEmpty) return null;
    final top = topErrors.first;
    final errorType = ErrorType.byId(top.key);
    if (errorType == null) return null;
    return 'Your most frequent challenge is ${errorType.name.toLowerCase()}.';
  }

  Map<String, dynamic> toJson() => {
        'averageMastery': averageMastery,
        'averageHalfLifeDays': averageHalfLifeDays,
        'averageRecallProbability': averageRecallProbability,
        'skillsMastered': skillsMastered,
        'skillsTotal': skillsTotal,
        'errorEntropy': errorEntropy,
        'averageTimePressure': averageTimePressure,
        'weakestSkillIds': weakestSkillIds,
        'mostVolatileSkillIds': mostVolatileSkillIds,
        'topErrors': topErrors.map((e) => {'id': e.key, 'rate': e.value}).toList(),
      };
}
