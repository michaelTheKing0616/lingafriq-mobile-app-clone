import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/chat_socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/services/polie_social_chat_helper.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Public channels. Language names are native names and are not translated.
const kGlobalChatChannels = [
  'general',
  'yoruba',
  'hausa',
  'igbo',
  'pidgin',
  'swahili',
  'zulu',
];

enum ChatSendState { sent, pending, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.handle,
    this.avatarUrl,
    this.createdAt,
    this.flagged = false,
    this.sendState = ChatSendState.sent,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String? handle;
  final String? avatarUrl;
  final String text;
  final DateTime? createdAt;
  final bool flagged;
  final ChatSendState sendState;

  bool get isPolie => handle?.toLowerCase() == 'polie_bot';

  ChatMessage copyWith({ChatSendState? sendState, String? id}) => ChatMessage(
    id: id ?? this.id,
    senderId: senderId,
    senderName: senderName,
    handle: handle,
    avatarUrl: avatarUrl,
    text: text,
    createdAt: createdAt,
    flagged: flagged,
    sendState: sendState ?? this.sendState,
  );

  /// Parses REST and socket payloads (several historical shapes).
  static ChatMessage? fromJson(Map<String, dynamic> m) {
    final s = m['sender_id'] is Map
        ? Map<String, dynamic>.from(m['sender_id'] as Map)
        : const <String, dynamic>{};
    final text = (m['message'] ?? m['body'] ?? m['text'] ?? '').toString();
    if (text.trim().isEmpty) return null;
    final senderId =
        (s['id'] ??
                m['userId'] ??
                (m['sender_id'] is Map ? null : m['sender_id']) ??
                '')
            .toString();
    final name =
        (s['username'] ?? s['first_name'] ?? m['username'] ?? m['sender'] ?? '')
            .toString();
    final handle = (s['global_id'] ?? m['global_id'])?.toString();
    final avatar = s['avatar_url'] ?? s['avatar'] ?? m['avatar'];
    final ts = (m['createdAt'] ?? m['timestamp'])?.toString();
    final id =
        (m['_id'] ??
                m['id'] ??
                m['clientMessageId'] ??
                '${senderId}_${ts ?? ''}_${text.hashCode}')
            .toString();
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: name,
      handle: (handle == null || handle.isEmpty) ? null : handle,
      avatarUrl: avatar is String && avatar.isNotEmpty ? avatar : null,
      text: text,
      createdAt: ts == null ? null : DateTime.tryParse(ts),
      flagged: m['flagged_toxic'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'message': text,
    'sender_id': {
      'id': senderId,
      'username': senderName,
      'global_id': ?handle,
      'avatar_url': ?avatarUrl,
    },
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    'flagged_toxic': flagged,
  };
}

class BlockedChatPerson {
  const BlockedChatPerson(this.id, this.name);
  final String id;
  final String name;
}

/// Signed-in learner as Global chat needs it.
class ChatMe {
  const ChatMe({
    required this.id,
    required this.name,
    this.handle,
    this.avatarUrl,
  });
  final String id;
  final String name;
  final String? handle;
  final String? avatarUrl;
}

final globalChatMeProvider = Provider<ChatMe?>((ref) {
  final u = ref.watch(userProvider);
  if (u == null) return null;
  return ChatMe(
    id: u.id.toString(),
    name: u.username,
    handle: u.global_id,
    avatarUrl: u.avatar,
  );
});

/// All REST + on-device storage for Global chat.
abstract class GlobalChatRepository {
  Future<List<ChatMessage>> fetch(String channel);
  Future<void> post(String channel, String text);
  Future<String> report(String messageId, String reason);
  Future<void> block(String userId);
  Future<void> unblock(String userId);
  Future<List<BlockedChatPerson>> blocked();
  Future<List<ChatMessage>> cached(String channel);
  Future<void> saveCache(String channel, List<ChatMessage> messages);
  Future<String?> lastChannel();
  Future<void> saveLastChannel(String channel);
  Future<Set<String>> muted();
  Future<void> saveMuted(Set<String> ids);
}

/// What Polie's follow-up produced for a send.
class PolieOutcome {
  const PolieOutcome({this.rateLimited = false, this.local = const []});
  final bool rateLimited;
  final List<ChatMessage> local;
}

/// Realtime socket + Polie for Global chat.
abstract class GlobalChatLive {
  void connect(ChatMe me);
  void join(String channel);
  void leave(String channel);
  bool get isConnected;

  /// Emits on the socket when connected; returns whether it was emitted.
  bool send(String channel, String text, ChatMe me);

  /// Messages arriving on [channel]; may repeat earlier ones (callers dedupe).
  Stream<ChatMessage> incoming(String channel);

  /// Polie reply when the text mentions @Polie, otherwise null.
  Future<PolieOutcome?> askPolie(String channel, String text);

  void markBlocked(String userId);
  void markUnblocked(String userId);
}

String _room(String channel) => 'global_$channel';

class ApiGlobalChatRepository implements GlobalChatRepository {
  static const _prefix = 'global_chat_cache_';
  static const _mutedKey = 'global_chat_muted_ids';

  List<ChatMessage> _parse(Object? raw) {
    Object? list = raw;
    if (raw is Map) {
      list = raw['data'] ?? raw['messages'] ?? raw['results'];
    }
    if (list is! List) return const [];
    return [
      for (final e in list)
        if (e is Map) ?ChatMessage.fromJson(Map<String, dynamic>.from(e)),
    ];
  }

