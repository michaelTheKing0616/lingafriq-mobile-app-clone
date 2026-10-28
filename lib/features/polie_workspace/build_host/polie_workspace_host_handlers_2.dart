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

import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_state.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_handlers_1.dart';

mixin PolieWorkspaceHostHandlers2 on PolieWorkspaceHostState, PolieWorkspaceHostHandlers1 {
Future<void> loadTutorLesson() async {
  if (this.tutorAutoLoadInFlight.value) return;
  this.tutorAutoLoadInFlight.value = true;
  this.isBusy.value = true;
  this.tutorFeedback.value = null;
  this.tutorFlipped.value = false;
  try {
    final difficultyGuide = switch (this.tutorDifficulty.value) {
      'beginner' =>
        'Focus on simple vocabulary, basic greetings, common phrases. Include heavy transliteration. Keep explanations simple and encouraging.',
      'intermediate' =>
        'Focus on grammar concepts, sentence construction, cultural context. Include moderate transliteration. Introduce idiomatic usage.',
      'advanced' =>
        'Focus on idiomatic expressions, literary devices, nuanced usage, proverbs. Minimal transliteration. Challenge the learner.',
      _ => '',
    };
    final seenConceptList = this.tutorSeenConcepts.value.take(20).join(', ');
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

Generate a tutor card for $targetLanguage at ${this.tutorDifficulty.value} level.
$difficultyGuide
$noveltyConstraint
Use a fresh concept each time. Nonce: $nonce
Make the card intelligent, informative, and culturally rich.
''');
    if (json != null) {
      final parsed = TutorLessonPayload.fromJson(json, this.modeResponse.value);
      final hasCoreFields =
          parsed.concept.trim().isNotEmpty &&
          parsed.explanation.trim().isNotEmpty;
      if (hasCoreFields) {
        final conceptKey = parsed.concept.trim().toLowerCase();
        if (this.tutorSeenConcepts.value.contains(conceptKey)) {
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
Generate a COMPLETE and DIFFERENT tutor card concept for $targetLanguage at ${this.tutorDifficulty.value} level.
Do not use this concept again: ${parsed.concept}
Do not use any of these prior concepts: ${this.tutorSeenConcepts.value.take(20).join(', ')}
Nonce: ${DateTime.now().microsecondsSinceEpoch}
''');
          if (retryJson != null) {
            final retryParsed = TutorLessonPayload.fromJson(
              retryJson,
              this.modeResponse.value,
            );
            this.tutorSeenConcepts.value = {
              ...tutorSeenConcepts.value,
              retryParsed.concept.trim().toLowerCase(),
            };
            await PolieTutorSavedCardsService.addSeenConceptKey(
              targetLanguage: targetLanguage,
              difficulty: this.tutorDifficulty.value,
              conceptKey: retryParsed.concept.trim().toLowerCase(),
            );
            this.tutorLesson.value = retryParsed;
            await refreshTutorSavedCards();
          } else {
            this.tutorLesson.value = parsed;
            await refreshTutorSavedCards();
          }
          return;
        }
        this.tutorSeenConcepts.value = {...tutorSeenConcepts.value, conceptKey};
        await PolieTutorSavedCardsService.addSeenConceptKey(
          targetLanguage: targetLanguage,
          difficulty: this.tutorDifficulty.value,
          conceptKey: conceptKey,
        );
        this.tutorLesson.value = parsed;
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
Generate a complete tutor card for $targetLanguage at ${this.tutorDifficulty.value} level.
''');
        if (retryJson != null) {
          this.tutorLesson.value = TutorLessonPayload.fromJson(
            retryJson,
            this.modeResponse.value,
          );
          final ck = this.tutorLesson.value!.concept.trim().toLowerCase();
          if (ck.isNotEmpty) {
            this.tutorSeenConcepts.value = {...tutorSeenConcepts.value, ck};
            await PolieTutorSavedCardsService.addSeenConceptKey(
              targetLanguage: targetLanguage,
              difficulty: this.tutorDifficulty.value,
              conceptKey: ck,
            );
          }
          await refreshTutorSavedCards();
        }
      }
    }
  } catch (e) {
    this.modeError.value =
        'Failed to load tutor card: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
  } finally {
    this.isBusy.value = false;
    this.tutorAutoLoadInFlight.value = false;
  }
}


Future<void> saveCurrentTutorCard() async {
  final lesson = this.tutorLesson.value;
  if (lesson == null) return;
  final conceptKey = lesson.concept.trim().toLowerCase();
  if (conceptKey.isEmpty) return;
  await PolieTutorSavedCardsService.saveCard(
    PolieTutorSavedCard(
      targetLanguage: targetLanguage,
      difficulty: this.tutorDifficulty.value,
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
  final l10n = AppLocalizations.of(this.context)!;
  await refreshTutorSavedCards();
  await showModalBottomSheet<void>(
    context: this.context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final items = this.tutorSavedCards.value;
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
                            this.tutorLesson.value = TutorLessonPayload(
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
                            this.tutorFeedback.value = null;
                            this.tutorFlipped.value = false;
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
  final answer = this.tutorInput.text.trim();
  if (answer.isEmpty || this.tutorLesson.value == null) return;
  this.isBusy.value = true;
  try {
    final questionCtx = this.tutorLesson.value!.practiceQuestion != null
        ? 'Practice question: ${this.tutorLesson.value!.practiceQuestion}'
        : 'Expected style example: ${this.tutorLesson.value!.example.targetLang}';
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
Concept: ${this.tutorLesson.value!.concept}
$questionCtx
User answer: "$answer"
Evaluate pedagogically:
- Give complete correction, not partial
- Explain why in plain learner-friendly language
- Give one next action and one micro drill
''');
    if (json != null) {
      this.tutorFeedback.value = TutorFeedbackPayload.fromJson(
        json,
        this.modeResponse.value,
      );
      await this.tutorProgress.recordSession(
        polieBuildTutorSessionResult(
          language: targetLanguage,
          answer: answer,
          verdict: this.tutorFeedback.value!,
          concept: this.tutorLesson.value!.concept,
        ),
      );
    }
  } catch (e) {
    this.modeError.value =
        'Failed to check answer: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
  } finally {
    this.isBusy.value = false;
  }
}


