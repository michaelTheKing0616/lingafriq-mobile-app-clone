import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  LearningAnalyticsService buildService({
    required List<List<Map<String, Object?>>> posted,
    Future<bool> Function()? isOnline,
    int maxAttempts = 3,
  }) {
    return LearningAnalyticsService(
      postBatch: (events) async {
        posted.add(events);
      },
      loadPrefs: SharedPreferences.getInstance,
      isOnline: isOnline ?? (() async => true),
      sessionIdFactory: () => 'sess_${'a' * 32}',
      now: () => DateTime.utc(2026, 10, 27, 12, 0, 0),
      maxSendAttempts: maxAttempts,
    );
  }

  test('session_started envelope shape and single emit per session', () async {
    final posted = <List<Map<String, Object?>>>[];
    final service = buildService(posted: posted);
    service.configureLearner(accountId: '507f1f77bcf86cd799439011', languageCode: 'yo');

    await service.beginLearningSession();
    await service.beginLearningSession();

    expect(posted, hasLength(1));
    final event = posted.single.single;
    expect(event['event_name'], 'session_started');
    expect(event['schema_version'], '1');
    expect(event['pseudonymous_user_id'], pseudonymousIdFromAccountId('507f1f77bcf86cd799439011'));
    expect(event['metrics'], isEmpty);
    expect(event.containsKey('answer'), isFalse);
  });

  test('item_answered maps to exercise_answered without answer text', () async {
    final posted = <List<Map<String, Object?>>>[];
    final service = buildService(posted: posted);
    service.configureLearner(accountId: 'acct-1');
    await service.beginLearningSession();

    await service.trackItemAnswered(
      itemId: 'item-42',
      correct: true,
      latencyMs: 1200,
      hintsUsed: 1,
    );

    expect(posted, hasLength(2));
    final answered = posted.last.single;
    expect(answered['event_name'], 'exercise_answered');
    final metrics = answered['metrics'] as Map<String, Object?>;
    expect(metrics['correct'], isTrue);
    expect(metrics['latency_ms'], 1200);
    expect(metrics['hints'], 1);
    expect(metrics['item_key'], stableItemKey('item-42'));
    expect(answered.keys, isNot(contains('answer')));
  });

  test('content_reported uses reason code and item key only', () async {
    final posted = <List<Map<String, Object?>>>[];
    final service = buildService(posted: posted);
    service.configureLearner(accountId: 'acct-2');
    await service.beginLearningSession();

    await service.trackContentReported(
      itemId: 'pack:item-9',
      reasonCode: ContentReportReasonCode.toneSpelling,
    );

    final event = posted.last.single;
    expect(event['event_name'], 'offline_operation');
    final metrics = event['metrics'] as Map<String, Object?>;
    expect(metrics['reason_code'], 1);
    expect(metrics['content_report'], isTrue);
    expect(metrics.containsKey('reason'), isFalse);
  });

  test('offline queue preserves order and flushes after reconnect', () async {
    final posted = <List<Map<String, Object?>>>[];
    var online = false;
    final service = buildService(
      posted: posted,
      isOnline: () async => online,
    );
    service.configureLearner(accountId: 'acct-3');

    await service.beginLearningSession();
    await service.trackItemAnswered(
      itemId: 'a',
      correct: false,
      latencyMs: 50,
      hintsUsed: 0,
    );
    expect(posted, isEmpty);
    expect(await service.pendingCount(), 2);

    online = true;
    await service.flush();
    expect(posted, hasLength(2));
    expect(posted[0].single['event_name'], 'session_started');
    expect(posted[1].single['event_name'], 'exercise_answered');
    expect(await service.pendingCount(), 0);
  });

  test('failed send retries then drops with counter', () async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    final service = LearningAnalyticsService(
      postBatch: (_) async {
        calls++;
        throw Exception('network');
      },
      loadPrefs: SharedPreferences.getInstance,
      isOnline: () async => true,
      sessionIdFactory: () => 'sess_${'b' * 32}',
      now: () => DateTime.utc(2026, 10, 27, 12, 0, 0),
      maxSendAttempts: 2,
    );
    service.configureLearner(accountId: 'acct-4');
    await service.beginLearningSession();

    await service.flush();
    expect(calls, 2);
    expect(service.droppedAfterRetries, 1);
    expect(await service.pendingCount(), 0);
  });
}
