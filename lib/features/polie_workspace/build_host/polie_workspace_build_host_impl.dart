import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/content/lingafriq_ux_voice.dart';
import 'package:lingafriq/models/correction_result.dart';
import 'package:lingafriq/models/translation_history_model.dart';
import 'package:lingafriq/models/tutor_progress_model.dart';
import 'package:lingafriq/models/vocabulary_progress_model.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_parsing.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_language_sheet.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_ui_helpers.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_mode_surface.dart';
import 'package:lingafriq/services/ai_gateway_client.dart';
import 'package:lingafriq/utils/supported_languages.dart';
import 'package:lingafriq/content/polie_conversation_prompt_builder.dart';
import 'package:lingafriq/services/ai/conversation_persistence_service.dart';
import 'package:lingafriq/services/ai/polie_conversation_stream_service.dart';
import 'package:lingafriq/services/ai/polie_voice_input_service.dart';
import 'package:lingafriq/services/content/polie_prompt_service.dart';
import 'package:lingafriq/services/content/polie_conversation_service.dart';
import 'package:lingafriq/services/review_progress_service.dart';
import 'package:lingafriq/services/translation_history_service.dart';
import 'package:lingafriq/services/tutor_progress_service.dart';
import 'package:lingafriq/services/vocabulary/vocabulary_service.dart';
import 'package:lingafriq/services/vocabulary_progress_service.dart';
import 'package:lingafriq/services/hybrid_polie/translation_service.dart';
import 'package:lingafriq/services/polie_tutor_saved_cards_service.dart';
import 'package:lingafriq/services/telemetry_service.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';
import 'package:lingafriq/utils/diacritics_enforcer.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/data/polie_translate_language_options.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart' as uuid;

import 'package:lingafriq/features/polie_workspace/polie_workspace_history_helpers.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_screen_widget.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_tx_helpers.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_runtime.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_build_host_scaffold.dart';

class PolieWorkspaceBuildHost extends HookConsumerWidget {
  const PolieWorkspaceBuildHost({super.key, required this.screen});
  final PolieWorkspaceScreen screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isCompactTopBar = viewportWidth < 420;
    final activeMode = useState<PolieMode>(
      screen.conversationOnly ? PolieMode.conversation : screen.initialMode,
    );
    // Live target language — switchable via the AppBar language pill.
    final activeTargetLanguage = useState<String>(screen.targetLanguage);
    final targetLanguage = activeTargetLanguage.value;
    final isBusy = useState<bool>(false);
    final modeResponse = useState<String>('');
    final modeError = useState<String?>(null);

    final translationInput = useTextEditingController();
    final conversationInput = useTextEditingController();
    final tutorInput = useTextEditingController();
    final roleplayInput = useTextEditingController();
    useListenable(translationInput);

    final autoTranslate = useState<bool>(true);
    final translationTone = useState<String>('formal');
    final translationOutput = useState<TranslationPayload?>(null);
    final translationHistoryQuery = useState<String>('');
    final translationHistory = useState<List<dynamic>>([]);
    final translationTrayOpen = useState<bool>(true);
    final translationTimer = useRef<Timer?>(null);
    final translationSourceLang =
        useState<String>(polieTxInitLabel(screen.sourceLanguage));
    final translationTargetLang =
        useState<String>(polieTxInitLabel(screen.targetLanguage));

    final tutorLesson = useState<TutorLessonPayload?>(null);
    final tutorFeedback = useState<TutorFeedbackPayload?>(null);
    final tutorDifficulty = useState<String>('beginner');
    final tutorFlipped = useState<bool>(false);
    final tutorAutoLoadInFlight = useRef<bool>(false);
    final tutorSeenConcepts = useRef<Set<String>>({});
    final tutorSavedCards = useState<List<PolieTutorSavedCard>>([]);
    final tutorIsCurrentSaved = useState<bool>(false);

    final roleplayDifficulty = useState<String>('bilingual');
    final roleplayScene = useState<String>(
      normalizeInitialRoleplayScene(screen.initialRoleplayScene),
    );
    final roleplayMessages = useState<List<RoleplayTurn>>([]);

