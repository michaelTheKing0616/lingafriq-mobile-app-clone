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

  test('session_started buffers until daily rollup', () async {
    final posted = <List<Map<String, Object?>>>[];
    final service = buildService(posted: posted);
    service.configureLearner(accountId: '507f1f77bcf86cd799439011', languageCode: 'yo');

    await service.beginLearningSession();
    await service.beginLearningSession();
    expect(posted, isEmpty);

    await service.flushDailyRollup();
    expect(posted, hasLength(1));
    final event = posted.single.single;
    expect(event['event_name'], 'offline_operation');
    final metrics = event['metrics'] as Map<String, Object?>;
    expect(metrics['daily_rollup'], isTrue);
    expect(metrics['session_started_count'], 1);
    expect(event['pseudonymous_user_id'], pseudonymousIdFromAccountId('507f1f77bcf86cd799439011'));
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

    expect(posted, isEmpty);
    await service.flushDailyRollup();
    expect(posted, hasLength(1));
    final rollup = posted.single.single;
    final metrics = rollup['metrics'] as Map<String, Object?>;
    expect(metrics['exercise_count'], 1);
    expect(metrics['exercise_correct_count'], 1);
    expect(metrics['exercise_latency_ms_sum'], 1200);
    expect(metrics.containsKey('item_key'), isFalse);
    expect(rollup.keys, isNot(contains('answer')));
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

    expect(posted, hasLength(1));
    final event = posted.single.single;
    expect(event['event_name'], 'offline_operation');
    final metrics = event['metrics'] as Map<String, Object?>;
    expect(metrics['reason_code'], 1);
    expect(metrics['content_report'], isTrue);
    expect(metrics.containsKey('reason'), isFalse);
    expect(metrics['daily_rollup'], isNot(true));
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
    expect(await service.pendingCount(), 0);

    await service.flushDailyRollup();
    expect(await service.pendingCount(), 1);

    online = true;
    await service.flush();
    expect(posted, hasLength(1));
    expect(posted.single.single['event_name'], 'offline_operation');
    expect(await service.pendingCount(), 0);
  });

  test('speech_attempt_scored unsure omits score fields', () async {
    final posted = <List<Map<String, Object?>>>[];
    final service = buildService(posted: posted);
    service.configureLearner(accountId: 'acct-5');
    await service.beginLearningSession();

    await service.trackSpeechAttemptScored(unsure: true);
    await service.flushDailyRollup();

    final event = posted.single.single;
    final metrics = event['metrics'] as Map<String, Object?>;
    expect(metrics['speech_unsure_count'], 1);
    expect(metrics.containsKey('phones_ok'), isFalse);
    expect(metrics.containsKey('audio'), isFalse);
  });

  test('speech_attempt_scored carries phones_ok tone_ok confidence', () async {
    final posted = <List<Map<String, Object?>>>[];
    final service = buildService(posted: posted);
    service.configureLearner(accountId: 'acct-6');
    await service.beginLearningSession();

    await service.trackSpeechAttemptScored(
      unsure: false,
      phonesOk: true,
      toneOk: false,
      confidence: 0.812,
    );
    await service.flushDailyRollup();

    final metrics = posted.single.single['metrics'] as Map<String, Object?>;
    expect(metrics['speech_phones_ok_count'], 1);
    expect(metrics['speech_tone_ok_count'], 0);
    expect(metrics.containsKey('confidence'), isFalse);
  });

  test('ai_turn carries mode_ord tokens latency fallback_used', () async {
    final posted = <List<Map<String, Object?>>>[];
    final service = buildService(posted: posted);
    service.configureLearner(accountId: 'acct-7');
    await service.beginLearningSession();

    await service.trackAiTurn(
      modeOrd: 0,
      tokens: 120,
      latencyMs: 450,
      fallbackUsed: true,
    );
    await service.flushDailyRollup();

    final metrics = posted.single.single['metrics'] as Map<String, Object?>;
    expect(metrics['ai_tokens_sum'], 120);
    expect(metrics['ai_latency_ms_sum'], 450);
    expect(metrics['ai_fallback_count'], 1);
    expect(metrics.containsKey('mode_ord'), isFalse);
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
    await service.flushDailyRollup();

    await service.flush();
    expect(calls, 2);
    expect(service.droppedAfterRetries, 1);
    expect(await service.pendingCount(), 0);
  });
}
