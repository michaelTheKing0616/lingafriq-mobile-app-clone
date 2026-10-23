// Vocabulary Progress Service
// Manages vocabulary learning, SRS, and progress tracking
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocabulary_progress_model.dart';
import '../providers/user_provider.dart';
import 'package:lingafriq/services/learning/fsrs6_scheduler.dart';
import 'package:lingafriq/services/learning/memory_state.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';

final vocabularyProgressServiceProvider = Provider<VocabularyProgressService>((ref) {
  return VocabularyProgressService(ref);
});

class VocabularyProgressService {
  final Ref _ref;
  VocabularyProgress? _cachedProgress;

  VocabularyProgressService(this._ref);

  /// Load vocabulary progress from local storage
  Future<VocabularyProgress> loadProgress(String language) async {
    if (_cachedProgress != null && _cachedProgress!.language == language) {
      return _cachedProgress!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('vocabulary_progress_$language');
      
      if (progressJson != null && progressJson.isNotEmpty) {
        _cachedProgress = VocabularyProgress.fromJsonString(progressJson);
        if (_cachedProgress!.language == language) {
          return _cachedProgress!;
        }
      }
    } catch (e) {
      debugPrint('Error loading vocabulary progress: $e');
    }

    _cachedProgress = VocabularyProgress(language: language);
    return _cachedProgress!;
  }

  /// Save vocabulary progress to local storage
  Future<void> saveProgress(VocabularyProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vocabulary_progress_${progress.language}', progress.toJsonString());
      _cachedProgress = progress;
      
      // Sync to backend
      await _syncToBackend(progress);
    } catch (e) {
      debugPrint('Error saving vocabulary progress: $e');
    }
  }

  /// Add or update a word
  Future<void> addWord(VocabularyWord word, {String category = 'general'}) async {
    final progress = await loadProgress(word.language);
    
    final existing = progress.words[word.word];
    final now = DateTime.now();
    
    final mastery = existing?.copyWith(
          timesSeen: (existing.timesSeen) + 1,
          lastSeen: now,
          firstSeen: existing.firstSeen ?? now,
        ) ??
        WordMastery(
          word: word.word,
          language: word.language,
          timesSeen: 1,
          firstSeen: now,
          lastSeen: now,
          nextReview: now.add(Duration(days: 1)),
          category: category,
        );

    final updatedWords = Map<String, WordMastery>.from(progress.words);
    updatedWords[word.word] = mastery;

    final updatedProgress = progress.copyWith(
      words: updatedWords,
      totalWordsLearned: updatedWords.length,
      lastActivity: now,
    );

    await saveProgress(updatedProgress);
  }

  /// Record word review result (SRS algorithm)
  Future<void> recordReview(String word, String language, bool isCorrect) async {
    final progress = await loadProgress(language);
    final mastery = progress.words[word];
    
    if (mastery == null) return;

    final now = DateTime.now();
    final newTimesSeen = mastery.timesSeen + 1;
    final newTimesCorrect = isCorrect ? mastery.timesCorrect + 1 : mastery.timesCorrect;
    final newMasteryLevel = newTimesSeen > 0 ? newTimesCorrect / newTimesSeen : 0.0;

    const scheduler = Fsrs6Scheduler.days();
    final reviewed = scheduler.review(
      MemoryState(
        stability: mastery.intervalDays > 0 ? mastery.intervalDays.toDouble() : null,
        difficulty: Fsrs6Scheduler.difficultyFromEase(mastery.easeFactor),
        phase: mastery.intervalDays > 0 ? FsrsPhase.review : FsrsPhase.learning,
        lastReview: mastery.intervalDays > 0
            ? now.subtract(Duration(days: mastery.intervalDays))
            : null,
      ),
      isCorrect ? FsrsRating.good : FsrsRating.again,
      now,
    );
    final newEaseFactor = Fsrs6Scheduler.easeFromDifficulty(reviewed.difficulty!);
    final newIntervalDays = reviewed.due!.difference(now).inDays.clamp(1, 36500);

    final nextReview = now.add(Duration(days: newIntervalDays));

    final updatedMastery = mastery.copyWith(
      timesSeen: newTimesSeen,
      timesCorrect: newTimesCorrect,
      masteryLevel: newMasteryLevel,
      lastSeen: now,
      nextReview: nextReview,
      intervalDays: newIntervalDays,
      easeFactor: newEaseFactor,
    );

    final updatedWords = Map<String, WordMastery>.from(progress.words);
    updatedWords[word] = updatedMastery;

    // Recalculate metrics
    final totalMastered = updatedWords.values.where((w) => w.isMastered).length;
    final dueForReview = updatedWords.values.where((w) => w.isDueForReview).length;

    final updatedProgress = progress.copyWith(
      words: updatedWords,
      totalWordsMastered: totalMastered,
      wordsDueForReview: dueForReview,
      lastActivity: now,
    );

    await saveProgress(updatedProgress);
  }

  /// Get words due for review
  Future<List<WordMastery>> getDueWords(String language) async {
    final progress = await loadProgress(language);
    return progress.getDueWords();
  }

  /// Get words by category
  Future<List<WordMastery>> getWordsByCategory(String language, String category) async {
    final progress = await loadProgress(language);
    return progress.getWordsByCategory(category);
  }

  /// Create custom word list
  Future<void> createWordList(String language, String listName, List<String> words) async {
    final progress = await loadProgress(language);
    
    // Add words to progress if not already present
    for (final word in words) {
      if (!progress.words.containsKey(word)) {
        await addWord(
          VocabularyWord(
            word: word,
            meaning: '',
            language: language,
          ),
          category: listName,
        );
      }
    }
  }

  /// Sync progress to backend
  Future<void> _syncToBackend(VocabularyProgress progress) async {
    try {
      final user = _ref.read(userProvider);
      if (user == null) return;

      await PersistedOutboxService.instance.enqueue(
          type: 'progress_sync',
          data: {
          'user_id': user.id.toString(),
          'type': 'vocabulary',
          'language': progress.language,
          'progress': progress.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error syncing vocabulary progress: $e');
    }
  }

  /// Clear cached progress
  void clearCache() {
    _cachedProgress = null;
  }
}

