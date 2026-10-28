import 'package:dio/dio.dart';
import 'package:lingafriq/services/chat/outbox_message_queue.dart';
import 'package:lingafriq/services/push/data_push_handler.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Read receipts only for mutual 1:1 contacts (P9-944 AC3).
class WaReadReceiptPolicy {
  const WaReadReceiptPolicy._();

  static bool showReadReceipts({
    required bool isDirectMessage,
    required bool isMutualContact,
  }) {
    if (!isDirectMessage) return false;
    return isMutualContact;
  }
}

class WaDmThreadPolicy {
  const WaDmThreadPolicy({
    required this.e2eeEnabled,
    required this.requiresModeration,
  });

  final bool e2eeEnabled;
  final bool requiresModeration;

  factory WaDmThreadPolicy.fromJson(Map<String, dynamic> json) {
    return WaDmThreadPolicy(
      e2eeEnabled: json['e2ee_enabled'] == true,
      requiresModeration: json['requires_moderation'] == true,
    );
  }
}

/// Row for the private chat inbox — backed by `GET /api/wa/conversations`.
class WaPrivateConversationRow {
  const WaPrivateConversationRow({
    required this.roomId,
    required this.otherUserId,
    required this.displayName,
    this.otherGlobalId,
    required this.lastPreview,
    required this.lastAt,
    required this.unreadCount,
    required this.lastMessageFromMe,
    required this.lastMessageRead,
  });

  final String roomId;
  final int otherUserId;
  final String displayName;
  /// Public handle from WA API (`global_id` on the other participant), when present.
  final String? otherGlobalId;
  final String lastPreview;
  final DateTime? lastAt;
  final int unreadCount;
  final bool lastMessageFromMe;
  final bool lastMessageRead;
}

/// Loads inbox + sends messages via Node WA + legacy chat thread API.
class WaPrivateChatService {
  WaPrivateChatService._();

  static const _uuid = Uuid();

  static bool _realtimeHooksInstalled = false;

  /// Wires P9-909 data-push foreground sync and prepares the DM outbox (idempotent).
  static void ensureDmRealtimeInfrastructure({
    ChatPushLocalNotifier? chatPushLocalNotifier,
  }) {
    ensureFirebaseForegroundDataPushBridge(
      localNotifier: chatPushLocalNotifier,
    );
    _realtimeHooksInstalled = true;
  }

  static bool get realtimeHooksInstalled => _realtimeHooksInstalled;

  static Future<ChatOutboxMessageQueue> _outboxQueue() async {
    final prefs = await SharedPreferences.getInstance();
    return ChatOutboxMessageQueue(prefs: prefs);
  }

