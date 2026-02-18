import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/providers/dio_provider.dart';

import 'package:lingafriq/ai/persona_cognition/persona_cognition_engine.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/personas/historical_roleplay_controller.dart';
import 'package:lingafriq/ai/personas/roleplay_assessment_engine.dart';
import 'package:lingafriq/ai/personas/roleplay_safety_filter.dart';
import 'package:lingafriq/services/voice/persona_tts_controller.dart';
import 'package:lingafriq/services/classroom/classroom_persona_service.dart';
import 'package:lingafriq/services/classroom/cross_class_persona_memory.dart';
import 'package:lingafriq/learning/pronunciation/persona_pronunciation_service.dart';

const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

// ---------------------------------------------------------------------------
// Singleton service providers
// ---------------------------------------------------------------------------

final personaCognitionEngineProvider = Provider<PersonaCognitionEngine>((ref) {
  return PersonaCognitionEngine(
    dio: ref.watch(client),
    apiKey: EnvConfig.groqApiKey,
    apiUrl: _groqUrl,
  );
});

final historicalRoleplayControllerProvider =
    Provider<HistoricalRoleplayController>((ref) {
  return HistoricalRoleplayController(
    dio: ref.watch(client),
    apiKey: EnvConfig.groqApiKey,
    apiUrl: _groqUrl,
  );
});

final roleplayAssessmentEngineProvider =
    Provider<RoleplayAssessmentEngine>((ref) {
  return RoleplayAssessmentEngine(
    dio: ref.watch(client),
    apiKey: EnvConfig.groqApiKey,
    apiUrl: _groqUrl,
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
  final String? error;

  const PersonaChatState({
    this.activePersonaId,
    this.activePersona,
    this.messages = const [],
    this.isProcessing = false,
    this.isSpeaking = false,
    this.error,
  });

  PersonaChatState copyWith({
    String? activePersonaId,
    HistoricalPersona? activePersona,
    List<CognitionChatMessage>? messages,
    bool? isProcessing,
    bool? isSpeaking,
    String? error,
  }) =>
      PersonaChatState(
        activePersonaId: activePersonaId ?? this.activePersonaId,
        activePersona: activePersona ?? this.activePersona,
        messages: messages ?? this.messages,
        isProcessing: isProcessing ?? this.isProcessing,
        isSpeaking: isSpeaking ?? this.isSpeaking,
        error: error,
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

  void setPersona(String personaId) {
    final persona = HistoricalPersonaRegistry.findById(personaId);
    state = PersonaChatState(
      activePersonaId: personaId,
      activePersona: persona,
    );
    ref.read(personaTtsControllerProvider).setPersona(personaId);
  }

  Future<PersonaCognitionResult?> sendMessage(
    String message, {
    String? learnerId,
    String? languageCode,
  }) async {
    if (state.activePersonaId == null) return null;
    state = state.copyWith(isProcessing: true, error: null);

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
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return null;
    }
  }

  Future<void> _speakResponse(String text) async {
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
