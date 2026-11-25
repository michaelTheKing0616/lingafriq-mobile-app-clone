import 'dart:async';

import 'package:lingafriq/features/polie_workspace/polie_workspace_models.dart';


import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_state.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_handlers_1.dart';
import 'package:lingafriq/features/polie_workspace/build_host/polie_workspace_host_handlers_2.dart';

mixin PolieWorkspaceHostHandlers3 on PolieWorkspaceHostState, PolieWorkspaceHostHandlers1, PolieWorkspaceHostHandlers2 {
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


}