  static bool _isOfflineTransportError(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout;
    }
    return false;
  }

  static Future<Map<String, dynamic>?> _postWaTextPayload({
    required String recipientId,
    required String message,
    required String clientMessageId,
    bool firstDmIntro = false,
    String? replyToId,
  }) async {
    final res = await ApiService.post(
      Api.waMessages,
      data: {
        'recipientId': recipientId,
        'message': message,
        'message_type': 'text',
        if (firstDmIntro) 'first_dm_intro': true,
        'client_message_id': clientMessageId,
        if (replyToId != null && replyToId.isNotEmpty) 'reply_to_id': replyToId,
      },
    );
    final raw = res.data;
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// Drains queued WA text sends after connectivity returns (P9-909 AC1).
  static Future<void> flushTextOutbox({
    required bool Function() isOnline,
  }) async {
    final queue = await _outboxQueue();
    await queue.flush(
      isOnline: isOnline,
      send: (entry) => _postWaTextPayload(
        recipientId: entry.recipientId,
        message: entry.message,
        clientMessageId: entry.clientMessageId,
      ),
    );
  }

  static List<Map<String, dynamic>> _listFromResponse(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (raw is Map) {
      final data = raw['data'];
      if (data is List) {
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return const [];
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return const {};
  }

  /// Parse `private_{low}_{high}` room id to the peer numeric id.
  static int? otherUserIdFromRoomId(String roomId, int myNumericId) {
    final m = RegExp(r'^private_(\d+)_(\d+)$').firstMatch(roomId.trim());
    if (m == null) return null;
    final a = int.tryParse(m.group(1)!);
    final b = int.tryParse(m.group(2)!);
    if (a == null || b == null) return null;
    if (a == myNumericId) return b;
    if (b == myNumericId) return a;
    return null;
  }

  static int? _readUserId(Map<String, dynamic> user) {
    final v = user['id'] ?? user['_id'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  static WaPrivateConversationRow? _parseRow(
    Map<String, dynamic> row,
    int myNumericId,
    String? myUsername,
  ) {
    final roomId = row['_id']?.toString() ?? '';
    if (roomId.isEmpty) return null;

    final last = _asMap(row['lastMessage']);
    final participants = row['participants'];
    final List<Map<String, dynamic>> plist = participants is List
        ? participants.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const [];

    int? otherId;
    String displayName = 'Learner';
    String? otherGlobalId;

    for (final p in plist) {
      final pid = _readUserId(p);
      if (pid != null && pid != myNumericId) {
        otherId = pid;
        displayName = (p['username'] ?? p['first_name'] ?? displayName).toString();
        final fn = p['first_name']?.toString().trim() ?? '';
        final ln = p['last_name']?.toString().trim() ?? '';
        if (fn.isNotEmpty) {
          displayName = ln.isNotEmpty ? '$fn $ln' : fn;
        }
        final gid = p['global_id'] ?? p['globalId'];
        if (gid != null && gid.toString().trim().isNotEmpty) {
          otherGlobalId = gid.toString().trim();
        }
        break;
      }
    }

    otherId ??= otherUserIdFromRoomId(roomId, myNumericId);
    if (otherId == null) return null;

    final preview = (last['message'] ?? '').toString();
    final ts = last['timestamp'] ?? last['createdAt'];
    DateTime? lastAt;
    if (ts != null) {
      lastAt = DateTime.tryParse(ts.toString());
    }

    final unreadTop = row['unreadCount'];
    final unreadCount = unreadTop is int
        ? unreadTop
        : int.tryParse(unreadTop?.toString() ?? '0') ?? 0;

    final senderUsername = (last['sender_username'] ?? '').toString();
    bool fromMe = myUsername != null &&
        senderUsername.isNotEmpty &&
        senderUsername == myUsername;
    if (!fromMe) {
      final senderMongo = last['sender_id'];
      if (senderMongo is Map) {
        final sid = _readUserId(Map<String, dynamic>.from(senderMongo));
        fromMe = sid == myNumericId;
      }
    }

    final readVal = last['read'];
    final lastRead = readVal == true || readVal == 'true';

    return WaPrivateConversationRow(
      roomId: roomId,
      otherUserId: otherId,
      displayName: displayName,
      otherGlobalId: otherGlobalId,
      lastPreview: preview,
      lastAt: lastAt,
      unreadCount: unreadCount,
      lastMessageFromMe: fromMe,
      lastMessageRead: lastRead,
    );
  }

  static Future<List<WaPrivateConversationRow>> fetchConversations({
    required int myNumericUserId,
    String? myUsername,
  }) async {
    final res = await ApiService.get(Api.waConversations);
    final rows = _listFromResponse(res.data);
    final out = <WaPrivateConversationRow>[];
    for (final r in rows) {
      final parsed = _parseRow(r, myNumericUserId, myUsername);
      if (parsed != null) out.add(parsed);
    }
    return out;
  }

  static Future<List<Map<String, dynamic>>> fetchPrivateMessages({
    required String otherUserId,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await ApiService.get(
      Api.chatPrivateMessages(otherUserId),
      queryParameters: {'page': page, 'limit': limit},
    );
    final raw = res.data;
    if (raw is Map && raw['data'] is Map) {
      final data = Map<String, dynamic>.from(raw['data'] as Map);
      final docs = data['docs'];
      if (docs is List) {
        return docs.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return const [];
  }

  static Future<Map<String, dynamic>?> sendTextMessage({
    required String recipientId,
    required String message,
    String? clientMessageId,
    bool firstDmIntro = false,
    String? replyToId,
  }) async {
    final cid = clientMessageId?.trim().isNotEmpty == true
        ? clientMessageId!.trim()
        : _uuid.v4();
    try {
      return await _postWaTextPayload(
        recipientId: recipientId,
        message: message,
        clientMessageId: cid,
        firstDmIntro: firstDmIntro,
        replyToId: replyToId,
      );
    } catch (e) {
      if (!_isOfflineTransportError(e)) rethrow;
      final queue = await _outboxQueue();
      await queue.enqueue(
        recipientId: recipientId,
        message: message,
        clientMessageId: cid,
      );
      return {
        'client_message_id': cid,
        'queued_offline': true,
        'message': message,
      };
    }
  }

  static Future<String?> uploadChatMediaFile(
    String localPath, {
    String type = 'audio',
  }) async {
    final res = await ApiService.uploadFile(
      Api.mediaUpload(),
      localPath,
      additionalData: {'type': type},
    );
    final raw = res.data;
    if (raw is! Map) return null;
    final data = raw['data'];
    if (data is Map) {
      for (final k in ['url', 'file_url', 'mediaUrl', 'publicUrl']) {
        final v = data[k];
        if (v is String && v.isNotEmpty) return v;
      }
    }
    for (final k in ['url', 'file_url']) {
      final v = raw[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> sendVoiceNote({
    required String recipientId,
    required String localFilePath,
    int? durationMs,
    String? replyToId,
    String? clientMessageId,
  }) async {
    final url = await uploadChatMediaFile(localFilePath, type: 'audio');
    if (url == null || url.isEmpty) {
      throw StateError('VOICE_UPLOAD_FAILED');
    }
    final label = durationMs != null && durationMs > 0
        ? 'Voice message (${(durationMs / 1000).ceil()}s)'
        : 'Voice message';
    final res = await ApiService.post(
      Api.waMessages,
      data: {
        'recipientId': recipientId,
        'message': label,
        'message_type': 'audio',
        'file_url': url,
        if (replyToId != null && replyToId.isNotEmpty) 'reply_to_id': replyToId,
        if (clientMessageId != null && clientMessageId.isNotEmpty)
          'client_message_id': clientMessageId,
      },
    );
    final raw = res.data;
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static Future<Map<String, dynamic>?> sendGroupTextMessage({
    required String tribeId,
    required String message,
    String messageType = 'text',
    String? fileUrl,
    String? replyToId,
  }) async {
    final res = await ApiService.post(
      'chat/tribe/$tribeId',
      data: {
        'message': message,
        'message_type': messageType,
        if (fileUrl != null && fileUrl.isNotEmpty) 'file_url': fileUrl,
        if (replyToId != null && replyToId.isNotEmpty) 'reply_to_id': replyToId,
      },
    );
    final raw = res.data;
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static Future<WaDmThreadPolicy> fetchDmThreadPolicy(int peerUserId) async {
    final res = await ApiService.post(
      'api/v2/messaging-policy/dm-thread',
      data: {'peer_user_id': peerUserId},
    );
    final raw = res.data;
    if (raw is Map && raw['ok'] == true) {
      return WaDmThreadPolicy.fromJson(Map<String, dynamic>.from(raw));
    }
    return const WaDmThreadPolicy(
      e2eeEnabled: false,
      requiresModeration: false,
    );
  }

  static Future<List<Map<String, dynamic>>> toggleReaction({
    required String messageId,
    required String emoji,
  }) async {
    final res = await ApiService.post(
      'api/wa/messages/$messageId/reaction',
      data: {'emoji': emoji},
    );
    final raw = res.data;
    if (raw is Map && raw['data'] is Map) {
      final data = Map<String, dynamic>.from(raw['data'] as Map);
      final reactions = data['reactions'];
      if (reactions is List) {
        return reactions.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return const [];
  }

  static Future<bool> toggleStarMessage(String messageId) async {
    final res = await ApiService.post('api/wa/messages/$messageId/star');
    final raw = res.data;
    if (raw is Map && raw['data'] is Map) {
      return raw['data']['starred'] == true;
    }
    return false;
  }

  static Future<void> markRoomRead({required String roomId}) async {
    await ApiService.post(
      'api/wa/messages/read',
      data: {'roomId': roomId},
    );
  }

  static String? mediaUrlFromMessageMap(Map<String, dynamic> m) {
    for (final k in ['file_url', 'fileUrl', 'media_url', 'mediaUrl']) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static String messageTypeFromMap(Map<String, dynamic> m) {
    return (m['message_type'] ?? m['messageType'] ?? 'text').toString();
  }

  /// P9-929: `GET /api/v2/first-dm/state` → kind string from server payload.
  static Future<Map<String, dynamic>> fetchFirstDmState(int peerUserId) async {
    final res = await ApiService.get(
      'api/v2/first-dm/state',
      queryParameters: {'peer_user_id': peerUserId},
    );
    final raw = res.data;
    if (raw is Map && raw['state'] is Map) {
      return Map<String, dynamic>.from(raw['state'] as Map);
    }
    return const {'kind': 'none'};
  }

  static Future<void> respondFirstDmRequest({
    required int initiatorUserId,
    required String decision,
  }) async {
    await ApiService.post(
      'api/v2/first-dm/respond',
      data: {
        'initiator_user_id': initiatorUserId,
        'decision': decision,
      },
    );
  }

  /// Durable log catch-up for one device (`GET /api/wa/messages/sync`).
  static Future<WaMessageSyncBatch?> syncMessagesSinceCursor({
    required String roomId,
    required String deviceId,
    int afterSeq = 0,
  }) async {
    final res = await ApiService.get(
      'api/wa/messages/sync',
      queryParameters: {
        'roomId': roomId,
        'deviceId': deviceId,
        'afterSeq': afterSeq,
      },
    );
    final raw = res.data;
    if (raw is! Map) return null;
    final data = raw['data'];
    if (data is! Map) return null;
    final messages = data['messages'];
    final cursor = data['cursor'];
    final parsed = <WaSyncedMessage>[];
    if (messages is List) {
      for (final item in messages) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        parsed.add(
          WaSyncedMessage(
            seq: int.tryParse(m['seq']?.toString() ?? '') ?? 0,
            serverMessageId: m['serverMessageId']?.toString() ?? '',
            clientMessageId: m['clientMessageId']?.toString(),
            message: m['message']?.toString() ?? '',
            read: m['read'] == true,
          ),
        );
      }
    }
    return WaMessageSyncBatch(
      messages: parsed,
      cursor: int.tryParse(cursor?.toString() ?? '') ?? afterSeq,
    );
  }

  /// Per-device read cursor (`POST /api/wa/messages/read-cursor`).
  static Future<WaDeviceReadCursor?> pushReadCursor({
    required String roomId,
    required String deviceId,
    required int readSeq,
  }) async {
    final res = await ApiService.post(
      'api/wa/messages/read-cursor',
      data: {
        'roomId': roomId,
        'deviceId': deviceId,
        'readSeq': readSeq,
      },
    );
    final raw = res.data;
    if (raw is! Map) return null;
    final data = raw['data'];
    if (data is! Map) return null;
    return WaDeviceReadCursor(
      deliveredSeq: int.tryParse(data['deliveredSeq']?.toString() ?? '') ?? 0,
      readSeq: int.tryParse(data['readSeq']?.toString() ?? '') ?? readSeq,
    );
  }

  /// Normalized `private_low_high` room id (matches Node `normalizePrivateRoomId`).
  static String privateRoomIdForNumericUsers(int a, int b) {
    final low = a < b ? a : b;
    final high = a < b ? b : a;
    return 'private_${low}_$high';
  }

  /// Updates typing presence for DM rooms (`POST /chat/typing`).
  static Future<void> setTyping({
    required String roomId,
    required bool isTyping,
  }) async {
    await ApiService.post(
      Api.chatTyping,
      data: {
        'roomId': roomId,
        'isTyping': isTyping,
      },
    );
  }

  /// Whether **another participant** in the room is typing (`GET /chat/typing/:roomId`, `othersTyping` field).
  static Future<bool> fetchOthersTyping(String roomId) async {
    try {
      final res = await ApiService.get(Api.chatTypingForRoom(roomId));
      final raw = res.data;
      if (raw is! Map) return false;
      final data = raw['data'];
      if (data is Map && data['othersTyping'] is bool) {
        return data['othersTyping'] as bool;
      }
      if (data is List) {
        return data.isNotEmpty;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

class WaSyncedMessage {
  const WaSyncedMessage({
    required this.seq,
    required this.serverMessageId,
    this.clientMessageId,
    required this.message,
    required this.read,
  });

  final int seq;
  final String serverMessageId;
  final String? clientMessageId;
  final String message;
  final bool read;
}

class WaMessageSyncBatch {
  const WaMessageSyncBatch({required this.messages, required this.cursor});

  final List<WaSyncedMessage> messages;
  final int cursor;
}

class WaDeviceReadCursor {
  const WaDeviceReadCursor({required this.deliveredSeq, required this.readSeq});

  final int deliveredSeq;
  final int readSeq;
}
