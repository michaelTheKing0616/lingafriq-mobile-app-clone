import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/services/ai_gateway_client.dart';

import 'package:lingafriq/ai/persona_cognition/epistemic_classifier.dart';
import 'package:lingafriq/ai/persona_cognition/persona_cognition_engine.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/personas/historical_roleplay_controller.dart';
import 'package:lingafriq/ai/personas/roleplay_assessment_engine.dart';
import 'package:lingafriq/ai/personas/roleplay_safety_filter.dart';
import 'package:lingafriq/services/performance/low_bandwidth_mode.dart';
import 'package:lingafriq/services/voice/persona_tts_controller.dart';
import 'package:lingafriq/services/classroom/classroom_persona_service.dart';
import 'package:lingafriq/services/classroom/cross_class_persona_memory.dart';
import 'package:lingafriq/learning/pronunciation/persona_pronunciation_service.dart';
import 'package:lingafriq/ai/persona_cognition/groq_two_pass_orchestrator.dart';

/// Shown when the server kill switch blocks a persona (P11-009).
const kPersonaUnavailableCopy =
    'This historical persona is temporarily unavailable. Try again later.';

// ---------------------------------------------------------------------------
// Singleton service providers
// ---------------------------------------------------------------------------

/// Server-backed persona availability (global or per-persona kill switch).
class PersonaKillSwitchClient {
  PersonaKillSwitchClient(this._dio);

  final Dio _dio;

  static const availabilityPath = '/api/ai/persona/availability';

  Future<bool> isPersonaAvailable(String personaId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$availabilityPath/${personaId.trim().toLowerCase()}',
      );
      final data = response.data;
      if (data == null || data['ok'] != true) return true;
      return data['available'] == true;
    } catch (_) {
      return true;
    }
  }
}

final personaKillSwitchClientProvider = Provider<PersonaKillSwitchClient>((ref) {
  return PersonaKillSwitchClient(ref.watch(client));
});

final personaCognitionEngineProvider = Provider<PersonaCognitionEngine>((ref) {
  final dio = ref.watch(client);
  return PersonaCognitionEngine(
    dio: dio,
    horizonModel: GatewayHorizonClassifierModel(dio),
  );
});

final historicalRoleplayControllerProvider =
    Provider<HistoricalRoleplayController>((ref) {
  return HistoricalRoleplayController(dio: ref.watch(client));
});

final roleplayAssessmentEngineProvider =
    Provider<RoleplayAssessmentEngine>((ref) {
  return RoleplayAssessmentEngine(
    dio: ref.watch(client),
    apiKey: '',
    apiUrl: ApiContract.ai.chatCompletion,
  );
});

final roleplaySafetyFilterProvider = Provider<RoleplaySafetyFilter>((ref) {
  return RoleplaySafetyFilter();
});

final personaTtsControllerProvider = Provider<PersonaTtsController>((ref) {
  return PersonaTtsController();
});

final crossClassPersonaMemoryProvider =
    Provider<CrossClassPersonaMemory>((ref) {
  return CrossClassPersonaMemory.instance;
});

final classroomPersonaServiceProvider =
    Provider.family<ClassroomPersonaService, String>((ref, personaId) {
  return ClassroomPersonaService(personaId);
});

final personaPronunciationServiceProvider =
    Provider<PersonaPronunciationService>((ref) {
  return PersonaPronunciationService();
});

// ---------------------------------------------------------------------------
// Persona chat state (manages active roleplay session via cognition engine)
// ---------------------------------------------------------------------------

class CognitionChatMessage {
  final String role;
  final String displayText;
  final PersonaCognitionResult? cognitionResult;
  final DateTime timestamp;

  const CognitionChatMessage({
    required this.role,
    required this.displayText,
    this.cognitionResult,
    required this.timestamp,
  });
}

class PersonaChatState {
  final String? activePersonaId;
  final HistoricalPersona? activePersona;
  final List<CognitionChatMessage> messages;
  final bool isProcessing;
  final bool isSpeaking;
  final bool personaUnavailable;
  final String? error;

  const PersonaChatState({
    this.activePersonaId,
    this.activePersona,
    this.messages = const [],
    this.isProcessing = false,
    this.isSpeaking = false,
    this.personaUnavailable = false,
    this.error,
  });

