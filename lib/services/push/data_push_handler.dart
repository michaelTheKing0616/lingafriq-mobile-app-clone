import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lingafriq/services/chat/wa_private_chat_service.dart';

/// Handles data-only chat pushes; message bodies are fetched over auth (P9-909).
class DataPushHandler {
  const DataPushHandler({
    this.deviceId = 'primary',
  });

  final String deviceId;

  static const chatMessageType = 'chat_message';

  static bool isDataOnlyPush(RemoteMessage message) {
    return message.notification == null && message.data.isNotEmpty;
  }

  static ChatWakePush? parseChatWakePush(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    if (type != chatMessageType) return null;
    final roomId = data['roomId']?.toString().trim() ?? '';
    if (roomId.isEmpty) return null;
    final seq = int.tryParse(data['seq']?.toString() ?? '') ?? 0;
    if (_containsForbiddenPreviewKeys(data)) return null;
    return ChatWakePush(roomId: roomId, afterSeq: seq > 0 ? seq - 1 : 0);
  }

  static bool _containsForbiddenPreviewKeys(Map<String, dynamic> data) {
    const forbidden = {
      'message',
      'body',
      'title',
      'text',
      'preview',
      'senderName',
      'sender_name',
      'displayName',
      'display_name',
    };
    for (final key in data.keys) {
      if (forbidden.contains(key)) return true;
    }
    return false;
  }

  Future<DataPushFetchResult> handleRemoteMessage(RemoteMessage message) async {
    if (!isDataOnlyPush(message)) {
      return const DataPushFetchResult(
        handled: false,
        reason: 'not_data_only',
      );
    }

    final wake = parseChatWakePush(message.data);
    if (wake == null) {
      return const DataPushFetchResult(
        handled: false,
        reason: 'unrecognized_payload',
      );
    }

    try {
      final batch = await WaPrivateChatService.syncMessagesSinceCursor(
        roomId: wake.roomId,
        deviceId: deviceId,
        afterSeq: wake.afterSeq,
      );
      if (batch == null) {
        return DataPushFetchResult(
          handled: true,
          reason: 'sync_empty_response',
          roomId: wake.roomId,
        );
      }
      log(
        'Data push fetched ${batch.messages.length} messages for ${wake.roomId}',
        name: 'DataPushHandler',
      );
      return DataPushFetchResult(
        handled: true,
        reason: 'sync_ok',
        roomId: wake.roomId,
        newCursor: batch.cursor,
        fetchedCount: batch.messages.length,
      );
    } catch (e) {
      log('Data push sync failed: $e', name: 'DataPushHandler');
      return DataPushFetchResult(
        handled: true,
        reason: 'sync_error',
        roomId: wake.roomId,
        error: e.toString(),
      );
    }
  }
}

class ChatWakePush {
  const ChatWakePush({required this.roomId, required this.afterSeq});

  final String roomId;
  final int afterSeq;
}

class DataPushFetchResult {
  const DataPushFetchResult({
    required this.handled,
    required this.reason,
    this.roomId,
    this.newCursor,
    this.fetchedCount = 0,
    this.error,
  });

  final bool handled;
  final String reason;
  final String? roomId;
  final int? newCursor;
  final int fetchedCount;
  final String? error;
}
