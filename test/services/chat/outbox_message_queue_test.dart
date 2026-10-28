import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/chat/outbox_message_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatOutboxMessageQueue P9-909', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('AC1 offline enqueue stays queued then sends in order when online', () async {
      final queue = ChatOutboxMessageQueue(prefs: prefs, maxAttempts: 3);
      await queue.enqueue(recipientId: '12', message: 'Ẹ káàbọ', clientMessageId: 'c1');
      await queue.enqueue(recipientId: '12', message: 'Báwo ni', clientMessageId: 'c2');

      final pending = await queue.listOrdered();
      expect(pending.every((e) => e.state == ChatOutboxState.queued), isTrue);

      final sentOrder = <String>[];
      var online = true;
      await queue.flush(
        isOnline: () => online,
        send: (entry) async {
          sentOrder.add(entry.clientMessageId);
          return {'id': entry.clientMessageId};
        },
      );

      expect(sentOrder, ['c1', 'c2']);
      final after = await queue.listOrdered();
      expect(after, isEmpty);
    });

    test('AC2 exhausted retries mark failed with tap-to-retry hint', () async {
      final queue = ChatOutboxMessageQueue(prefs: prefs, maxAttempts: 2);
      await queue.enqueue(recipientId: '3', message: 'test', clientMessageId: 'fail-me');

      for (var i = 0; i < 3; i++) {
        await queue.flush(
          isOnline: () => true,
          send: (_) async => null,
        );
      }

      final rows = await queue.listOrdered();
      expect(rows, hasLength(1));
      expect(rows.first.state, ChatOutboxState.failed);
      expect(rows.first.showFailedTapToRetry, isTrue);
      expect(rows.first.failedUserHint, 'failed, tap to retry');

      await queue.retry('fail-me');
      expect((await queue.listOrdered()).first.state, ChatOutboxState.queued);
    });
  });
}
