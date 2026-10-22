import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/lesson/lesson_item_service.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';

void main() {
  test('server ack removes only rows with ok true', () {
    final clock = DateTime.utc(2026, 1, 1);
    final box = DurableOutbox(clock: () => clock);
    box.restore({
      'clientOperationId': 'a',
      'idempotencyKey': 'k-a',
      'attempts': 0,
      'createdAt': '2026-01-01T00:00:00.000Z',
    });
    box.restore({
      'clientOperationId': 'b',
      'idempotencyKey': 'k-b',
      'attempts': 0,
      'createdAt': '2026-01-01T00:00:00.000Z',
    });

    final removed = box.applyServerResults([
      {'clientOperationId': 'a', 'ok': true},
      {'clientOperationId': 'b', 'ok': false, 'error': 'version_conflict'},
    ], {'a', 'b'});

    expect(removed, 1);
    expect(box.contains('a'), isFalse);
    expect(box.contains('b'), isTrue);
    expect(box.rows['b']!['attempts'], 1);
    expect(box.rows['b']!['conflict'], isTrue);
    expect(box.due(batchSize: 10), isEmpty);
  });

  test('transport failure keeps the row and backs off', () {
    var now = DateTime.utc(2026, 1, 1);
    final box = DurableOutbox(clock: () => now);
    box.restore({
      'clientOperationId': 'a',
      'attempts': 0,
      'createdAt': '2026-01-01T00:00:00.000Z',
    });

    box.markTransportFailure(['a'], 'http_500');

    expect(box.contains('a'), isTrue);
    expect(box.rows['a']!['attempts'], 1);
    expect(box.rows['a']!['lastError'], 'http_500');
    expect(box.due(batchSize: 10), isEmpty);

    now = now.add(const Duration(milliseconds: 250));
    expect(box.due(batchSize: 10), hasLength(1));
  });

  test('encoded rows survive a restart', () {
    final box = DurableOutbox(clock: () => DateTime.utc(2026, 1, 1));
    box.restore({
      'clientOperationId': 'a',
      'idempotencyKey': 'k',
      'type': 'noop',
      'payload': {'n': 1},
      'attempts': 2,
      'createdAt': '2026-01-01T00:00:00.000Z',
    });

    final restored = DurableOutbox.decode(box.encode());

    expect(restored.contains('a'), isTrue);
    expect(restored.rows['a']!['attempts'], 2);
    expect(restored.rows['a']!['idempotencyKey'], 'k');
    expect(restored.rows['a']!['payload'], {'n': 1});
  });

  test('the same payload keeps one idempotency key', () {
    final first = DurableOutbox.idempotencyKeyFor('progress_metrics_merge', {
      'xp': 1,
      'language': 'yo',
    });
    final second = DurableOutbox.idempotencyKeyFor('progress_metrics_merge', {
      'xp': 1,
      'language': 'yo',
    });
    expect(first, second);

    final box = DurableOutbox();
    box.restore({
      'clientOperationId': 'a',
      'idempotencyKey': first,
    });
    expect(box.idForIdempotencyKey(second), 'a');
  });

  test('lesson progress enqueues only through the persisted outbox type', () async {
    final calls = <Map<String, dynamic>>[];
    final service = LessonItemService(Dio());
    service.enqueueOverride = ({
      required String type,
      required Map<String, dynamic> payload,
    }) async {
      calls.add({'type': type, 'payload': payload});
      return 'op-1';
    };

    final id = await service.enqueueLessonProgress({'xp': 3});

    expect(id, 'op-1');
    expect(calls, hasLength(1));
    expect(calls.single['type'], 'progress_metrics_merge');
    expect(calls.single['payload'], {'xp': 3});
  });
}
