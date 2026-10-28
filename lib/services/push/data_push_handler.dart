import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lingafriq/services/chat/wa_private_chat_service.dart';

/// Local notification copy built only from authenticated sync (never from FCM data).
class ChatPushLocalNotification {
  const ChatPushLocalNotification({
    required this.title,
    required this.body,
    required this.roomId,
    this.usedGenericBody = false,
  });

  final String title;
  final String body;
  final String roomId;
  final bool usedGenericBody;
}

typedef ChatPushLocalNotifier = Future<void> Function(ChatPushLocalNotification notification);

/// Handles data-only chat pushes; message bodies are fetched over auth (P9-909 / P9-941).
class DataPushHandler {
  const DataPushHandler({
    this.deviceId = 'primary',
    this.localNotifier,
  });

  final String deviceId;
  final ChatPushLocalNotifier? localNotifier;

  static const chatMessageType = 'chat_message';

  static const genericEncryptedTitle = 'New message';
  static const genericEncryptedBody =
      'Open LingAfriq to read your message. We never put chat text in push alerts.';

  static const genericDecryptFailedBody =
      'You have a new message. Open the app to read it when you are ready.';

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
      'fileUrl',
      'file_url',
      'mediaPreview',
    };
    for (final key in data.keys) {
      if (forbidden.contains(key)) return true;
    }
    return false;
  }

  static ChatPushLocalNotification notificationFromSync({
    required String roomId,
    required WaMessageSyncBatch batch,
    required String reason,
  }) {
    if (reason == 'sync_error' || batch.messages.isEmpty) {
      return ChatPushLocalNotification(
        title: genericEncryptedTitle,
        body: reason == 'sync_error' ? genericDecryptFailedBody : genericEncryptedBody,
        roomId: roomId,
        usedGenericBody: true,
      );
    }
    final last = batch.messages.last;
    final preview = _sanitizePreview(last.message);
    if (preview.isEmpty) {
      return ChatPushLocalNotification(
        title: genericEncryptedTitle,
        body: genericEncryptedBody,
        roomId: roomId,
        usedGenericBody: true,
      );
    }
    return ChatPushLocalNotification(
      title: genericEncryptedTitle,
      body: preview,
      roomId: roomId,
    );
  }

  static String _sanitizePreview(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length <= 120) return trimmed;
    return '${trimmed.substring(0, 117)}…';
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
        syncBatch: batch,
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

  /// P9-941 — sync then show a local notification (generic when decrypt/sync fails).
  Future<DataPushFetchResult> handleRemoteMessageWithLocalNotification(
    RemoteMessage message,
  ) async {
    final result = await handleRemoteMessage(message);
    if (!result.handled || result.roomId == null) {
      return result;
    }
    final notifier = localNotifier;
    if (notifier == null) {
      return result;
    }
    final roomId = result.roomId!;
    if (result.reason == 'sync_ok' && result.syncBatch != null) {
      await notifier(
        notificationFromSync(
          roomId: roomId,
          batch: result.syncBatch!,
          reason: result.reason,
        ),
      );
    } else if (result.reason == 'sync_error' ||
        result.reason == 'sync_empty_response') {
      await notifier(
        ChatPushLocalNotification(
          title: genericEncryptedTitle,
          body: result.reason == 'sync_error'
              ? genericDecryptFailedBody
              : genericEncryptedBody,
          roomId: roomId,
          usedGenericBody: true,
        ),
      );
    }
    return result;
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
    this.syncBatch,
  });

  final bool handled;
  final String reason;
  final String? roomId;
  final int? newCursor;
  final int fetchedCount;
  final String? error;
  final WaMessageSyncBatch? syncBatch;
}
