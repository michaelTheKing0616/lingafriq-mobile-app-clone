import '../learning/fsrs6_scheduler.dart';
import '../learning/memory_state.dart';
import '../../models/offline/local_vocabulary.dart';
import '../../utils/api_service.dart';
import '../../utils/structured_logger.dart';
import 'local_database_service.dart';

/// Vocabulary Store Service
/// Schedules vocabulary with FSRS-6. The stored ease rises when difficulty falls.
class VocabularyStore {
  static final VocabularyStore _instance = VocabularyStore._internal();
  factory VocabularyStore() => _instance;
  VocabularyStore._internal();

  final LocalDatabaseService _db = LocalDatabaseService();

  /// Add a word to the vocabulary store
  Future<void> addWord(LocalVocabulary word) async {
    if (_db.vocabularyExists(word.id)) {
      await _db.updateVocabulary(word);
    } else {
      await _db.saveVocabulary(word);
    }
  }

  /// Get words due for review
  /// Returns words sorted by priority (most overdue first)
  List<LocalVocabulary> getWordsDueForReview(String language, {int? limit}) {
    final now = DateTime.now();
    final allVocabulary = _db.getVocabularyByLanguage(language);
    
    final dueWords = allVocabulary.where((vocab) {
      if (vocab.nextReviewDate == null) return true;
      return vocab.nextReviewDate!.isBefore(now) || vocab.nextReviewDate!.isAtSameMomentAs(now);
    }).toList();

    dueWords.sort((a, b) {
      if (a.nextReviewDate == null && b.nextReviewDate == null) {
        return a.addedAt.compareTo(b.addedAt);
      }
      if (a.nextReviewDate == null) return -1;
      if (b.nextReviewDate == null) return 1;
      
      final aOverdue = now.difference(a.nextReviewDate!).inDays;
      final bOverdue = now.difference(b.nextReviewDate!).inDays;
      
      if (aOverdue != bOverdue) {
        return bOverdue.compareTo(aOverdue);
      }
      
      return a.easeFactor.compareTo(b.easeFactor);
    });

    if (limit != null && limit > 0) {
      return dueWords.take(limit).toList();
    }
    
    return dueWords;
  }

  /// Review a word with a quality rating from 0 to 5.
  Future<void> reviewWord(String id, int quality) async {
    if (quality < 0 || quality > 5) {
      throw ArgumentError('Quality must be between 0 and 5');
    }

    final vocab = _db.getVocabulary(id);
    if (vocab == null) {
      throw Exception('Vocabulary item not found: $id');
    }

    final updatedVocab = _updateSRSMetadata(vocab, quality);
    await _db.updateVocabulary(updatedVocab);
  }

  LocalVocabulary _updateSRSMetadata(LocalVocabulary vocab, int quality) {
    final now = DateTime.now();
    const scheduler = Fsrs6Scheduler.days();
    final reviewed = scheduler.review(
      MemoryState(
        stability: vocab.interval > 0 ? vocab.interval.toDouble() : null,
        difficulty: Fsrs6Scheduler.difficultyFromEase(vocab.easeFactor),
        phase: vocab.interval > 0 ? FsrsPhase.review : FsrsPhase.learning,
        lastReview: vocab.lastReviewedAt ??
            (vocab.interval > 0 ? now.subtract(Duration(days: vocab.interval)) : null),
      ),
      FsrsRating.fromQuality(quality),
      now,
    );
    final interval = reviewed.due!.difference(now).inDays.clamp(1, 36500);
    final repetitions = quality < 3 ? 0 : vocab.repetitions + 1;
    return vocab.copyWith(
      easeFactor: Fsrs6Scheduler.easeFromDifficulty(reviewed.difficulty!),
      interval: interval,
      repetitions: repetitions,
      nextReviewDate: now.add(Duration(days: interval)),
      lastReviewedAt: now,
      quality: quality,
      totalReviews: vocab.totalReviews + 1,
      correctReviews: quality >= 3 ? vocab.correctReviews + 1 : vocab.correctReviews,
      isMastered: interval >= 365 && repetitions >= 5,
    );
  }

