import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'global_chat_repository.dart';

enum ChatLoad { loading, ready, error }

enum SendResult { sent, empty, signedOut, failed, polieBusy, ageRestricted }

class GlobalChatState {
  const GlobalChatState({
    this.channel = 'general',
    this.messages = const [],
    this.load = ChatLoad.loading,
    this.fromCache = false,
    this.sending = false,
    this.muted = const {},
    this.blocked = const {},
    this.serverLocked = false,
  });

  final String channel;
  final List<ChatMessage> messages;
  final ChatLoad load;

  /// Showing saved messages because the network failed.
  final bool fromCache;
  final bool sending;
  final Set<String> muted;
  final Set<String> blocked;

  /// The server answered 403 `age_restricted`: show the locked view, whatever the app thought.
  final bool serverLocked;

  /// Messages the learner should see (blocked and muted senders removed).
  List<ChatMessage> get visible => [
    for (final m in messages)
      if (!blocked.contains(m.senderId) && !muted.contains(m.senderId)) m,
  ];

  int get hiddenCount => messages.length - visible.length;

  GlobalChatState copyWith({
    String? channel,
    List<ChatMessage>? messages,
    ChatLoad? load,
    bool? fromCache,
    bool? sending,
    Set<String>? muted,
    Set<String>? blocked,
    bool? serverLocked,
  }) => GlobalChatState(
    channel: channel ?? this.channel,
    messages: messages ?? this.messages,
    load: load ?? this.load,
    fromCache: fromCache ?? this.fromCache,
    sending: sending ?? this.sending,
    muted: muted ?? this.muted,
    blocked: blocked ?? this.blocked,
    serverLocked: serverLocked ?? this.serverLocked,
  );
}

class GlobalChatController extends Notifier<GlobalChatState> {
  StreamSubscription<ChatMessage>? _live;
  int _localSeq = 0;
  String? _joined;

  GlobalChatRepository get _repo => ref.read(globalChatRepositoryProvider);
  GlobalChatLive get _socket => ref.read(globalChatLiveProvider);

  @override
  GlobalChatState build() {
    final live = _socket;
    ref.onDispose(() {
      _live?.cancel();
      live.leave(_joined ?? 'general');
    });
    scheduleMicrotask(_start);
    return const GlobalChatState();
  }

  Future<void> _start() async {
    final muted = await _repo.muted();
    final saved = await _repo.lastChannel();
    final channel = kGlobalChatChannels.contains(saved) ? saved! : 'general';
    if (!ref.mounted) return;
    state = state.copyWith(muted: muted, channel: channel);
    final me = ref.read(globalChatMeProvider);
    if (me != null) _socket.connect(me);
    await _enter(channel);
  }

  Future<void> _enter(String channel) async {
    _live?.cancel();
    _socket.join(channel);
    _joined = channel;
    _live = _socket.incoming(channel).listen(_merge);
    await refresh();
  }

  Future<void> selectChannel(String channel) async {
    if (channel == state.channel || !kGlobalChatChannels.contains(channel)) {
      return;
    }
    _socket.leave(state.channel);
    state = state.copyWith(
      channel: channel,
      messages: const [],
      load: ChatLoad.loading,
      fromCache: false,
    );
    await _repo.saveLastChannel(channel);
    await _enter(channel);
  }

  Future<void> refresh() async {
    final channel = state.channel;
    state = state.copyWith(load: ChatLoad.loading);
    try {
      final list = await _repo.fetch(channel);
      if (!ref.mounted || channel != state.channel) return;
      final pending = state.messages.where(
        (m) => m.sendState != ChatSendState.sent,
      );
      state = state.copyWith(
        messages: [...list, ...pending],
        load: ChatLoad.ready,
        fromCache: false,
      );
      unawaited(_repo.saveCache(channel, state.messages));
    } on GlobalChatAgeRestricted {
      if (!ref.mounted) return;
      // Never show cached public messages to an account the server has locked.
      state = state.copyWith(
        messages: const [],
        load: ChatLoad.ready,
        fromCache: false,
        serverLocked: true,
      );
      unawaited(_repo.saveCache(channel, const []));
    } catch (_) {
      final cached = await _repo.cached(channel);
      if (!ref.mounted || channel != state.channel) return;
      state = cached.isEmpty
          ? state.copyWith(load: ChatLoad.error)
          : state.copyWith(
              messages: cached,
              load: ChatLoad.ready,
              fromCache: true,
            );
    }
  }

