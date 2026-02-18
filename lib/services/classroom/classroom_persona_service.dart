import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/personas/historical_roleplay_controller.dart' show TeachingPoint;
import 'package:lingafriq/ai/personas/roleplay_safety_filter.dart';

/// A student question in the live classroom queue with scoring for moderation.
class ClassroomQuestion {
  final String id;
  final String learnerId;
  final String text;
  final DateTime timestamp;
  final double relevanceScore;
  final double clarityScore;
  final double safetyScore;
  final double learningValue;
  /// Learner IDs who asked the same or similar question (for merged/deduped).
  final List<String> askedByLearnerIds;

  double get priority =>
      relevanceScore * 0.3 +
      clarityScore * 0.2 +
      safetyScore * 0.2 +
      learningValue * 0.3;

  const ClassroomQuestion({
    required this.id,
    required this.learnerId,
    required this.text,
    required this.timestamp,
    required this.relevanceScore,
    required this.clarityScore,
    required this.safetyScore,
    required this.learningValue,
    this.askedByLearnerIds = const [],
  });

  ClassroomQuestion copyWith({
    String? id,
    String? learnerId,
    String? text,
    DateTime? timestamp,
    double? relevanceScore,
    double? clarityScore,
    double? safetyScore,
    double? learningValue,
    List<String>? askedByLearnerIds,
  }) {
    return ClassroomQuestion(
      id: id ?? this.id,
      learnerId: learnerId ?? this.learnerId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      clarityScore: clarityScore ?? this.clarityScore,
      safetyScore: safetyScore ?? this.safetyScore,
      learningValue: learningValue ?? this.learningValue,
      askedByLearnerIds: askedByLearnerIds ?? this.askedByLearnerIds,
    );
  }
}

/// Persona response in classroom context (addressed to one or all learners).
class ClassroomPersonaResponse {
  final String text;
  final String addressedTo;
  final List<TeachingPoint> teachingPoints;
  final String emotionTone;
  final bool isGroupResponse;

  const ClassroomPersonaResponse({
    required this.text,
    required this.addressedTo,
    this.teachingPoints = const [],
    this.emotionTone = 'neutral',
    this.isGroupResponse = false,
  });
}

/// Orchestrates persona behavior in a multi-learner live classroom:
/// question queue, prioritization, deduplication, teacher controls, behavior overrides.
class ClassroomPersonaService {
  final String _personaId;
  final List<ClassroomQuestion> _questionQueue = [];
  final Set<String> _processedQuestionHashes = {};
  final Set<String> _mutedLearnerIds = {};
  bool _isPaused = false;

  static const int _semanticHashLength = 50;

  ClassroomPersonaService(this._personaId);

  final RoleplaySafetyFilter _safetyFilter = RoleplaySafetyFilter();

  /// Adds a student question to the queue. Scores it, checks duplicates, and enqueues.
  void submitQuestion(String learnerId, String text) {
    if (_mutedLearnerIds.contains(learnerId)) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final safetyResult = _safetyFilter.checkInput(trimmed, _personaId);
    final safetyScore = safetyResult.isAllowed ? 1.0 : 0.0;

    final relevanceScore = _scoreRelevance(trimmed);
    final clarityScore = _scoreClarity(trimmed);
    final learningValue = _scoreLearningValue(trimmed);

    final hash = _semanticHash(trimmed);
    final existingIndex = _questionQueue.indexWhere(
      (q) => _semanticHash(q.text) == hash,
    );

    if (existingIndex >= 0) {
      final existing = _questionQueue[existingIndex];
      if (!existing.askedByLearnerIds.contains(learnerId)) {
        final merged = existing.copyWith(
          askedByLearnerIds: [
            ...existing.askedByLearnerIds,
            learnerId,
          ],
        );
        _questionQueue[existingIndex] = merged;
      }
      return;
    }

    if (_processedQuestionHashes.contains(hash)) return;

    final id = '${DateTime.now().millisecondsSinceEpoch}_$learnerId';
    final question = ClassroomQuestion(
      id: id,
      learnerId: learnerId,
      text: trimmed,
      timestamp: DateTime.now(),
      relevanceScore: relevanceScore,
      clarityScore: clarityScore,
      safetyScore: safetyScore,
      learningValue: learningValue,
      askedByLearnerIds: [learnerId],
    );

    _questionQueue.add(question);
  }

  String _semanticHash(String text) {
    final normalized = text.toLowerCase().trim();
    if (normalized.length <= _semanticHashLength) return normalized;
    return normalized.substring(0, _semanticHashLength);
  }