  /// Get mastery statistics for a language
  Map<String, dynamic> getMasteryStats(String language) {
    final allVocab = _db.getVocabularyByLanguage(language);
    
    if (allVocab.isEmpty) {
      return {
        'total': 0,
        'mastered': 0,
        'learning': 0,
        'new': 0,
        'masteryPercentage': 0.0,
        'averageEaseFactor': 0.0,
        'totalReviews': 0,
        'correctReviews': 0,
        'accuracyPercentage': 0.0,
      };
    }

    final mastered = allVocab.where((v) => v.isMastered).length;
    final learning = allVocab.where((v) => 
      !v.isMastered && v.repetitions > 0 && v.nextReviewDate != null
    ).length;
    final newWords = allVocab.where((v) => 
      v.repetitions == 0 || v.nextReviewDate == null
    ).length;

    final totalReviews = allVocab.fold<int>(
      0,
      (sum, v) => sum + v.totalReviews,
    );
    
    final correctReviews = allVocab.fold<int>(
      0,
      (sum, v) => sum + v.correctReviews,
    );

    final averageEaseFactor = allVocab.isEmpty
        ? 0.0
        : allVocab.fold<double>(
            0.0,
            (sum, v) => sum + v.easeFactor,
          ) / allVocab.length;

    final accuracyPercentage = totalReviews > 0
        ? (correctReviews / totalReviews) * 100.0
        : 0.0;

    return {
      'total': allVocab.length,
      'mastered': mastered,
      'learning': learning,
      'new': newWords,
      'masteryPercentage': (mastered / allVocab.length) * 100.0,
      'averageEaseFactor': averageEaseFactor,
      'totalReviews': totalReviews,
      'correctReviews': correctReviews,
      'accuracyPercentage': accuracyPercentage,
    };
  }

  /// Sync vocabulary with backend
  Future<void> syncWithBackend() async {
    try {
      await ApiService.initialize();
      
      final allVocab = _db.getAllVocabulary();
      
      for (final vocab in allVocab) {
        try {
          final response = await ApiService.post(
            '/api/vocabulary/sync',
            data: vocab.toJson(),
          );
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            logger.debug('Synced vocabulary item: ${vocab.id}');
          }
        } catch (e) {
          logger.error('Failed to sync vocabulary item: ${vocab.id}', error: e);
        }
      }
    } catch (e) {
      logger.error('Failed to sync vocabulary with backend', error: e);
      rethrow;
    }
  }

  /// Get vocabulary by category
  List<LocalVocabulary> getVocabularyByCategory(String category) {
    return _db.getVocabularyByCategory(category);
  }

  /// Get mastered vocabulary
  List<LocalVocabulary> getMasteredVocabulary(String language) {
    return _db.getMasteredVocabulary()
        .where((v) => v.language == language)
        .toList();
  }

  /// Get vocabulary item by ID
  LocalVocabulary? getVocabulary(String id) {
    return _db.getVocabulary(id);
  }

  /// Delete vocabulary item
  Future<void> deleteVocabulary(String id) async {
    await _db.deleteVocabulary(id);
  }

  /// Batch add vocabulary
  Future<void> addWordsBatch(List<LocalVocabulary> words) async {
    await _db.saveVocabularyBatch(words);
  }

  /// Get vocabulary count for a language
  int getVocabularyCount(String language) {
    return _db.getVocabularyByLanguage(language).length;
  }

  /// Get words that need review soon (within next N days)
  List<LocalVocabulary> getWordsDueSoon(String language, int days) {
    final now = DateTime.now();
    final deadline = now.add(Duration(days: days));
    final allVocabulary = _db.getVocabularyByLanguage(language);
    
    return allVocabulary.where((vocab) {
      if (vocab.nextReviewDate == null) return true;
      return vocab.nextReviewDate!.isBefore(deadline) || 
             vocab.nextReviewDate!.isAtSameMomentAs(deadline);
    }).toList();
  }
}
