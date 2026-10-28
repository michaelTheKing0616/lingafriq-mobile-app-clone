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
    Future<void> refreshTutorSavedCards() async {
      final saved = await PolieTutorSavedCardsService.loadSavedCards();
      tutorSavedCards.value = saved
          .where(
            (c) =>
                c.targetLanguage.trim().toLowerCase() ==
                    targetLanguage.trim().toLowerCase() &&
                c.difficulty.trim().toLowerCase() ==
                    tutorDifficulty.value.trim().toLowerCase(),
          )
          .toList();

      final currentConceptKey =
          tutorLesson.value?.concept.trim().toLowerCase() ?? '';
      tutorIsCurrentSaved.value = currentConceptKey.isNotEmpty &&
          tutorSavedCards.value.any((c) => c.conceptKey == currentConceptKey);
    }

    Future<void> loadTutorSeenConcepts() async {
      final seen = await PolieTutorSavedCardsService.loadSeenConceptKeys(
        targetLanguage: targetLanguage,
        difficulty: tutorDifficulty.value,
      );
      tutorSeenConcepts.value = seen.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
    }

    useEffect(() {
      Future.microtask(() async {
        await loadTutorSeenConcepts();
        await refreshTutorSavedCards();
      });
      return null;
    }, [tutorDifficulty.value, targetLanguage]);

    final translationHistoryService = ref.read(
      translationHistoryServiceProvider,
    );
    final tutorProgress = ref.read(tutorProgressServiceProvider);
    final vocabProgress = ref.read(vocabularyProgressServiceProvider);
    final vocabularyService = ref.read(vocabularyServiceProvider);
    final reviewProgress = ref.read(reviewProgressServiceProvider);
    final streakDays = useState<int>(0);

    useEffect(() {
      reviewProgress.loadStatistics(targetLanguage).then((stats) {
        streakDays.value = stats.currentStreak;
      });
      return null;
    }, [targetLanguage]);

    String buildStreakBannerText() {
      final days = streakDays.value;
      if (days > 0) {
        return '🔥 $days day${days == 1 ? '' : 's'} streak!';
      }
      return LingAfriqUxVoice.dailyPractice.first;
    }

    Future<void> syncTranslationLanguagesToChat() async {
      if (activeMode.value != PolieMode.translation) return;
      await chat.setModeAndLanguage(
        mode: PolieMode.translation,
        sourceLanguage: translationSourceLang.value,
        targetLanguage: translationTargetLang.value,
      );
    }

    Future<void> setMode(PolieMode mode) async {
      activeMode.value = mode;
      modeError.value = null;
      modeResponse.value = '';
      final src = mode == PolieMode.translation
          ? translationSourceLang.value
          : screen.sourceLanguage;
      final tgt = mode == PolieMode.translation
          ? translationTargetLang.value
          : targetLanguage;
      await chat.setModeAndLanguage(
        mode: mode,
        sourceLanguage: src,
        targetLanguage: tgt,
      );
    }

    Future<Map<String, dynamic>?> askForJson(String prompt) async {
      try {
        final tgt = activeMode.value == PolieMode.translation
            ? translationTargetLang.value
            : targetLanguage;
        final src = activeMode.value == PolieMode.translation
            ? translationSourceLang.value
            : screen.sourceLanguage;
        final raw = await gateway
            .completePolieJson(
              polieModeName: activeMode.value.name,
              userMessage: prompt,
              language: tgt,
              languageCode: SupportedLanguages.getLanguageCode(tgt),
              sourceLanguage: SupportedLanguages.getLanguageCode(src),
              targetLanguage: SupportedLanguages.getLanguageCode(tgt),
            )
            .timeout(const Duration(seconds: 25));
        modeResponse.value = raw;
        final parsed = tryParseJson(raw);
        if (parsed == null) {
          modeError.value =
              'Polie returned an unreadable response. Please try again.';
          return null;
        }
        return parsed;
      } on AiGatewayException catch (e) {
        modeError.value = AiGatewayClient.userMessageFor(e, body: e.body);
        return null;
      } catch (e) {
        modeError.value = e.toString().replaceFirst('Exception: ', '');
        return null;
      }
    }

    Future<void> loadTranslationHistory() async {
      final history = await translationHistoryService.loadHistory();
      final query = translationHistoryQuery.value.trim().toLowerCase();
      final filtered = history.entries
          .where((entry) {
            if (query.isEmpty) return true;
            return entry.sourceText.toLowerCase().contains(query) ||
                entry.primaryTranslation.toLowerCase().contains(query);
          })
          .take(20)
          .toList();
      translationHistory.value = filtered;
    }

    Future<void> runTranslation(String text) async {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return;
      isBusy.value = true;
      modeError.value = null;
      try {
        Map<String, dynamic>? json = await askForJson('''
Return STRICT JSON only.
{
  "primary":"string",
  "alternatives":[{"text":"string","note":"string"}],
  "cultural_note":"string|null",
  "tone_achieved":"formal|casual|literal|poetic"
}

Translate from ${translationSourceLang.value} to ${translationTargetLang.value}.
Tone requested: ${translationTone.value}
Text: "$trimmed"
''');
        // If backend/LLM returns non-JSON prose, use the same translation stack as Hybrid Polie.
        if (json == null) {
          modeError.value = null;
          final tr = await TranslationService().translate(
            text: trimmed,
            sourceLang: polieBackendKeyForDisplayOrGroq(
              translationSourceLang.value,
            ),
            targetLang: polieBackendKeyForDisplayOrGroq(
              translationTargetLang.value,
            ),
            includePhraseBreakdown: false,
          );
          var primary = tr.translation.trim();
          // If Hybrid Polie fallback is used, it may not apply tone (Google/NLLB/MyMemory).
          // Apply a short tone-rewrite pass so the tone chips have real effect.
          if (primary.isNotEmpty && translationTone.value != 'formal') {
            final rewrite = await askForJson('''
Return STRICT JSON only.
{"rewritten":"string"}

You are rewriting a translation to match a requested tone WITHOUT changing meaning.
Target language: ${translationTargetLang.value}
Requested tone: ${translationTone.value}
Rules:
- Preserve the original meaning exactly.
- Keep it in ${translationTargetLang.value}. Do not switch languages.
- Keep it natural and idiomatic for native speakers.
- For "literal", keep it as close to word-for-word as possible while still grammatical.
- For "poetic", allow tasteful figurative language but do not add new facts.

Original translation:
"$primary"
''');
            final rewritten = (rewrite?['rewritten'] ?? '').toString().trim();
            if (rewritten.isNotEmpty) {
              primary = rewritten;
            }
          }
          if (primary.isNotEmpty) {
            json = <String, dynamic>{
              'primary': primary,
              'alternatives': <dynamic>[],
              'cultural_note': null,
              'tone_achieved': translationTone.value,
            };
            modeResponse.value = jsonEncode(json);
          }
        }
        if (json != null) {
          final parsed = TranslationPayload.fromJson(
            json,
            rawFallback: modeResponse.value,
          );
          translationOutput.value = normalizeTranslationPayload(
            payload: parsed,
            targetLanguage: translationTargetLang.value,
            sourceText: trimmed,
          );
          await translationHistoryService.addTranslation(
            polieToHistoryEntry(
              input: trimmed,
              payload: translationOutput.value!,
              sourceLanguage: translationSourceLang.value,
              targetLanguage: translationTargetLang.value,
            ),
          );
          await loadTranslationHistory();
        }
      } catch (e) {
        modeError.value =
            'Translation failed: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
      }
    }

    Future<void> speakText(String text, {String? languageName}) async {
      final normalized = text.trim();
      if (normalized.isEmpty || normalized == '-') return;
      final lang = (languageName ?? targetLanguage).trim();
      final ok = await ref.read(ttsProvider.notifier).speak(
            normalized,
            languageName: lang,
          );
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not play audio. Check your connection or try again.',
            ),
          ),
        );
      }
    }

    Future<void> openTranslationHistorySheet() async {
      translationTrayOpen.value = true;
      await loadTranslationHistory();
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final localSearch = TextEditingController(
            text: translationHistoryQuery.value,
          );
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.68,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              final query = localSearch.text.trim().toLowerCase();
              final filtered = translationHistory.value
                  .where((entry) {
                    if (entry is! TranslationEntry) return false;
                    if (query.isEmpty) return true;
                    return entry.sourceText.toLowerCase().contains(query) ||
                        entry.primaryTranslation.toLowerCase().contains(query);
                  })
                  .cast<TranslationEntry>()
                  .toList();
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'Translation History',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        controller: localSearch,
                        onChanged: (v) {
                          translationHistoryQuery.value = v;
                          (sheetContext as Element).markNeedsBuild();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search source or translation',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No matching history entries.',
                                style: GoogleFonts.nunito(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final entry = filtered[index];
                                return ListTile(
                                  title: Text(
                                    entry.sourceText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    entry.primaryTranslation,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(
                                    Icons.north_west_rounded,
                                    size: 18,
                                  ),
                                  onTap: () async {
                                    Navigator.of(sheetContext).pop();
                                    translationInput.text = entry.sourceText;
                                    await runTranslation(entry.sourceText);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
      translationTrayOpen.value = false;
    }

    Future<void> loadTutorLesson() async {
      if (tutorAutoLoadInFlight.value) return;
      tutorAutoLoadInFlight.value = true;
      isBusy.value = true;
      tutorFeedback.value = null;
      tutorFlipped.value = false;
      try {
        final difficultyGuide = switch (tutorDifficulty.value) {
          'beginner' =>
            'Focus on simple vocabulary, basic greetings, common phrases. Include heavy transliteration. Keep explanations simple and encouraging.',
          'intermediate' =>
            'Focus on grammar concepts, sentence construction, cultural context. Include moderate transliteration. Introduce idiomatic usage.',
          'advanced' =>
            'Focus on idiomatic expressions, literary devices, nuanced usage, proverbs. Minimal transliteration. Challenge the learner.',
          _ => '',
        };
        final seenConceptList = tutorSeenConcepts.value.take(20).join(', ');
        final noveltyConstraint = seenConceptList.isEmpty
            ? ''
            : 'Do NOT repeat previously used concepts: $seenConceptList';
        final nonce = DateTime.now().microsecondsSinceEpoch;
        final json = await askForJson('''
Return STRICT JSON only.
{
 "concept":"title of the lesson concept",
 "explanation":"2-3 warm, clear sentences explaining the concept",
 "example":{"target_lang":"example phrase in $targetLanguage","transliteration":"phonetic guide","english":"English translation"},
 "memory_tip":"a memorable tip to remember this concept",
 "watch_out":"common mistake or tricky aspect, or null",
 "practice_question":"an instructive question for the learner to practice this concept",
 "practice_hint":"a subtle hint to help answer the practice question"
}

Generate a tutor card for $targetLanguage at ${tutorDifficulty.value} level.
$difficultyGuide
$noveltyConstraint
Use a fresh concept each time. Nonce: $nonce
Make the card intelligent, informative, and culturally rich.
''');
        if (json != null) {
          final parsed = TutorLessonPayload.fromJson(json, modeResponse.value);
          final hasCoreFields =
              parsed.concept.trim().isNotEmpty &&
              parsed.explanation.trim().isNotEmpty;
          if (hasCoreFields) {
            final conceptKey = parsed.concept.trim().toLowerCase();
            if (tutorSeenConcepts.value.contains(conceptKey)) {
              final retryJson = await askForJson('''
Return STRICT JSON only with all fields populated.
{
 "concept":"title of the lesson concept",
 "explanation":"2-3 warm, clear sentences explaining the concept",
 "example":{"target_lang":"example phrase in $targetLanguage","transliteration":"phonetic guide","english":"English translation"},
 "memory_tip":"a memorable tip to remember this concept",
 "watch_out":"common mistake or tricky aspect, or null",
 "practice_question":"an instructive question for the learner to practice this concept",
 "practice_hint":"a subtle hint to help answer the practice question"
}
Generate a COMPLETE and DIFFERENT tutor card concept for $targetLanguage at ${tutorDifficulty.value} level.
Do not use this concept again: ${parsed.concept}
Do not use any of these prior concepts: ${tutorSeenConcepts.value.take(20).join(', ')}
Nonce: ${DateTime.now().microsecondsSinceEpoch}
''');
              if (retryJson != null) {
                final retryParsed = TutorLessonPayload.fromJson(
                  retryJson,
                  modeResponse.value,
                );
                tutorSeenConcepts.value = {
                  ...tutorSeenConcepts.value,
                  retryParsed.concept.trim().toLowerCase(),
                };
                await PolieTutorSavedCardsService.addSeenConceptKey(
                  targetLanguage: targetLanguage,
                  difficulty: tutorDifficulty.value,
                  conceptKey: retryParsed.concept.trim().toLowerCase(),
                );
                tutorLesson.value = retryParsed;
                await refreshTutorSavedCards();
              } else {
                tutorLesson.value = parsed;
                await refreshTutorSavedCards();
              }
              return;
            }
            tutorSeenConcepts.value = {...tutorSeenConcepts.value, conceptKey};
            await PolieTutorSavedCardsService.addSeenConceptKey(
              targetLanguage: targetLanguage,
              difficulty: tutorDifficulty.value,
              conceptKey: conceptKey,
            );
            tutorLesson.value = parsed;
            await refreshTutorSavedCards();
          } else {
            // Retry once with stricter completeness constraints.
            final retryJson = await askForJson('''
Return STRICT JSON only with all fields populated.
{
 "concept":"title of the lesson concept",
 "explanation":"2-3 warm, clear sentences explaining the concept",
 "example":{"target_lang":"example phrase in $targetLanguage","transliteration":"phonetic guide","english":"English translation"},
 "memory_tip":"a memorable tip to remember this concept",
 "watch_out":"common mistake or tricky aspect, or null",
 "practice_question":"an instructive question for the learner to practice this concept",
 "practice_hint":"a subtle hint to help answer the practice question"
}
Do not leave concept or explanation empty.
Generate a complete tutor card for $targetLanguage at ${tutorDifficulty.value} level.
''');
            if (retryJson != null) {
              tutorLesson.value = TutorLessonPayload.fromJson(
                retryJson,
                modeResponse.value,
              );
              final ck = tutorLesson.value!.concept.trim().toLowerCase();
              if (ck.isNotEmpty) {
                tutorSeenConcepts.value = {...tutorSeenConcepts.value, ck};
                await PolieTutorSavedCardsService.addSeenConceptKey(
                  targetLanguage: targetLanguage,
                  difficulty: tutorDifficulty.value,
                  conceptKey: ck,
                );
              }
              await refreshTutorSavedCards();
            }
          }
        }
      } catch (e) {
        modeError.value =
            'Failed to load tutor card: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
        tutorAutoLoadInFlight.value = false;
      }
    }

    Future<void> saveCurrentTutorCard() async {
      final lesson = tutorLesson.value;
      if (lesson == null) return;
      final conceptKey = lesson.concept.trim().toLowerCase();
      if (conceptKey.isEmpty) return;
      await PolieTutorSavedCardsService.saveCard(
        PolieTutorSavedCard(
          targetLanguage: targetLanguage,
          difficulty: tutorDifficulty.value,
          conceptKey: conceptKey,
          concept: lesson.concept,
          explanation: lesson.explanation,
          exampleTarget: lesson.example.targetLang,
          exampleTransliteration: lesson.example.transliteration,
          exampleEnglish: lesson.example.english,
          memoryTip: lesson.memoryTip,
          watchOut: lesson.watchOut,
          practiceQuestion: lesson.practiceQuestion,
          practiceHint: lesson.practiceHint,
          savedAt: DateTime.now(),
        ),
      );
      await refreshTutorSavedCards();
    }

    Future<void> openTutorSavedCards() async {
      final l10n = AppLocalizations.of(context)!;
      await refreshTutorSavedCards();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final items = tutorSavedCards.value;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.polieTutorSavedCards,
                          style: Theme.of(sheetContext).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.polieTutorNoSavedCardsYet,
                          style: Theme.of(sheetContext).textTheme.bodyMedium,
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final c = items[index];
                            return ListTile(
                              title: Text(c.concept),
                              subtitle: Text(
                                c.exampleTarget,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                tutorLesson.value = TutorLessonPayload(
                                  concept: c.concept,
                                  explanation: c.explanation,
                                  example: TutorExample(
                                    targetLang: c.exampleTarget,
                                    transliteration: c.exampleTransliteration,
                                    english: c.exampleEnglish,
                                  ),
                                  memoryTip: c.memoryTip,
                                  watchOut: c.watchOut,
                                  practiceQuestion: c.practiceQuestion,
                                  practiceHint: c.practiceHint,
                                );
                                tutorFeedback.value = null;
                                tutorFlipped.value = false;
                                Navigator.of(sheetContext).pop();
                                refreshTutorSavedCards();
                              },
                              trailing: TextButton(
                                onPressed: () async {
                                  await PolieTutorSavedCardsService.removeCard(
                                    c.conceptKey,
                                  );
                                  await refreshTutorSavedCards();
                                  setSheetState(() {});
                                },
                                child: Text(l10n.polieTutorRemoveSavedCard),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    Future<void> checkTutorAnswer() async {
      final answer = tutorInput.text.trim();
      if (answer.isEmpty || tutorLesson.value == null) return;
      isBusy.value = true;
      try {
        final questionCtx = tutorLesson.value!.practiceQuestion != null
            ? 'Practice question: ${tutorLesson.value!.practiceQuestion}'
            : 'Expected style example: ${tutorLesson.value!.example.targetLang}';
        final json = await askForJson('''
Return STRICT JSON only.
{
 "verdict":"correct|close|incorrect",
 "score":0,
 "encouragement":"...",
 "correction":"...",
 "why":"...",
 "native_speaker_note":"...|null",
 "next_step":"one concrete next exercise the learner should do now",
 "drill":"short micro-drill question to practice immediately"
}

Language: $targetLanguage
Concept: ${tutorLesson.value!.concept}
$questionCtx
User answer: "$answer"
Evaluate pedagogically:
- Give complete correction, not partial
- Explain why in plain learner-friendly language
- Give one next action and one micro drill
''');
        if (json != null) {
          tutorFeedback.value = TutorFeedbackPayload.fromJson(
            json,
            modeResponse.value,
          );
          await tutorProgress.recordSession(
            polieBuildTutorSessionResult(
              language: targetLanguage,
              answer: answer,
              verdict: tutorFeedback.value!,
              concept: tutorLesson.value!.concept,
            ),
          );
        }
      } catch (e) {
        modeError.value =
            'Failed to check answer: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
      }
    }

    Future<void> sendRoleplayTurn() async {
      final input = roleplayInput.text.trim();
      if (input.isEmpty) return;
      roleplayMessages.value = [
        ...roleplayMessages.value,
        RoleplayTurn.user(input),
      ];
      roleplayInput.clear();
      isBusy.value = true;
      try {
        final json = await askForJson('''
Return STRICT JSON only. Do NOT include any text outside the JSON object.
{
 "character_response":{
  "target_lang":"a reply in $targetLanguage",
  "transliteration":"phonetic guide",
  "english":"English translation",
  "emotion":"curious|warm|impatient|amused|surprised|neutral",
  "action":"optional physical action or null"
 },
 "coaching":{
  "user_accuracy":50,
  "feedback_type":"praise|suggestion|correction|encouragement",
  "feedback":"1-2 sentences of feedback",
  "better_phrasing":"improved version or null"
 }
}

Roleplay scene: ${roleplayScene.value}
Difficulty: ${roleplayDifficulty.value}
Target language: $targetLanguage
User line: "$input"
Stay in character. Respond naturally for the scene.
''');
        if (json != null) {
          roleplayMessages.value = [
            ...roleplayMessages.value,
            RoleplayTurn.ai(
              RoleplayPayload.fromJson(json, modeResponse.value),
            ),
          ];
        } else {
          roleplayMessages.value = [
            ...roleplayMessages.value,
            RoleplayTurn.ai(
              RoleplayPayload(
                characterResponse: const RoleplayCharacterResponse(
                  targetLang: '...',
                  transliteration: '-',
                  english: '(Polie could not parse this response. Try again!)',
                  emotion: 'neutral',
                  action: null,
                ),
                coaching: const RoleplayCoaching(
                  userAccuracy: 0,
                  feedbackType: 'encouragement',
                  feedback:
                      'There was a parsing error. Please try your line again.',
                  betterPhrasing: null,
                ),
              ),
            ),
          ];
        }
      } catch (e) {
        modeError.value =
            'Roleplay error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
      }
    }

    Future<void> toggleConversationVoiceInput() async {
      voiceErrorMessage.value = null;
      if (voiceListening.value) {
        await voiceService.stop();
        voiceListening.value = false;
        return;
      }
      try {
        // Subscribe before starting so we don't miss the first transcript.
        late StreamSubscription<PolieVoiceTranscript> sub;
        sub = voiceService.transcripts.listen(
          (t) {
            conversationInput.text = t.text;
            conversationInput.selection = TextSelection.fromPosition(
              TextPosition(offset: conversationInput.text.length),
            );
            if (t.isFinal) {
              voiceListening.value = false;
              sub.cancel();
              if (t.text.trim().isNotEmpty) {
                // Auto-send after [sendConversation] is defined (see effect below).
                pendingVoiceConversationText.value = t.text.trim();
              }
            }
          },
          onError: (e) {
            voiceErrorMessage.value = e.toString();
            voiceListening.value = false;
            sub.cancel();
          },
          onDone: () {
            sub.cancel();
          },
        );
        voiceListening.value = true;
        await voiceService.start(language: targetLanguage);
      } catch (e) {
        voiceErrorMessage.value = e.toString();
        voiceListening.value = false;
      }
    }

    Future<void> sendConversation([String? prefilledText]) async {
      final text = (prefilledText ?? conversationInput.text).trim();
      if (text.isEmpty) return;
      final wantsEnglish =
          conversationIncludeEnglishTranslations.value ||
          RegExp(
            r'english translation|with english|translate to english|english in',
            caseSensitive: false,
          ).hasMatch(text);
      final style = conversationResponseStyle.value.trim().toLowerCase();
      final styleInstruction = switch (style) {
        'formal' => 'Use a formal, respectful register. Avoid slang. Be precise.',
        'humorous' =>
          'Be humorous and playful, but never rude. Keep accuracy and clarity.',
        'witty' =>
          'Be witty and clever. Light wordplay is welcome if it fits the topic. Keep accuracy.',
        'terse' =>
          'Be concise: 2–4 sentences max, but still answer fully and accurately.',
        _ =>
          'Be richly detailed: 12–20 sentences. Smart, accurate, engaging, and complete.',
      };
      conversationMessages.value = [
        ...conversationMessages.value,
        ConversationTurn.user(text),
      ];
      if (prefilledText == null) conversationInput.clear();
      isBusy.value = true;
      final turnStarted = DateTime.now();

      // Ensure conversationId is set for persistence + sync.
      conversationId.value ??= const uuid.Uuid().v4();
      final activeConversationId = conversationId.value!;

      // Persist user turn locally; non-blocking.
      unawaited(
        persistence.appendTurn(
          conversationId: activeConversationId,
          language: targetLanguage,
          persona: 'encouraging_mentor',
          titleHint: text,
          turn: PersistedTurn(
            role: 'user',
            text: text,
            language: targetLanguage,
            createdAt: DateTime.now(),
          ),
        ),
      );

      // ---------------------------------------------------------------------
      // Primary path: streaming SSE conversation.
      //
      // We attempt the new /api/v2/polie/conversation/stream endpoint first so
      // the user sees token-by-token output (p50 first token < 1.2s). If the
      // stream returns a server error OR yields no meaningful text, we fall
      // through to the legacy JSON-only path below.
      // ---------------------------------------------------------------------
      bool streamingSucceeded = false;
      try {
        final streamService = PolieConversationStreamService();
        final streamHistory = <PolieConversationTurnInput>[];
        for (final turn in conversationMessages.value) {
          if (turn.userText != null && turn.userText!.trim().isNotEmpty) {
            streamHistory.add(
              PolieConversationTurnInput(
                role: 'user',
                text: turn.userText!.trim(),
              ),
            );
          } else if (turn.ai != null &&
              !turn.ai!.isError &&
              turn.ai!.messageTarget.trim().isNotEmpty) {
            streamHistory.add(
              PolieConversationTurnInput(
                role: 'assistant',
                text: turn.ai!.messageTarget.trim(),
              ),
            );
          }
        }
        // Pop the just-appended current user message — it's passed separately.
        if (streamHistory.isNotEmpty &&
            streamHistory.last.role == 'user' &&
            streamHistory.last.text == text) {
          streamHistory.removeLast();
        }

        conversationStreamingTarget.value = '';
        conversationStreamingActive.value = true;

        PolieConversationStreamFinalEvent? finalEvent;
        String? streamError;

        await for (final evt in streamService.sendConversationTurn(
          language: targetLanguage,
          userMessage: text,
          conversationId: conversationId.value,
          responseStyle: conversationResponseStyle.value,
          wantsEnglish: wantsEnglish,
          history: streamHistory,
        )) {
          if (evt is PolieConversationStreamMetaEvent) {
            conversationId.value = evt.conversationId;
          } else if (evt is PolieConversationStreamDeltaEvent) {
            conversationStreamingTarget.value =
                '${conversationStreamingTarget.value}${evt.text}';
          } else if (evt is PolieConversationStreamFinalEvent) {
            finalEvent = evt;
          } else if (evt is PolieConversationStreamErrorEvent) {
            streamError = evt.error;
          } else if (evt is PolieConversationStreamDoneEvent) {
            break;
          }
        }

        conversationStreamingActive.value = false;
        conversationStreamingTarget.value = '';
        streamService.dispose();

        if (streamError == null &&
            finalEvent != null &&
            finalEvent.messageTarget.trim().isNotEmpty) {
          final payload = enforceConversationDiacritics(
            ConversationPayload(
              messageTarget: finalEvent.messageTarget,
              englishTranslation: finalEvent.englishTranslation,
              correction: ConversationCorrection(
                tier: finalEvent.correction.tier,
                hasCorrection: finalEvent.correction.hasCorrection,
                wasCorrect: finalEvent.correction.wasCorrect,
                correction: finalEvent.correction.correction,
                note: finalEvent.correction.note,
              ),
              suggestedReplies: finalEvent.suggestedReplies,
              newVocab: finalEvent.newVocab
                  .map(
                    (v) => ConversationVocab(
                      word: v.word,
                      meaning: v.meaning,
                    ),
                  )
                  .toList(),
            ),
            targetLanguage,
          );
          conversationMessages.value = [
            ...conversationMessages.value,
            ConversationTurn.ai(payload),
          ];
          // Update language ratio for the in-app progress bar.
          final targetLetters = RegExp(r'[^\x00-\x7F]').hasMatch(text);
          final oldRatio = languageRatio.value;
          languageRatio.value =
              ((oldRatio * (conversationMessages.value.length - 1)) +
                      (targetLetters ? 1 : 0)) /
                  conversationMessages.value.length;
          // Persist assistant turn (server already saved its copy, this is
          // the local cache for offline resilience).
          unawaited(
            persistence.appendTurn(
              conversationId: activeConversationId,
              language: targetLanguage,
              persona: 'encouraging_mentor',
              turn: PersistedTurn(
                role: 'assistant',
                text: payload.messageTarget,
                language: targetLanguage,
                englishTranslation: payload.englishTranslation,
                correction: PersistedCorrection(
                  tier: payload.correction.tier,
                  hasCorrection: payload.correction.hasCorrection,
                  wasCorrect: payload.correction.wasCorrect,
                  correction: payload.correction.correction,
                  note: payload.correction.note,
                ),
                suggestedReplies: payload.suggestedReplies,
                newVocab: payload.newVocab
                    .map(
                      (v) => PersistedVocab(
                        word: v.word,
                        meaning: v.meaning,
                      ),
                    )
                    .toList(),
                createdAt: DateTime.now(),
              ),
            ),
          );
          streamingSucceeded = true;
          unawaited(
            ref.read(telemetryServiceProvider).trackPolieConversationTurn(
              language: targetLanguage,
              success: true,
              usedStreaming: true,
              durationMs:
                  DateTime.now().difference(turnStarted).inMilliseconds,
              messageLength: payload.messageTarget.length,
            ),
          );
        } else {
          // Streaming failed: fall through to legacy JSON path.
          debugPrint(
            '[Polie] stream failed; falling back to JSON path: $streamError',
          );
          unawaited(
            ref.read(telemetryServiceProvider).trackPolieConversationTurn(
              language: targetLanguage,
              success: false,
              usedStreaming: true,
              durationMs:
                  DateTime.now().difference(turnStarted).inMilliseconds,
              errorCode: streamError ?? 'empty_stream',
            ),
          );
        }
      } catch (e) {
        conversationStreamingActive.value = false;
        conversationStreamingTarget.value = '';
        debugPrint('[Polie] streaming threw $e; using JSON fallback');
        unawaited(
          ref.read(telemetryServiceProvider).trackPolieConversationTurn(
            language: targetLanguage,
            success: false,
            usedStreaming: true,
            durationMs: DateTime.now().difference(turnStarted).inMilliseconds,
            errorCode: 'stream_exception',
          ),
        );
      }

      if (streamingSucceeded) {
        isBusy.value = false;
        return;
      }

      try {
        bool _userAskedForGreeting(String userText) {
          final t = userText.toLowerCase();
          // Keep this broad but safe: only exempt greeting-only responses when the user
          // explicitly asked for greetings/hello/how to greet.
          return t.contains('greeting') ||
              t.contains('greetings') ||
              t.contains('say hello') ||
              t.contains('hello') ||
              t.contains('hi') ||
              t.contains('good morning') ||
              t.contains('good afternoon') ||
              t.contains('good evening') ||
              t.contains('how do i greet') ||
              t.contains('how to greet') ||
              t.contains('teach me a greeting');
        }

        bool _looksLikeGreetingOnly(String candidate) {
          final normalized = candidate
              .toLowerCase()
              .trim()
              .replaceAll(RegExp(r'[\u2019\u2018]'), "'")
              // NOTE: raw strings (r'') cannot escape `'` with backslash.
              // Use a raw double-quoted string so `'` is allowed inside.
              .replaceAll(
                RegExp(r"[^a-zA-ZÀ-ÖØ-öø-ÿẸỌṢẹọṣ'\s?!.]"),
                '',
              )
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (normalized.isEmpty) return false;

          // Quick reject: if there's enough content, it's not "greeting-only".
          final words =
              normalized.split(' ').where((w) => w.trim().isNotEmpty).toList();
          if (words.length >= 6) return false;

          // Common greeting-only outputs we want to catch (across several languages).
          const greetingPhrases = <String>{
            // Yoruba
            'bawo',
            'báwo',
            'bawo ni',
            'báwo ni',
            'ẹ káàrọ̀',
            'ẹ kaaro',
            'ẹ káàsán',
            'ẹ kaasan',
            'ẹ kúalẹ́',
            'ẹ kuale',
            'ẹ n lẹ',
            'ẹ nle',
            'ẹ̀ n lẹ',
            // Igbo / Hausa / Swahili / generic
            'kedu',
            'sannu',
            'habari',
            'habari yako',
            'jambo',
            'mambo',
            'ndewo',
            'hello',
            'hi',
          };

          // Strip trailing punctuation for comparison.
          final bare = normalized.replaceAll(RegExp(r'[?!.]+$'), '').trim();
          if (greetingPhrases.contains(bare)) return true;

          // Also catch "báwo ni?" variants etc.
          if (greetingPhrases.contains(bare.replaceAll('?', ''))) return true;

          return false;
        }

        // Relaxed gate (v4): only reject clearly broken outputs. Previously this
        // gate enforced an 80-char minimum + sentence-richness which caused
        // valid short, idiomatic replies to be discarded. We now accept any
        // reasonable answer and only retry when:
        //   - The response is empty after cleaning, OR
        //   - It looks like raw JSON or markdown fences leaked through, OR
        //   - It is a bare greeting when the user did not ask for one, OR
        //   - It is severely truncated mid-word (no terminal punctuation AND
        //     ends with a partial token).
        bool _isMissingOrWeakMessageTarget(Map<String, dynamic> obj) {
          final raw = (obj['message_target'] ?? obj['message'] ?? '').toString();
          final cleaned = cleanAiText(raw, fallback: '').trim();
          if (cleaned.isEmpty) return true;
          if (cleaned.startsWith('{') || cleaned.startsWith('[')) return true;
          if (!_userAskedForGreeting(text) && _looksLikeGreetingOnly(cleaned)) {
            return true;
          }
          // Severe truncation: very short AND no terminal punctuation.
          if (cleaned.length < 12 && looksTruncated(cleaned)) return true;
          return false;
        }

        Future<Map<String, dynamic>?> _askConversationJson({
          required String prompt,
          int timeoutSeconds = 25,
        }) async {
          try {
            final raw = await chat
                .sendMessageForJson(prompt)
                .timeout(Duration(seconds: timeoutSeconds));
            modeResponse.value = raw;
            final parsed = tryParseJson(raw);
            if (parsed == null) return null;
            return parsed;
          } catch (_) {
            // Fall back to shared helper, but keep same behaviour.
            return await askForJson(prompt);
          }
        }

        final nonce = DateTime.now().microsecondsSinceEpoch;
        final promptService = ref.read(poliePromptServiceProvider);
        final personaSnippets = await promptService.persona(
          PolieConversationPromptBuilder.defaultPersonaKey,
        );
        final convBuilder = PolieConversationPromptBuilder();
        final personaPrefix = convBuilder.personaPrefixFromSnippets(
          personaSnippets,
          targetLanguage,
        );

        // Build the rolling multi-turn history buffer from the in-memory
        // conversation. We include the most recent turns (up to
        // [PolieConversationPromptBuilder.maxHistoryTurns]) so the LLM has
        // proper context for coreference, follow-ups, and topic continuity.
        final history = <PolieConversationTurnContext>[];
        for (final turn in conversationMessages.value) {
          if (turn.userText != null && turn.userText!.trim().isNotEmpty) {
            // Skip the just-appended current user message (added at line ~920).
            history.add(
              PolieConversationTurnContext(
                role: 'user',
                text: turn.userText!.trim(),
              ),
            );
          } else if (turn.ai != null &&
              !turn.ai!.isError &&
              turn.ai!.messageTarget.trim().isNotEmpty) {
            history.add(
              PolieConversationTurnContext(
                role: 'assistant',
                text: turn.ai!.messageTarget.trim(),
              ),
            );
          }
        }
        // Pop the current user message off the tail — it's passed separately
        // via [userMessage] in the prompt. This avoids the LLM seeing it twice.
        if (history.isNotEmpty &&
            history.last.role == 'user' &&
            history.last.text == text) {
          history.removeLast();
        }

        Map<String, dynamic>? json = await askForJson(
          convBuilder.buildConversationJsonPrompt(
            targetLanguage: targetLanguage,
            userMessage: text,
            responseStyle: conversationResponseStyle.value,
            styleInstruction: styleInstruction,
            wantsEnglish: wantsEnglish,
            personaSystemPrefix: personaPrefix,
            nonce: nonce,
            history: history,
          ),
        );

        // Stricter retry if message_target is missing/too short/low-quality.
        if (json != null && _isMissingOrWeakMessageTarget(json!)) {
          final strictJson = await _askConversationJson(
            prompt: convBuilder.buildConversationJsonPrompt(
              targetLanguage: targetLanguage,
              userMessage: text,
              responseStyle: conversationResponseStyle.value,
              styleInstruction: styleInstruction,
              wantsEnglish: wantsEnglish,
              personaSystemPrefix: personaPrefix,
              nonce: DateTime.now().microsecondsSinceEpoch,
              strict: true,
              history: history,
            ),
          );
          if (strictJson != null && !_isMissingOrWeakMessageTarget(strictJson)) {
            json = strictJson;
          }
        }

        // If still weak, do a continuation retry (strict).
        if (json != null && _isMissingOrWeakMessageTarget(json!)) {
          final continuation = await _askConversationJson(prompt: '''
Return STRICT JSON only:
{
  "message_target":"string (in $targetLanguage, >= 140 chars, fully complete, no trailing truncation)",
  "message_english":${wantsEnglish ? '"string"' : 'null'},
  "correction":{"tier":"correct","has_correction":false,"was_correct":true,"correction":"","note":"short note"},
  "suggested_replies":["reply 1 in $targetLanguage","reply 2 in $targetLanguage","reply 3 in $targetLanguage"],
  "new_vocab":[]
}

Rewrite the response from scratch (do NOT output a short continuation). It must be fully complete and detailed.
User message: "$text"
Target language: $targetLanguage
Style: ${conversationResponseStyle.value}
Nonce: ${DateTime.now().microsecondsSinceEpoch}
''');
          if (continuation != null && !_isMissingOrWeakMessageTarget(continuation)) {
            json = continuation;
          }
        }

        // LAST RESORT: normal Groq chat completion (not offline translation, not JSON).
        if (json == null || (json != null && _isMissingOrWeakMessageTarget(json!))) {
          final chatPrompt = '''
You are Polie: a smart, witty, accurate conversation partner.
This is OPEN-ENDED CHAT mode. The user can ask about ANY topic.

Reply in $targetLanguage with correct orthography/diacritics.
Response style: ${conversationResponseStyle.value}
Style rules: $styleInstruction

Rules:
- Answer the user's question directly first.
- Be detailed and complete (prefer 12–20 sentences unless style is "terse").
- Do NOT ignore the user's prompt.
${wantsEnglish ? '- After your reply, do NOT include the English translation in the same text. (It will be handled separately.)' : '- Do NOT include any English.'}

User message: "$text"
''';

          final raw = await gateway.completePolieJson(
            polieModeName: PolieMode.conversation.name,
            userMessage: chatPrompt,
            language: targetLanguage,
            languageCode: SupportedLanguages.getLanguageCode(targetLanguage),
            targetLanguage: SupportedLanguages.getLanguageCode(targetLanguage),
          );
          final targetReply = cleanAiText(raw, fallback: raw).trim();

          String? englishTranslation;
          if (wantsEnglish && targetReply.isNotEmpty) {
            try {
              // Translate the Polie reply to English using the hybrid translation stack.
              // Avoid offline dictionary here so it can't collapse to phrase-pack outputs.
              final tr = await TranslationService().translate(
                text: targetReply,
                sourceLang: polieBackendKeyForDisplayOrGroq(targetLanguage),
                targetLang: polieBackendKeyForDisplayOrGroq('English'),
                includePhraseBreakdown: false,
                allowOffline: false,
              );
              final maybe = tr.translation.trim();
              if (maybe.isNotEmpty && maybe != targetReply) {
                englishTranslation = maybe;
              }
            } catch (_) {
              // Best-effort; keep null if translation fails.
            }
          }

          if (targetReply.isEmpty) {
            // Generation failed end-to-end. Surface a real error turn so the
            // user can retry instead of seeing a meaningless "-" placeholder.
            conversationMessages.value = [
              ...conversationMessages.value,
              ConversationTurn.aiError(
                'Polie could not generate a reply just now. Tap retry to try again.',
                retryUserText: text,
              ),
            ];
            unawaited(
              persistence.appendTurn(
                conversationId: activeConversationId,
                language: targetLanguage,
                persona: 'encouraging_mentor',
                turn: PersistedTurn(
                  role: 'assistant',
                  text: '',
                  language: targetLanguage,
                  isError: true,
                  errorMessage:
                      'Polie could not generate a reply just now. Tap retry to try again.',
                  createdAt: DateTime.now(),
                ),
              ),
            );
            return;
          }

          final fallbackPayload = enforceConversationDiacritics(
            ConversationPayload(
              messageTarget: targetReply,
              englishTranslation: englishTranslation,
              correction: const ConversationCorrection(
                tier: 'correct',
                hasCorrection: false,
                wasCorrect: true,
                correction: null,
                note: '',
              ),
              suggestedReplies: const [],
              newVocab: const [],
            ),
            targetLanguage,
          );

          conversationMessages.value = [
            ...conversationMessages.value,
            ConversationTurn.ai(fallbackPayload),
          ];
          unawaited(
            persistence.appendTurn(
              conversationId: activeConversationId,
              language: targetLanguage,
              persona: 'encouraging_mentor',
              turn: PersistedTurn(
                role: 'assistant',
                text: fallbackPayload.messageTarget,
                language: targetLanguage,
                englishTranslation: fallbackPayload.englishTranslation,
                createdAt: DateTime.now(),
              ),
            ),
          );
          return;
        }

        if (json != null) {
          final rawPayload = ConversationPayload.fromJson(
            json,
            modeResponse.value,
          );
          final payload = enforceConversationDiacritics(
            rawPayload,
            targetLanguage,
          );
          conversationMessages.value = [
            ...conversationMessages.value,
            ConversationTurn.ai(payload),
          ];
          final targetLetters = RegExp(r'[^\x00-\x7F]').hasMatch(text);
          final oldRatio = languageRatio.value;
          languageRatio.value =
              ((oldRatio * (conversationMessages.value.length - 1)) +
                  (targetLetters ? 1 : 0)) /
              conversationMessages.value.length;
          unawaited(
            persistence.appendTurn(
              conversationId: activeConversationId,
              language: targetLanguage,
              persona: 'encouraging_mentor',
              turn: PersistedTurn(
                role: 'assistant',
                text: payload.messageTarget,
                language: targetLanguage,
                englishTranslation: payload.englishTranslation,
                correction: PersistedCorrection(
                  tier: payload.correction.tier,
                  hasCorrection: payload.correction.hasCorrection,
                  wasCorrect: payload.correction.wasCorrect,
                  correction: payload.correction.correction,
                  note: payload.correction.note,
                ),
                suggestedReplies: payload.suggestedReplies,
                newVocab: payload.newVocab
                    .map(
                      (v) => PersistedVocab(
                        word: v.word,
                        meaning: v.meaning,
                      ),
                    )
                    .toList(),
                createdAt: DateTime.now(),
              ),
            ),
          );
          unawaited(
            ref.read(telemetryServiceProvider).trackPolieConversationTurn(
              language: targetLanguage,
              success: true,
              usedStreaming: false,
              durationMs:
                  DateTime.now().difference(turnStarted).inMilliseconds,
              messageLength: payload.messageTarget.length,
            ),
          );
        }
      } catch (e) {
        modeError.value =
            'Conversation error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
        unawaited(
          ref.read(telemetryServiceProvider).trackPolieConversationTurn(
            language: targetLanguage,
            success: false,
            usedStreaming: false,
            durationMs: DateTime.now().difference(turnStarted).inMilliseconds,
            errorCode: 'conversation_exception',
          ),
        );
      } finally {
        isBusy.value = false;
      }
    }

    useEffect(() {
      final pending = pendingVoiceConversationText.value;
      if (pending == null || pending.isEmpty) return null;
      pendingVoiceConversationText.value = null;
      unawaited(sendConversation(pending));
      return null;
    }, [pendingVoiceConversationText.value]);

    Future<void> loadVocabCard() async {
      isBusy.value = true;
      try {
        final exclusionClause = vocabShownWords.value.isEmpty
            ? ''
            : '\nDo NOT repeat these previously shown words: ${vocabShownWords.value.take(30).join(', ')}';
        final json = await askForJson('''
Return STRICT JSON only.
{
 "word":"a $targetLanguage word",
 "pronunciation":"phonetic pronunciation",
 "part_of_speech":"noun|verb|adjective|adverb|phrase|greeting",
 "english":"English meaning",
 "example":{"target":"example sentence in $targetLanguage","english":"English translation"},
 "memory_peg":"a memorable association to remember this word",
 "cultural_note":"cultural context or null",
 "related_words":[{"word":"related word","relationship":"synonym|antonym|related|derived"}],
 "difficulty":"beginner|intermediate|advanced"
}

Generate one unique $targetLanguage vocabulary card.$exclusionClause
Category focus: ${vocabSetName.value}
Difficulty preference: ${vocabDifficultyTarget.value}
If difficulty preference is "mixed", rotate levels naturally over successive cards.
''');
        if (json != null) {
          var parsed = VocabPayload.fromJson(json, modeResponse.value);
          if (isUnavailableWord(parsed.word)) {
            // Retry once if payload word is missing/placeholder.
            final retryJson = await askForJson('''
Return STRICT JSON only with a valid non-empty "word" in $targetLanguage.
{
 "word":"a real $targetLanguage word (never 'Word unavailable')",
 "pronunciation":"phonetic pronunciation",
 "part_of_speech":"noun|verb|adjective|adverb|phrase|greeting",
 "english":"English meaning",
 "example":{"target":"example sentence in $targetLanguage","english":"English translation"},
 "memory_peg":"a memorable association to remember this word",
 "cultural_note":"cultural context or null",
 "related_words":[{"word":"related word","relationship":"synonym|antonym|related|derived"}],
 "difficulty":"beginner|intermediate|advanced"
}
$exclusionClause
''');
            if (retryJson != null) {
              parsed = VocabPayload.fromJson(retryJson, modeResponse.value);
            }
          }
          if (isUnavailableWord(parsed.word)) {
            parsed = fallbackVocabPayload(targetLanguage);
          }
          vocabCard.value = parsed;
          vocabShownWords.value = {
            ...vocabShownWords.value,
            vocabCard.value!.word.toLowerCase(),
          };
          vocabReveal.value = false;
          vocabDeckCount.value = (vocabDeckCount.value - 1).clamp(0, 999);
        }
      } catch (e) {
        modeError.value =
            'Vocab error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
      }
    }

    Future<void> scoreSrs(String bucket) async {
      final card = vocabCard.value;
      if (card == null) return;
      vocabSrsChoice.value = bucket;
      final isCorrect = bucket == 'good' || bucket == 'easy';
      await vocabProgress.addWord(
        buildVocabularyWord(card, targetLanguage),
        category: vocabSetName.value,
      );
      await vocabularyService.addWord(
        word: card.word,
        language: targetLanguage,
        translation: card.english,
        pronunciation: card.pronunciation,
        exampleSentences: ['${card.example.target} - ${card.example.english}'],
        culturalNote: card.culturalNote,
        partOfSpeech: card.partOfSpeech,
        tags: [vocabSetName.value, 'polie_vocab_mode'],
        enrichWithAI: false,
      );
      await vocabProgress.recordReview(card.word, targetLanguage, isCorrect);
      await loadVocabCard();
    }

    Future<void> loadReview() async {
      isBusy.value = true;
      try {
        final reviewStats = await reviewProgress.loadStatistics(targetLanguage);
        final vocabProg = await vocabProgress.loadProgress(targetLanguage);
        final tutorProg = await tutorProgress.loadProgress(targetLanguage);

        final wordsSeen = vocabProg.totalWordsLearned > 0
            ? vocabProg.totalWordsLearned
            : reviewStats.totalItemsReviewed;
        final totalWords = vocabProg.words.length;
        final correctWords = vocabProg.words.values
            .where((w) => w.isMastered)
            .length;
        final vocabAccuracy = totalWords > 0
            ? (correctWords / totalWords) * 100
            : 0.0;
        final overallAccuracy = reviewStats.averageAccuracy > 0
            ? (reviewStats.averageAccuracy + vocabAccuracy) / 2
            : vocabAccuracy > 0
            ? vocabAccuracy
            : 0.0;
        final lessonsDone = tutorProg.totalSessions + reviewStats.totalReviews;
        final streak = reviewStats.currentStreak;

        final json = await askForJson('''
Return STRICT JSON only.
{
 "headline_insight":"a short motivational headline about the learner progress",
 "strengths":[{"area":"skill area","note":"what they do well"}],
 "growth_areas":[{"area":"skill area","note":"what to improve","quick_win":"one quick action"}],
 "coaching_paragraph":"2-3 sentences of personalized coaching",
 "next_steps":[{"type":"lesson|scene|vocabulary_review","title":"suggested activity","why":"reason"}],
 "motivational_close":"an encouraging closing sentence"
}

Review period: ${reviewPeriod.value}
Words learned: $wordsSeen
Tutor lessons completed: $lessonsDone
Average accuracy: ${overallAccuracy.toStringAsFixed(1)}%
Current streak: $streak days
Language: $targetLanguage
''');
        if (json != null) {
          reviewPayload.value = ReviewPayload.fromJson(
            json,
            modeResponse.value,
            wordsSeen: wordsSeen,
            accuracy: overallAccuracy,
            streak: streak,
            lessonsDone: lessonsDone,
          );
        }
      } catch (e) {
        modeError.value =
            'Review error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
      }
    }

    useEffect(() {
      final init = screen.conversationOnly ? PolieMode.conversation : screen.initialMode;
      setMode(init);
      loadTranslationHistory();
      if (init == PolieMode.tutor) loadTutorLesson();
      if (init == PolieMode.vocab) loadVocabCard();
      if (init == PolieMode.review) loadReview();
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
        Future.microtask(loadTutorLesson);
      }
      if (activeMode.value == PolieMode.vocab &&
          vocabCard.value == null &&
          !isBusy.value) {
        Future.microtask(loadVocabCard);
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
            runTranslation(text);
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
          Future.microtask(() => runTranslation(text));
        }
      }
      return null;
    }, [autoTranslate.value]);

    final modeTheme = polieThemeForMode(activeMode.value);

    return Scaffold(
      backgroundColor: modeTheme.background,
      appBar: AppBar(
        backgroundColor: modeTheme.background,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).maybePop();
          },
        ),
        title: Text(
          screen.conversationOnly ? 'Ling Chat' : 'Polie',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: modeTheme.title,
            fontSize: isCompactTopBar ? 24 : 28,
          ),
        ),
        actions: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isBusy.value
                ? null
                : () async {
                    final selected = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (sheetCtx) {
                        final options = kPolieTranslateLanguageOptions
                            .where((o) => o.displayName != 'Auto Detect')
                            .toList()
                          ..sort((a, b) =>
                              a.displayName.compareTo(b.displayName));
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    12,
                                  ),
                                  child: Text(
                                    'Choose conversation language',
                                    style: GoogleFonts.playfairDisplay(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                for (final o in options)
                                  ListTile(
                                    dense: true,
                                    leading: Text(
                                      o.flag,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    title: Text(o.displayName),
                                    trailing: o.displayName == targetLanguage
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: Color(0xFFD4822A),
                                          )
                                        : null,
                                    onTap: () => Navigator.of(sheetCtx)
                                        .pop(o.displayName),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                    if (selected != null && selected != targetLanguage) {
                      activeTargetLanguage.value = selected;
                      try {
                        await chat.setModeAndLanguage(
                          mode: activeMode.value,
                          targetLanguage: selected,
                        );
                      } catch (e) {
                        debugPrint(
                          '[Polie] setModeAndLanguage failed: $e',
                        );
                      }
                    }
                  },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(
                horizontal: isCompactTopBar ? 8 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: modeTheme.border),
                color: modeTheme.card,
              ),
              child: Row(
                children: [
                  if (!isCompactTopBar)
                    Text(
                      (polieOptionForDisplayName(targetLanguage)?.flag ??
                          '🌍'),
                    ),
                  if (!isCompactTopBar) const SizedBox(width: 6),
                  Text(targetLanguage),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                ],
              ),
            ),
          ),
          if (!isCompactTopBar)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined),
            ),
          if (!isCompactTopBar)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.person_outline_rounded),
            ),
          if (isCompactTopBar)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'settings', child: Text('Settings')),
                PopupMenuItem(value: 'profile', child: Text('Profile')),
              ],
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (!screen.conversationOnly)
            Padding(
              padding: EdgeInsets.fromLTRB(
                isCompactTopBar ? 8 : 12,
                0,
                isCompactTopBar ? 8 : 12,
                8,
              ),
              child: PolieModeSwitcherRail<PolieMode>(
                selected: activeMode.value,
                items: PolieWorkspaceScreen.modeItems
                    .map(
                      (e) => PolieModeSwitcherItem<PolieMode>(
                        value: e.mode,
                        icon: e.icon,
                        label: e.label,
                      ),
                    )
                    .toList(),
                onChanged: (mode) async {
                  await setMode(mode);
                  if (mode == PolieMode.tutor && tutorLesson.value == null) {
                    await loadTutorLesson();
                  }
                if (mode == PolieMode.vocab && vocabCard.value == null) {
                  await loadVocabCard();
                }
                if (mode == PolieMode.review && reviewPayload.value == null) {
                  await loadReview();
                }
                },
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(animation);
                final fade = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: fade,
                  child: SlideTransition(
                    position: slide,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.992,
                        end: 1,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                );
              },
              child: polieWorkspaceModeSurface(
                key: ValueKey(activeMode.value),
                context: context,
                mode: activeMode.value,
                theme: modeTheme,
                isBusy: isBusy.value,
                modeError: modeError.value,
                // translation
                translationInput: translationInput,
                translationOutput: translationOutput.value,
                translationTone: translationTone,
                autoTranslate: autoTranslate,
                translationTrayOpen: translationTrayOpen,
                translationHistoryQuery: translationHistoryQuery,
                translationHistory: translationHistory.value,
                onRunTranslation: runTranslation,
                onSearchHistory: () async => loadTranslationHistory(),
                onOpenTranslationHistory: openTranslationHistorySheet,
                translationSourceLang: translationSourceLang,
                translationTargetLang: translationTargetLang,
                onTranslationLanguagesChanged: syncTranslationLanguagesToChat,
                // tutor
                tutorLesson: tutorLesson.value,
                tutorFeedback: tutorFeedback.value,
                tutorDifficulty: tutorDifficulty,
                tutorFlipped: tutorFlipped,
                tutorInput: tutorInput,
                onLoadTutorLesson: loadTutorLesson,
                onCheckTutorAnswer: checkTutorAnswer,
                onSaveTutorCard: saveCurrentTutorCard,
                onOpenTutorSavedCards: openTutorSavedCards,
                tutorIsCurrentSaved: tutorIsCurrentSaved,
                // roleplay
                roleplayDifficulty: roleplayDifficulty,
                roleplayScene: roleplayScene,
                roleplayMessages: roleplayMessages.value,
                roleplayInput: roleplayInput,
                onSendRoleplay: sendRoleplayTurn,
                // conversation
                conversationMessages: conversationMessages.value,
                conversationInput: conversationInput,
                conversationIncludeEnglishTranslations:
                    conversationIncludeEnglishTranslations,
                conversationResponseStyle: conversationResponseStyle,
                languageRatio: languageRatio.value,
                onSendConversation: sendConversation,
                onSpeakText: speakText,
                conversationStreamingActive:
                    conversationStreamingActive.value,
                conversationStreamingTarget:
                    conversationStreamingTarget.value,
                conversationVoiceListening: voiceListening.value,
                onToggleConversationVoiceInput:
                    toggleConversationVoiceInput,
                // vocab
                vocabCard: vocabCard.value,
                vocabReveal: vocabReveal,
                vocabSetName: vocabSetName,
                vocabDifficultyTarget: vocabDifficultyTarget,
                vocabDeckCount: vocabDeckCount.value,
                vocabSrsChoice: vocabSrsChoice.value,
                onLoadVocabCard: loadVocabCard,
                onScoreSrs: scoreSrs,
                // review
                reviewPayload: reviewPayload.value,
                reviewPeriod: reviewPeriod,
                onLoadReview: loadReview,
                introDismissed: modeIntroDismissed.value,
                onDismissIntro: (modeName) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(
                    'polie_mode_intro_${modeName}_dismissed',
                    true,
                  );
                  modeIntroDismissed.value = {
                    ...modeIntroDismissed.value,
                    modeName,
                  };
                },
                tutorStreakBannerText: buildStreakBannerText(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
