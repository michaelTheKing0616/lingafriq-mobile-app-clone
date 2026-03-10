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
import 'package:uuid/uuid.dart' as uuid;

class PolieWorkspaceScreen extends HookConsumerWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final PolieMode initialMode;

  const PolieWorkspaceScreen({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.initialMode,
  });

  static const _modeItems = <_ModeChipItem>[
    _ModeChipItem(mode: PolieMode.translation, icon: '⇄', label: 'Translation'),
    _ModeChipItem(mode: PolieMode.tutor, icon: '📖', label: 'Tutor'),
    _ModeChipItem(mode: PolieMode.roleplay, icon: '🎭', label: 'Roleplay'),
    _ModeChipItem(mode: PolieMode.conversation, icon: '💬', label: 'Conversation'),
    _ModeChipItem(mode: PolieMode.vocab, icon: '✦', label: 'Vocabulary'),
    _ModeChipItem(mode: PolieMode.review, icon: '📊', label: 'Review'),
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
    final roleplayScene = useState<String>('Market');
    final roleplayMessages = useState<List<_RoleplayTurn>>([]);

    final conversationMessages = useState<List<_ConversationTurn>>([]);
    final languageRatio = useState<double>(0);

    final vocabCard = useState<_VocabPayload?>(null);
    final vocabReveal = useState<bool>(false);
    final vocabDeckCount = useState<int>(10);
    final vocabSetName = useState<String>('Core Daily Words');
    final vocabSrsChoice = useState<String?>(null);

    final reviewPayload = useState<_ReviewPayload?>(null);
    final reviewPeriod = useState<String>('week');

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
        final raw = await chat.sendMessage(prompt);
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
      isBusy.value = false;
    }

    Future<void> loadTutorLesson() async {
      isBusy.value = true;
      tutorFeedback.value = null;
      final json = await askForJson(
        '''
Return STRICT JSON only.
{
 "concept":"title",
 "explanation":"2-3 warm sentences",
 "example":{"target_lang":"...","transliteration":"...","english":"..."},
 "memory_tip":"...",
 "watch_out":"...|null"
}

Generate a tutor card for $targetLanguage at ${tutorDifficulty.value} level.
''',
      );
      if (json != null) tutorLesson.value = _TutorLessonPayload.fromJson(json, modeResponse.value);
      isBusy.value = false;
    }

    Future<void> checkTutorAnswer() async {
      final answer = tutorInput.text.trim();
      if (answer.isEmpty || tutorLesson.value == null) return;
      isBusy.value = true;
      final json = await askForJson(
        '''
Return STRICT JSON only.
{
 "verdict":"correct|close|incorrect",
 "score":0,
 "encouragement":"...",
 "correction":"...",
 "why":"...",
 "native_speaker_note":"...|null"
}

Language: $targetLanguage
Concept: ${tutorLesson.value!.concept}
Expected style example: ${tutorLesson.value!.example.targetLang}
User answer: "$answer"
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
      isBusy.value = false;
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
      final json = await askForJson(
        '''
Return STRICT JSON only.
{
 "character_response":{
  "target_lang":"...",
  "transliteration":"...",
  "english":"...",
  "emotion":"curious|warm|impatient|amused|surprised|neutral",
  "action":"...|null"
 },
 "coaching":{
  "user_accuracy":0,
  "feedback_type":"praise|suggestion|correction|encouragement",
  "feedback":"1-2 sentences",
  "better_phrasing":"...|null"
 }
}

Roleplay scene: ${roleplayScene.value}
Difficulty: ${roleplayDifficulty.value}
Target language: $targetLanguage
User line: "$input"
Stay in character.
''',
      );
      if (json != null) {
        roleplayMessages.value = [
          ...roleplayMessages.value,
          _RoleplayTurn.ai(_RoleplayPayload.fromJson(json, modeResponse.value)),
        ];
      }
      isBusy.value = false;
    }

    Future<void> sendConversation() async {
      final text = conversationInput.text.trim();
      if (text.isEmpty) return;
      conversationMessages.value = [...conversationMessages.value, _ConversationTurn.user(text)];
      conversationInput.clear();
      isBusy.value = true;
      final json = await askForJson(
        '''
Return STRICT JSON only.
{
 "message":"Natural reply with **bolded vocab**. 2-4 sentences.",
 "correction":{"has_correction":true,"was_correct":false,"correction":"...","note":"..."},
 "suggested_replies":["...", "..."],
 "new_vocab":[{"word":"...","meaning":"..."}]
}

Target language: $targetLanguage
User message: "$text"
''',
      );
      if (json != null) {
        final payload = _ConversationPayload.fromJson(json, modeResponse.value);
        conversationMessages.value = [...conversationMessages.value, _ConversationTurn.ai(payload)];
        final targetLetters = RegExp(r'[^\x00-\x7F]').hasMatch(text);
        final oldRatio = languageRatio.value;
        languageRatio.value = ((oldRatio * (conversationMessages.value.length - 1)) + (targetLetters ? 1 : 0)) /
            conversationMessages.value.length;
      }
      isBusy.value = false;
    }

    Future<void> loadVocabCard() async {
      isBusy.value = true;
      final json = await askForJson(
        '''
Return STRICT JSON only.
{
 "word":"...",
 "pronunciation":"...",
 "part_of_speech":"...",
 "english":"...",
 "example":{"target":"...","english":"..."},
 "memory_peg":"...",
 "cultural_note":"...|null",
 "related_words":[{"word":"...","relationship":"synonym|antonym|related|derived"}],
 "difficulty":"beginner|intermediate|advanced"
}

Generate one $targetLanguage vocabulary card.
''',
      );
      if (json != null) {
        vocabCard.value = _VocabPayload.fromJson(json, modeResponse.value);
        vocabReveal.value = false;
        vocabDeckCount.value = (vocabDeckCount.value - 1).clamp(0, 999);
      }
      isBusy.value = false;
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
      final stats = await reviewProgress.loadStatistics(targetLanguage);
      final json = await askForJson(
        '''
Return STRICT JSON only.
{
 "headline_insight":"...",
 "strengths":[{"area":"...","note":"..."}],
 "growth_areas":[{"area":"...","note":"...","quick_win":"..."}],
 "coaching_paragraph":"2-3 sentences",
 "next_steps":[{"type":"lesson|scene|vocabulary_review","title":"...","why":"..."}],
 "motivational_close":"..."
}

Review period: ${reviewPeriod.value}
Total reviews: ${stats.totalReviews}
Average accuracy: ${stats.averageAccuracy.toStringAsFixed(1)}
Current streak: ${stats.currentStreak}
''',
      );
      if (json != null) {
        reviewPayload.value = _ReviewPayload.fromJson(
          json,
          modeResponse.value,
          wordsSeen: stats.totalItemsReviewed,
          accuracy: stats.averageAccuracy,
          streak: stats.currentStreak,
          lessonsDone: stats.totalReviews,
        );
      }
      isBusy.value = false;
    }

    useEffect(() {
      setMode(initialMode);
      loadTranslationHistory();
      if (initialMode == PolieMode.tutor) loadTutorLesson();
      if (initialMode == PolieMode.vocab) loadVocabCard();
      if (initialMode == PolieMode.review) loadReview();
      return null;
    }, const []);

    useEffect(() {
      if (!autoTranslate.value) return null;
      final text = translationInput.text.trim();
      translationTimer.value?.cancel();
      if (activeMode.value == PolieMode.translation && text.isNotEmpty) {
        translationTimer.value = Timer(const Duration(milliseconds: 500), () {
          runTranslation(text);
        });
      }
      return () => translationTimer.value?.cancel();
    }, [translationInput.text, autoTranslate.value, activeMode.value, translationTone.value]);

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
            child: _ModeSwitcher(
              mode: activeMode.value,
              items: _modeItems,
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
    required _ModeTheme theme,
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
    required Future<void> Function() onSendConversation,
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
            child: Text(modeError, style: bodyStyle),
          );

    if (mode == PolieMode.translation) {
      final alternatives = translationOutput?.alternatives ?? const <_AltItem>[];
      return SingleChildScrollView(
        key: key,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            error,
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
                        Row(
                          children: [
                            Text('${translationInput.text.length} chars', style: bodyStyle),
                            const SizedBox(width: 10),
                            Text('${translationInput.text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length} words',
                                style: bodyStyle),
                            const Spacer(),
                            FilledButton(
                              onPressed: isBusy ? null : () => onRunTranslation(translationInput.text),
                              style: FilledButton.styleFrom(backgroundColor: theme.accent),
                              child: Text(isBusy ? 'Translating...' : 'Translate'),
                            ),
                          ],
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
                    SizedBox(height: 260, child: inputPanel),
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
                    if ((tutorLesson?.watchOut ?? '').isNotEmpty) Text('Watch out: ${tutorLesson!.watchOut}', style: bodyStyle),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: tutorInput,
              minLines: 2,
              maxLines: 4,
              decoration: _inputDecoration(theme, 'Type your answer'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: isBusy ? null : onCheckTutorAnswer,
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
                            decoration: _inputDecoration(theme, 'Scene'),
                            items: const ['Market', 'Restaurant', 'Meeting Elder', 'Job Interview', 'Family Dinner']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) => roleplayScene.value = v ?? 'Market',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: roleplayDifficulty.value,
                            decoration: _inputDecoration(theme, 'Difficulty'),
                            items: const ['bilingual', 'hint', 'immersion']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
                          if (roleplayDifficulty.value != 'immersion')
                            Text(ai.characterResponse.english, style: bodyStyle.copyWith(color: const Color(0xFFD8C9B7))),
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
                    decoration: _inputDecoration(theme, 'Speak your line...'),
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
                                        onPressed: () {},
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
                      Expanded(child: _srsButton('Again (1m)', Colors.red.shade500, () => onScoreSrs('again'))),
                      const SizedBox(width: 6),
                      Expanded(child: _srsButton('Hard (10m)', Colors.orange.shade600, () => onScoreSrs('hard'))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _srsButton('Good (1d)', Colors.green.shade600, () => onScoreSrs('good'))),
                      const SizedBox(width: 6),
                      Expanded(child: _srsButton('Easy (4d)', Colors.blue.shade600, () => onScoreSrs('easy'))),
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

  InputDecoration _inputDecoration(_ModeTheme theme, String hint) {
    return InputDecoration(
      hintText: hint,
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

  _ModeTheme _themeForMode(PolieMode mode) {
    switch (mode) {
      case PolieMode.translation:
        return const _ModeTheme(
          background: Color(0xFFFAF3E0),
          card: Colors.white,
          title: Color(0xFF2D1B0E),
          body: Color(0xFF3F2A1A),
          border: Color(0xFFD9CBB6),
          accent: Color(0xFFD4822A),
        );
      case PolieMode.tutor:
        return const _ModeTheme(
          background: Color(0xFFFAF3E0),
          card: Colors.white,
          title: Color(0xFF2D1B0E),
          body: Color(0xFF3F2A1A),
          border: Color(0xFFD9CBB6),
          accent: Color(0xFFD4822A),
        );
      case PolieMode.roleplay:
        return const _ModeTheme(
          background: Color(0xFF0F0A04),
          card: Color(0xFF1A130C),
          title: Color(0xFFFAF3E0),
          body: Color(0xFFE8DAC5),
          border: Color(0xFF3A2A1C),
          accent: Color(0xFFC4663A),
        );
      case PolieMode.conversation:
        return const _ModeTheme(
          background: Color(0xFFF5F0E8),
          card: Colors.white,
          title: Color(0xFF2D1B0E),
          body: Color(0xFF3F2A1A),
          border: Color(0xFFE0D5C4),
          accent: Color(0xFFD4822A),
        );
      case PolieMode.vocab:
        return const _ModeTheme(
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
        return const _ModeTheme(
          background: Color(0xFFFAF3E0),
          card: Colors.white,
          title: Color(0xFF2D1B0E),
          body: Color(0xFF3F2A1A),
          border: Color(0xFFD9CBB6),
          accent: Color(0xFFD4822A),
        );
    }
  }

  Widget _srsButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
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

class _ModeSwitcher extends StatelessWidget {
  final PolieMode mode;
  final List<_ModeChipItem> items;
  final ValueChanged<PolieMode> onChanged;

  const _ModeSwitcher({
    required this.mode,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final active = item.mode == mode;
          return Tooltip(
            message: item.label,
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(item.mode);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(horizontal: active ? 14 : 10, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFD4822A).withOpacity(0.16) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: active ? const Color(0xFFD4822A) : const Color(0xFFD4822A).withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Text(item.icon, style: const TextStyle(fontSize: 16)),
                    if (active) ...[
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF7E5CD),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Map<String, dynamic>? _tryParseJson(String raw) {
  try {
    final stripped = raw
        .replaceAll(RegExp(r'^```json', multiLine: true), '')
        .replaceAll(RegExp(r'^```', multiLine: true), '')
        .trim();
    final first = stripped.indexOf('{');
    final last = stripped.lastIndexOf('}');
    if (first >= 0 && last > first) {
      final jsonBody = stripped.substring(first, last + 1);
      final decoded = jsonDecode(jsonBody);
      if (decoded is Map<String, dynamic>) return decoded;
    }
  } catch (_) {}
  return null;
}

dynamic _n(Map<String, dynamic>? map, String key, dynamic fallback) => map?[key] ?? fallback;

class _ModeChipItem {
  final PolieMode mode;
  final String icon;
  final String label;
  const _ModeChipItem({required this.mode, required this.icon, required this.label});
}

class _ModeTheme {
  final Color background;
  final Color card;
  final Color title;
  final Color body;
  final Color border;
  final Color accent;
  const _ModeTheme({
    required this.background,
    required this.card,
    required this.title,
    required this.body,
    required this.border,
    required this.accent,
  });
}

class _AltItem {
  final String text;
  final String note;
  const _AltItem({required this.text, required this.note});
}

class _TranslationPayload {
  final String primary;
  final List<_AltItem> alternatives;
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
      primary: (_n(json, 'primary', '') as String).trim().isNotEmpty ? (_n(json, 'primary', '') as String) : rawFallback,
      alternatives: alternativesRaw
          .map((e) => _AltItem(text: (_n(e, 'text', '') as String), note: (_n(e, 'note', '') as String)))
          .where((e) => e.text.trim().isNotEmpty)
          .toList(),
      culturalNote: (_n(json, 'cultural_note', '') ?? '').toString(),
      toneAchieved: (_n(json, 'tone_achieved', '-') ?? '-').toString(),
    );
  }
}

class _TutorLessonPayload {
  final String concept;
  final String explanation;
  final _TutorExample example;
  final String memoryTip;
  final String? watchOut;
  const _TutorLessonPayload({
    required this.concept,
    required this.explanation,
    required this.example,
    required this.memoryTip,
    required this.watchOut,
  });
  factory _TutorLessonPayload.fromJson(Map<String, dynamic> json, String fallback) {
    final ex = (_n(json, 'example', const {}) as Map).cast<String, dynamic>();
    return _TutorLessonPayload(
      concept: (_n(json, 'concept', 'Lesson') as String),
      explanation: (_n(json, 'explanation', fallback) as String),
      example: _TutorExample(
        targetLang: (_n(ex, 'target_lang', '-') as String),
        transliteration: (_n(ex, 'transliteration', '-') as String),
        english: (_n(ex, 'english', '-') as String),
      ),
      memoryTip: (_n(json, 'memory_tip', '-') as String),
      watchOut: (_n(json, 'watch_out', '') as String?)?.trim().isEmpty ?? true ? null : (_n(json, 'watch_out', '') as String),
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
  const _TutorFeedbackPayload({
    required this.verdict,
    required this.score,
    required this.encouragement,
    required this.correction,
    required this.why,
    required this.nativeSpeakerNote,
  });
  factory _TutorFeedbackPayload.fromJson(Map<String, dynamic> json, String fallback) {
    return _TutorFeedbackPayload(
      verdict: (_n(json, 'verdict', 'close') as String),
      score: (_n(json, 'score', 50) as num).toInt(),
      encouragement: (_n(json, 'encouragement', fallback) as String),
      correction: (_n(json, 'correction', '-') as String),
      why: (_n(json, 'why', '-') as String),
      nativeSpeakerNote: (_n(json, 'native_speaker_note', '') as String?)?.trim().isEmpty ?? true
          ? null
          : (_n(json, 'native_speaker_note', '') as String),
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
        targetLang: (_n(c, 'target_lang', fallback) as String),
        transliteration: (_n(c, 'transliteration', '-') as String),
        english: (_n(c, 'english', '-') as String),
        emotion: (_n(c, 'emotion', 'neutral') as String),
        action: (_n(c, 'action', '') as String?)?.trim().isEmpty ?? true ? null : (_n(c, 'action', '') as String),
      ),
      coaching: _RoleplayCoaching(
        userAccuracy: (_n(coaching, 'user_accuracy', 50) as num).toInt(),
        feedbackType: (_n(coaching, 'feedback_type', 'suggestion') as String),
        feedback: (_n(coaching, 'feedback', '-') as String),
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
      message: (_n(json, 'message', fallback) as String),
      correction: _ConversationCorrection(
        hasCorrection: (_n(c, 'has_correction', false) as bool?) ?? false,
        wasCorrect: (_n(c, 'was_correct', true) as bool?) ?? true,
        correction: (_n(c, 'correction', '') as String?)?.trim().isEmpty ?? true ? null : (_n(c, 'correction', '') as String),
        note: (_n(c, 'note', '-') as String),
      ),
      suggestedReplies: replies,
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
      word: (_n(json, 'word', fallback) as String),
      pronunciation: (_n(json, 'pronunciation', '-') as String),
      partOfSpeech: (_n(json, 'part_of_speech', 'word') as String),
      english: (_n(json, 'english', '-') as String),
      example: _VocabExample(
        target: (_n(ex, 'target', '-') as String),
        english: (_n(ex, 'english', '-') as String),
      ),
      memoryPeg: (_n(json, 'memory_peg', '-') as String),
      culturalNote: (_n(json, 'cultural_note', '') as String?)?.trim().isEmpty ?? true ? null : (_n(json, 'cultural_note', '') as String),
      relatedWords: relatedRaw
          .map((e) => _VocabRelatedWord(word: (_n(e, 'word', '') as String), relationship: (_n(e, 'relationship', '') as String)))
          .where((e) => e.word.trim().isNotEmpty)
          .toList(),
      difficulty: (_n(json, 'difficulty', 'beginner') as String),
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