    final conversationMessages = useState<List<ConversationTurn>>([]);
    final languageRatio = useState<double>(0);
    final conversationIncludeEnglishTranslations = useState<bool>(false);
    final conversationResponseStyle = useState<String>('lengthy');
    // Live streaming state: holds the active in-flight assistant message so we
    // can render token-by-token while the SSE stream is open. Cleared once the
    // 'final' event lands or the stream errors.
    final conversationStreamingTarget = useState<String>('');
    final conversationStreamingActive = useState<bool>(false);
    final conversationId = useState<String?>(null);
    // Voice input (mic-to-text). Built once and disposed with the widget.
    final voiceService = useMemoized(() => PolieVoiceInputService(), const []);
    useEffect(() {
      return () => voiceService.dispose();
    }, const []);
    final voiceListening = useState<bool>(false);
    final voiceErrorMessage = useState<String?>(null);
    final pendingVoiceConversationText = useState<String?>(null);
    final persistence = useMemoized(
      () => ConversationPersistenceService(),
      const [],
    );
    final conversationRestored = useRef<bool>(false);
    // Restore the most-recent persisted conversation on first build so the UI
    // boots with continuity across app restarts. Cancelled if the user has
    // already begun typing in this session.
    useEffect(() {
      if (conversationRestored.value) return null;
      conversationRestored.value = true;
      () async {
        try {
          final doc = await persistence.restoreMostRecent();
          if (doc == null || doc.turns.isEmpty) return;
          // Only restore if the user hasn't started a fresh conversation.
          if (conversationMessages.value.isNotEmpty) return;
          final restored = <ConversationTurn>[];
          for (final t in doc.turns) {
            if (t.role == 'user') {
              if (t.text.trim().isNotEmpty) {
                restored.add(ConversationTurn.user(t.text));
              }
            } else {
              if (t.isError) {
                restored.add(
                  ConversationTurn.aiError(
                    t.errorMessage ??
                        'Polie could not generate a reply just now. Tap retry to try again.',
                  ),
                );
              } else if (t.text.trim().isNotEmpty) {
                restored.add(
                  ConversationTurn.ai(
                    ConversationPayload(
                      messageTarget: t.text,
                      englishTranslation: t.englishTranslation,
                      correction: t.correction != null
                          ? ConversationCorrection(
                              tier: t.correction!.tier,
                              hasCorrection: t.correction!.hasCorrection,
                              wasCorrect: t.correction!.wasCorrect,
                              correction: t.correction!.correction,
                              note: t.correction!.note,
                            )
                          : const ConversationCorrection(
                              tier: 'correct',
                              hasCorrection: false,
                              wasCorrect: true,
                              correction: null,
                              note: '',
                            ),
                      suggestedReplies: t.suggestedReplies,
                      newVocab: t.newVocab
                          .map(
                            (v) => ConversationVocab(
                              word: v.word,
                              meaning: v.meaning,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              }
            }
          }
          conversationMessages.value = restored;
          conversationId.value = doc.conversationId;
          if (doc.language.isNotEmpty &&
              doc.language != activeTargetLanguage.value) {
            activeTargetLanguage.value = doc.language;
          }
        } catch (e) {
          debugPrint('[Polie] conversation restore failed: $e');
        }
      }();
      return null;
    }, const []);

    final vocabCard = useState<VocabPayload?>(null);
    final vocabReveal = useState<bool>(false);
    final vocabDeckCount = useState<int>(10);
    final vocabSetName = useState<String>('Core Daily Words');
    final vocabDifficultyTarget = useState<String>('mixed');
    final vocabSrsChoice = useState<String?>(null);
    final vocabShownWords = useRef<Set<String>>({});

    final reviewPayload = useState<ReviewPayload?>(null);
    final reviewPeriod = useState<String>('week');
    final modeIntroDismissed = useState<Set<String>>({});

    final chat = ref.read(groqChatProvider.notifier);
    final gateway = AiGatewayClient(ref.read(client));

    final translationHistoryService = ref.read(
      translationHistoryServiceProvider,
    );
    final tutorProgress = ref.read(tutorProgressServiceProvider);
    final vocabProgress = ref.read(vocabularyProgressServiceProvider);
    final vocabularyService = ref.read(vocabularyServiceProvider);
    final reviewProgress = ref.read(reviewProgressServiceProvider);
    final streakDays = useState<int>(0);

    final host = PolieWorkspaceHostRuntime(
      context: context,
      ref: ref,
      screen: screen,
      isCompactTopBar: isCompactTopBar,
      activeMode: activeMode,
      activeTargetLanguage: activeTargetLanguage,
      isBusy: isBusy,
      modeResponse: modeResponse,
      modeError: modeError,
      translationInput: translationInput,
      conversationInput: conversationInput,
      tutorInput: tutorInput,
      roleplayInput: roleplayInput,
      autoTranslate: autoTranslate,
      translationTone: translationTone,
      translationOutput: translationOutput,
      translationHistoryQuery: translationHistoryQuery,
      translationHistory: translationHistory,
      translationTrayOpen: translationTrayOpen,
      translationTimer: translationTimer,
      translationSourceLang: translationSourceLang,
      translationTargetLang: translationTargetLang,
      tutorLesson: tutorLesson,
      tutorFeedback: tutorFeedback,
      tutorDifficulty: tutorDifficulty,
      tutorFlipped: tutorFlipped,
      tutorAutoLoadInFlight: tutorAutoLoadInFlight,
      tutorSeenConcepts: tutorSeenConcepts,
      tutorSavedCards: tutorSavedCards,
      tutorIsCurrentSaved: tutorIsCurrentSaved,
      roleplayDifficulty: roleplayDifficulty,
      roleplayScene: roleplayScene,
      roleplayMessages: roleplayMessages,
      conversationMessages: conversationMessages,
      languageRatio: languageRatio,
      conversationIncludeEnglishTranslations: conversationIncludeEnglishTranslations,
      conversationResponseStyle: conversationResponseStyle,
      conversationStreamingTarget: conversationStreamingTarget,
      conversationStreamingActive: conversationStreamingActive,
      conversationId: conversationId,
      voiceService: voiceService,
      voiceListening: voiceListening,
      voiceErrorMessage: voiceErrorMessage,
      pendingVoiceConversationText: pendingVoiceConversationText,
      persistence: persistence,
      conversationRestored: conversationRestored,
      vocabCard: vocabCard,
      vocabReveal: vocabReveal,
      vocabDeckCount: vocabDeckCount,
      vocabSetName: vocabSetName,
      vocabDifficultyTarget: vocabDifficultyTarget,
      vocabSrsChoice: vocabSrsChoice,
      vocabShownWords: vocabShownWords,
      reviewPayload: reviewPayload,
      reviewPeriod: reviewPeriod,
      modeIntroDismissed: modeIntroDismissed,
      chat: chat,
      gateway: gateway,
      translationHistoryService: translationHistoryService,
      tutorProgress: tutorProgress,
      vocabProgress: vocabProgress,
      vocabularyService: vocabularyService,
      reviewProgress: reviewProgress,
      streakDays: streakDays,
    );

    useEffect(() {
      Future.microtask(() async {
        await host.loadTutorSeenConcepts();
        await host.refreshTutorSavedCards();
      });
      return null;
    }, [tutorDifficulty.value, targetLanguage]);

    useEffect(() {
      reviewProgress.loadStatistics(targetLanguage).then((stats) {
        streakDays.value = stats.currentStreak;
      });
      return null;
    }, [targetLanguage]);

    useEffect(() {
      final init = screen.conversationOnly ? PolieMode.conversation : screen.initialMode;
      host.setMode(init);
      host.loadTranslationHistory();
      if (init == PolieMode.tutor) host.loadTutorLesson();
      if (init == PolieMode.vocab) host.loadVocabCard();
      if (init == PolieMode.review) host.loadReview();
      SharedPreferences.getInstance().then((prefs) {
        final dismissed = <String>{};
        for (final m in PolieMode.values) {
          if (prefs.getBool('polie_mode_intro_${m.name}_dismissed') ?? false) {
            dismissed.add(m.name);
          }
        }
        modeIntroDismissed.value = dismissed;
      });
      return null;
    }, const []);

    useEffect(() {
      if (activeMode.value == PolieMode.tutor &&
          tutorLesson.value == null &&
          !isBusy.value) {
        Future.microtask(host.loadTutorLesson);
      }
      if (activeMode.value == PolieMode.vocab &&
          vocabCard.value == null &&
          !isBusy.value) {
        Future.microtask(host.loadVocabCard);
      }
      return null;
    }, [activeMode.value]);

    useEffect(
      () {
        translationTimer.value?.cancel();
        if (!autoTranslate.value) return null;
        final text = translationInput.text.trim();
        if (activeMode.value == PolieMode.translation && text.isNotEmpty) {
          translationTimer.value = Timer(const Duration(milliseconds: 500), () {
            host.runTranslation(text);
          });
        }
        return () => translationTimer.value?.cancel();
      },
      [
        translationInput.text,
        autoTranslate.value,
        activeMode.value,
        translationTone.value,
        translationSourceLang.value,
        translationTargetLang.value,
      ],
    );

    // Fire translation immediately when auto-translate is toggled ON with existing input
    useEffect(() {
      if (autoTranslate.value && activeMode.value == PolieMode.translation) {
        final text = translationInput.text.trim();
        if (text.isNotEmpty && !isBusy.value) {
          Future.microtask(() => host.runTranslation(text));
        }
      }
      return null;
    }, [autoTranslate.value]);

    useEffect(() {
      final pending = pendingVoiceConversationText.value;
      if (pending == null || pending.isEmpty) return null;
      pendingVoiceConversationText.value = null;
      unawaited(host.sendConversation(pending));
      return null;
    }, [pendingVoiceConversationText.value]);

    final modeTheme = polieThemeForMode(activeMode.value);

    return polieWorkspaceBuildHostScaffold(host, modeTheme);
  }
}
