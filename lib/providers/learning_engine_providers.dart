import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/providers/dio_provider.dart';

import 'package:lingafriq/ai/modes/polie_mode_controller.dart';
import 'package:lingafriq/ai/modes/mode_prompts.dart';
import 'package:lingafriq/ai/modes/roleplay_engine.dart';
import 'package:lingafriq/ai/pedagogy/error_classifier.dart' show PhonemeResult;
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';
import 'package:lingafriq/learning/scheduling/review_scheduler.dart';
import 'package:lingafriq/content/import_media/media_learning_pipeline.dart';
import 'package:lingafriq/services/social/peer_learning_service.dart';
import 'package:lingafriq/services/gamification/competence_gamification.dart';

// =============================================================================
// Service Providers (singletons)
// =============================================================================

final polieModeControllerProvider = Provider<PolieModeController>((ref) {
  final dio = ref.watch(client);
  return PolieModeController(
    dio: dio,
    apiKey: EnvConfig.groqApiKey,
    apiUrl: 'https://api.groq.com/openai/v1/chat/completions',
  );
});

final roleplayEngineProvider = Provider<RoleplayEngine>((ref) {
  final dio = ref.watch(client);
  return RoleplayEngine(
    dio: dio,
    apiKey: EnvConfig.groqApiKey,
    apiUrl: 'https://api.groq.com/openai/v1/chat/completions',
  );
});

final reviewSchedulerProvider = Provider<ReviewScheduler>((ref) {
  return ReviewScheduler();
});

final mediaLearningPipelineProvider = Provider<MediaLearningPipeline>((ref) {
  return MediaLearningPipeline();
});

final peerLearningServiceProvider = Provider<PeerLearningService>((ref) {
  return PeerLearningService();
});

final competenceGamificationProvider = Provider<CompetenceGamification>((ref) {
  return CompetenceGamification();
});

// =============================================================================
// Polie Mode State (manages active chat session across modes)
// =============================================================================

final polieModeStateProvider =
    NotifierProvider<PolieModeNotifier, PolieModeState>(
  PolieModeNotifier.new,
);

class PolieModeState {
  final PolieModeName activeMode;
  final String? activeLearnerId;
  final String? activeLanguageCode;
  final String? activeSkillId;
  final List<PolieModeResponse> history;
  final bool isProcessing;
  final String? error;

  const PolieModeState({
    this.activeMode = PolieModeName.tutor,
    this.activeLearnerId,
    this.activeLanguageCode,
    this.activeSkillId,
    this.history = const [],
    this.isProcessing = false,
    this.error,
  });

  PolieModeState copyWith({
    PolieModeName? activeMode,
    String? activeLearnerId,
    String? activeLanguageCode,
    String? activeSkillId,
    List<PolieModeResponse>? history,
    bool? isProcessing,
    String? error,
  }) =>
      PolieModeState(
        activeMode: activeMode ?? this.activeMode,
        activeLearnerId: activeLearnerId ?? this.activeLearnerId,
        activeLanguageCode: activeLanguageCode ?? this.activeLanguageCode,
        activeSkillId: activeSkillId ?? this.activeSkillId,
        history: history ?? this.history,
        isProcessing: isProcessing ?? this.isProcessing,
        error: error,
      );
}

class PolieModeNotifier extends Notifier<PolieModeState> {
  @override
  PolieModeState build() => const PolieModeState();

  void setSession({
    required String learnerId,
    required String languageCode,
    required String skillId,
    PolieModeName? mode,
  }) {
    state = state.copyWith(
      activeLearnerId: learnerId,
      activeLanguageCode: languageCode,
      activeSkillId: skillId,
      activeMode: mode ?? state.activeMode,
    );
  }

  void switchMode(PolieModeName mode) {
    state = state.copyWith(activeMode: mode, history: []);
  }

  Future<PolieModeResponse?> sendMessage(
    String message, {
    List<PhonemeResult>? phonemeResults,
    double responseTimeSeconds = 0,
  }) async {
    if (state.activeLearnerId == null || state.activeSkillId == null) return null;

    state = state.copyWith(isProcessing: true, error: null);

    try {
      final controller = ref.read(polieModeControllerProvider);
      final response = await controller.processMessage(
        mode: state.activeMode,
        learnerId: state.activeLearnerId!,
        languageCode: state.activeLanguageCode ?? 'en',
        message: message,
        targetSkillId: state.activeSkillId!,
        phonemeResults: phonemeResults,
        responseTimeSeconds: responseTimeSeconds,
      );

      state = state.copyWith(
        isProcessing: false,
        history: [...state.history, response],
      );

      // Trigger sync after successful interaction
      ref.read(learningSyncServiceProvider).queueStateSync(
            state.activeLearnerId!,
            state.activeSkillId!,
          );

      return response;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return null;
    }
  }
}

// =============================================================================
// Review Session State
// =============================================================================

final reviewSessionProvider =
    NotifierProvider<ReviewSessionNotifier, ReviewSessionState>(
  ReviewSessionNotifier.new,
);

class ReviewSessionState {
  final ReviewSession? activeSession;
  final int currentItemIndex;
  final List<bool> results;
  final bool isActive;
  final bool shouldStop;

  const ReviewSessionState({
    this.activeSession,
    this.currentItemIndex = 0,
    this.results = const [],
    this.isActive = false,
    this.shouldStop = false,
  });

  ReviewSessionState copyWith({
    ReviewSession? activeSession,
    int? currentItemIndex,
    List<bool>? results,
    bool? isActive,
    bool? shouldStop,
  }) =>
      ReviewSessionState(
        activeSession: activeSession ?? this.activeSession,
        currentItemIndex: currentItemIndex ?? this.currentItemIndex,
        results: results ?? this.results,
        isActive: isActive ?? this.isActive,
        shouldStop: shouldStop ?? this.shouldStop,
      );

