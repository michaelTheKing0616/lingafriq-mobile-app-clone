import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/chat/wa_private_chat_service.dart';

void main() {
  test('privateRoomIdForNumericUsers normalizes low_high', () {
    expect(WaPrivateChatService.privateRoomIdForNumericUsers(20, 5), 'private_5_20');
  });

  test('otherUserIdFromRoomId resolves peer', () {
    expect(
      WaPrivateChatService.otherUserIdFromRoomId('private_5_20', 5),
      20,
    );
  });

  test('otherUserIdFromRoomId rejects rooms that do not include me', () {
    expect(
      WaPrivateChatService.otherUserIdFromRoomId('private_5_20', 11),
      isNull,
    );
  });
}