  void _merge(ChatMessage m) {
    if (!ref.mounted) return;
    final i = state.messages.indexWhere(
      (e) =>
          e.id == m.id ||
          (e.sendState != ChatSendState.sent &&
              e.senderId == m.senderId &&
              e.text == m.text),
    );
    if (i >= 0) {
      if (state.messages[i].sendState == ChatSendState.sent) return;
      final next = [...state.messages]..[i] = m;
      state = state.copyWith(messages: next);
      return;
    }
    state = state.copyWith(messages: [...state.messages, m]);
  }

  Future<SendResult> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.sending) return SendResult.empty;
    final me = ref.read(globalChatMeProvider);
    if (me == null) return SendResult.signedOut;
    final channel = state.channel;
    final local = ChatMessage(
      id: 'local_${_localSeq++}_${DateTime.now().microsecondsSinceEpoch}',
      senderId: me.id,
      senderName: me.name,
      handle: me.handle,
      avatarUrl: me.avatarUrl,
      text: text,
      createdAt: DateTime.now(),
      sendState: ChatSendState.pending,
    );
    state = state.copyWith(sending: true, messages: [...state.messages, local]);
    _socket.send(channel, text, me);
    var ok = true;
    var locked = false;
    try {
      await _repo.post(channel, text);
    } on GlobalChatAgeRestricted {
      ok = false;
      locked = true;
    } catch (_) {
      ok = false;
    }
    if (!ref.mounted) return ok ? SendResult.sent : SendResult.failed;
    if (!ok) {
      state = state.copyWith(
        sending: false,
        serverLocked: locked ? true : null,
        messages: [
          for (final m in state.messages)
            if (m.id != local.id) m,
        ],
      );
      return locked ? SendResult.ageRestricted : SendResult.failed;
    }
    state = state.copyWith(
      sending: false,
      messages: [
        for (final m in state.messages)
          m.id == local.id ? m.copyWith(sendState: ChatSendState.sent) : m,
      ],
    );
    unawaited(_repo.saveCache(channel, state.messages));
    final polie = await _socket.askPolie(channel, text);
    if (!ref.mounted || polie == null) return SendResult.sent;
    if (polie.rateLimited) return SendResult.polieBusy;
    if (polie.local.isNotEmpty && channel == state.channel) {
      state = state.copyWith(messages: [...state.messages, ...polie.local]);
    }
    return SendResult.sent;
  }

  Future<void> mute(String userId) async {
    final next = {...state.muted, userId};
    state = state.copyWith(muted: next);
    await _repo.saveMuted(next);
  }

  Future<void> unmute(String userId) async {
    final next = {...state.muted}..remove(userId);
    state = state.copyWith(muted: next);
    await _repo.saveMuted(next);
  }

  Future<void> block(String userId) async {
    await _repo.block(userId);
    _socket.markBlocked(userId);
    if (ref.mounted) {
      state = state.copyWith(blocked: {...state.blocked, userId});
    }
  }

  Future<void> unblock(String userId) async {
    await _repo.unblock(userId);
    _socket.markUnblocked(userId);
    if (ref.mounted) {
      state = state.copyWith(blocked: {...state.blocked}..remove(userId));
    }
  }

  Future<String> report(String messageId, String reason) =>
      _repo.report(messageId, reason);

  Future<List<BlockedChatPerson>> loadBlocked() => _repo.blocked();
}

final globalChatControllerProvider =
    NotifierProvider.autoDispose<GlobalChatController, GlobalChatState>(
      GlobalChatController.new,
    );
