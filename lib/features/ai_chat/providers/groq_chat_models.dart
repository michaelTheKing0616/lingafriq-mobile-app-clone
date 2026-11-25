import 'package:lingafriq/services/learning/fsrs6_scheduler.dart';
import 'package:lingafriq/services/learning/memory_state.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'],
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

// Word memory scheduled with FSRS-6.
class WordMemory {
  double ease = 2.5;
  int repetitions = 0; // Number of successful reviews
  int intervalDays = 1; // Days until next review
  DateTime nextReview = DateTime.now();
  int attempts = 0;
  int successes = 0;
  int strength = 0; // Legacy: 0-5 (mapped from repetitions)

  WordMemory({
    this.ease = 2.5,
    this.repetitions = 0,
    this.intervalDays = 1,
    DateTime? nextReview,
    this.attempts = 0,
    this.successes = 0,
  }) : nextReview = nextReview ?? DateTime.now() {
    // Map repetitions to legacy strength for backward compatibility
    strength = repetitions.clamp(0, 5);
  }

  /// Quality is 0–5. The name stays so existing callers keep compiling.
  void updateWithSM2(int quality) {
    final now = DateTime.now();
    const scheduler = Fsrs6Scheduler.days();
    final reviewed = scheduler.review(
      MemoryState(
        stability: intervalDays > 0 ? intervalDays.toDouble() : null,
        difficulty: Fsrs6Scheduler.difficultyFromEase(ease),
        phase: intervalDays > 0 ? FsrsPhase.review : FsrsPhase.learning,
        lastReview: intervalDays > 0 ? now.subtract(Duration(days: intervalDays)) : null,
      ),
      FsrsRating.fromQuality(quality),
      now,
    );
    ease = Fsrs6Scheduler.easeFromDifficulty(reviewed.difficulty!);
    intervalDays = reviewed.due!.difference(now).inDays.clamp(1, 36500);
    repetitions = quality < 3 ? 0 : repetitions + 1;
    nextReview = now.add(Duration(days: intervalDays));
    strength = repetitions.clamp(0, 5);
    attempts++;
    if (quality >= 3) successes++;
  }

  Map<String, dynamic> toJson() => {
        'ease': ease,
        'repetitions': repetitions,
        'intervalDays': intervalDays,
        'strength': strength,
        'nextReview': nextReview.toIso8601String(),
        'attempts': attempts,
        'successes': successes,
      };

  factory WordMemory.fromJson(Map<String, dynamic> json) => WordMemory(
        ease: (json['ease'] ?? 2.5).toDouble(),
        repetitions: json['repetitions'] ?? 0,
        intervalDays: json['intervalDays'] ?? 1,
        nextReview: DateTime.parse(json['nextReview']),
        attempts: json['attempts'] ?? 0,
        successes: json['successes'] ?? 0,
      );
}

// CEFR Info
class CEFRInfo {
  String level; // A1, A2, B1, B2, C1, C2
  double score; // 0-100
  DateTime lastUpdated;

  CEFRInfo({
    required this.level,
    required this.score,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'level': level,
        'score': score,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory CEFRInfo.fromJson(Map<String, dynamic> json) => CEFRInfo(
        level: json['level'] ?? 'A1',
        score: (json['score'] ?? 0.0).toDouble(),
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}

// Grammar Feedback
class GrammarFeedback {
  final String corrected;
  final List<Map<String, String>> errors;
  final double score; // 0.0-1.0

  GrammarFeedback({
    required this.corrected,
    required this.errors,
    required this.score,
  });
}

// Conversation Turn
enum ConversationTurn { user, ai }

// Polie chat modes - Premium version with all modes
enum PolieMode { translation, tutor, roleplay, conversation, vocab, review, pronunciation, grammar }

