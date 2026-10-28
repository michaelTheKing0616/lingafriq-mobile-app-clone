import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/chat/wa_private_chat_service.dart';
import 'package:lingafriq/services/push/data_push_handler.dart';

void main() {
  group('DataPushHandler P9-909', () {
    test('AC3 rejects notification+body payloads', () {
      final withNotification = RemoteMessage(
        notification: const RemoteNotification(title: 'Hi', body: 'secret'),
        data: const {'type': 'chat_message', 'roomId': 'private_1_2', 'seq': '1'},
      );
      expect(DataPushHandler.isDataOnlyPush(withNotification), isFalse);
    });

    test('parse accepts data-only chat wake', () {
      final wake = DataPushHandler.parseChatWakePush(const {
        'type': 'chat_message',
        'roomId': 'private_4_9',
        'seq': '12',
      });
      expect(wake?.roomId, 'private_4_9');
      expect(wake?.afterSeq, 11);
    });

    test('parse rejects preview keys in data map', () {
      final wake = DataPushHandler.parseChatWakePush(const {
        'type': 'chat_message',
        'roomId': 'private_1_2',
        'seq': '3',
        'message': 'leaked',
      });
      expect(wake, isNull);
    });

    test('P9-941 notificationFromSync uses synced text only', () {
      final batch = WaMessageSyncBatch(
        messages: [
          WaSyncedMessage(
            seq: 1,
            serverMessageId: 'a',
            message: 'Ẹ kú àárọ̀',
            read: false,
          ),
        ],
        cursor: 1,
      );
      final note = DataPushHandler.notificationFromSync(
        roomId: 'private_2_5',
        batch: batch,
        reason: 'sync_ok',
      );
      expect(note.body, 'Ẹ kú àárọ̀');
      expect(note.usedGenericBody, isFalse);
    });

    test('P9-941 generic notification when sync fails', () {
      final batch = WaMessageSyncBatch(messages: [], cursor: 0);
      final note = DataPushHandler.notificationFromSync(
        roomId: 'private_2_5',
        batch: batch,
        reason: 'sync_error',
      );
      expect(note.usedGenericBody, isTrue);
      expect(note.body, DataPushHandler.genericDecryptFailedBody);
    });
  });
}
