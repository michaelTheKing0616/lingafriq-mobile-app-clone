import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';
import 'package:lingafriq/learning/skill_graph/skill_registry.dart';

/// Provides the LearnerModelService as a singleton via Riverpod.
final learnerModelServiceProvider = Provider<LearnerModelService>((ref) {
  return LearnerModelService.instance;
});

/// Provides the SkillRegistry as a singleton via Riverpod.
final skillRegistryProvider = Provider<SkillRegistry>((ref) {
  return SkillRegistry.instance;
});

/// Provides the current learner's skill state for a specific skill.
///
/// Usage: `ref.watch(learnerSkillStateProvider(('learnerId', 'skillId')))`
final learnerSkillStateProvider =
    Provider.family<LearnerSkillState, (String learnerId, String skillId)>(
  (ref, params) {
    final service = ref.watch(learnerModelServiceProvider);
    return service.getState(
      learnerId: params.$1,
      skillId: params.$2,
    );
  },
);

/// Provides skill recommendations for a learner in a specific language.
///
/// Usage: `ref.watch(skillRecommendationsProvider(('learnerId', 'langCode')))`
final skillRecommendationsProvider =
    Provider.family<List<SkillRecommendation>, (String learnerId, String languageCode)>(
  (ref, params) {
    final service = ref.watch(learnerModelServiceProvider);
    return service.getRecommendations(
      learnerId: params.$1,
      languageCode: params.$2,
    );
  },
);

/// Provides cognitive metrics for a learner in a specific language.
///
/// Usage: `ref.watch(cognitiveMetricsProvider(('learnerId', 'langCode')))`
final cognitiveMetricsProvider =
    Provider.family<LearnerCognitiveMetrics, (String learnerId, String languageCode)>(
  (ref, params) {
    final service = ref.watch(learnerModelServiceProvider);
    return service.getCognitiveMetrics(
      learnerId: params.$1,
      languageCode: params.$2,
    );
  },
);

/// Provides mastered skill IDs for a learner in a specific language.
final masteredSkillsProvider =
    Provider.family<Set<String>, (String learnerId, String languageCode)>(
  (ref, params) {
    final service = ref.watch(learnerModelServiceProvider);
    return service.getMasteredSkillIds(params.$1, params.$2);
  },
);

/// Stateful notifier for managing learner model interactions.
///
/// Handles recording attempts and refreshing derived providers.
class LearnerModelNotifier extends Notifier<LearnerModelState> {
  @override
  LearnerModelState build() {
    return const LearnerModelState();
  }

  /// Records a practice attempt and triggers state refresh.
  Future<LearnerSkillState> recordAttempt({
    required String learnerId,
    required String skillId,
    required bool wasCorrect,
    List<String> errorTypeIds = const [],
    double responseTimeSeconds = 0,
    double expectedTimeSeconds = 5,
  }) async {
    state = state.copyWith(isProcessing: true);

    try {
      final service = ref.read(learnerModelServiceProvider);
      final updated = await service.recordAttempt(
        learnerId: learnerId,
        skillId: skillId,
        wasCorrect: wasCorrect,
        errorTypeIds: errorTypeIds,
        responseTimeSeconds: responseTimeSeconds,
        expectedTimeSeconds: expectedTimeSeconds,
      );

      state = state.copyWith(
        isProcessing: false,
        lastUpdatedSkillId: skillId,
        lastUpdateTimestamp: DateTime.now(),
      );

      // Invalidate dependent providers
      ref.invalidateSelf();

      return updated;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Initializes the learner model and skill registry.
  Future<void> initialize() async {
    state = state.copyWith(isProcessing: true);

    try {
      await SkillRegistry.instance.initialize();
      await LearnerModelService.instance.initialize();

      state = state.copyWith(
        isProcessing: false,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to initialize learner model: $e',
      );
    }
  }
}

/// State for the LearnerModelNotifier.
class LearnerModelState {
  final bool isProcessing;
  final bool isInitialized;
  final String? error;
  final String? lastUpdatedSkillId;
  final DateTime? lastUpdateTimestamp;

  const LearnerModelState({
    this.isProcessing = false,
    this.isInitialized = false,
    this.error,
    this.lastUpdatedSkillId,
    this.lastUpdateTimestamp,
  });

  LearnerModelState copyWith({
    bool? isProcessing,
    bool? isInitialized,
    String? error,
    String? lastUpdatedSkillId,
    DateTime? lastUpdateTimestamp,
  }) {
    return LearnerModelState(
      isProcessing: isProcessing ?? this.isProcessing,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
      lastUpdatedSkillId: lastUpdatedSkillId ?? this.lastUpdatedSkillId,
      lastUpdateTimestamp: lastUpdateTimestamp ?? this.lastUpdateTimestamp,
    );
  }
}

/// Provider for the LearnerModelNotifier.
final learnerModelProvider =
    NotifierProvider<LearnerModelNotifier, LearnerModelState>(
  LearnerModelNotifier.new,
);