  ReviewSessionItem? get currentItem {
    if (activeSession == null) return null;
    if (currentItemIndex >= activeSession!.items.length) return null;
    return activeSession!.items[currentItemIndex];
  }

  double get completionRatio {
    if (activeSession == null || activeSession!.items.isEmpty) return 0;
    return currentItemIndex / activeSession!.items.length;
  }
}

class ReviewSessionNotifier extends Notifier<ReviewSessionState> {
  @override
  ReviewSessionState build() => const ReviewSessionState();

  void startSession({
    required String learnerId,
    required String languageCode,
  }) {
    final scheduler = ref.read(reviewSchedulerProvider);
    final session = scheduler.generateSession(
      learnerId: learnerId,
      languageCode: languageCode,
    );

    state = ReviewSessionState(
      activeSession: session,
      currentItemIndex: 0,
      results: [],
      isActive: true,
    );
  }

  void recordResult(bool wasCorrect) {
    final newResults = [...state.results, wasCorrect];
    final scheduler = ref.read(reviewSchedulerProvider);
    final shouldStop = scheduler.shouldStopSession(recentResults: newResults);

    state = state.copyWith(
      results: newResults,
      currentItemIndex: state.currentItemIndex + 1,
      shouldStop: shouldStop,
      isActive: !shouldStop &&
          state.currentItemIndex + 1 < (state.activeSession?.items.length ?? 0),
    );
  }

  void endSession() {
    state = const ReviewSessionState();
  }
}

// =============================================================================
// Competence Achievement State
// =============================================================================

final competenceAchievementProvider = Provider.family<
    List<CompetenceAchievement>,
    (String learnerId, String languageCode)>((ref, params) {
  final gamification = ref.watch(competenceGamificationProvider);
  return gamification.evaluateAchievements(
    learnerId: params.$1,
    languageCode: params.$2,
    previouslyEarned: {},
  );
});

final competenceLevelProvider = Provider.family<
    CompetenceLevel,
    (String learnerId, String languageCode)>((ref, params) {
  final gamification = ref.watch(competenceGamificationProvider);
  return gamification.getCompetenceLevel(
    learnerId: params.$1,
    languageCode: params.$2,
  );
});

final dailyInsightProvider = Provider.family<
    String,
    (String learnerId, String languageCode)>((ref, params) {
  final gamification = ref.watch(competenceGamificationProvider);
  return gamification.generateDailyInsight(
    learnerId: params.$1,
    languageCode: params.$2,
  );
});

final progressPredictionProvider = Provider.family<
    ProgressPrediction,
    (String learnerId, String languageCode)>((ref, params) {
  final gamification = ref.watch(competenceGamificationProvider);
  return gamification.predictTomorrow(
    learnerId: params.$1,
    languageCode: params.$2,
  );
});

// =============================================================================
// Learning Sync Service (bridges local → backend)
// =============================================================================

final learningSyncServiceProvider = Provider<LearningSyncService>((ref) {
  final dio = ref.watch(client);
  return LearningSyncService(dio: dio);
});

class LearningSyncService {
  final Dio _dio;
  final List<_PendingSyncItem> _queue = [];

  LearningSyncService({required Dio dio}) : _dio = dio;

  void queueStateSync(String learnerId, String skillId) {
    _queue.add(_PendingSyncItem(
      type: 'learner_state',
      learnerId: learnerId,
      skillId: skillId,
      timestamp: DateTime.now(),
    ));
  }

  void queueAchievementSync(String learnerId, String achievementId) {
    _queue.add(_PendingSyncItem(
      type: 'achievement',
      learnerId: learnerId,
      skillId: achievementId,
      timestamp: DateTime.now(),
    ));
  }

  void queuePeerCorrectionSync(String correctionId) {
    _queue.add(_PendingSyncItem(
      type: 'peer_correction',
      learnerId: correctionId,
      skillId: '',
      timestamp: DateTime.now(),
    ));
  }

  Future<int> syncPending() async {
    if (_queue.isEmpty) return 0;

    final batch = List<_PendingSyncItem>.from(_queue);
    _queue.clear();

    int synced = 0;
    for (final item in batch) {
      try {
        switch (item.type) {
          case 'learner_state':
            final state = LearnerModelService.instance.getState(
              learnerId: item.learnerId,
              skillId: item.skillId,
            );
            await _dio.post(
              ApiContract.url(ApiContract.learning.syncState),
              data: {
                'learnerId': item.learnerId,
                'skillId': item.skillId,
                'state': state.toJson(),
              },
            );
            synced++;
            break;

          case 'achievement':
            await _dio.post(
              ApiContract.url(ApiContract.learning.syncAchievement),
              data: {
                'learnerId': item.learnerId,
                'achievementId': item.skillId,
                'timestamp': item.timestamp.toIso8601String(),
              },
            );
            synced++;
            break;

          case 'peer_correction':
            await _dio.post(
              ApiContract.url(ApiContract.learning.syncCorrection),
              data: {
                'correctionId': item.learnerId,
                'timestamp': item.timestamp.toIso8601String(),
              },
            );
            synced++;
            break;
        }
      } catch (_) {
        _queue.add(item);
      }
    }

    return synced;
  }
}

class _PendingSyncItem {
  final String type;
  final String learnerId;
  final String skillId;
  final DateTime timestamp;

  const _PendingSyncItem({
    required this.type,
    required this.learnerId,
    required this.skillId,
    required this.timestamp,
  });
}
