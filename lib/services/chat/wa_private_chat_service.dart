import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/api_service.dart';

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
    return b;
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
  }) async {
    final res = await ApiService.post(
      Api.waMessages,
      data: {
        'recipientId': recipientId,
        'message': message,
        'message_type': 'text',
      },
    );
    final raw = res.data;
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}