  double _scoreRelevance(String text) {
    final words = text.split(RegExp(r'\s+'));
    if (words.isEmpty) return 0.5;
    final persona = HistoricalPersonaRegistry.findById(_personaId);
    if (persona == null) return 0.5;
    final vocab = persona.commonVocabulary.map((e) => e.toLowerCase()).toSet();
    final matches = words.where((w) => vocab.contains(w.toLowerCase())).length;
    if (words.length < 3) return 0.6;
    return (0.4 + 0.6 * (matches / words.length)).clamp(0.0, 1.0);
  }

  double _scoreClarity(String text) {
    final words = text.split(RegExp(r'\s+'));
    if (words.isEmpty) return 0.0;
    if (words.length >= 5 && words.length <= 80) return 0.9;
    if (words.length < 2) return 0.4;
    if (words.length > 100) return 0.5;
    return 0.7;
  }

  double _scoreLearningValue(String text) {
    final len = text.trim().length;
    if (len < 10) return 0.3;
    if (len >= 20 && len <= 200) return 0.85;
    return 0.6;
  }

  /// Returns the next best question to answer and removes it from the queue.
  ClassroomQuestion? getNextQuestion() {
    if (_isPaused || _questionQueue.isEmpty) return null;

    final eligible = _questionQueue
        .where((q) => !_mutedLearnerIds.contains(q.learnerId))
        .toList();
    if (eligible.isEmpty) return null;

    eligible.sort((a, b) => b.priority.compareTo(a.priority));
    final next = eligible.first;
    _questionQueue.remove(next);
    _processedQuestionHashes.add(_semanticHash(next.text));
    return next;
  }

  /// Groups by semantic similarity (shared words > 60%) and returns one representative per group.
  List<ClassroomQuestion> deduplicateQueue() {
    if (_questionQueue.isEmpty) return [];

    final groups = <String, List<ClassroomQuestion>>{};
    for (final q in _questionQueue) {
      final keyWords = _keyWords(q.text);
      bool merged = false;
      for (final entry in groups.entries) {
        final repKey = _keyWords(entry.value.first.text);
        if (_wordOverlap(keyWords, repKey) >= 0.6) {
          entry.value.add(q);
          merged = true;
          break;
        }
      }
      if (!merged) {
        groups[q.id] = [q];
      }
    }

    return groups.values.map((list) {
      final rep = list.first;
      final allLearners = list
          .expand((q) => q.askedByLearnerIds)
          .toSet()
          .toList();
      return rep.copyWith(askedByLearnerIds: allLearners);
    }).toList();
  }

  Set<String> _keyWords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toSet();
  }

  double _wordOverlap(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    return (a.intersection(b).length / a.union(b).length);
  }

  void pause() {
    _isPaused = true;
  }

  void resume() {
    _isPaused = false;
  }

  /// Skips the current (next) question without returning it.
  void skipCurrentQuestion() {
    if (_questionQueue.isEmpty) return;
    final eligible = _questionQueue
        .where((q) => !_mutedLearnerIds.contains(q.learnerId))
        .toList();
    if (eligible.isEmpty) return;
    eligible.sort((a, b) => b.priority.compareTo(a.priority));
    _questionQueue.remove(eligible.first);
  }

  /// Updates question text and recomputes scores.
  void rephraseQuestion(String questionId, String newText) {
    final index = _questionQueue.indexWhere((q) => q.id == questionId);
    if (index < 0) return;

    final q = _questionQueue[index];
    final safetyResult = _safetyFilter.checkInput(newText.trim(), _personaId);
    final safetyScore = safetyResult.isAllowed ? 1.0 : 0.0;

    _questionQueue[index] = q.copyWith(
      text: newText.trim(),
      relevanceScore: _scoreRelevance(newText),
      clarityScore: _scoreClarity(newText),
      safetyScore: safetyScore,
      learningValue: _scoreLearningValue(newText),
    );
  }

  void muteStudent(String learnerId) {
    _mutedLearnerIds.add(learnerId);
  }

  /// Personas behave differently in classrooms: longer, didactic, follow-ups, slower pace, examples.
  Map<String, dynamic> getClassroomBehaviorOverrides() {
    return {
      'response_length': 'long',
      'didactic': true,
      'ask_followups': true,
      'pace': 'slower',
      'use_examples': true,
    };
  }

  /// After every N turns, suggests a comprehension check prompt.
  String? generateComprehensionCheck(
    List<ClassroomPersonaResponse> recentResponses,
  ) {
    if (recentResponses.isEmpty) return null;
    if (recentResponses.length % 3 == 0) {
      return 'Before we continue, can someone rephrase what we just discussed?';
    }
    return null;
  }

  int get queueLength => _questionQueue.length;
  bool get isPaused => _isPaused;
}
