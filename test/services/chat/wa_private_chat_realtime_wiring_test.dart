import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/chat/wa_private_chat_service.dart';
import 'package:lingafriq/services/push/data_push_handler.dart';

void main() {
  test('ensureDmRealtimeInfrastructure registers data-push bridge once', () async {
    await resetFirebaseForegroundDataPushBridgeForTest();
    expect(WaPrivateChatService.realtimeHooksInstalled, isFalse);
    WaPrivateChatService.ensureDmRealtimeInfrastructure();
    expect(WaPrivateChatService.realtimeHooksInstalled, isTrue);
    WaPrivateChatService.ensureDmRealtimeInfrastructure();
    await resetFirebaseForegroundDataPushBridgeForTest();
  });
}
