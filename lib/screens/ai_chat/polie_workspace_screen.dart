import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/translation_history_model.dart';
import 'package:lingafriq/models/tutor_progress_model.dart';
import 'package:lingafriq/models/vocabulary_progress_model.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/services/review_progress_service.dart';
import 'package:lingafriq/services/translation_history_service.dart';
import 'package:lingafriq/services/tutor_progress_service.dart';
import 'package:lingafriq/services/vocabulary/vocabulary_service.dart';
import 'package:lingafriq/services/vocabulary_progress_service.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';
import 'package:lingafriq/providers/tts_provider.dart';
import 'package:lingafriq/utils/diacritics_enforcer.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart' as uuid;

class PolieWorkspaceScreen extends HookConsumerWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final PolieMode initialMode;
  final String? initialRoleplayScene;

  const PolieWorkspaceScreen({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.initialMode,
    this.initialRoleplayScene,
  });

  static const _modeItems = <ModeChipItem>[
    ModeChipItem(mode: PolieMode.translation, icon: '⇄', label: 'Translation'),
    ModeChipItem(mode: PolieMode.tutor, icon: '📖', label: 'Tutor'),
    ModeChipItem(mode: PolieMode.roleplay, icon: '🎭', label: 'Roleplay'),
    ModeChipItem(mode: PolieMode.conversation, icon: '💬', label: 'Conversation'),
    ModeChipItem(mode: PolieMode.vocab, icon: '✦', label: 'Vocabulary'),
    ModeChipItem(mode: PolieMode.review, icon: '📊', label: 'Review'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isCompactTopBar = viewportWidth < 420;
    final activeMode = useState<PolieMode>(initialMode);
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
    final translationOutput = useState<_TranslationPayload?>(null);
    final translationHistoryQuery = useState<String>('');
    final translationHistory = useState<List<dynamic>>([]);
    final translationTrayOpen = useState<bool>(true);
    final translationTimer = useRef<Timer?>(null);

    final tutorLesson = useState<_TutorLessonPayload?>(null);
    final tutorFeedback = useState<_TutorFeedbackPayload?>(null);
    final tutorDifficulty = useState<String>('beginner');
    final tutorFlipped = useState<bool>(false);
    final tutorAutoLoadInFlight = useRef<bool>(false);
    final tutorSeenConcepts = useRef<Set<String>>({});

    final roleplayDifficulty = useState<String>('bilingual');
    final roleplayScene = useState<String>(normalizeInitialRoleplayScene(initialRoleplayScene));
    final roleplayMessages = useState<List<_RoleplayTurn>>([]);

    final conversationMessages = useState<List<_ConversationTurn>>([]);
    final languageRatio = useState<double>(0);

    final vocabCard = useState<_VocabPayload?>(null);
    final vocabReveal = useState<bool>(false);
    final vocabDeckCount = useState<int>(10);
    final vocabSetName = useState<String>('Core Daily Words');
    final vocabDifficultyTarget = useState<String>('mixed');
    final vocabSrsChoice = useState<String?>(null);
    final vocabShownWords = useRef<Set<String>>({});

    final reviewPayload = useState<_ReviewPayload?>(null);
    final reviewPeriod = useState<String>('week');
    final modeIntroDismissed = useState<Set<String>>({});

    final chat = ref.read(groqChatProvider.notifier);
    final translationHistoryService = ref.read(translationHistoryServiceProvider);
    final tutorProgress = ref.read(tutorProgressServiceProvider);
    final vocabProgress = ref.read(vocabularyProgressServiceProvider);
    final vocabularyService = ref.read(vocabularyServiceProvider);
    final reviewProgress = ref.read(reviewProgressServiceProvider);

    Future<void> setMode(PolieMode mode) async {
      activeMode.value = mode;
      modeError.value = null;
      modeResponse.value = '';
      await chat.setModeAndLanguage(
        mode: mode,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    }

    Future<Map<String, dynamic>?> askForJson(String prompt) async {
      try {
        final raw = await chat
            .sendMessageForJson(prompt)
            .timeout(const Duration(seconds: 25));
        modeResponse.value = raw;
        final parsed = _tryParseJson(raw);
        if (parsed == null) {
          modeError.value = 'Polie returned an unreadable response. Please try again.';
          return null;
        }
        return parsed;
      } catch (e) {
        modeError.value = e.toString();
        return null;
      }
    }

    Future<void> loadTranslationHistory() async {
      final history = await translationHistoryService.loadHistory();
      final query = translationHistoryQuery.value.trim().toLowerCase();
      final filtered = history.entries.where((entry) {
        if (query.isEmpty) return true;
        return entry.sourceText.toLowerCase().contains(query) ||
            entry.primaryTranslation.toLowerCase().contains(query);
      }).take(20).toList();
      translationHistory.value = filtered;
    }

    Future<void> runTranslation(String text) async {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return;
      isBusy.value = true;
      modeError.value = null;
      try {
        final json = await askForJson(
          '''
Return STRICT JSON only.
{
  "primary":"string",
  "alternatives":[{"text":"string","note":"string"}],
  "cultural_note":"string|null",
  "tone_achieved":"formal|casual|literal|poetic"
}

Translate from $sourceLanguage to $targetLanguage.
Tone requested: ${translationTone.value}
Text: "$trimmed"
''',
        );
        if (json != null) {
          final parsed = _TranslationPayload.fromJson(json, rawFallback: modeResponse.value);
          translationOutput.value = _normalizeTranslationPayload(
            payload: parsed,
            targetLanguage: targetLanguage,
            sourceText: trimmed,
          );
          await translationHistoryService.addTranslation(
            _toHistoryEntry(
              input: trimmed,
              payload: translationOutput.value!,
              sourceLanguage: sourceLanguage,
              targetLanguage: targetLanguage,
            ),
          );
          await loadTranslationHistory();
        }
      } catch (e) {
        modeError.value = 'Translation failed: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
      }
    }

    Future<void> speakText(String text) async {
      final normalized = text.trim();
      if (normalized.isEmpty || normalized == '-') return;
      await ref.read(ttsProvider.notifier).speak(
            normalized,
            languageName: targetLanguage,
          );
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
          final localSearch = TextEditingController(text: translationHistoryQuery.value);
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.68,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              final query = localSearch.text.trim().toLowerCase();
              final filtered = translationHistory.value.where((entry) {
                if (entry is! TranslationEntry) return false;
                if (query.isEmpty) return true;
                return entry.sourceText.toLowerCase().contains(query) ||
                    entry.primaryTranslation.toLowerCase().contains(query);
              }).cast<TranslationEntry>().toList();
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
                          Text('Translation History', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No matching history entries.',
                                style: GoogleFonts.nunito(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final entry = filtered[index];
                                return ListTile(
                                  title: Text(entry.sourceText, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                    entry.primaryTranslation,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.north_west_rounded, size: 18),
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
          'beginner' => 'Focus on simple vocabulary, basic greetings, common phrases. Include heavy transliteration. Keep explanations simple and encouraging.',
          'intermediate' => 'Focus on grammar concepts, sentence construction, cultural context. Include moderate transliteration. Introduce idiomatic usage.',
          'advanced' => 'Focus on idiomatic expressions, literary devices, nuanced usage, proverbs. Minimal transliteration. Challenge the learner.',
          _ => '',
        };
        final seenConceptList = tutorSeenConcepts.value.take(20).join(', ');
        final noveltyConstraint = seenConceptList.isEmpty
            ? ''
            : 'Do NOT repeat previously used concepts: $seenConceptList';
        final nonce = DateTime.now().microsecondsSinceEpoch;
        final json = await askForJson(
          '''
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
''',
        );
        if (json != null) {
          final parsed = _TutorLessonPayload.fromJson(json, modeResponse.value);
          final hasCoreFields = parsed.concept.trim().isNotEmpty && parsed.explanation.trim().isNotEmpty;
          if (hasCoreFields) {
            final conceptKey = parsed.concept.trim().toLowerCase();
            if (tutorSeenConcepts.value.contains(conceptKey)) {
              final retryJson = await askForJson(
                '''
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
''',
              );
              if (retryJson != null) {
                final retryParsed = _TutorLessonPayload.fromJson(retryJson, modeResponse.value);
                tutorSeenConcepts.value = {
                  ...tutorSeenConcepts.value,
                  retryParsed.concept.trim().toLowerCase(),
                };
                tutorLesson.value = retryParsed;
              } else {
                tutorLesson.value = parsed;
              }
              return;
            }
            tutorSeenConcepts.value = {
              ...tutorSeenConcepts.value,
              conceptKey,
            };
            tutorLesson.value = parsed;
          } else {
            // Retry once with stricter completeness constraints.
            final retryJson = await askForJson(
              '''
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
''',
            );
            if (retryJson != null) {
              tutorLesson.value = _TutorLessonPayload.fromJson(retryJson, modeResponse.value);
            }
          }
        }
      } catch (e) {
        modeError.value = 'Failed to load tutor card: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
        tutorAutoLoadInFlight.value = false;
      }
    }

    Future<void> checkTutorAnswer() async {
      final answer = tutorInput.text.trim();
      if (answer.isEmpty || tutorLesson.value == null) return;
      isBusy.value = true;
      try {
        final questionCtx = tutorLesson.value!.practiceQuestion != null
            ? 'Practice question: ${tutorLesson.value!.practiceQuestion}'
            : 'Expected style example: ${tutorLesson.value!.example.targetLang}';
        final json = await askForJson(
          '''
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
''',
        );
        if (json != null) {
          tutorFeedback.value = _TutorFeedbackPayload.fromJson(json, modeResponse.value);
          await tutorProgress.recordSession(
            _buildTutorSessionResult(
              language: targetLanguage,
              answer: answer,
              verdict: tutorFeedback.value!,
              concept: tutorLesson.value!.concept,
            ),
          );
        }
      } catch (e) {
        modeError.value = 'Failed to check answer: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
      }
    }

    Future<void> sendRoleplayTurn() async {
      final input = roleplayInput.text.trim();
      if (input.isEmpty) return;
      roleplayMessages.value = [
        ...roleplayMessages.value,
        _RoleplayTurn.user(input),
      ];
      roleplayInput.clear();
      isBusy.value = true;
      try {
        final json = await askForJson(
          '''
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
''',
        );
        if (json != null) {
          roleplayMessages.value = [
            ...roleplayMessages.value,
            _RoleplayTurn.ai(_RoleplayPayload.fromJson(json, modeResponse.value)),
          ];
        } else {
          roleplayMessages.value = [
            ...roleplayMessages.value,
            _RoleplayTurn.ai(_RoleplayPayload(
              characterResponse: const _RoleplayCharacterResponse(
                targetLang: '...', transliteration: '-', english: '(Polie could not parse this response. Try again!)',
                emotion: 'neutral', action: null,
              ),
              coaching: const _RoleplayCoaching(
                userAccuracy: 0, feedbackType: 'encouragement',
                feedback: 'There was a parsing error. Please try your line again.', betterPhrasing: null,
              ),
            )),
          ];
        }
      } catch (e) {
        modeError.value = 'Roleplay error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
      }
    }

    Future<void> sendConversation([String? prefilledText]) async {
      final text = (prefilledText ?? conversationInput.text).trim();
      if (text.isEmpty) return;
      final wantsInlineEnglish = RegExp(r'english translation|with english|translate to english|english in', caseSensitive: false)
          .hasMatch(text);
      conversationMessages.value = [...conversationMessages.value, _ConversationTurn.user(text)];
      if (prefilledText == null) conversationInput.clear();
      isBusy.value = true;
      try {
        Map<String, dynamic>? json = await askForJson(
          '''
Return STRICT JSON only. Do NOT wrap in markdown. Do NOT include text outside the JSON.
{
 "message":"A rich, complete reply in a mix of $targetLanguage and English. 4-8 sentences that may include translation, explanation, and short examples when helpful.",
 "correction":{"has_correction":false,"was_correct":true,"correction":"corrected version or empty","note":"explanation"},
 "suggested_replies":["reply option 1 in $targetLanguage","reply option 2","reply option 3"],
 "new_vocab":[{"word":"new word","meaning":"meaning"}]
}

You are Polie, a friendly language coach focused on expressive, free-form help.
Treat Conversation mode as a hybrid of translation + tutoring, but keep a conversational tone.
Target language: $targetLanguage
User message: "$text"
Respond with depth and clarity:
- If user asks for translation, provide natural translation and explain word choice.
- If user asks for meaning/grammar/proverb/slang/culture, explain clearly and include 1-2 examples.
- If user asks open-ended topic questions, still weave in useful language learning guidance.
- Keep answers complete and not cut off.
${wantsInlineEnglish ? '- User requested English translations: for each target-language sentence, include immediate English translation in parentheses.' : ''}
If the user made grammar mistakes in $targetLanguage, set has_correction to true and provide the correction.
''',
        );
        if (json != null) {
          final msg = _cleanAiText((json['message'] ?? '').toString());
          if (_looksTruncated(msg) || !_isConversationResponseRich(msg)) {
            final continuation = await askForJson(
              '''
Return STRICT JSON only:
{"message":"single completed conversational message","correction":{"has_correction":false,"was_correct":true,"correction":"","note":"short note"},"suggested_replies":["reply 1","reply 2"],"new_vocab":[]}

Continue and COMPLETE the previous response in natural style for $targetLanguage.
Ensure the response is fully complete, coherent, and can include explanation/examples if relevant.
The response MUST be at least 3 full sentences and directly follow user's instruction constraints.
User message: "$text"
''',
            );
            if (continuation != null &&
                !_looksTruncated(_cleanAiText((continuation['message'] ?? '').toString())) &&
                _isConversationResponseRich(_cleanAiText((continuation['message'] ?? '').toString()))) {
              json = continuation;
            }
          }
        }
        if (json != null) {
          final rawPayload = _ConversationPayload.fromJson(json, modeResponse.value);
          final payload = _enforceConversationDiacritics(rawPayload, targetLanguage);
          conversationMessages.value = [...conversationMessages.value, _ConversationTurn.ai(payload)];
          final targetLetters = RegExp(r'[^\x00-\x7F]').hasMatch(text);
          final oldRatio = languageRatio.value;
          languageRatio.value = ((oldRatio * (conversationMessages.value.length - 1)) + (targetLetters ? 1 : 0)) /
              conversationMessages.value.length;
        }
      } catch (e) {
        modeError.value = 'Conversation error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
      }
    }

    Future<void> loadVocabCard() async {
      isBusy.value = true;
      try {
        final exclusionClause = vocabShownWords.value.isEmpty
            ? ''
            : '\nDo NOT repeat these previously shown words: ${vocabShownWords.value.take(30).join(', ')}';
        final json = await askForJson(
          '''
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
''',
        );
        if (json != null) {
          var parsed = _VocabPayload.fromJson(json, modeResponse.value);
          if (_isUnavailableWord(parsed.word)) {
            // Retry once if payload word is missing/placeholder.
            final retryJson = await askForJson(
              '''
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
''',
            );
            if (retryJson != null) {
              parsed = _VocabPayload.fromJson(retryJson, modeResponse.value);
            }
          }
          if (_isUnavailableWord(parsed.word)) {
            parsed = _fallbackVocabPayload(targetLanguage);
          }
          vocabCard.value = parsed;
          vocabShownWords.value = {...vocabShownWords.value, vocabCard.value!.word.toLowerCase()};
          vocabReveal.value = false;
          vocabDeckCount.value = (vocabDeckCount.value - 1).clamp(0, 999);
        }
      } catch (e) {
        modeError.value = 'Vocab error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
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
        _buildVocabularyWord(card, targetLanguage),
        category: vocabSetName.value,
      );
      await vocabularyService.addWord(
        word: card.word,
        language: targetLanguage,
        translation: card.english,
        pronunciation: card.pronunciation,
        exampleSentences: [
          '${card.example.target} - ${card.example.english}',
        ],
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

        final wordsSeen = vocabProg.totalWordsLearned > 0 ? vocabProg.totalWordsLearned : reviewStats.totalItemsReviewed;
        final totalWords = vocabProg.words.length;
        final correctWords = vocabProg.words.values.where((w) => w.isMastered).length;
        final vocabAccuracy = totalWords > 0 ? (correctWords / totalWords) * 100 : 0.0;
        final overallAccuracy = reviewStats.averageAccuracy > 0
            ? (reviewStats.averageAccuracy + vocabAccuracy) / 2
            : vocabAccuracy > 0 ? vocabAccuracy : 0.0;
        final lessonsDone = tutorProg.totalSessions + reviewStats.totalReviews;
        final streak = reviewStats.currentStreak;

        final json = await askForJson(
          '''
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
''',
        );
        if (json != null) {
          reviewPayload.value = _ReviewPayload.fromJson(
            json,
            modeResponse.value,
            wordsSeen: wordsSeen,
            accuracy: overallAccuracy,
            streak: streak,
            lessonsDone: lessonsDone,
          );
        }
      } catch (e) {
        modeError.value = 'Review error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
      }
    }

    useEffect(() {
      setMode(initialMode);
      loadTranslationHistory();
      if (initialMode == PolieMode.tutor) loadTutorLesson();
      if (initialMode == PolieMode.vocab) loadVocabCard();
      if (initialMode == PolieMode.review) loadReview();
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
      if (activeMode.value == PolieMode.tutor && tutorLesson.value == null && !isBusy.value) {
        Future.microtask(loadTutorLesson);
      }
      if (activeMode.value == PolieMode.vocab && vocabCard.value == null && !isBusy.value) {
        Future.microtask(loadVocabCard);
      }
      return null;
    }, [activeMode.value]);

    useEffect(() {
      translationTimer.value?.cancel();
      if (!autoTranslate.value) return null;
      final text = translationInput.text.trim();
      if (activeMode.value == PolieMode.translation && text.isNotEmpty) {
        translationTimer.value = Timer(const Duration(milliseconds: 500), () {
          runTranslation(text);
        });
      }
      return () => translationTimer.value?.cancel();
    }, [translationInput.text, autoTranslate.value, activeMode.value, translationTone.value]);

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

    final modeTheme = _themeForMode(activeMode.value);

    return Scaffold(
      backgroundColor: modeTheme.background,
      appBar: AppBar(
        backgroundColor: modeTheme.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Polie',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: modeTheme.title,
            fontSize: isCompactTopBar ? 24 : 28,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: EdgeInsets.symmetric(horizontal: isCompactTopBar ? 8 : 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: modeTheme.border),
              color: modeTheme.card,
            ),
            child: Row(
              children: [
                if (!isCompactTopBar) const Text('NG'),
                if (!isCompactTopBar) const SizedBox(width: 6),
                Text(targetLanguage),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
          if (!isCompactTopBar) IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
          if (!isCompactTopBar) IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline_rounded)),
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
          Padding(
            padding: EdgeInsets.fromLTRB(isCompactTopBar ? 8 : 12, 0, isCompactTopBar ? 8 : 12, 8),
            child: PolieModeSwitcherRail<PolieMode>(
              selected: activeMode.value,
              items: _modeItems
                  .map((e) => PolieModeSwitcherItem<PolieMode>(
                        value: e.mode,
                        icon: e.icon,
                        label: e.label,
                      ))
                  .toList(),
              onChanged: (mode) async {
                await setMode(mode);
                if (mode == PolieMode.tutor && tutorLesson.value == null) await loadTutorLesson();
                if (mode == PolieMode.vocab && vocabCard.value == null) await loadVocabCard();
                if (mode == PolieMode.review && reviewPayload.value == null) await loadReview();
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
                final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                return FadeTransition(
                  opacity: fade,
                  child: SlideTransition(
                    position: slide,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.992, end: 1).animate(animation),
                      child: child,
                    ),
                  ),
                );
              },
              child: _buildModeSurface(
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
                // tutor
                tutorLesson: tutorLesson.value,
                tutorFeedback: tutorFeedback.value,
                tutorDifficulty: tutorDifficulty,
                tutorFlipped: tutorFlipped,
                tutorInput: tutorInput,
                onLoadTutorLesson: loadTutorLesson,
                onCheckTutorAnswer: checkTutorAnswer,
                // roleplay
                roleplayDifficulty: roleplayDifficulty,
                roleplayScene: roleplayScene,
                roleplayMessages: roleplayMessages.value,
                roleplayInput: roleplayInput,
                onSendRoleplay: sendRoleplayTurn,
                // conversation
                conversationMessages: conversationMessages.value,
                conversationInput: conversationInput,
                languageRatio: languageRatio.value,
                onSendConversation: sendConversation,
                onSpeakText: speakText,
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
                  await prefs.setBool('polie_mode_intro_${modeName}_dismissed', true);
                  modeIntroDismissed.value = {...modeIntroDismissed.value, modeName};
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSurface({
    required Key key,
    required BuildContext context,
    required PolieMode mode,
    required ModeTheme theme,
    required bool isBusy,
    required String? modeError,
    required TextEditingController translationInput,
    required _TranslationPayload? translationOutput,
    required ValueNotifier<String> translationTone,
    required ValueNotifier<bool> autoTranslate,
    required ValueNotifier<bool> translationTrayOpen,
    required ValueNotifier<String> translationHistoryQuery,
    required List<dynamic> translationHistory,
    required Future<void> Function(String) onRunTranslation,
    required Future<void> Function() onSearchHistory,
    required Future<void> Function() onOpenTranslationHistory,
    required _TutorLessonPayload? tutorLesson,
    required _TutorFeedbackPayload? tutorFeedback,
    required ValueNotifier<String> tutorDifficulty,
    required ValueNotifier<bool> tutorFlipped,
    required TextEditingController tutorInput,
    required Future<void> Function() onLoadTutorLesson,
    required Future<void> Function() onCheckTutorAnswer,
    required ValueNotifier<String> roleplayDifficulty,
    required ValueNotifier<String> roleplayScene,
    required List<_RoleplayTurn> roleplayMessages,
    required TextEditingController roleplayInput,
    required Future<void> Function() onSendRoleplay,
    required List<_ConversationTurn> conversationMessages,
    required TextEditingController conversationInput,
    required double languageRatio,
    required Future<void> Function([String?]) onSendConversation,
    required Future<void> Function(String) onSpeakText,
    required _VocabPayload? vocabCard,
    required ValueNotifier<bool> vocabReveal,
    required ValueNotifier<String> vocabSetName,
    required ValueNotifier<String> vocabDifficultyTarget,
    required int vocabDeckCount,
    required String? vocabSrsChoice,
    required Future<void> Function() onLoadVocabCard,
    required Future<void> Function(String) onScoreSrs,
    required _ReviewPayload? reviewPayload,
    required ValueNotifier<String> reviewPeriod,
    required Future<void> Function() onLoadReview,
    required Set<String> introDismissed,
    required void Function(String modeName) onDismissIntro,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 700;
    final isTinyPhone = screenWidth < 390;
    final basePad = isTinyPhone ? 8.0 : 12.0;
    final bodyStyle = GoogleFonts.nunito(color: theme.body, fontSize: 14);
    final monoStyle = GoogleFonts.jetBrainsMono(color: theme.title, fontSize: 13.5);
    Widget card(Widget child, {Color? color}) {
      return Container(
        decoration: BoxDecoration(
          color: color ?? theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: child,
      );
    }

    final error = modeError == null
        ? const SizedBox.shrink()
        : Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(modeError, style: bodyStyle)),
              ],
            ),
          );
    const modeDescriptions = <PolieMode, String>{
      PolieMode.translation: 'Precision tool. Split-panel translation with dynamic output updates.',
      PolieMode.tutor: 'Interactive classroom notebook with flip cards and inline feedback.',
      PolieMode.roleplay: 'Dark cinematic stage with scene-first character cards and live coaching.',
      PolieMode.conversation: 'WhatsApp-style chat with a patient friend. The only bubble-chat mode.',
      PolieMode.vocab: 'Museum word theater: one dramatic word, dark focus, SRS actions.',
      PolieMode.review: 'Personal coach dashboard with animated bars and clear next steps.',
    };
    const modeIcons = <PolieMode, String>{
      PolieMode.translation: '\u21C4',
      PolieMode.tutor: '\uD83D\uDCD6',
      PolieMode.roleplay: '\uD83C\uDFAD',
      PolieMode.conversation: '\uD83D\uDCAC',
      PolieMode.vocab: '\u2726',
      PolieMode.review: '\uD83D\uDCCA',
    };
    final intro = (mode == PolieMode.conversation || introDismissed.contains(mode.name))
        ? const SizedBox.shrink()
        : Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.accent.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(modeIcons[mode] ?? '', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.name[0].toUpperCase() + mode.name.substring(1),
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: theme.title,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        modeDescriptions[mode] ?? '',
                        style: GoogleFonts.nunito(fontSize: 12.5, color: theme.body),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onDismissIntro(mode.name),
                  child: Icon(Icons.close_rounded, size: 18, color: theme.body.withOpacity(0.6)),
                ),
              ],
            ),
          );

    if (mode == PolieMode.translation) {
      final alternatives = translationOutput?.alternatives ?? const <AltItem>[];
      final effectiveAlternatives = alternatives.isNotEmpty
          ? alternatives
          : _buildFallbackAlternatives(
              translationOutput?.primary ?? '',
              translationTone.value,
            );
      final tones = const ['formal', 'casual', 'poetic', 'literal'];
      final wordCount = translationInput.text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length;
      return Container(
        key: key,
        padding: EdgeInsets.fromLTRB(basePad, basePad, basePad, basePad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            intro,
            error,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: isPhone ? 170 : 160,
                  child: CheckboxListTile(
                    value: autoTranslate.value,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-translate'),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (_) => autoTranslate.value = !autoTranslate.value,
                  ),
                ),
                Text('Tone:', style: bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                ...tones.map((tone) => ChoiceChip(
                      label: Text(tone[0].toUpperCase() + tone.substring(1)),
                      selected: translationTone.value == tone,
                      selectedColor: theme.accent.withOpacity(0.2),
                      onSelected: (_) => translationTone.value = tone,
                    )),
                if (!isPhone) Text('${translationInput.text.length} chars · $wordCount words', style: bodyStyle),
                IconButton(
                  tooltip: 'History',
                  onPressed: onOpenTranslationHistory,
                  icon: const Icon(Icons.history_rounded),
                ),
                IconButton(
                  tooltip: translationTrayOpen.value ? 'Hide alternatives' : 'Show alternatives',
                  onPressed: () => translationTrayOpen.value = !translationTrayOpen.value,
                  icon: Icon(
                    translationTrayOpen.value ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                  ),
                ),
              ],
            ),
            if (isPhone) ...[
              const SizedBox(height: 4),
              Text('${translationInput.text.length} chars · $wordCount words', style: bodyStyle),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final panelGap = 8.0;
                  final idealPanelWidth = (constraints.maxWidth - panelGap) / 2;
                  final panelWidth = isPhone ? idealPanelWidth : idealPanelWidth.clamp(260.0, 460.0);
                  final leftPanel = Container(
                    width: panelWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.border),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              DropdownButton<String>(
                                value: sourceLanguage,
                                items: [sourceLanguage]
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (_) {},
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: isBusy ? null : () => onRunTranslation(translationInput.text),
                                icon: const Icon(Icons.sync_alt_rounded),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: TextField(
                            controller: translationInput,
                            maxLines: null,
                            expands: true,
                            style: GoogleFonts.nunito(fontSize: isPhone ? 18 : 20),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              hintText: 'Type text here',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  final rightPanel = Container(
                    width: panelWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.border),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              DropdownButton<String>(
                                value: targetLanguage,
                                items: [targetLanguage]
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (_) {},
                              ),
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => onSpeakText(translationOutput?.primary ?? ''),
                                icon: const Icon(Icons.volume_up_outlined, size: 20),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  final text = (translationOutput?.primary ?? '').trim();
                                  if (text.isEmpty) return;
                                  await Clipboard.setData(ClipboardData(text: text));
                                },
                                icon: const Icon(Icons.copy_outlined, size: 20),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: onOpenTranslationHistory,
                                icon: const Icon(Icons.history_toggle_off_rounded, size: 20),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAnimatedWordFlow(
                                  translationOutput?.primary ?? '',
                                  GoogleFonts.nunito(fontSize: isPhone ? 20 : 24, color: theme.title),
                                ),
                                if ((translationOutput?.culturalNote ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    translationOutput!.culturalNote,
                                    style: bodyStyle.copyWith(color: theme.body.withOpacity(0.9)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (isPhone) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        leftPanel,
                        SizedBox(width: panelGap),
                        rightPanel,
                      ],
                    );
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        leftPanel,
                        SizedBox(width: panelGap),
                        rightPanel,
                      ],
                    ),
                  );
                },
              ),
            ),
            if (translationTrayOpen.value && MediaQuery.viewInsetsOf(context).bottom <= 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alternatives',
                      style: bodyStyle.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    if (effectiveAlternatives.isEmpty)
                      Text('No alternatives available yet.', style: bodyStyle)
                    else
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: effectiveAlternatives.length > 6 ? 6 : effectiveAlternatives.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final alt = effectiveAlternatives[i];
                            return ActionChip(
                              label: Text(
                                alt.text,
                                overflow: TextOverflow.ellipsis,
                                style: bodyStyle.copyWith(fontSize: 13),
                              ),
                              onPressed: isBusy
                                  ? null
                                  : () {
                                      translationInput.text = alt.text;
                                      onRunTranslation(alt.text);
                                    },
                            );
                          },
                        ),
                      ),
                    if (effectiveAlternatives.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        effectiveAlternatives.first.note,
                        style: bodyStyle.copyWith(color: theme.body.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (mode == PolieMode.tutor) {
      const lessonTopics = ['Greetings', 'Pronouns', 'Tones', 'Family Terms'];
      final showSidebar = !isPhone;
      return Container(
        key: key,
        child: Row(
          children: [
            if (showSidebar)
              Container(
                width: 230,
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                color: const Color(0xFF2A170B),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Lessons', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('🔥 7 day streak!', style: GoogleFonts.nunito(color: const Color(0xFFE8DAC5), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Text('Difficulty', style: GoogleFonts.nunito(color: const Color(0xFFE8DAC5))),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tutorDifficulty.value,
                      dropdownColor: const Color(0xFF2A1F14),
                      style: const TextStyle(color: Color(0xFFFAF3E0)),
                      decoration: _inputDecoration(theme, 'Difficulty').copyWith(fillColor: const Color(0xFF3A2A1C)),
                      items: const ['beginner', 'intermediate', 'advanced']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => tutorDifficulty.value = v ?? 'beginner',
                    ),
                    const SizedBox(height: 12),
                    ...lessonTopics.map((topic) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: topic == 'Greetings' ? const Color(0xFFD4822A) : const Color(0xFF3A2A1C),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(topic, style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        )),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A2A1C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '💡 Quick Fact\nYoruba has 3 tones: high (á), mid (a), and low (à).',
                        style: GoogleFonts.nunito(color: const Color(0xFFE8DAC5)),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    intro,
                    error,
                    if (!showSidebar)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A170B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🔥 7 day streak!', style: GoogleFonts.nunito(color: const Color(0xFFE8DAC5), fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: tutorDifficulty.value,
                              dropdownColor: const Color(0xFF2A1F14),
                              style: const TextStyle(color: Color(0xFFFAF3E0)),
                              decoration: _inputDecoration(theme, 'Difficulty').copyWith(fillColor: const Color(0xFF3A2A1C)),
                              items: const ['beginner', 'intermediate', 'advanced']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => tutorDifficulty.value = v ?? 'beginner',
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: lessonTopics
                                  .map((topic) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: topic == 'Greetings' ? const Color(0xFFD4822A) : const Color(0xFF3A2A1C),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(topic, style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    isTinyPhone
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Lesson 1: ${tutorLesson?.concept ?? 'Greetings by Time of Day'}',
                                style: GoogleFonts.playfairDisplay(
                                  color: theme.title,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: isBusy ? null : onLoadTutorLesson,
                                style: FilledButton.styleFrom(backgroundColor: theme.accent),
                                child: Text(isBusy ? 'Loading...' : 'New Card'),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Lesson 1: ${tutorLesson?.concept ?? 'Greetings by Time of Day'}',
                                  style: GoogleFonts.playfairDisplay(
                                    color: theme.title,
                                    fontSize: isPhone ? 22 : 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: isBusy ? null : onLoadTutorLesson,
                                style: FilledButton.styleFrom(backgroundColor: theme.accent),
                                child: Text(isBusy ? 'Loading...' : 'New Card'),
                              ),
                            ],
                          ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.33,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
                    ),
                    const SizedBox(height: 16),
                    AnimatedCrossFade(
                      firstChild: card(
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tutorLesson?.concept ?? 'Greetings by Time of Day',
                                style: GoogleFonts.playfairDisplay(
                                  color: theme.title,
                                  fontSize: isTinyPhone ? 20 : 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(tutorLesson?.explanation ?? '', style: bodyStyle.copyWith(fontSize: isTinyPhone ? 15 : 18)),
                              const SizedBox(height: 14),
                              card(
                                color: const Color(0xFFF6EED8),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tutorLesson?.example.targetLang ?? '-',
                                        style: GoogleFonts.nunito(
                                          fontSize: isTinyPhone ? 26 : 34,
                                          fontWeight: FontWeight.w700,
                                          color: theme.title,
                                        ),
                                      ),
                                      Text(tutorLesson?.example.transliteration ?? '-', style: monoStyle),
                                      Text(tutorLesson?.example.english ?? '-', style: bodyStyle.copyWith(fontSize: isTinyPhone ? 18 : 24)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              card(
                                color: const Color(0xFFF8F3E6),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    '💡 Memory Tip\n${tutorLesson?.memoryTip ?? '-'}',
                                    style: bodyStyle.copyWith(fontSize: isTinyPhone ? 17 : 22),
                                  ),
                                ),
                              ),
                              if ((tutorLesson?.watchOut ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                card(
                                  color: const Color(0xFFFBEAEC),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      '⚠️ Watch Out\n${tutorLesson!.watchOut}',
                                      style: bodyStyle.copyWith(fontSize: isTinyPhone ? 17 : 22),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: tutorLesson == null ? null : () => tutorFlipped.value = true,
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.accent,
                                  minimumSize: const Size(double.infinity, 52),
                                ),
                                child: const Text('Practice This Lesson'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      secondChild: card(
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Practice',
                                style: GoogleFonts.playfairDisplay(
                                  color: theme.title,
                                  fontSize: isTinyPhone ? 20 : 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tutorLesson?.practiceQuestion ?? 'How would you apply this concept?',
                                style: bodyStyle.copyWith(fontWeight: FontWeight.w700, fontSize: isTinyPhone ? 18 : 23),
                              ),
                              if ((tutorLesson?.practiceHint ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Hint: ${tutorLesson!.practiceHint}',
                                    style: bodyStyle.copyWith(fontStyle: FontStyle.italic, fontSize: isTinyPhone ? 16 : 20),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: tutorInput,
                                minLines: 2,
                                maxLines: 4,
                                decoration: _inputDecoration(theme, 'Type your answer here...'),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: isBusy || tutorLesson == null ? null : onCheckTutorAnswer,
                                style: FilledButton.styleFrom(backgroundColor: theme.accent),
                                child: Text(isBusy ? 'Checking...' : 'Check Answer'),
                              ),
                              if (tutorFeedback != null) ...[
                                const SizedBox(height: 10),
                                Text('${tutorFeedback.verdict.toUpperCase()} • ${tutorFeedback.score}', style: bodyStyle.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Text(tutorFeedback.encouragement, style: bodyStyle),
                                Text('Correction: ${tutorFeedback.correction}', style: bodyStyle),
                                Text('Why: ${tutorFeedback.why}', style: bodyStyle),
                                const SizedBox(height: 8),
                                Text('Next step: ${tutorFeedback.nextStep}', style: bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                              ],
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () => tutorFlipped.value = false,
                                child: const Text('Back to Lesson'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      crossFadeState: tutorFlipped.value ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (mode == PolieMode.roleplay) {
      final sceneSubtitle = <String, String>{
        'Market': 'Bargain for goods with a friendly vendor',
        'Restaurant': 'Order naturally and ask follow-up questions',
        'Meeting Elder': 'Use respectful phrases and proper tone',
        'Job Interview': 'Answer clearly and confidently',
        'Family Dinner': 'Keep the tone warm and social',
      };
      return Container(
        key: key,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0A04), Color(0xFF1A130C)],
          ),
        ),
        child: Column(
          children: [
            intro,
            error,
            Container(
              width: double.infinity,
              height: isPhone ? 124 : 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8E2E09), Color(0xFFE09A18)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'At the ${roleplayScene.value}',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: isPhone ? 26 : 34,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Change Scene'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sceneSubtitle[roleplayScene.value] ?? 'Practice natural conversation in context',
                      style: GoogleFonts.nunito(color: Colors.white.withOpacity(0.9), fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 24, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: Opacity(
                    opacity: (1 - (value / 24)).clamp(0, 1),
                    child: child,
                  ),
                );
              },
              child: card(
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFD4822A),
                        child: Text('MB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mama Bisi', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                            Text('Friendly, patient vendor', style: GoogleFonts.nunito(color: Colors.white70)),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Chip(
                            label: Text('Bilingual', style: TextStyle(fontSize: isTinyPhone ? 11 : 12)),
                            backgroundColor: const Color(0xFF2BDB8C),
                            visualDensity: isTinyPhone ? const VisualDensity(horizontal: -2, vertical: -2) : null,
                          ),
                          Chip(
                            label: Text('Hints', style: TextStyle(fontSize: isTinyPhone ? 11 : 12)),
                            visualDensity: isTinyPhone ? const VisualDensity(horizontal: -2, vertical: -2) : null,
                          ),
                          Chip(
                            label: Text('Immersion', style: TextStyle(fontSize: isTinyPhone ? 11 : 12)),
                            visualDensity: isTinyPhone ? const VisualDensity(horizontal: -2, vertical: -2) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                color: Colors.black.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: card(
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: roleplayMessages.length,
                  itemBuilder: (context, index) {
                    final item = roleplayMessages[index];
                    if (item.userText != null) {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC4663A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(item.userText!, style: bodyStyle.copyWith(color: Colors.white)),
                        ),
                      );
                    }
                    final ai = item.ai!;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15110D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4822A).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ai.characterResponse.targetLang, style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0))),
                          const SizedBox(height: 4),
                          Text('English: ${ai.characterResponse.english}', style: bodyStyle.copyWith(color: const Color(0xFFD8C9B7))),
                          const SizedBox(height: 6),
                          Text(
                            '${ai.coaching.feedbackType.toUpperCase()} • ${ai.coaching.userAccuracy}',
                            style: bodyStyle.copyWith(color: const Color(0xFFF2C14E), fontWeight: FontWeight.w700),
                          ),
                          Text(ai.coaching.feedback, style: bodyStyle.copyWith(color: const Color(0xFFF2E6D7))),
                          if ((ai.coaching.betterPhrasing ?? '').isNotEmpty)
                            Text('Try: ${ai.coaching.betterPhrasing}', style: monoStyle.copyWith(color: const Color(0xFFFAF3E0))),
                        ],
                      ),
                    );
                  },
                ),
                color: Colors.black.withOpacity(0.28),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  style: IconButton.styleFrom(backgroundColor: Colors.white10),
                  icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: roleplayInput,
                    style: const TextStyle(color: Color(0xFFFAF3E0)),
                    decoration: _inputDecoration(theme, 'Speak your line...').copyWith(
                      hintStyle: const TextStyle(color: Color(0xFFD8C9B7)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  style: IconButton.styleFrom(backgroundColor: Colors.white10),
                  icon: const Icon(Icons.mic_none_rounded, color: Colors.white),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: isBusy ? null : onSendRoleplay,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.accent,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: Text(isBusy ? '...' : '🌐'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (mode == PolieMode.conversation) {
      return Container(
        key: key,
        color: const Color(0xFFF5F0E8),
        child: Column(
          children: [
            intro,
            error,
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFD4822A),
                    child: Icon(Icons.smart_toy_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Polie', style: bodyStyle.copyWith(fontWeight: FontWeight.w800)),
                      Text('Online', style: bodyStyle.copyWith(color: const Color(0xFF4A7C59), fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: isTinyPhone ? 88 : 120,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: languageRatio.clamp(0, 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7C59),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: conversationMessages.length,
                itemBuilder: (context, index) {
                  final item = conversationMessages[index];
                  if (item.userText != null) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4822A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(item.userText!, style: bodyStyle.copyWith(color: Colors.white)),
                      ),
                    );
                  }
                  final ai = item.ai!;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.border.withOpacity(0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  ai.message,
                                  style: bodyStyle.copyWith(color: const Color(0xFF2D1B0E)),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                onPressed: () => onSpeakText(ai.message),
                                icon: const Icon(Icons.volume_up_outlined, size: 18),
                              ),
                            ],
                          ),
                          if (ai.correction.hasCorrection)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('Correction: ${ai.correction.correction ?? ai.correction.note}',
                                  style: bodyStyle.copyWith(color: Colors.orange.shade800)),
                            ),
                          if (ai.suggestedReplies.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: ai.suggestedReplies
                                  .take(3)
                                  .map((reply) => ActionChip(
                                        label: SizedBox(
                                          width: isTinyPhone ? 140 : null,
                                          child: Text(
                                            reply,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: isTinyPhone ? 12 : 14),
                                          ),
                                        ),
                                        visualDensity: isTinyPhone ? const VisualDensity(horizontal: -2, vertical: -2) : null,
                                        onPressed: isBusy ? null : () => onSendConversation(reply),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.sentiment_satisfied_alt_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: conversationInput,
                      decoration: _inputDecoration(theme, 'Type a message...').copyWith(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(color: theme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(color: theme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(color: theme.accent, width: 1.3),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                    icon: const Icon(Icons.mic_none_rounded, size: 20),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: isBusy ? null : onSendConversation,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.accent,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: Text(isBusy ? '...' : '➤'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (mode == PolieMode.vocab) {
      return Container(
        key: key,
        color: const Color(0xFF0F0A04),
        child: Column(
          children: [
            intro,
            error,
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: card(
                color: Colors.white.withOpacity(0.02),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 6,
                        spacing: 10,
                        children: [
                          Text(
                            vocabSetName.value,
                            style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0), fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${(10 - vocabDeckCount).clamp(0, 10)}/10 • $vocabDeckCount remaining',
                            style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0), fontSize: isTinyPhone ? 12 : 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: ((10 - vocabDeckCount).clamp(0, 10)) / 10,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4822A)),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final category in const [
                            'Core Daily Words',
                            'Travel',
                            'Food',
                            'Greetings',
                            'Business',
                            'Culture',
                          ])
                            ChoiceChip(
                              label: Text(category, style: const TextStyle(fontSize: 12)),
                              selected: vocabSetName.value == category,
                              selectedColor: const Color(0xFFD4822A).withOpacity(0.25),
                              onSelected: (_) => vocabSetName.value = category,
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: vocabDifficultyTarget.value,
                                dropdownColor: const Color(0xFF1A130C),
                                style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0)),
                                items: const [
                                  DropdownMenuItem(value: 'mixed', child: Text('Difficulty: Mixed')),
                                  DropdownMenuItem(value: 'beginner', child: Text('Difficulty: Beginner')),
                                  DropdownMenuItem(value: 'intermediate', child: Text('Difficulty: Intermediate')),
                                  DropdownMenuItem(value: 'advanced', child: Text('Difficulty: Advanced')),
                                ],
                                onChanged: (v) {
                                  if (v != null) vocabDifficultyTarget.value = v;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => vocabReveal.value = !vocabReveal.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: isTinyPhone ? (screenWidth - 24).clamp(260, 330).toDouble() : 330,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A130C),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFD4822A).withOpacity(0.35), blurRadius: 24),
                      ],
                    ),
                    child: vocabCard == null
                        ? Text('Tap "Next Word"', style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0)))
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (vocabReveal.value)
                                Text(
                                  '${vocabCard.partOfSpeech.toUpperCase()} · ${vocabCard.difficulty.toUpperCase()}',
                                  style: bodyStyle.copyWith(color: const Color(0xFFF2C14E), fontWeight: FontWeight.w800),
                                )
                              else
                                const Center(child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFF2C14E), size: 26)),
                              const SizedBox(height: 8),
                              Text(
                                vocabCard.word,
                                style: GoogleFonts.jetBrainsMono(
                                  color: const Color(0xFFFAF3E0),
                                  fontSize: isTinyPhone ? 44 : 56,
                                  letterSpacing: isTinyPhone ? 1.0 : 1.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(vocabCard.pronunciation, style: bodyStyle.copyWith(color: const Color(0xFFF2C14E))),
                              const SizedBox(height: 6),
                              if (!vocabReveal.value)
                                Text('Tap to reveal', style: bodyStyle.copyWith(color: const Color(0xFFD8C9B7))),
                              if (vocabReveal.value) ...[
                                const SizedBox(height: 10),
                                card(
                                  color: Colors.white.withOpacity(0.06),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(vocabCard.english, style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0), fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Text(vocabCard.example.target, style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0))),
                                        Text(vocabCard.example.english, style: bodyStyle.copyWith(color: const Color(0xFFD8C9B7))),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                card(
                                  color: Colors.white.withOpacity(0.06),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      '💡 Memory Peg\n${vocabCard.memoryPeg}',
                                      style: bodyStyle.copyWith(color: const Color(0xFFF2C14E)),
                                    ),
                                  ),
                                ),
                                if ((vocabCard.culturalNote ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  card(
                                    color: Colors.white.withOpacity(0.06),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        '🟢 Cultural Note\n${vocabCard.culturalNote}',
                                        style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _srsButton(context, 'Again (1m)', Colors.red.shade500, isBusy ? null : () => onScoreSrs('again'))),
                      const SizedBox(width: 6),
                      Expanded(child: _srsButton(context, 'Hard (10m)', Colors.orange.shade600, isBusy ? null : () => onScoreSrs('hard'))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _srsButton(context, 'Good (1d)', Colors.green.shade600, isBusy ? null : () => onScoreSrs('good'))),
                      const SizedBox(width: 6),
                      Expanded(child: _srsButton(context, 'Easy (4d)', Colors.blue.shade600, isBusy ? null : () => onScoreSrs('easy'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Last SRS choice: ${vocabSrsChoice ?? '-'}', style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0))),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: isBusy ? null : onLoadVocabCard,
                    style: FilledButton.styleFrom(backgroundColor: theme.accent),
                    child: Text(isBusy ? '...' : 'Next Word'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      key: key,
      padding: EdgeInsets.fromLTRB(basePad, basePad, basePad, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          intro,
          error,
          Text(
            'Your Progress Report',
            style: GoogleFonts.playfairDisplay(
              fontSize: isTinyPhone ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: theme.title,
            ),
          ),
          const SizedBox(height: 4),
          Text("Let's see how you're doing! 📊", style: bodyStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _periodChip(
                context: context,
                label: 'This Week',
                selected: reviewPeriod.value == 'week',
                onTap: () => reviewPeriod.value = 'week',
              ),
              _periodChip(
                context: context,
                label: 'This Month',
                selected: reviewPeriod.value == 'month',
                onTap: () => reviewPeriod.value = 'month',
              ),
              _periodChip(
                context: context,
                label: 'All Time',
                selected: reviewPeriod.value == 'all',
                onTap: () => reviewPeriod.value = 'all',
              ),
              IconButton(
                onPressed: isBusy ? null : onLoadReview,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (reviewPayload == null)
            card(
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('No review data yet. Tap Refresh.', style: bodyStyle),
              ),
            )
          else ...[
            if (isTinyPhone) ...[
              _statCard(context, 'Words Learned', '${reviewPayload.wordsSeen}', const Color(0xFFD4822A)),
              const SizedBox(height: 8),
              _statCard(context, 'Accuracy', '${reviewPayload.accuracy.toStringAsFixed(1)}%', const Color(0xFF4A7C59)),
              const SizedBox(height: 8),
              _statCard(context, 'Day Streak', '${reviewPayload.streak}', const Color(0xFFE2B93B)),
              const SizedBox(height: 8),
              _statCard(context, 'Lessons Done', '${reviewPayload.lessonsDone}', const Color(0xFFC4663A)),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _statCard(context, 'Words Learned', '${reviewPayload.wordsSeen}', const Color(0xFFD4822A))),
                  const SizedBox(width: 8),
                  Expanded(child: _statCard(context, 'Accuracy', '${reviewPayload.accuracy.toStringAsFixed(1)}%', const Color(0xFF4A7C59))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _statCard(context, 'Day Streak', '${reviewPayload.streak}', const Color(0xFFE2B93B))),
                  const SizedBox(width: 8),
                  Expanded(child: _statCard(context, 'Lessons Done', '${reviewPayload.lessonsDone}', const Color(0xFFC4663A))),
                ],
              ),
            ],
            const SizedBox(height: 10),
            card(
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Skills Breakdown', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...reviewPayload.skillBars.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.key, style: bodyStyle),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: e.value),
                              duration: const Duration(milliseconds: 520),
                              builder: (context, value, _) => LinearProgressIndicator(
                                value: value,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(_skillColor(e.key)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            card(
              color: const Color(0xFFD4822A),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Polie's Insights", style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                      reviewPayload.headlineInsight,
                      style: GoogleFonts.nunito(fontSize: 19, color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(reviewPayload.coachingParagraph, style: GoogleFonts.nunito(fontSize: 14, color: Colors.white.withOpacity(0.95))),
                    const SizedBox(height: 10),
                    Text('💪 Your Strengths', style: GoogleFonts.nunito(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...reviewPayload.strengths.map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${s.area}\n${s.note}', style: GoogleFonts.nunito(color: Colors.white, fontSize: 13)),
                        )),
                    Text('🎯 Areas to Focus On', style: GoogleFonts.nunito(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...reviewPayload.growthAreas.map((g) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${g.area}\n${g.note}\n💡 Quick win: ${g.quickWin}',
                            style: GoogleFonts.nunito(color: Colors.white, fontSize: 13),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            card(
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recommended Next Steps', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: reviewPayload.nextSteps
                          .map(
                            (s) => SizedBox(
                              width: isPhone ? (screenWidth - (basePad * 2) - 8).clamp(220, 340).toDouble() : 260,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.border),
                                ),
                                child: Text('${s.title}\n${s.why}\nStart now →', style: bodyStyle.copyWith(fontSize: 13)),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFC64F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(reviewPayload.motivationalClose, style: bodyStyle.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedWordFlow(String text, TextStyle style) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        for (var i = 0; i < words.length; i++)
          TweenAnimationBuilder<double>(
            key: ValueKey('${words[i]}-$i-$text'),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 120 + (i * 20).clamp(0, 500)),
            builder: (context, value, child) => Opacity(opacity: value, child: child),
            child: Text(words[i], style: style),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(ModeTheme theme, String hint) {
    final isDark = theme.background.computeLuminance() < 0.2;
    return InputDecoration(
      hintText: hint,
      hintStyle: isDark ? const TextStyle(color: Color(0xFFD8C9B7)) : null,
      filled: true,
      fillColor: theme.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.accent, width: 1.3),
      ),
    );
  }

  Widget _periodChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 8 : 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD4822A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9CBB6)),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: selected ? Colors.white : const Color(0xFF2D1B0E),
            fontWeight: FontWeight.w700,
            fontSize: compact ? 12 : 14,
          ),
        ),
      ),
    );
  }

  ModeTheme _themeForMode(PolieMode mode) {
    switch (mode) {
      case PolieMode.translation:
        return const ModeTheme(
          background: Color(0xFFFAF3E0),
          card: Colors.white,
          title: Color(0xFF2D1B0E),
          body: Color(0xFF3F2A1A),
          border: Color(0xFFD9CBB6),
          accent: Color(0xFFD4822A),
        );
      case PolieMode.tutor:
        return const ModeTheme(
          background: Color(0xFFFAF3E0),
          card: Colors.white,
          title: Color(0xFF2D1B0E),
          body: Color(0xFF3F2A1A),
          border: Color(0xFFD9CBB6),
          accent: Color(0xFFD4822A),
        );
      case PolieMode.roleplay:
        return const ModeTheme(
          background: Color(0xFF0F0A04),
          card: Color(0xFF1A130C),
          title: Color(0xFFFAF3E0),
          body: Color(0xFFE8DAC5),
          border: Color(0xFF3A2A1C),
          accent: Color(0xFFC4663A),
        );
      case PolieMode.conversation:
        return const ModeTheme(
          background: Color(0xFFF5F0E8),
          card: Colors.white,
          title: Color(0xFF2D1B0E),
          body: Color(0xFF3F2A1A),
          border: Color(0xFFE0D5C4),
          accent: Color(0xFFD4822A),
        );
      case PolieMode.vocab:
        return const ModeTheme(
          background: Color(0xFF0F0A04),
          card: Color(0xFF1A130C),
          title: Color(0xFFFAF3E0),
          body: Color(0xFFE8DAC5),
          border: Color(0xFF3A2A1C),
          accent: Color(0xFFF2C14E),
        );
      case PolieMode.review:
      case PolieMode.pronunciation:
      case PolieMode.grammar:
        return const ModeTheme(
          background: Color(0xFFFAF3E0),
          card: Colors.white,
          title: Color(0xFF2D1B0E),
          body: Color(0xFF3F2A1A),
          border: Color(0xFFD9CBB6),
          accent: Color(0xFFD4822A),
        );
    }
  }

  Widget _srsButton(BuildContext context, String label, Color color, VoidCallback? onTap) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 9 : 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, Color stripe) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9CBB6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, decoration: BoxDecoration(color: stripe, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.nunito(fontSize: compact ? 11 : 12)),
          Row(
            children: [
              Icon(_statIcon(label), size: 16, color: stripe),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(fontSize: compact ? 17 : 20, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _statIcon(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('word')) return Icons.menu_book_rounded;
    if (normalized.contains('accuracy')) return Icons.trending_up_rounded;
    if (normalized.contains('streak')) return Icons.local_fire_department_rounded;
    if (normalized.contains('lesson')) return Icons.chat_bubble_outline_rounded;
    return Icons.insights_rounded;
  }

  Color _skillColor(String skill) {
    final s = skill.toLowerCase();
    if (s.contains('vocab')) return const Color(0xFFD4822A);
    if (s.contains('grammar')) return const Color(0xFF4A7C59);
    if (s.contains('pronunciation')) return const Color(0xFFE2B93B);
    if (s.contains('conversation')) return const Color(0xFFC4663A);
    return const Color(0xFFD4822A);
  }
}

Map<String, dynamic>? _tryParseJson(String raw) {
  // Strip control characters that break JSON parsing
  final cleaned = raw
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
      .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
      .trim();

  // Attempt 1: direct parse (works when response_format: json_object is used)
  try {
    final decoded = jsonDecode(cleaned);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {}

  // Attempt 2: extract JSON object between first { and last }
  try {
    final first = cleaned.indexOf('{');
    final last = cleaned.lastIndexOf('}');
    if (first >= 0 && last > first) {
      final jsonBody = cleaned.substring(first, last + 1);
      final decoded = jsonDecode(jsonBody);
      if (decoded is Map<String, dynamic>) return decoded;
    }
  } catch (_) {}

  // Attempt 3: roleplay-aware extraction when nested JSON is broken
  try {
    if (cleaned.contains('character_response') || cleaned.contains('target_lang')) {
      final targetMatch = RegExp(r'"target_lang"\s*:\s*"([^"]*)"').firstMatch(cleaned);
      final englishMatch = RegExp(r'"english"\s*:\s*"([^"]*)"').firstMatch(cleaned);
      final feedbackMatch = RegExp(r'"feedback"\s*:\s*"([^"]*)"').firstMatch(cleaned);
      if (targetMatch != null) {
        return {
          'character_response': {
            'target_lang': targetMatch.group(1) ?? '',
            'transliteration': '-',
            'english': englishMatch?.group(1) ?? '-',
            'emotion': 'neutral',
            'action': null,
          },
          'coaching': {
            'user_accuracy': 50,
            'feedback_type': 'suggestion',
            'feedback': feedbackMatch?.group(1) ?? 'Keep practicing!',
            'better_phrasing': null,
          },
        };
      }
    }
  } catch (_) {}

  // Attempt 4: build minimal JSON from key:value prose (graceful degradation)
  try {
    final lines = cleaned.split('\n').where((l) => l.trim().isNotEmpty);
    final map = <String, dynamic>{};
    for (final line in lines) {
      final colonIdx = line.indexOf(':');
      if (colonIdx > 0) {
        final key = line.substring(0, colonIdx).trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
        final value = line.substring(colonIdx + 1).trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          map[key] = value;
        }
      }
    }
    if (map.isNotEmpty) {
      if (!map.containsKey('primary') && map.length == 1) {
        map['primary'] = map.values.first;
      }
      return map;
    }
  } catch (_) {}

  debugPrint('[Polie] _tryParseJson failed on: ${raw.length > 200 ? raw.substring(0, 200) : raw}');
  return null;
}

dynamic _n(Map<String, dynamic>? map, String key, dynamic fallback) => map?[key] ?? fallback;

String _cleanAiText(String input, {String fallback = '-'}) {
  var out = input.trim();
  if (out.isEmpty) return fallback;
  out = out
      .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
      .replaceAll(RegExp(r'```'), '')
      .replaceAll(RegExp(r'^\{\s*"message"\s*:\s*"', multiLine: true), '')
      .replaceAll(RegExp(r'"\s*\}\s*$', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (out.startsWith('{') || out.startsWith('[')) return fallback;
  return out;
}

bool _looksTruncated(String message) {
  final m = message.trim();
  if (m.isEmpty) return true;
  if (m.length < 8) return true;
  final last = m.codeUnitAt(m.length - 1);
  if (last == 46 || last == 33 || last == 63) return false; // . ! ?
  if ((last == 34 || last == 39) && m.length > 1) {
    final prev = m.codeUnitAt(m.length - 2);
    if (prev == 46 || prev == 33 || prev == 63) return false; // . ! ? before quote
  }
  return true;
}

bool _isConversationResponseRich(String message) {
  final normalized = message.trim();
  if (normalized.length < 45) return false;
  final sentenceCount = RegExp(r'[.!?]+').allMatches(normalized).length;
  if (sentenceCount >= 3) return true;
  return normalized.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length >= 16;
}

List<AltItem> _buildFallbackAlternatives(String primary, String tone) {
  final clean = primary.trim();
  if (clean.isEmpty || clean == '-') return const <AltItem>[];
  final note = switch (tone.toLowerCase()) {
    'formal' => 'Primary formal rendering',
    'casual' => 'Primary casual rendering',
    'poetic' => 'Primary poetic rendering',
    'literal' => 'Primary literal rendering',
    _ => 'Primary rendering',
  };
  return <AltItem>[
    AltItem(text: clean, note: note),
  ];
}

_TranslationPayload _normalizeTranslationPayload({
  required _TranslationPayload payload,
  required String targetLanguage,
  required String sourceText,
}) {
  String fixText(String value) {
    var out = value.trim();
    if (out.isEmpty) return out;
    final enforced = DiacriticsEnforcer.enforceWithMetadata(
      out,
      targetLanguage,
      enableFuzzy: true,
      fuzzyThreshold: 0.7,
    );
    out = (enforced['text'] as String?) ?? out;

    // High-impact correction for a common greeting regression.
    final asksGoodMorning = RegExp(r'\bgood\s+morning\b', caseSensitive: false).hasMatch(sourceText);
    final isYoruba = targetLanguage.toLowerCase().contains('yor');
    if (isYoruba && asksGoodMorning) {
      final normalized = out.toLowerCase().replaceAll(RegExp(r'[\s\-\.\,]'), '');
      if (normalized == 'eka' || normalized == 'ẹká' || normalized == 'ekaaro' || normalized == 'ẹkáárọ̀') {
        out = 'Ẹ káàárọ̀';
      }
    }
    return out;
  }

  final primary = fixText(payload.primary);
  final alternatives = payload.alternatives
      .map((alt) => AltItem(text: fixText(alt.text), note: alt.note))
      .where((alt) => alt.text.trim().isNotEmpty)
      .toList();

  return _TranslationPayload(
    primary: primary,
    alternatives: alternatives,
    culturalNote: payload.culturalNote,
    toneAchieved: payload.toneAchieved,
  );
}

_ConversationPayload _enforceConversationDiacritics(
  _ConversationPayload payload,
  String language,
) {
  String enforce(String value) {
    if (value.trim().isEmpty) return value;
    final result = DiacriticsEnforcer.enforceWithMetadata(
      value,
      language,
      enableFuzzy: true,
      fuzzyThreshold: 0.7,
    );
    return (result['text'] as String?) ?? value;
  }

  return _ConversationPayload(
    message: enforce(payload.message),
    correction: _ConversationCorrection(
      hasCorrection: payload.correction.hasCorrection,
      wasCorrect: payload.correction.wasCorrect,
      correction: payload.correction.correction == null ? null : enforce(payload.correction.correction!),
      note: enforce(payload.correction.note),
    ),
    suggestedReplies: payload.suggestedReplies.map(enforce).toList(),
    newVocab: payload.newVocab
        .map((v) => _ConversationVocab(
              word: enforce(v.word),
              meaning: v.meaning,
            ))
        .toList(),
  );
}

class _TranslationPayload {
  final String primary;
  final List<AltItem> alternatives;
  final String culturalNote;
  final String toneAchieved;
  const _TranslationPayload({
    required this.primary,
    required this.alternatives,
    required this.culturalNote,
    required this.toneAchieved,
  });

  factory _TranslationPayload.fromJson(Map<String, dynamic> json, {required String rawFallback}) {
    final alternativesRaw = (_n(json, 'alternatives', const []) as List)
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    return _TranslationPayload(
      primary: _cleanAiText(
        (_n(json, 'primary', '') as String).trim().isNotEmpty ? (_n(json, 'primary', '') as String) : rawFallback,
        fallback: _cleanAiText(rawFallback, fallback: '-'),
      ),
      alternatives: alternativesRaw
          .map((e) => AltItem(text: (_n(e, 'text', '') as String), note: (_n(e, 'note', '') as String)))
          .where((e) => e.text.trim().isNotEmpty)
          .toList(),
      culturalNote: _cleanAiText((_n(json, 'cultural_note', '') ?? '').toString(), fallback: ''),
      toneAchieved: _cleanAiText((_n(json, 'tone_achieved', '-') ?? '-').toString(), fallback: '-'),
    );
  }
}

class _TutorLessonPayload {
  final String concept;
  final String explanation;
  final _TutorExample example;
  final String memoryTip;
  final String? watchOut;
  final String? practiceQuestion;
  final String? practiceHint;
  const _TutorLessonPayload({
    required this.concept,
    required this.explanation,
    required this.example,
    required this.memoryTip,
    required this.watchOut,
    this.practiceQuestion,
    this.practiceHint,
  });
  factory _TutorLessonPayload.fromJson(Map<String, dynamic> json, String fallback) {
    final ex = (_n(json, 'example', const {}) as Map).cast<String, dynamic>();
    String sanitize(String value, {String fallbackText = '-'}) {
      final v = value.trim();
      if (v.isEmpty) return fallbackText;
      if (v.startsWith('{') || v.startsWith('```') || v.startsWith('[')) return fallbackText;
      return _cleanAiText(v, fallback: fallbackText);
    }
    String concept = (_n(json, 'concept', 'Lesson') as String);
    // Guard against raw JSON leaking into concept field
    if (concept.startsWith('{') || concept.startsWith('```')) {
      concept = 'Lesson';
    }
    String explanation = (_n(json, 'explanation', fallback) as String);
    if (explanation.startsWith('{') || explanation.startsWith('```')) {
      explanation = 'Let us practice this concept step by step with a clear example.';
    }
    return _TutorLessonPayload(
      concept: sanitize(concept, fallbackText: 'Lesson'),
      explanation: sanitize(explanation, fallbackText: 'Let us practice this concept step by step.'),
      example: _TutorExample(
        targetLang: sanitize((_n(ex, 'target_lang', '-') as String),
            fallbackText: 'Example unavailable'),
        transliteration: sanitize((_n(ex, 'transliteration', '-') as String),
            fallbackText: '-'),
        english: sanitize((_n(ex, 'english', '-') as String),
            fallbackText: 'Meaning unavailable'),
      ),
      memoryTip: sanitize((_n(json, 'memory_tip', '-') as String),
          fallbackText: 'Repeat the pattern aloud three times.'),
      watchOut: (_n(json, 'watch_out', '') as String?)?.trim().isEmpty ?? true
          ? null
          : sanitize((_n(json, 'watch_out', '') as String), fallbackText: ''),
      practiceQuestion: (_n(json, 'practice_question', '') as String?)?.trim().isEmpty ?? true
          ? null
          : sanitize((_n(json, 'practice_question', '') as String),
              fallbackText: 'Can you write one sentence using this concept?'),
      practiceHint: (_n(json, 'practice_hint', '') as String?)?.trim().isEmpty ?? true
          ? null
          : sanitize((_n(json, 'practice_hint', '') as String),
              fallbackText: 'Start with a short simple sentence.'),
    );
  }
}

class _TutorExample {
  final String targetLang;
  final String transliteration;
  final String english;
  const _TutorExample({
    required this.targetLang,
    required this.transliteration,
    required this.english,
  });
}

class _TutorFeedbackPayload {
  final String verdict;
  final int score;
  final String encouragement;
  final String correction;
  final String why;
  final String? nativeSpeakerNote;
  final String nextStep;
  final String drill;
  const _TutorFeedbackPayload({
    required this.verdict,
    required this.score,
    required this.encouragement,
    required this.correction,
    required this.why,
    required this.nativeSpeakerNote,
    required this.nextStep,
    required this.drill,
  });
  factory _TutorFeedbackPayload.fromJson(Map<String, dynamic> json, String fallback) {
    String sanitize(String value, {String fallbackText = '-'}) {
      final v = value.trim();
      if (v.isEmpty) return fallbackText;
      if (v.startsWith('{') || v.startsWith('```') || v.startsWith('[')) return fallbackText;
      return _cleanAiText(v, fallback: fallbackText);
    }
    return _TutorFeedbackPayload(
      verdict: (_n(json, 'verdict', 'close') as String),
      score: (_n(json, 'score', 50) as num).toInt(),
      encouragement: sanitize((_n(json, 'encouragement', fallback) as String),
          fallbackText: 'Good effort. Keep practicing and try again.'),
      correction: sanitize((_n(json, 'correction', '-') as String),
          fallbackText: 'Try a simpler sentence pattern.'),
      why: sanitize((_n(json, 'why', '-') as String),
          fallbackText: 'Your structure is close; adjust word order and tense.'),
      nativeSpeakerNote: (_n(json, 'native_speaker_note', '') as String?)?.trim().isEmpty ?? true
          ? null
          : sanitize((_n(json, 'native_speaker_note', '') as String), fallbackText: ''),
      nextStep: sanitize((_n(json, 'next_step', '') as String),
          fallbackText: 'Write one new sentence using this pattern and read it aloud.'),
      drill: sanitize((_n(json, 'drill', '') as String),
          fallbackText: 'Mini drill: rewrite your answer in a shorter sentence.'),
    );
  }
}

class _RoleplayPayload {
  final _RoleplayCharacterResponse characterResponse;
  final _RoleplayCoaching coaching;
  const _RoleplayPayload({required this.characterResponse, required this.coaching});
  factory _RoleplayPayload.fromJson(Map<String, dynamic> json, String fallback) {
    final c = (_n(json, 'character_response', const {}) as Map).cast<String, dynamic>();
    final coaching = (_n(json, 'coaching', const {}) as Map).cast<String, dynamic>();
    return _RoleplayPayload(
      characterResponse: _RoleplayCharacterResponse(
        targetLang: _cleanAiText((_n(c, 'target_lang', fallback) as String), fallback: _cleanAiText(fallback)),
        transliteration: _cleanAiText((_n(c, 'transliteration', '-') as String), fallback: '-'),
        english: _cleanAiText((_n(c, 'english', '-') as String), fallback: 'English translation unavailable.'),
        emotion: (_n(c, 'emotion', 'neutral') as String),
        action: (_n(c, 'action', '') as String?)?.trim().isEmpty ?? true ? null : (_n(c, 'action', '') as String),
      ),
      coaching: _RoleplayCoaching(
        userAccuracy: (_n(coaching, 'user_accuracy', 50) as num).toInt(),
        feedbackType: (_n(coaching, 'feedback_type', 'suggestion') as String),
        feedback: _cleanAiText((_n(coaching, 'feedback', '-') as String)),
        betterPhrasing:
            (_n(coaching, 'better_phrasing', '') as String?)?.trim().isEmpty ?? true ? null : (_n(coaching, 'better_phrasing', '') as String),
      ),
    );
  }
}

class _RoleplayCharacterResponse {
  final String targetLang;
  final String transliteration;
  final String english;
  final String emotion;
  final String? action;
  const _RoleplayCharacterResponse({
    required this.targetLang,
    required this.transliteration,
    required this.english,
    required this.emotion,
    required this.action,
  });
}

class _RoleplayCoaching {
  final int userAccuracy;
  final String feedbackType;
  final String feedback;
  final String? betterPhrasing;
  const _RoleplayCoaching({
    required this.userAccuracy,
    required this.feedbackType,
    required this.feedback,
    required this.betterPhrasing,
  });
}

class _RoleplayTurn {
  final String? userText;
  final _RoleplayPayload? ai;
  const _RoleplayTurn._({this.userText, this.ai});
  factory _RoleplayTurn.user(String text) => _RoleplayTurn._(userText: text);
  factory _RoleplayTurn.ai(_RoleplayPayload ai) => _RoleplayTurn._(ai: ai);
}

class _ConversationPayload {
  final String message;
  final _ConversationCorrection correction;
  final List<String> suggestedReplies;
  final List<_ConversationVocab> newVocab;
  const _ConversationPayload({
    required this.message,
    required this.correction,
    required this.suggestedReplies,
    required this.newVocab,
  });
  factory _ConversationPayload.fromJson(Map<String, dynamic> json, String fallback) {
    final c = (_n(json, 'correction', const {}) as Map).cast<String, dynamic>();
    final replies = (_n(json, 'suggested_replies', const []) as List).map((e) => e.toString()).toList();
    final vocabRaw = (_n(json, 'new_vocab', const []) as List)
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    return _ConversationPayload(
      message: _cleanAiText((_n(json, 'message', fallback) as String), fallback: _cleanAiText(fallback)),
      correction: _ConversationCorrection(
        hasCorrection: (_n(c, 'has_correction', false) as bool?) ?? false,
        wasCorrect: (_n(c, 'was_correct', true) as bool?) ?? true,
        correction: (_n(c, 'correction', '') as String?)?.trim().isEmpty ?? true ? null : (_n(c, 'correction', '') as String),
        note: _cleanAiText((_n(c, 'note', '-') as String)),
      ),
      suggestedReplies: replies.map((e) => _cleanAiText(e, fallback: '')).where((e) => e.isNotEmpty).toList(),
      newVocab: vocabRaw
          .map((e) => _ConversationVocab(word: (_n(e, 'word', '') as String), meaning: (_n(e, 'meaning', '') as String)))
          .where((e) => e.word.trim().isNotEmpty)
          .toList(),
    );
  }
}

class _ConversationCorrection {
  final bool hasCorrection;
  final bool wasCorrect;
  final String? correction;
  final String note;
  const _ConversationCorrection({
    required this.hasCorrection,
    required this.wasCorrect,
    required this.correction,
    required this.note,
  });
}

class _ConversationVocab {
  final String word;
  final String meaning;
  const _ConversationVocab({required this.word, required this.meaning});
}

class _ConversationTurn {
  final String? userText;
  final _ConversationPayload? ai;
  const _ConversationTurn._({this.userText, this.ai});
  factory _ConversationTurn.user(String text) => _ConversationTurn._(userText: text);
  factory _ConversationTurn.ai(_ConversationPayload ai) => _ConversationTurn._(ai: ai);
}

class _VocabPayload {
  final String word;
  final String pronunciation;
  final String partOfSpeech;
  final String english;
  final _VocabExample example;
  final String memoryPeg;
  final String? culturalNote;
  final List<_VocabRelatedWord> relatedWords;
  final String difficulty;
  const _VocabPayload({
    required this.word,
    required this.pronunciation,
    required this.partOfSpeech,
    required this.english,
    required this.example,
    required this.memoryPeg,
    required this.culturalNote,
    required this.relatedWords,
    required this.difficulty,
  });
  factory _VocabPayload.fromJson(Map<String, dynamic> json, String fallback) {
    final ex = (_n(json, 'example', const {}) as Map).cast<String, dynamic>();
    final relatedRaw = (_n(json, 'related_words', const []) as List)
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    return _VocabPayload(
      word: _cleanAiText((_n(json, 'word', fallback) as String), fallback: 'New word'),
      pronunciation: _cleanAiText((_n(json, 'pronunciation', '-') as String)),
      partOfSpeech: _cleanAiText((_n(json, 'part_of_speech', 'word') as String), fallback: 'word'),
      english: _cleanAiText((_n(json, 'english', '-') as String)),
      example: _VocabExample(
        target: _cleanAiText((_n(ex, 'target', '-') as String)),
        english: _cleanAiText((_n(ex, 'english', '-') as String)),
      ),
      memoryPeg: _cleanAiText((_n(json, 'memory_peg', '-') as String)),
      culturalNote: (_n(json, 'cultural_note', '') as String?)?.trim().isEmpty ?? true ? null : (_n(json, 'cultural_note', '') as String),
      relatedWords: relatedRaw
          .map((e) => _VocabRelatedWord(word: (_n(e, 'word', '') as String), relationship: (_n(e, 'relationship', '') as String)))
          .where((e) => e.word.trim().isNotEmpty)
          .toList(),
      difficulty: _cleanAiText((_n(json, 'difficulty', 'beginner') as String), fallback: 'beginner'),
    );
  }
}

class _VocabExample {
  final String target;
  final String english;
  const _VocabExample({required this.target, required this.english});
}

class _VocabRelatedWord {
  final String word;
  final String relationship;
  const _VocabRelatedWord({required this.word, required this.relationship});
}

class _ReviewPayload {
  final String headlineInsight;
  final List<_ReviewArea> strengths;
  final List<_ReviewGrowthArea> growthAreas;
  final String coachingParagraph;
  final List<_ReviewNextStep> nextSteps;
  final String motivationalClose;
  final int wordsSeen;
  final double accuracy;
  final int streak;
  final int lessonsDone;
  final Map<String, double> skillBars;
  const _ReviewPayload({
    required this.headlineInsight,
    required this.strengths,
    required this.growthAreas,
    required this.coachingParagraph,
    required this.nextSteps,
    required this.motivationalClose,
    required this.wordsSeen,
    required this.accuracy,
    required this.streak,
    required this.lessonsDone,
    required this.skillBars,
  });
  factory _ReviewPayload.fromJson(
    Map<String, dynamic> json,
    String fallback, {
    required int wordsSeen,
    required double accuracy,
    required int streak,
    required int lessonsDone,
  }) {
    final strengthsRaw = (_n(json, 'strengths', const []) as List)
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    final growthRaw = (_n(json, 'growth_areas', const []) as List)
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    final nextRaw = (_n(json, 'next_steps', const []) as List)
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    return _ReviewPayload(
      headlineInsight: (_n(json, 'headline_insight', fallback) as String),
      strengths: strengthsRaw
          .map((e) => _ReviewArea(area: (_n(e, 'area', '') as String), note: (_n(e, 'note', '') as String)))
          .where((e) => e.area.isNotEmpty)
          .toList(),
      growthAreas: growthRaw
          .map(
            (e) => _ReviewGrowthArea(
              area: (_n(e, 'area', '') as String),
              note: (_n(e, 'note', '') as String),
              quickWin: (_n(e, 'quick_win', '') as String),
            ),
          )
          .where((e) => e.area.isNotEmpty)
          .toList(),
      coachingParagraph: (_n(json, 'coaching_paragraph', '-') as String),
      nextSteps: nextRaw
          .map(
            (e) => _ReviewNextStep(
              type: (_n(e, 'type', '') as String),
              title: (_n(e, 'title', '') as String),
              why: (_n(e, 'why', '') as String),
            ),
          )
          .where((e) => e.title.isNotEmpty)
          .toList(),
      motivationalClose: (_n(json, 'motivational_close', '-') as String),
      wordsSeen: wordsSeen,
      accuracy: accuracy,
      streak: streak,
      lessonsDone: lessonsDone,
      skillBars: {
        'Vocabulary': ((accuracy / 100) + 0.05).clamp(0, 1).toDouble(),
        'Grammar': ((accuracy / 100) - 0.07).clamp(0, 1).toDouble(),
        'Pronunciation': ((accuracy / 100) - 0.12).clamp(0, 1).toDouble(),
        'Conversation': ((accuracy / 100) + 0.02).clamp(0, 1).toDouble(),
      },
    );
  }
}

class _ReviewArea {
  final String area;
  final String note;
  const _ReviewArea({required this.area, required this.note});
}

class _ReviewGrowthArea {
  final String area;
  final String note;
  final String quickWin;
  const _ReviewGrowthArea({required this.area, required this.note, required this.quickWin});
}

class _ReviewNextStep {
  final String type;
  final String title;
  final String why;
  const _ReviewNextStep({required this.type, required this.title, required this.why});
}

TranslationEntry _toHistoryEntry({
  required String input,
  required _TranslationPayload payload,
  required String sourceLanguage,
  required String targetLanguage,
}) {
  return TranslationEntry(
    id: const uuid.Uuid().v4(),
    sourceText: input,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
    primaryTranslation: payload.primary,
    alternatives: payload.alternatives
        .map((a) => TranslationAlternative(translation: a.text, context: a.note.isEmpty ? null : a.note))
        .toList(),
    timestamp: DateTime.now(),
  );
}

dynamic _buildTutorSessionResult({
  required String language,
  required String answer,
  required _TutorFeedbackPayload verdict,
  required String concept,
}) {
  return TutorSessionResult(
    sessionId: 'polie_tutor_${DateTime.now().millisecondsSinceEpoch}',
    language: language,
    cefrLevel: 'A1',
    interactions: [
      TutorInteraction(
        type: 'exercise',
        content: concept,
        userResponse: answer,
        score: verdict.score.toDouble(),
        feedback: verdict.why,
        timestamp: DateTime.now(),
      ),
    ],
    overallScore: verdict.score.toDouble(),
    skillScores: {
      'grammar': verdict.score.toDouble(),
      'vocabulary': verdict.score.toDouble(),
      'comprehension': verdict.score.toDouble(),
      'pronunciation': verdict.score.toDouble(),
    },
    topicsCovered: [concept],
    vocabularyLearned: answer.split(RegExp(r'\s+')).where((w) => w.length > 2).take(8).toList(),
    grammarPoints: [concept],
    timeSpent: 1,
    completedAt: DateTime.now(),
  );
}

dynamic _buildVocabularyWord(_VocabPayload card, String language) {
  return VocabularyWord(
    word: card.word,
    meaning: card.english,
    language: language,
    pronunciation: card.pronunciation,
    partOfSpeech: card.partOfSpeech,
    examples: [
      '${card.example.target} - ${card.example.english}',
    ],
    metadata: {
      'difficulty': card.difficulty,
      if (card.culturalNote != null) 'cultural_note': card.culturalNote,
    },
  );
}

bool _isUnavailableWord(String word) {
  final w = word.trim().toLowerCase();
  return w.isEmpty || w == 'word unavailable' || w == 'unavailable' || w == 'n/a' || w == '-';
}

_VocabPayload _fallbackVocabPayload(String language) {
  final lang = language.trim().toLowerCase();
  if (lang.contains('yoruba')) {
    return const _VocabPayload(
      word: 'ẹ̀kọ́',
      pronunciation: '/ɛ̀.kɔ́/',
      partOfSpeech: 'noun',
      english: 'lesson',
      example: _VocabExample(target: 'Ẹ̀kọ́ yìí dára.', english: 'This lesson is good.'),
      memoryPeg: 'Think of EKO as learning in action.',
      culturalNote: null,
      relatedWords: [
        _VocabRelatedWord(word: 'kọ́', relationship: 'related'),
      ],
      difficulty: 'beginner',
    );
  }
  if (lang.contains('igbo')) {
    return const _VocabPayload(
      word: 'mmụta',
      pronunciation: '/m.mu.ta/',
      partOfSpeech: 'noun',
      english: 'learning',
      example: _VocabExample(target: 'Mmụ̀ta dị mkpa.', english: 'Learning is important.'),
      memoryPeg: 'Learning grows step by step.',
      culturalNote: null,
      relatedWords: [
        _VocabRelatedWord(word: 'mụ', relationship: 'related'),
      ],
      difficulty: 'beginner',
    );
  }
  if (lang.contains('swahili')) {
    return const _VocabPayload(
      word: 'kujifunza',
      pronunciation: '/ku.dʒi.fun.za/',
      partOfSpeech: 'verb',
      english: 'to learn',
      example: _VocabExample(target: 'Ninapenda kujifunza.', english: 'I like to learn.'),
      memoryPeg: 'Learning is a daily journey.',
      culturalNote: null,
      relatedWords: [
        _VocabRelatedWord(word: 'soma', relationship: 'related'),
      ],
      difficulty: 'beginner',
    );
  }
  return const _VocabPayload(
    word: 'learning',
    pronunciation: '/lɜːrnɪŋ/',
    partOfSpeech: 'noun',
    english: 'learning',
    example: _VocabExample(target: 'Learning opens opportunities.', english: 'Learning opens opportunities.'),
    memoryPeg: 'Keep one new word every day.',
    culturalNote: null,
    relatedWords: [
      _VocabRelatedWord(word: 'study', relationship: 'related'),
    ],
    difficulty: 'beginner',
  );
}