  PersonaChatState copyWith({
    String? activePersonaId,
    HistoricalPersona? activePersona,
    List<CognitionChatMessage>? messages,
    bool? isProcessing,
    bool? isSpeaking,
    bool? personaUnavailable,
    String? error,
    bool clearError = false,
  }) =>
      PersonaChatState(
        activePersonaId: activePersonaId ?? this.activePersonaId,
        activePersona: activePersona ?? this.activePersona,
        messages: messages ?? this.messages,
        isProcessing: isProcessing ?? this.isProcessing,
        isSpeaking: isSpeaking ?? this.isSpeaking,
        personaUnavailable: personaUnavailable ?? this.personaUnavailable,
        error: clearError ? null : (error ?? this.error),
      );

  List<String> get conversationHistory => messages
      .map((m) =>
          m.role == 'user' ? 'Learner: ${m.displayText}' : 'Persona: ${m.displayText}')
      .toList();
}

final personaChatProvider =
    NotifierProvider<PersonaChatNotifier, PersonaChatState>(
  PersonaChatNotifier.new,
);

class PersonaChatNotifier extends Notifier<PersonaChatState> {
  @override
  PersonaChatState build() => const PersonaChatState();

  Future<void> setPersona(String personaId) async {
    final persona = HistoricalPersonaRegistry.findById(personaId);
    state = PersonaChatState(
      activePersonaId: personaId,
      activePersona: persona,
      personaUnavailable: false,
      error: null,
    );
    ref.read(personaTtsControllerProvider).setPersona(personaId);

    final available =
        await ref.read(personaKillSwitchClientProvider).isPersonaAvailable(personaId);
    if (!available) {
      state = state.copyWith(
        personaUnavailable: true,
        error: kPersonaUnavailableCopy,
      );
    }
  }

  void markPersonaUnavailable([String message = kPersonaUnavailableCopy]) {
    state = state.copyWith(
      isProcessing: false,
      personaUnavailable: true,
      error: message,
    );
  }

  Future<PersonaCognitionResult?> sendMessage(
    String message, {
    String? learnerId,
    String? languageCode,
  }) async {
    if (state.activePersonaId == null) return null;
    if (state.personaUnavailable) {
      state = state.copyWith(error: kPersonaUnavailableCopy);
      return null;
    }
    state = state.copyWith(isProcessing: true, clearError: true);

    state = state.copyWith(
      messages: [
        ...state.messages,
        CognitionChatMessage(
          role: 'user',
          displayText: message,
          timestamp: DateTime.now(),
        ),
      ],
    );

    try {
      final engine = ref.read(personaCognitionEngineProvider);
      final result = await engine.processInput(
        personaId: state.activePersonaId!,
        userInput: message,
        learnerId: learnerId ?? 'anonymous',
        languageCode: languageCode ?? 'en',
        conversationHistory: state.conversationHistory,
      );

      state = state.copyWith(
        isProcessing: false,
        messages: [
          ...state.messages,
          CognitionChatMessage(
            role: 'persona',
            displayText: result.personaReply,
            cognitionResult: result,
            timestamp: DateTime.now(),
          ),
        ],
      );

      _speakResponse(result.personaReply);
      return result;
    } on PersonaTurnGatewayError catch (e) {
      if (e.code == 'PersonaDisabled') {
        markPersonaUnavailable(kPersonaUnavailableCopy);
      } else {
        state = state.copyWith(isProcessing: false, error: e.message);
      }
      return null;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return null;
    }
  }

  Future<void> _speakResponse(String text) async {
    if (!loadAudioImmediately(LowBandwidthMode.instance.decision)) return;
    state = state.copyWith(isSpeaking: true);
    try {
      await ref.read(personaTtsControllerProvider).speak(text);
    } catch (_) {
      // TTS failure is non-critical
    } finally {
      state = state.copyWith(isSpeaking: false);
    }
  }

  Future<void> speakMessage(String text) async {
    await _speakResponse(text);
  }

  void interrupt() {
    ref.read(personaTtsControllerProvider).interrupt();
    state = state.copyWith(isSpeaking: false);
  }

  RoleplayAssessmentReport? generateAssessment(String learnerId) {
    // Assessment requires conversation history; delegate to assessment engine synchronously
    // (full implementation would call the async API version)
    return null;
  }

  void clearSession() {
    state = const PersonaChatState();
  }
}
