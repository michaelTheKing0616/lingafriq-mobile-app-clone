/// Idempotent learning events. One client id is applied once.
/// Ordering for sync is event time, then client id.
const String learningEventPath = '/api/learning/events';

const Set<String> learningEventSources = {
  'lesson_item',
  'game',
  'polie_graded_turn',
  'persona_mission',
  'pronunciation_attempt',
};

class LearningEvent {
  const LearningEvent({
    required this.clientEventId,
    required this.source,
    required this.eventTime,
    this.language,
    this.payload = const {},
    this.audioOptIn = false,
  });

  final String clientEventId;
  final String source;
  final DateTime eventTime;
  final String? language;
  final Map<String, Object?> payload;
  final bool audioOptIn;

  Map<String, Object?> toJson() {
    final body = Map<String, Object?>.from(payload);
    if (!audioOptIn) {
      body.remove('audio');
      body.remove('audioBytes');
      body.remove('audioUrl');
    }
    return {
      'clientEventId': clientEventId,
      'source': source,
      'eventTime': eventTime.toUtc().toIso8601String(),
      if (language != null) 'language': language,
      'audioOptIn': audioOptIn,
      'payload': body,
    };
  }
}

class LearningEventLog {
  final List<LearningEvent> _applied = [];
  final Set<String> _ids = {};

  /// Returns true only the first time this client id is accepted.
  bool apply(LearningEvent event) {
    if (!learningEventSources.contains(event.source)) {
      throw ArgumentError('unknown learning event source');
    }
    if (event.clientEventId.isEmpty) {
      throw ArgumentError('client_event_id is required');
    }
    if (!_ids.add(event.clientEventId)) return false;
    _applied.add(event);
    return true;
  }

  List<Map<String, Object?>> orderedForSync() {
    final copy = List<LearningEvent>.from(_applied);
    copy.sort((a, b) {
      final byTime = a.eventTime.compareTo(b.eventTime);
      if (byTime != 0) return byTime;
      return a.clientEventId.compareTo(b.clientEventId);
    });
    return copy.map((event) => event.toJson()).toList();
  }
}
