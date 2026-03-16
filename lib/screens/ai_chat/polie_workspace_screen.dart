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

    final roleplayDifficulty = useState<String>('bilingual');
    final roleplayScene = useState<String>(normalizeInitialRoleplayScene(initialRoleplayScene));
    final roleplayMessages = useState<List<_RoleplayTurn>>([]);

    final conversationMessages = useState<List<_ConversationTurn>>([]);
    final languageRatio = useState<double>(0);

    final vocabCard = useState<_VocabPayload?>(null);
    final vocabReveal = useState<bool>(false);
    final vocabDeckCount = useState<int>(10);
    final vocabSetName = useState<String>('Core Daily Words');
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
          translationOutput.value = _TranslationPayload.fromJson(json, rawFallback: modeResponse.value);
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

    Future<void> loadTutorLesson() async {
      isBusy.value = true;
      tutorFeedback.value = null;
      try {
        final difficultyGuide = switch (tutorDifficulty.value) {
          'beginner' => 'Focus on simple vocabulary, basic greetings, common phrases. Include heavy transliteration. Keep explanations simple and encouraging.',
          'intermediate' => 'Focus on grammar concepts, sentence construction, cultural context. Include moderate transliteration. Introduce idiomatic usage.',
          'advanced' => 'Focus on idiomatic expressions, literary devices, nuanced usage, proverbs. Minimal transliteration. Challenge the learner.',
          _ => '',
        };
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
Make the card intelligent, informative, and culturally rich.
''',
        );
        if (json != null) tutorLesson.value = _TutorLessonPayload.fromJson(json, modeResponse.value);
      } catch (e) {
        modeError.value = 'Failed to load tutor card: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
      } finally {
        isBusy.value = false;
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
      conversationMessages.value = [...conversationMessages.value, _ConversationTurn.user(text)];
      if (prefilledText == null) conversationInput.clear();
      isBusy.value = true;
      try {
        Map<String, dynamic>? json = await askForJson(
          '''
Return STRICT JSON only. Do NOT wrap in markdown. Do NOT include text outside the JSON.
{
 "message":"Your natural reply in a mix of $targetLanguage and English. 2-4 sentences. Use the target language naturally.",
 "correction":{"has_correction":false,"was_correct":true,"correction":"corrected version or empty","note":"explanation"},
 "suggested_replies":["reply option 1 in $targetLanguage","reply option 2"],
 "new_vocab":[{"word":"new word","meaning":"meaning"}]
}

You are Polie, a friendly language tutor. Have a natural conversation.
Target language: $targetLanguage
User message: "$text"
Respond conversationally. If the user made grammar mistakes in $targetLanguage, set has_correction to true and provide the correction.
''',
        );
        if (json != null) {
          final msg = _cleanAiText((json['message'] ?? '').toString());
          if (_looksTruncated(msg)) {
            final continuation = await askForJson(
              '''
Return STRICT JSON only:
{"message":"single completed conversational message","correction":{"has_correction":false,"was_correct":true,"correction":"","note":"short note"},"suggested_replies":["reply 1","reply 2"],"new_vocab":[]}

Continue and COMPLETE the previous response in natural style for $targetLanguage.
User message: "$text"
''',
            );
            if (continuation != null && !_looksTruncated(_cleanAiText((continuation['message'] ?? '').toString()))) {
              json = continuation;
            }
          }
        }
        if (json != null) {
          final payload = _ConversationPayload.fromJson(json, modeResponse.value);
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
''',
        );
        if (json != null) {
          vocabCard.value = _VocabPayload.fromJson(json, modeResponse.value);
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
          'Polie • $targetLanguage',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: modeTheme.title,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
                // tutor
                tutorLesson: tutorLesson.value,
                tutorFeedback: tutorFeedback.value,
                tutorDifficulty: tutorDifficulty,
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
                // vocab
                vocabCard: vocabCard.value,
                vocabReveal: vocabReveal,
                vocabSetName: vocabSetName,
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
    required _TutorLessonPayload? tutorLesson,
    required _TutorFeedbackPayload? tutorFeedback,
    required ValueNotifier<String> tutorDifficulty,
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
    required _VocabPayload? vocabCard,
    required ValueNotifier<bool> vocabReveal,
    required ValueNotifier<String> vocabSetName,
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
            padding: const EdgeInsets.all(10),
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
      PolieMode.translation: 'Translate text between English and your target language with tone options.',
      PolieMode.tutor: 'Get bite-sized grammar and vocabulary lessons with practice questions.',
      PolieMode.roleplay: 'Practice real conversations in immersive scenarios with AI characters.',
      PolieMode.conversation: 'Have a freeform conversation to build fluency naturally.',
      PolieMode.vocab: 'Learn and review vocabulary with spaced repetition flashcards.',
      PolieMode.review: 'See your learning stats and get personalized review suggestions.',
    };

    const modeIcons = <PolieMode, String>{
      PolieMode.translation: '\u21C4',
      PolieMode.tutor: '\uD83D\uDCD6',
      PolieMode.roleplay: '\uD83C\uDFAD',
      PolieMode.conversation: '\uD83D\uDCAC',
      PolieMode.vocab: '\u2726',
      PolieMode.review: '\uD83D\uDCCA',
    };

    final intro = introDismissed.contains(mode.name)
        ? const SizedBox.shrink()
        : Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
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
      return SingleChildScrollView(
        key: key,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            error,
            intro,
            Row(
              children: [
                Expanded(
                  child: _chipToggle(
                    label: 'Auto Translate',
                    selected: autoTranslate.value,
                    onTap: () => autoTranslate.value = !autoTranslate.value,
                    color: theme.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: translationTone.value,
                    decoration: _inputDecoration(theme, 'Tone'),
                    items: const ['formal', 'casual', 'poetic', 'literal']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => translationTone.value = v ?? 'formal',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final split = constraints.maxWidth > 820;
                final inputPanel = card(
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Source ($sourceLanguage)', style: bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: translationInput,
                          maxLines: 8,
                          decoration: _inputDecoration(theme, 'Type text to translate'),
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, rowConstraints) {
                            final compact = rowConstraints.maxWidth < 390;
                            final wordCount = translationInput.text
                                .trim()
                                .split(RegExp(r'\s+'))
                                .where((e) => e.isNotEmpty)
                                .length;
                            final counter = compact
                                ? Text(
                                    '${translationInput.text.length} chars • $wordCount words',
                                    style: bodyStyle,
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${translationInput.text.length} chars', style: bodyStyle),
                                      const SizedBox(width: 10),
                                      Text('$wordCount words', style: bodyStyle),
                                    ],
                                  );
                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  counter,
                                  const SizedBox(height: 8),
                                  FilledButton(
                                    onPressed: isBusy ? null : () => onRunTranslation(translationInput.text),
                                    style: FilledButton.styleFrom(backgroundColor: theme.accent),
                                    child: Text(isBusy ? 'Translating...' : 'Translate'),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                counter,
                                const Spacer(),
                                FilledButton(
                                  onPressed: isBusy ? null : () => onRunTranslation(translationInput.text),
                                  style: FilledButton.styleFrom(backgroundColor: theme.accent),
                                  child: Text(isBusy ? 'Translating...' : 'Translate'),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
                final outputPanel = card(
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Output ($targetLanguage)', style: bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Text(
                          translationOutput?.primary ?? 'Translation appears here...',
                          style: GoogleFonts.jetBrainsMono(
                            color: theme.title,
                            fontSize: 18,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if ((translationOutput?.culturalNote ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4822A).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('Cultural Context • ${translationOutput!.culturalNote}', style: bodyStyle),
                          ),
                        const SizedBox(height: 10),
                        Text('Tone achieved: ${translationOutput?.toneAchieved ?? '-'}', style: bodyStyle),
                      ],
                    ),
                  ),
                );
                if (split) {
                  return Row(
                    children: [
                      Expanded(child: inputPanel),
                      const SizedBox(width: 10),
                      Expanded(child: outputPanel),
                    ],
                  );
                }
                return Column(
                  children: [
                    inputPanel,
                    const SizedBox(height: 10),
                    outputPanel,
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            card(
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => translationTrayOpen.value = !translationTrayOpen.value,
                      child: Row(
                        children: [
                          Text('Alternatives & Notes', style: bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Icon(translationTrayOpen.value ? Icons.expand_less : Icons.expand_more, color: theme.title),
                        ],
                      ),
                    ),
                    if (translationTrayOpen.value) ...[
                      const SizedBox(height: 8),
                      ...alternatives.take(3).map(
                            (alt) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('• ${alt.text} — ${alt.note}', style: bodyStyle),
                            ),
                          ),
                      if (alternatives.isEmpty) Text('No alternatives yet.', style: bodyStyle),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            card(
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('History (last 20)', style: bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: _inputDecoration(theme, 'Search history'),
                            onChanged: (v) => translationHistoryQuery.value = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(onPressed: onSearchHistory, icon: const Icon(Icons.search_rounded)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...translationHistory.take(5).map((item) {
                      final source = item.sourceText?.toString() ?? '';
                      final translated = item.primaryTranslation?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('$source  →  $translated', style: monoStyle),
                      );
                    }),
                    if (translationHistory.isEmpty) Text('No translation history yet.', style: bodyStyle),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (mode == PolieMode.tutor) {
      return SingleChildScrollView(
        key: key,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            error,
            intro,
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: tutorDifficulty.value,
                    decoration: _inputDecoration(theme, 'Difficulty'),
                    items: const ['beginner', 'intermediate', 'advanced']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => tutorDifficulty.value = v ?? 'beginner',
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
            const SizedBox(height: 10),
            card(
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tutorLesson?.concept ?? 'Tutor card is loading...', style: GoogleFonts.playfairDisplay(color: theme.title, fontSize: 24)),
                    const SizedBox(height: 8),
                    Text(tutorLesson?.explanation ?? '', style: bodyStyle),
                    const SizedBox(height: 12),
                    card(
                      color: theme.background.withOpacity(0.45),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tutorLesson?.example.targetLang ?? '-', style: bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                            Text(tutorLesson?.example.transliteration ?? '-', style: monoStyle),
                            Text(tutorLesson?.example.english ?? '-', style: bodyStyle),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Memory tip: ${tutorLesson?.memoryTip ?? '-'}', style: bodyStyle),
                    if ((tutorLesson?.watchOut ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFC4663A)),
                            const SizedBox(width: 4),
                            Expanded(child: Text('Watch out: ${tutorLesson!.watchOut}', style: bodyStyle.copyWith(color: const Color(0xFFC4663A)))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (tutorLesson?.practiceQuestion != null) ...[
              const SizedBox(height: 10),
              card(
                color: const Color(0xFFD4822A).withOpacity(0.08),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Practice Question', style: bodyStyle.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFFD4822A))),
                      const SizedBox(height: 6),
                      Text(tutorLesson!.practiceQuestion!, style: bodyStyle.copyWith(fontSize: 15)),
                      if (tutorLesson.practiceHint != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Hint: ${tutorLesson.practiceHint}', style: bodyStyle.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: tutorInput,
              minLines: 2,
              maxLines: 4,
              decoration: _inputDecoration(theme, tutorLesson?.practiceQuestion != null ? 'Type your answer to the practice question' : 'Type your answer'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: isBusy || tutorLesson == null ? null : onCheckTutorAnswer,
              style: FilledButton.styleFrom(backgroundColor: theme.accent),
              child: Text(isBusy ? 'Checking...' : 'Check Answer'),
            ),
            if (tutorFeedback != null) ...[
              const SizedBox(height: 10),
              card(
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tutorFeedback.verdict.toUpperCase()} • ${tutorFeedback.score}',
                        style: bodyStyle.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(tutorFeedback.encouragement, style: bodyStyle),
                      Text('Correction: ${tutorFeedback.correction}', style: bodyStyle),
                      Text('Why: ${tutorFeedback.why}', style: bodyStyle),
                      const SizedBox(height: 8),
                      Text('Next step: ${tutorFeedback.nextStep}', style: bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                      Text('Drill: ${tutorFeedback.drill}', style: bodyStyle),
                      if ((tutorFeedback.nativeSpeakerNote ?? '').isNotEmpty) Text('Native note: ${tutorFeedback.nativeSpeakerNote}', style: bodyStyle),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (mode == PolieMode.roleplay) {
      return Container(
        key: key,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0A04), Color(0xFF1A130C)],
          ),
        ),
        child: Column(
          children: [
            error,
            intro,
            card(
              color: Colors.white.withOpacity(0.06),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: roleplayScene.value,
                            dropdownColor: const Color(0xFF2A1F14),
                            style: const TextStyle(color: Color(0xFFFAF3E0), fontSize: 14),
                            decoration: _inputDecoration(theme, 'Scene'),
                            items: const ['Market', 'Restaurant', 'Meeting Elder', 'Job Interview', 'Family Dinner']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: Color(0xFFFAF3E0)))))
                                .toList(),
                            onChanged: (v) => roleplayScene.value = v ?? 'Market',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: roleplayDifficulty.value,
                            dropdownColor: const Color(0xFF2A1F14),
                            style: const TextStyle(color: Color(0xFFFAF3E0), fontSize: 14),
                            decoration: _inputDecoration(theme, 'Difficulty'),
                            items: const ['bilingual', 'hint', 'immersion']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: Color(0xFFFAF3E0)))))
                                .toList(),
                            onChanged: (v) => roleplayDifficulty.value = v ?? 'bilingual',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2D1B0E), Color(0xFFC4663A)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${roleplayScene.value} • Curtain rise',
                        style: GoogleFonts.playfairDisplay(color: const Color(0xFFFAF3E0), fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: card(
                color: Colors.white.withOpacity(0.06),
                ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: roleplayMessages.length,
                  itemBuilder: (context, index) {
                    final item = roleplayMessages[index];
                    if (item.userText != null) {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF20160E),
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
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
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
                FilledButton(
                  onPressed: isBusy ? null : onSendRoleplay,
                  style: FilledButton.styleFrom(backgroundColor: theme.accent),
                  child: Text(isBusy ? '...' : 'Send'),
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
            error,
            intro,
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: card(
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const CircleAvatar(backgroundColor: Color(0xFFD4822A), child: Icon(Icons.smart_toy_rounded, color: Colors.white)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Polie • online', style: bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      SizedBox(
                        width: 130,
                        child: LinearProgressIndicator(
                          value: languageRatio,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A7C59)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: conversationMessages.length,
                itemBuilder: (context, index) {
                  final item = conversationMessages[index];
                  if (item.userText != null) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ai.message, style: bodyStyle.copyWith(color: const Color(0xFF2D1B0E))),
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
                                        label: Text(reply),
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
                  Expanded(
                    child: TextField(
                      controller: conversationInput,
                      decoration: _inputDecoration(theme, 'Message'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: isBusy ? null : onSendConversation,
                    style: FilledButton.styleFrom(backgroundColor: theme.accent),
                    child: Text(isBusy ? '...' : 'Send'),
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
            error,
            intro,
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: card(
                color: Colors.white.withOpacity(0.06),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(child: Text(vocabSetName.value, style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0)))),
                      Text('Remaining: $vocabDeckCount', style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0))),
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
                    width: 330,
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
                            children: [
                              Text(
                                vocabCard.word,
                                style: GoogleFonts.jetBrainsMono(
                                  color: const Color(0xFFFAF3E0),
                                  fontSize: 42,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(vocabCard.pronunciation, style: bodyStyle.copyWith(color: const Color(0xFFF2C14E))),
                              if (vocabReveal.value) ...[
                                const SizedBox(height: 10),
                                Text(vocabCard.english, style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0))),
                                Text(vocabCard.example.target, style: bodyStyle.copyWith(color: const Color(0xFFFAF3E0))),
                                Text(vocabCard.example.english, style: bodyStyle.copyWith(color: const Color(0xFFD8C9B7))),
                                const SizedBox(height: 8),
                                Text('Memory peg: ${vocabCard.memoryPeg}',
                                    style: bodyStyle.copyWith(color: const Color(0xFFF2C14E))),
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
                      Expanded(child: _srsButton('Again (1m)', Colors.red.shade500, isBusy ? null : () => onScoreSrs('again'))),
                      const SizedBox(width: 6),
                      Expanded(child: _srsButton('Hard (10m)', Colors.orange.shade600, isBusy ? null : () => onScoreSrs('hard'))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _srsButton('Good (1d)', Colors.green.shade600, isBusy ? null : () => onScoreSrs('good'))),
                      const SizedBox(width: 6),
                      Expanded(child: _srsButton('Easy (4d)', Colors.blue.shade600, isBusy ? null : () => onScoreSrs('easy'))),
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          error,
          intro,
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: reviewPeriod.value,
                  decoration: _inputDecoration(theme, 'Period'),
                  items: const ['week', 'month', 'all']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => reviewPeriod.value = v ?? 'week',
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isBusy ? null : onLoadReview,
                style: FilledButton.styleFrom(backgroundColor: theme.accent),
                child: Text(isBusy ? 'Refreshing...' : 'Refresh'),
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
            Row(
              children: [
                Expanded(child: _statCard('Words Seen', '${reviewPayload.wordsSeen}', const Color(0xFFD4822A))),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Accuracy', '${reviewPayload.accuracy.toStringAsFixed(1)}%', const Color(0xFF4A7C59))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _statCard('Streak', '${reviewPayload.streak}', const Color(0xFFC4663A))),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Lessons', '${reviewPayload.lessonsDone}', const Color(0xFF2D1B0E))),
              ],
            ),
            const SizedBox(height: 10),
            card(
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reviewPayload.headlineInsight,
                        style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: theme.title)),
                    const SizedBox(height: 8),
                    Text(reviewPayload.coachingParagraph, style: bodyStyle),
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
                    Text('Skills', style: bodyStyle.copyWith(fontWeight: FontWeight.w800)),
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
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4822A)),
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
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next Steps', style: bodyStyle.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ...reviewPayload.nextSteps.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• ${s.title} (${s.type}) — ${s.why}', style: bodyStyle),
                        )),
                    const SizedBox(height: 6),
                    Text(reviewPayload.motivationalClose, style: bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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

  Widget _chipToggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: selected ? color.withOpacity(0.18) : Colors.transparent,
          border: Border.all(color: selected ? color : color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, color: color),
            const SizedBox(width: 6),
            Text(label),
          ],
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

  Widget _srsButton(String label, Color color, VoidCallback? onTap) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(label, style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color stripe) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, decoration: BoxDecoration(color: stripe, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.nunito(fontSize: 12)),
          Text(value, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
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
  if (RegExp(r"[.!?]['\"]?$").hasMatch(m)) return false;
  return true;
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
      word: _cleanAiText((_n(json, 'word', fallback) as String), fallback: 'Word unavailable'),
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
