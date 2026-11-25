import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/learning/learning_event_log.dart';

void main() {
  test('a repeated client id is stored once and order is time then id', () {
    final log = LearningEventLog();
    final first = LearningEvent(
      clientEventId: 'b',
      source: 'lesson_item',
      eventTime: DateTime.utc(2026, 1, 2),
    );
    expect(log.apply(first), isTrue);
    expect(log.apply(first), isFalse);

    log.apply(LearningEvent(
      clientEventId: 'a',
      source: 'game',
      eventTime: DateTime.utc(2026, 1, 2),
    ));
    log.apply(LearningEvent(
      clientEventId: 'c',
      source: 'polie_graded_turn',
      eventTime: DateTime.utc(2026, 1, 1),
    ));
    log.apply(LearningEvent(
      clientEventId: 'd',
      source: 'persona_mission',
      eventTime: DateTime.utc(2026, 1, 3),
    ));
    log.apply(LearningEvent(
      clientEventId: 'e',
      source: 'pronunciation_attempt',
      eventTime: DateTime.utc(2026, 1, 3),
      audioOptIn: false,
      payload: {'score': 0.4, 'audio': 'raw-bytes'},
    ));

    final ordered = log.orderedForSync();
    expect(ordered.map((row) => row['clientEventId']), ['c', 'a', 'b', 'd', 'e']);
    expect(ordered.last['payload'], {'score': 0.4});
  });

  test('opt-in keeps audio and an unknown source is rejected', () {
    final log = LearningEventLog();
    log.apply(LearningEvent(
      clientEventId: 'audio-1',
      source: 'pronunciation_attempt',
      eventTime: DateTime.utc(2026, 1, 1),
      audioOptIn: true,
      payload: {'audio': 'kept'},
    ));
    expect(log.orderedForSync().single['payload'], {'audio': 'kept'});
    expect(
      () => log.apply(LearningEvent(
        clientEventId: 'x',
        source: 'other',
        eventTime: DateTime.utc(2026, 1, 1),
      )),
      throwsArgumentError,
    );
  });
}
