import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
