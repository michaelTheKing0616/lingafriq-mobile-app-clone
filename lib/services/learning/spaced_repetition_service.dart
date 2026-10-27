// Spaced Repetition Service — FSRS-6 scheduling (P5-019; legacy SM-2 removed).

import '../../utils/simple_cache.dart';
import 'fsrs6_scheduler.dart';
import 'memory_state.dart';

/// Spaced repetition card
class SRCard {
  final String lessonItemId;
  final double easeFactor;
  final int interval;
  final int repetitions;
  final DateTime lastReview;
  final DateTime nextReview;
  final int quality;

  SRCard({
    required this.lessonItemId,
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
    required this.lastReview,
    required this.nextReview,
    required this.quality,
  });

  Map<String, dynamic> toJson() {
    return {
      'lesson_item_id': lessonItemId,
      'ease_factor': easeFactor,
      'interval': interval,
      'repetitions': repetitions,
      'last_review': lastReview.toIso8601String(),
      'next_review': nextReview.toIso8601String(),
      'quality': quality,
    };
  }

  factory SRCard.fromJson(Map<String, dynamic> json) {
    return SRCard(
      lessonItemId: json['lesson_item_id'] as String,
      easeFactor: (json['ease_factor'] ?? 2.5).toDouble(),
      interval: json['interval'] as int? ?? 1,
      repetitions: json['repetitions'] as int? ?? 0,
      lastReview: DateTime.parse(json['last_review'] as String),
      nextReview: DateTime.parse(json['next_review'] as String),
      quality: json['quality'] as int? ?? 0,
    );
  }
}

/// Spaced Repetition Service
class SpacedRepetitionService {
  static final SpacedRepetitionService _instance = SpacedRepetitionService._internal();
  factory SpacedRepetitionService() => _instance;
  SpacedRepetitionService._internal();

  final SimpleCache _cache = SimpleCache();
  final Map<String, SRCard> _cards = {};
  static const Duration _cacheTTL = Duration(days: 365);

  /// Initialize or load cards for user
  Future<void> initializeUser(String userId) async {
    final cacheKey = 'sr_cards_$userId';
    final cached = _cache.get<Map<String, SRCard>>(cacheKey);
    if (cached != null) {
      _cards.addAll(cached);
    }
  }

  /// Get or create card for lesson item
  SRCard getOrCreateCard(String userId, String lessonItemId) {
    final key = '${userId}_$lessonItemId';
    
    if (_cards.containsKey(key)) {
      return _cards[key]!;
    }

    final newCard = SRCard(
      lessonItemId: lessonItemId,
      easeFactor: 2.5,
      interval: 1,
      repetitions: 0,
      lastReview: DateTime.now(),
      nextReview: DateTime.now(),
      quality: 0,
    );

    _cards[key] = newCard;
    _saveUserCards(userId);
    return newCard;
  }

  /// FSRS quality (0–5) from a practice outcome — shared by lessons and GameKit (P8-901).
  int qualityFromPracticeOutcome({
    required bool wasCorrect,
    double accuracy = 1.0,
  }) {
    if (!wasCorrect) {
      return qualityScoreToSM2(accuracy.clamp(0.0, 0.59));
    }
    return qualityScoreToSM2(accuracy.clamp(0.0, 1.0));
  }

  /// Updates SRS for a practice answer using the same quality mapping as lesson review.
  SRCard reviewFromPracticeOutcome({
    required String userId,
    required String lessonItemId,
    required bool wasCorrect,
    double accuracy = 1.0,
  }) {
    final quality = qualityFromPracticeOutcome(
      wasCorrect: wasCorrect,
      accuracy: accuracy,
    );
    return reviewCard(
      userId: userId,
      lessonItemId: lessonItemId,
      quality: quality,
    );
  }

  /// Review a card with quality rating (0-5)
  SRCard reviewCard({
    required String userId,
    required String lessonItemId,
    required int quality,
  }) {
    final card = getOrCreateCard(userId, lessonItemId);
    
    final updatedCard = _updateCard(card, quality);
    final key = '${userId}_$lessonItemId';
    _cards[key] = updatedCard;
    _saveUserCards(userId);

    return updatedCard;
  }

