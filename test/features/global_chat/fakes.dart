import 'dart:async';

import 'package:lingafriq/features/global_chat/global_chat_repository.dart';

class FakeRepo implements GlobalChatRepository {
  FakeRepo({
    Map<String, List<ChatMessage>>? server,
    Map<String, List<ChatMessage>>? cache,
    this.last,
    Set<String>? muted,
  }) : server = server ?? {},
       cacheStore = cache ?? {},
       mutedStore = muted ?? {};

  final Map<String, List<ChatMessage>> server;
  final Map<String, List<ChatMessage>> cacheStore;
  final Set<String> mutedStore;
  String? last;
  bool fetchFails = false;
  bool postFails = false;
  Completer<void>? postGate;
  Completer<List<ChatMessage>>? fetchGate;
  final posts = <(String, String)>[];
  final reports = <(String, String)>[];
  final blockedIds = <String>[];
  final unblockedIds = <String>[];
  List<BlockedChatPerson> blockedList = const [];
  int fetchCount = 0;

  @override
  Future<List<ChatMessage>> fetch(String channel) async {
    fetchCount++;
    if (fetchGate != null) return fetchGate!.future;
    if (fetchFails) throw StateError('offline');
    return server[channel] ?? const [];
  }

  @override
  Future<void> post(String channel, String text) async {
    posts.add((channel, text));
    if (postGate != null) await postGate!.future;
    if (postFails) throw StateError('offline');
  }

  @override
  Future<String> report(String messageId, String reason) async {
    reports.add((messageId, reason));
    return 'R-42';
  }

  @override
  Future<void> block(String userId) async => blockedIds.add(userId);

  @override
  Future<void> unblock(String userId) async => unblockedIds.add(userId);

  @override
  Future<List<BlockedChatPerson>> blocked() async => blockedList;

  @override
  Future<List<ChatMessage>> cached(String channel) async =>
      cacheStore[channel] ?? const [];

  @override
  Future<void> saveCache(String channel, List<ChatMessage> messages) async =>
      cacheStore[channel] = messages;

  @override
  Future<String?> lastChannel() async => last;

  @override
  Future<void> saveLastChannel(String channel) async => last = channel;

  @override
  Future<Set<String>> muted() async => {...mutedStore};

  @override
  Future<void> saveMuted(Set<String> ids) async => mutedStore
    ..clear()
    ..addAll(ids);
}

class FakeLive implements GlobalChatLive {
  final joined = <String>[];
  final left = <String>[];
  final sent = <(String, String)>[];
  final marked = <String>[];
  final unmarked = <String>[];
  ChatMe? connectedAs;
  bool connected = true;
  PolieOutcome? polie;
  final _streams = <String, StreamController<ChatMessage>>{};

  void push(String channel, ChatMessage m) => _streams[channel]?.add(m);

  @override
  void connect(ChatMe me) => connectedAs = me;
  @override
  void join(String channel) => joined.add(channel);
  @override
  void leave(String channel) => left.add(channel);
  @override
  bool get isConnected => connected;
  @override
  bool send(String channel, String text, ChatMe me) {
    if (!connected) return false;
    sent.add((channel, text));
    return true;
  }

  @override
  Stream<ChatMessage> incoming(String channel) =>
      (_streams[channel] ??= StreamController<ChatMessage>.broadcast()).stream;

  @override
  Future<PolieOutcome?> askPolie(String channel, String text) async =>
      text.toLowerCase().contains('@polie') ? polie : null;

  @override
  void markBlocked(String userId) => marked.add(userId);
  @override
  void markUnblocked(String userId) => unmarked.add(userId);
}

final t0 = DateTime.now();

ChatMessage msg(
  String id,
  String sender,
  String name,
  String text, {
  String? handle,
  int minsAgo = 5,
  bool flagged = false,
}) => ChatMessage(
  id: id,
  senderId: sender,
  senderName: name,
  handle: handle,
  text: text,
  createdAt: t0.subtract(Duration(minutes: minsAgo)),
  flagged: flagged,
);

const me = ChatMe(id: 'me', name: 'Tope', handle: 'tope');
