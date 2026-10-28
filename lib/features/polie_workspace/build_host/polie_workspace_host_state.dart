import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_screen_widget.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart' hide ConversationTurn;
import 'package:lingafriq/services/polie_tutor_saved_cards_service.dart';
import 'package:lingafriq/services/ai/conversation_persistence_service.dart';
import 'package:lingafriq/services/ai/polie_voice_input_service.dart';
import 'package:lingafriq/services/ai_gateway_client.dart';
import 'package:lingafriq/services/review_progress_service.dart';
import 'package:lingafriq/services/translation_history_service.dart';
import 'package:lingafriq/services/tutor_progress_service.dart';
import 'package:lingafriq/services/vocabulary/vocabulary_service.dart';
import 'package:lingafriq/services/vocabulary_progress_service.dart';

/// Mutable hook state bag for Polie workspace build host handlers (P12-005).
class PolieWorkspaceHostState {
  PolieWorkspaceHostState({
    required this.context,
    required this.ref,
    required this.screen,
    required this.isCompactTopBar,
    required this.activeMode,
    required this.activeTargetLanguage,
    required this.isBusy,
    required this.modeResponse,
    required this.modeError,
    required this.translationInput,
    required this.conversationInput,
    required this.tutorInput,
    required this.roleplayInput,
    required this.autoTranslate,
    required this.translationTone,
    required this.translationOutput,
    required this.translationHistoryQuery,
    required this.translationHistory,
    required this.translationTrayOpen,
    required this.translationTimer,
    required this.translationSourceLang,
    required this.translationTargetLang,
    required this.tutorLesson,
    required this.tutorFeedback,
    required this.tutorDifficulty,
    required this.tutorFlipped,
    required this.tutorAutoLoadInFlight,
    required this.tutorSeenConcepts,
    required this.tutorSavedCards,
    required this.tutorIsCurrentSaved,
    required this.roleplayDifficulty,
    required this.roleplayScene,
    required this.roleplayMessages,
    required this.conversationMessages,
    required this.languageRatio,
    required this.conversationIncludeEnglishTranslations,
    required this.conversationResponseStyle,
    required this.conversationStreamingTarget,
    required this.conversationStreamingActive,
    required this.conversationId,
    required this.voiceService,
    required this.voiceListening,
    required this.voiceErrorMessage,
    required this.pendingVoiceConversationText,
    required this.persistence,
    required this.conversationRestored,
    required this.vocabCard,
    required this.vocabReveal,
    required this.vocabDeckCount,
    required this.vocabSetName,
    required this.vocabDifficultyTarget,
    required this.vocabSrsChoice,
    required this.vocabShownWords,
    required this.reviewPayload,
    required this.reviewPeriod,
    required this.modeIntroDismissed,
    required this.chat,
    required this.gateway,
    required this.translationHistoryService,
    required this.tutorProgress,
    required this.vocabProgress,
    required this.vocabularyService,
    required this.reviewProgress,
    required this.streakDays,
  });

  final BuildContext context;
  final WidgetRef ref;
  final PolieWorkspaceScreen screen;
  final bool isCompactTopBar;

  final ValueNotifier<PolieMode> activeMode;
  final ValueNotifier<String> activeTargetLanguage;
  final ValueNotifier<bool> isBusy;
  final ValueNotifier<String> modeResponse;
  final ValueNotifier<String?> modeError;

  final TextEditingController translationInput;
  final TextEditingController conversationInput;
  final TextEditingController tutorInput;
  final TextEditingController roleplayInput;

  final ValueNotifier<bool> autoTranslate;
  final ValueNotifier<String> translationTone;
  final ValueNotifier<TranslationPayload?> translationOutput;
  final ValueNotifier<String> translationHistoryQuery;
  final ValueNotifier<List<dynamic>> translationHistory;
  final ValueNotifier<bool> translationTrayOpen;
  final ObjectRef<Timer?> translationTimer;
  final ValueNotifier<String> translationSourceLang;
  final ValueNotifier<String> translationTargetLang;

  final ValueNotifier<TutorLessonPayload?> tutorLesson;
  final ValueNotifier<TutorFeedbackPayload?> tutorFeedback;
  final ValueNotifier<String> tutorDifficulty;
  final ValueNotifier<bool> tutorFlipped;
  final ObjectRef<bool> tutorAutoLoadInFlight;
  final ObjectRef<Set<String>> tutorSeenConcepts;
  final ValueNotifier<List<PolieTutorSavedCard>> tutorSavedCards;
  final ValueNotifier<bool> tutorIsCurrentSaved;

  final ValueNotifier<String> roleplayDifficulty;
  final ValueNotifier<String> roleplayScene;
  final ValueNotifier<List<RoleplayTurn>> roleplayMessages;

  final ValueNotifier<List<ConversationTurn>> conversationMessages;
  final ValueNotifier<double> languageRatio;
  final ValueNotifier<bool> conversationIncludeEnglishTranslations;
  final ValueNotifier<String> conversationResponseStyle;
  final ValueNotifier<String> conversationStreamingTarget;
  final ValueNotifier<bool> conversationStreamingActive;
  final ValueNotifier<String?> conversationId;

  final PolieVoiceInputService voiceService;
  final ValueNotifier<bool> voiceListening;
  final ValueNotifier<String?> voiceErrorMessage;
  final ValueNotifier<String?> pendingVoiceConversationText;
  final ConversationPersistenceService persistence;
  final ObjectRef<bool> conversationRestored;

  final ValueNotifier<VocabPayload?> vocabCard;
  final ValueNotifier<bool> vocabReveal;
  final ValueNotifier<int> vocabDeckCount;
  final ValueNotifier<String> vocabSetName;
  final ValueNotifier<String> vocabDifficultyTarget;
  final ValueNotifier<String?> vocabSrsChoice;
  final ObjectRef<Set<String>> vocabShownWords;

  final ValueNotifier<ReviewPayload?> reviewPayload;
  final ValueNotifier<String> reviewPeriod;
  final ValueNotifier<Set<String>> modeIntroDismissed;

  final GroqChatProvider chat;
  final AiGatewayClient gateway;
  final TranslationHistoryService translationHistoryService;
  final TutorProgressService tutorProgress;
  final VocabularyProgressService vocabProgress;
  final VocabularyService vocabularyService;
  final ReviewProgressService reviewProgress;
  final ValueNotifier<int> streakDays;

  String get targetLanguage => activeTargetLanguage.value;
}