  @override
  Future<List<ChatMessage>> fetch(String channel) async {
    final r = await ApiService.get(
      Api.chatGlobal,
      queryParameters: {'channel': channel, 'limit': 50},
    );
    if (r.statusCode != 200) {
      throw StateError('global chat ${r.statusCode}');
    }
    return _parse(r.data);
  }

  @override
  Future<void> post(String channel, String text) async {
    final r = await ApiService.post(
      Api.chatGlobal,
      data: {'message': text, 'channel': channel},
    );
    final c = r.statusCode ?? 0;
    if (c < 200 || c >= 300) throw StateError('send $c');
  }

  @override
  Future<String> report(String messageId, String reason) async {
    final r = await ApiService.post(
      'chat/messages/$messageId/report',
      data: {'reason': reason},
    );
    final body = r.data;
    final ref = body is Map ? body['referenceId']?.toString() ?? '' : '';
    if (ref.isEmpty) throw StateError('missing reference');
    return ref;
  }

  @override
  Future<void> block(String userId) =>
      ApiService.post(Api.connectionBlock(), data: {'targetUserId': userId});

  @override
  Future<void> unblock(String userId) =>
      ApiService.post(Api.connectionUnblock(), data: {'targetUserId': userId});

  @override
  Future<List<BlockedChatPerson>> blocked() async {
    final r = await ApiService.get(Api.connectionsBlocked);
    final body = r.data;
    final rows = body is Map && body['data'] is List
        ? body['data'] as List
        : const [];
    final out = <BlockedChatPerson>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final u = row['connected_user_id'];
      final id = u is Map ? (u['_id'] ?? u['id'] ?? '').toString() : '$u';
      final name = u is Map ? (u['username'] ?? '').toString() : '';
      if (id.isNotEmpty && id != 'null') out.add(BlockedChatPerson(id, name));
    }
    return out;
  }

  Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  @override
  Future<List<ChatMessage>> cached(String channel) async {
    final raw = (await _p).getString('$_prefix$channel');
    if (raw == null || raw.isEmpty) return const [];
    try {
      return _parse(jsonDecode(raw));
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveCache(String channel, List<ChatMessage> messages) async {
    final keep = messages
        .where((m) => m.sendState == ChatSendState.sent)
        .toList();
    final tail = keep.length > 120 ? keep.sublist(keep.length - 120) : keep;
    await (await _p).setString(
      '$_prefix$channel',
      jsonEncode([for (final m in tail) m.toJson()]),
    );
  }

  @override
  Future<String?> lastChannel() async =>
      (await _p).getString('${_prefix}last_channel');

  @override
  Future<void> saveLastChannel(String channel) async =>
      (await _p).setString('${_prefix}last_channel', channel);

  @override
  Future<Set<String>> muted() async =>
      ((await _p).getStringList(_mutedKey) ?? const []).toSet();

  @override
  Future<void> saveMuted(Set<String> ids) async =>
      (await _p).setStringList(_mutedKey, ids.toList()..sort());
}

class SocketGlobalChatLive implements GlobalChatLive {
  SocketGlobalChatLive(this._ref);
  final Ref _ref;

  ChatSocketNotifier get _n => _ref.read(chatSocketProvider.notifier);

  @override
  void connect(ChatMe me) => _n.connect(me.id, me.name, globalId: me.handle);

  @override
  void join(String channel) => _n.joinRoom(_room(channel));

  @override
  void leave(String channel) => _n.leaveRoom(_room(channel));

  @override
  bool get isConnected => _ref.read(chatSocketProvider).isConnected;

  @override
  bool send(String channel, String text, ChatMe me) {
    if (!isConnected) return false;
    _n.sendMessage(_room(channel), text, me.id, me.name, null, me.handle);
    return true;
  }

  @override
  Stream<ChatMessage> incoming(String channel) {
    late final StreamController<ChatMessage> c;
    ProviderSubscription<ChatSocketState>? sub;
    c = StreamController<ChatMessage>(
      onListen: () {
        sub = _ref.listen<ChatSocketState>(chatSocketProvider, (_, _) {
          for (final m in _n.messagesForRoom(_room(channel))) {
            final msg = ChatMessage.fromJson(m);
            if (msg != null) c.add(msg);
          }
        });
      },
      onCancel: () => sub?.close(),
    );
    return c.stream;
  }

  @override
  Future<PolieOutcome?> askPolie(String channel, String text) async {
    final out = await deliverPolieAfterSendWith(
      read: _ref.read,
      userMessage: text,
      socketRoom: _room(channel),
      rateLimitScope: 'g_$channel',
      chatContext: 'Global chat #$channel',
    );
    if (out == null) return null;
    return PolieOutcome(
      rateLimited: out.rateLimited,
      local: [
        for (final m in out.localAppend ?? const <Map<String, dynamic>>[])
          ?ChatMessage.fromJson(m),
      ],
    );
  }

  @override
  void markBlocked(String userId) => _n.markUserBlocked(userId);

  @override
  void markUnblocked(String userId) => _n.markUserUnblocked(userId);
}

final globalChatRepositoryProvider = Provider<GlobalChatRepository>(
  (ref) => ApiGlobalChatRepository(),
);

final globalChatLiveProvider = Provider<GlobalChatLive>(
  (ref) => SocketGlobalChatLive(ref),
);