  SRCard _updateCard(SRCard card, int quality) {
    const scheduler = Fsrs6Scheduler.days();
    final now = DateTime.now();
    final memory = Fsrs6Scheduler.migrateLegacySm2(
      easeFactor: card.easeFactor,
      intervalDays: card.interval,
      repetitions: card.repetitions,
      lastReview: card.lastReview,
    );
    final reviewed = scheduler.review(
      memory,
      FsrsRating.fromQuality(quality),
      now,
    );
    final interval = reviewed.due == null
        ? 1
        : reviewed.due!.difference(now).inDays.clamp(1, 36500);
    final repetitions = reviewed.phase == FsrsPhase.learning ? 0 : card.repetitions + 1;

    return SRCard(
      lessonItemId: card.lessonItemId,
      easeFactor: Fsrs6Scheduler.easeFromDifficulty(reviewed.difficulty!),
      interval: interval,
      repetitions: repetitions,
      lastReview: now,
      nextReview: reviewed.due ?? now.add(Duration(days: interval)),
      quality: quality,
    );
  }

  /// Get cards due for review
  List<SRCard> getDueCards(String userId, {int? limit}) {
    final now = DateTime.now();
    final dueCards = _cards.values
        .where((card) {
          final key = _cards.entries.firstWhere((e) => e.value == card).key;
          return key.startsWith('${userId}_') && card.nextReview.isBefore(now);
        })
        .toList();

    dueCards.sort((a, b) => a.nextReview.compareTo(b.nextReview));

    if (limit != null) {
      return dueCards.take(limit).toList();
    }

    return dueCards;
  }

  /// Get cards due today
  List<SRCard> getCardsDueToday(String userId) {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _cards.values
        .where((card) {
          final key = _cards.entries.firstWhere((e) => e.value == card).key;
          return key.startsWith('${userId}_') &&
              card.nextReview.isBefore(endOfDay) &&
              card.nextReview.isAfter(now.subtract(const Duration(days: 1)));
        })
        .toList();
  }

  /// Get review statistics
  Map<String, dynamic> getReviewStats(String userId) {
    final userCards = _cards.entries
        .where((e) => e.key.startsWith('${userId}_'))
        .map((e) => e.value)
        .toList();

    final now = DateTime.now();
    final due = userCards.where((c) => c.nextReview.isBefore(now)).length;
    final newCards = userCards.where((c) => c.repetitions == 0).length;
    final learning = userCards.where((c) => c.repetitions > 0 && c.repetitions < 3).length;
    final mastered = userCards.where((c) => c.repetitions >= 3 && c.interval >= 21).length;

    return {
      'total_cards': userCards.length,
      'due_now': due,
      'new_cards': newCards,
      'learning': learning,
      'mastered': mastered,
      'average_ease_factor': userCards.isEmpty
          ? 0.0
          : userCards.map((c) => c.easeFactor).reduce((a, b) => a + b) / userCards.length,
    };
  }

  /// Get next review time
  DateTime? getNextReviewTime(String userId) {
    final dueCards = getDueCards(userId);
    if (dueCards.isEmpty) {
      final allCards = _cards.values
          .where((card) {
            final key = _cards.entries.firstWhere((e) => e.value == card).key;
            return key.startsWith('${userId}_');
          })
          .toList();

      if (allCards.isEmpty) return null;

      allCards.sort((a, b) => a.nextReview.compareTo(b.nextReview));
      return allCards.first.nextReview;
    }

    return dueCards.first.nextReview;
  }

  /// Convert quality score (0.0-1.0) to SM-2 quality (0-5)
  int qualityScoreToSM2(double score) {
    if (score >= 0.9) return 5;
    if (score >= 0.8) return 4;
    if (score >= 0.7) return 3;
    if (score >= 0.6) return 2;
    if (score >= 0.5) return 1;
    return 0;
  }

  void _saveUserCards(String userId) {
    final userCards = <String, SRCard>{};
    for (final entry in _cards.entries) {
      if (entry.key.startsWith('${userId}_')) {
        userCards[entry.key] = entry.value;
      }
    }

    _cache.set('sr_cards_$userId', userCards, ttl: _cacheTTL);
  }

  void clearUserCards(String userId) {
    final keysToRemove = _cards.keys
        .where((key) => key.startsWith('${userId}_'))
        .toList();

    for (final key in keysToRemove) {
      _cards.remove(key);
    }

    _cache.remove('sr_cards_$userId');
  }
}
