import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/config/sync_outbox_operation_types.dart';

void main() {
  test('game_srs_upsert_many is a valid sync v2 outbox type', () {
    expect(isValidSyncOutboxOperationType('game_srs_upsert_many'), isTrue);
  });

  test('unknown types are rejected', () {
    expect(isValidSyncOutboxOperationType('not_a_real_operation'), isFalse);
  });
}