Future<void> sendRoleplayTurn() async {
  final input = this.roleplayInput.text.trim();
  if (input.isEmpty) return;
  this.roleplayMessages.value = [
    ...roleplayMessages.value,
    RoleplayTurn.user(input),
  ];
  this.roleplayInput.clear();
  this.isBusy.value = true;
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

Roleplay scene: ${this.roleplayScene.value}
Difficulty: ${this.roleplayDifficulty.value}
Target language: $targetLanguage
User line: "$input"
Stay in character. Respond naturally for the scene.
''');
    if (json != null) {
      this.roleplayMessages.value = [
        ...roleplayMessages.value,
        RoleplayTurn.ai(
          RoleplayPayload.fromJson(json, this.modeResponse.value),
        ),
      ];
    } else {
      this.roleplayMessages.value = [
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
    this.modeError.value =
        'Roleplay error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
  } finally {
    this.isBusy.value = false;
  }
}


Future<void> toggleConversationVoiceInput() async {
  this.voiceErrorMessage.value = null;
  if (this.voiceListening.value) {
    await this.voiceService.stop();
    this.voiceListening.value = false;
    return;
  }
  try {
    // Subscribe before starting so we don't miss the first transcript.
    late StreamSubscription<PolieVoiceTranscript> sub;
    sub = this.voiceService.transcripts.listen(
      (t) {
        this.conversationInput.text = t.text;
        this.conversationInput.selection = TextSelection.fromPosition(
          TextPosition(offset: this.conversationInput.text.length),
        );
        if (t.isFinal) {
          this.voiceListening.value = false;
          sub.cancel();
          if (t.text.trim().isNotEmpty) {
            // Auto-send after [sendConversation] is defined (see effect below).
            this.pendingVoiceConversationText.value = t.text.trim();
          }
        }
      },
      onError: (e) {
        this.voiceErrorMessage.value = e.toString();
        this.voiceListening.value = false;
        sub.cancel();
      },
      onDone: () {
        sub.cancel();
      },
    );
    this.voiceListening.value = true;
    await this.voiceService.start(language: targetLanguage);
  } catch (e) {
    this.voiceErrorMessage.value = e.toString();
    this.voiceListening.value = false;
  }
}


}
