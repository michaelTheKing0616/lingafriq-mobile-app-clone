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
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_handlers_2.dart';

mixin PolieWorkspaceHostHandlers3 on PolieWorkspaceHostState, PolieWorkspaceHostHandlers1, PolieWorkspaceHostHandlers2 {
Future<void> loadVocabCard() async {
  this.isBusy.value = true;
  try {
    final exclusionClause = this.vocabShownWords.value.isEmpty
        ? ''
        : '\nDo NOT repeat these previously shown words: ${this.vocabShownWords.value.take(30).join(', ')}';
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
Category focus: ${this.vocabSetName.value}
Difficulty preference: ${this.vocabDifficultyTarget.value}
If difficulty preference is "mixed", rotate levels naturally over successive cards.
''');
    if (json != null) {
      var parsed = VocabPayload.fromJson(json, this.modeResponse.value);
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
          parsed = VocabPayload.fromJson(retryJson, this.modeResponse.value);
        }
      }
      if (isUnavailableWord(parsed.word)) {
        parsed = fallbackVocabPayload(targetLanguage);
      }
      this.vocabCard.value = parsed;
      this.vocabShownWords.value = {
        ...vocabShownWords.value,
        this.vocabCard.value!.word.toLowerCase(),
      };
      this.vocabReveal.value = false;
      this.vocabDeckCount.value = (this.vocabDeckCount.value - 1).clamp(0, 999);
    }
  } catch (e) {
    this.modeError.value =
        'Vocab error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
  } finally {
    this.isBusy.value = false;
  }
}


Future<void> scoreSrs(String bucket) async {
  final card = this.vocabCard.value;
  if (card == null) return;
  this.vocabSrsChoice.value = bucket;
  final isCorrect = bucket == 'good' || bucket == 'easy';
  await this.vocabProgress.addWord(
    buildVocabularyWord(card, targetLanguage),
    category: this.vocabSetName.value,
  );
  await this.vocabularyService.addWord(
    word: card.word,
    language: targetLanguage,
    translation: card.english,
    pronunciation: card.pronunciation,
    exampleSentences: ['${card.example.target} - ${card.example.english}'],
    culturalNote: card.culturalNote,
    partOfSpeech: card.partOfSpeech,
    tags: [this.vocabSetName.value, 'polie_vocab_mode'],
    enrichWithAI: false,
  );
  await this.vocabProgress.recordReview(card.word, targetLanguage, isCorrect);
  await loadVocabCard();
}


Future<void> loadReview() async {
  this.isBusy.value = true;
  try {
    final reviewStats = await this.reviewProgress.loadStatistics(targetLanguage);
    final vocabProg = await this.vocabProgress.loadProgress(targetLanguage);
    final tutorProg = await this.tutorProgress.loadProgress(targetLanguage);

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

Review period: ${this.reviewPeriod.value}
Words learned: $wordsSeen
Tutor lessons completed: $lessonsDone
Average accuracy: ${overallAccuracy.toStringAsFixed(1)}%
Current streak: $streak days
Language: $targetLanguage
''');
    if (json != null) {
      this.reviewPayload.value = ReviewPayload.fromJson(
        json,
        this.modeResponse.value,
        wordsSeen: wordsSeen,
        accuracy: overallAccuracy,
        streak: streak,
        lessonsDone: lessonsDone,
      );
    }
  } catch (e) {
    this.modeError.value =
        'Review error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
  } finally {
    this.isBusy.value = false;
  }
}


}
