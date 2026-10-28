import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../models/profile_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/chat/chat_room_learning_service.dart';
import '../../services/chat/mls_session_service.dart';
import '../../services/chat/wa_private_chat_service.dart';
import '../../services/socket/socket_event_schemas.dart';
import '../../utils/api.dart';
import '../../utils/api_service.dart';
import '../../widgets/chat/language_status_chip.dart';
import '../../widgets/chat/tone_lens_sheet.dart';
import '../../widgets/chat/voice_note_recorder.dart';
import '../../widgets/chat/voice_note_transcript.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/polie_mention_handler.dart';
import '../../services/polie_rate_limiter.dart';
import '../../services/chat/polie_dm_local_store.dart';
import '../../services/env_config.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../utils/pan_african_design_system.dart' show PanAfricanSpacing;
import '../../utils/transport_error_policy.dart';
import '../../widgets/griot/griot_widgets.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'contact_info_screen.dart';
import 'first_dm_prompt_sheet.dart';
import 'report_block_sheet.dart';

/// Private DM thread — loads history from `GET /chat/private/:otherUserId` and
/// sends via `POST /api/wa/messages`.
class PrivateChatScreen extends ConsumerStatefulWidget {
  const PrivateChatScreen({
    super.key,
    this.otherUserId,
    this.otherDisplayName,
    this.contact,
  }) : assert(
         otherUserId != null || contact != null,
         'Provide otherUserId or contact map with id/userId/otherUserId',
       );

  final int? otherUserId;
  final String? otherDisplayName;
  final dynamic contact;

  @override
  ConsumerState<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends ConsumerState<PrivateChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _typingController;
  final List<_ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _loadError;

  Timer? _typingPollTimer;
  Timer? _typingDebounce;
  Timer? _typingIdleTimer;
  bool _peerTyping = false;
  String? _dmRoomId;
  io.Socket? _socket;
  bool _socketReady = false;
  bool _socketConnecting = false;
  String? _myMongoId;
  bool _typingListenerAttached = false;
  bool _inboundRequestSheetShown = false;
  String _firstDmKind = 'accepted';
  bool _requiresModeration = false;
  MlsSessionSnapshot? _mlsSnapshot;
  final MlsSessionService _mlsSession = MlsSessionService();
  _ChatMessage? _replyTarget;
  final GlobalKey<VoiceNoteRecorderState> _voiceNoteKey =
      GlobalKey<VoiceNoteRecorderState>();
  final AudioPlayer _voicePlayer = AudioPlayer();
  String? _playingVoiceId;
  ChatRoomLearningService? _learningService;
  ChatLearningSurfacePolicy _learningPolicy =
      ChatLearningSurfacePolicy.hiddenForMinorOrUnknownAge;
  List<ChatLanguageStatusEntry> _peerLanguageStatuses = const [];
  final Map<String, VoiceNoteTranscriptController> _transcriptControllers = {};
  bool _messageCheckRunning = false;

  static String _socketOriginFromBaseUrl(String baseUrl) {
    final raw = baseUrl.trim();
    if (raw.isEmpty) return raw;
    final uri = Uri.parse(
      raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw,
    );
    if (uri.scheme.isEmpty) return raw;
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portPart';
  }

  static String? _mongoIdFromJwt(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
      final payload = jsonDecode(utf8.decode(payloadBytes));
      if (payload is! Map) return null;
      final v = payload['_id'] ?? payload['sub'] ?? payload['userId'];
      final s = v?.toString();
      if (s == null || s.trim().isEmpty) return null;
      return s.trim();
    } catch (_) {
      return null;
    }
  }

  int? get _peerNumericId {
    if (widget.otherUserId != null) return widget.otherUserId;
    final c = widget.contact;
    if (c is Map) {
      final v = c['otherUserId'] ?? c['userId'] ?? c['id'];
      return int.tryParse(v?.toString() ?? '');
    }
    return null;
  }

  String get _contactName {
    if (widget.otherDisplayName != null &&
        widget.otherDisplayName!.trim().isNotEmpty) {
      return widget.otherDisplayName!.trim();
    }
    final c = widget.contact;
    if (c is Map) return c['name']?.toString() ?? 'Contact';
    if (c is String) return c;
    try {
      return (c as dynamic).username?.toString() ?? 'Contact';
    } catch (_) {
      return 'Contact';
    }
  }

  String get _contactInitial {
    final c = widget.contact;
    if (c is Map && c['initial'] != null) {
      return c['initial'].toString();
    }
    return _contactName.isNotEmpty ? _contactName[0].toUpperCase() : '?';
  }

  bool get _contactOnline {
    final c = widget.contact;
    if (c is Map) return c['isOnline'] == true;
    return false;
  }

  bool get _isMutualContact {
    if (_firstDmKind == 'accepted') return true;
    final c = widget.contact;
    if (c is Map && c['isMutualContact'] == true) return true;
    return false;
  }

  bool get _showReadReceipts => WaReadReceiptPolicy.showReadReceipts(
        isDirectMessage: true,
        isMutualContact: _isMutualContact,
      );

  @override
  void initState() {
    super.initState();
    WaPrivateChatService.ensureDmRealtimeInfrastructure();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMessages());

    // Listen once: if the user profile arrives after the chat loads, enable typing support.
    ref.listen<ProfileModel?>(userProvider, (prev, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ensureTypingPresence();
      });
    });
  }

  Future<void> _loadMessages() async {
    final peer = _peerNumericId;
    if (peer == null) {
      setState(() {
        _loading = false;
        _loadError = 'Missing peer user id for this chat.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final raw = await WaPrivateChatService.fetchPrivateMessages(
        otherUserId: peer.toString(),
      );
      final me = ref.read(userProvider);
      final list = <_ChatMessage>[];
      for (final m in raw) {
        list.add(_messageFromApi(m, me));
      }
      if (me != null) {
        final overlays = await PolieDmLocalStore.load(me.id, peer);
        for (final o in overlays) {
          list.add(
            _ChatMessage(
              text: o.text,
              isMe: false,
              time: o.timeLabel,
              isRead: true,
              isFromPolie: true,
              sortMs: o.atMs,
            ),
          );
        }
      }
      list.sort((a, b) => a.sortMs.compareTo(b.sortMs));
      if (mounted) {
        setState(() {
          _messages
            ..clear()
            ..addAll(list);
          _loading = false;
        });
        _scrollToBottom();
        _ensureTypingPresence();
        unawaited(_refreshFirstDmState(showInboundSheet: true));
        unawaited(_refreshMessagingPolicy());
        unawaited(_refreshLearningSurfaces());
        final room = _dmRoomId;
        if (room != null) {
          unawaited(WaPrivateChatService.markRoomRead(roomId: room));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e is DioException
            ? TransportErrorPolicy.toUserMessage(e)
            : 'Could not load messages.';
      });
    }
  }

  _ChatMessage _messageFromApi(Map<String, dynamic> m, ProfileModel? me) {
    final text = (m['message'] ?? '').toString();
    final ts = m['timestamp'] ?? m['createdAt'];
    DateTime? dt;
    if (ts != null) dt = DateTime.tryParse(ts.toString());
    final timeStr = dt != null
        ? TimeOfDay.fromDateTime(dt.toLocal()).format(context)
        : '';

    var isMe = false;
    final sender = m['sender_id'];
    if (sender is Map && me != null) {
      final id = sender['id'];
      if (id is int) isMe = id == me.id;
    }
    if (!isMe && me != null) {
      isMe = (m['sender_username']?.toString() ?? '') == me.username;
    }

    final read = m['read'] == true;
    final sortMs = dt?.millisecondsSinceEpoch ?? 0;
    final id = m['_id']?.toString() ?? m['id']?.toString() ?? '';
    final type = WaPrivateChatService.messageTypeFromMap(m);
    final audioUrl = type == 'audio'
        ? WaPrivateChatService.mediaUrlFromMessageMap(m)
        : null;
    final reactionsRaw = m['reactions'];
    final reactions = <String, int>{};
    if (reactionsRaw is List) {
      for (final r in reactionsRaw) {
        if (r is! Map) continue;
        final emoji = r['emoji']?.toString();
        if (emoji == null || emoji.isEmpty) continue;
        reactions[emoji] = (reactions[emoji] ?? 0) + 1;
      }
    }
    final replySnippet = m['reply_to'] is Map
        ? (m['reply_to'] as Map)['message']?.toString()
        : null;
    return _ChatMessage(
      id: id,
      text: text,
      isMe: isMe,
      time: timeStr,
      isRead: read,
      sortMs: sortMs,
      messageType: type,
      audioUrl: audioUrl,
      reactions: reactions,
      replySnippet: replySnippet,
    );
  }

  Future<void> _refreshMessagingPolicy() async {
    final peer = _peerNumericId;
    final me = ref.read(userProvider);
    if (peer == null || me == null || !mounted) return;
    try {
      final snapshot = await _mlsSession.bootstrapDirectMessage(
        peerUserId: peer,
        myNumericUserId: me.id,
      );
      if (mounted) {
        setState(() {
          _mlsSnapshot = snapshot;
          _requiresModeration = snapshot.requiresModeration;
        });
      }
    } catch (_) {}
  }

  Future<void> _sendDmText({
    required int peer,
    required String message,
    String? replyToId,
    bool firstDmIntro = false,
  }) async {
    var snapshot = _mlsSnapshot;
    if (snapshot == null) {
      await _refreshMessagingPolicy();
      snapshot = _mlsSnapshot;
    }
    if (snapshot != null && snapshot.e2eeActive) {
      await _mlsSession.sendDirectMessage(
        snapshot: snapshot,
        recipientId: peer.toString(),
        message: message,
        replyToId: replyToId,
        firstDmIntro: firstDmIntro,
      );
      return;
    }
    await WaPrivateChatService.sendTextMessage(
      recipientId: peer.toString(),
      message: message,
      firstDmIntro: firstDmIntro,
      replyToId: replyToId,
    );
  }

  Future<void> _acknowledgeKeyChange() async {
    final key = _mlsSnapshot?.threadKey;
    if (key == null) return;
    final updated = await _mlsSession.acknowledgeKeyChange(key);
    if (!mounted) return;
    setState(() => _mlsSnapshot = updated);
    await _loadMessages();
  }

  List<Widget> _buildE2eeStatusStrip(ColorScheme cs) {
    final snapshot = _mlsSnapshot;
    if (snapshot == null) return const [];

    switch (snapshot.uiState) {
      case MlsEncryptionUiState.encrypted:
        return [
          Semantics(
            label: snapshot.accessibilityLabel(snapshot.uiState),
            child: Material(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    SizedBox(width: PanAfricanSpacing.md),
                    Icon(Icons.lock_rounded, color: cs.primary, size: 20),
                    SizedBox(width: PanAfricanSpacing.xs),
                    Expanded(
                      child: Text(
                        kE2eeOnLabel,
                        style: ModernGriotTypography.labelSmall(
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];
      case MlsEncryptionUiState.keyChanged:
        return [
          Material(
            color: cs.errorContainer,
            child: Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    kE2eeKeyChangeTitle,
                    style: ModernGriotTypography.titleSmall(
                      color: cs.onErrorContainer,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  Text(
                    kE2eeKeyChangeBody,
                    style: ModernGriotTypography.bodySmall(
                      color: cs.onErrorContainer,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Semantics(
                    button: true,
                    label: 'Continue after encryption key change',
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _acknowledgeKeyChange,
                        child: const Text('Continue'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];
      case MlsEncryptionUiState.recoveryFailed:
        return [
          Material(
            color: cs.errorContainer,
            child: ListTile(
              minVerticalPadding: 12,
              leading: Icon(Icons.key_off_rounded, color: cs.onErrorContainer),
              title: Text(
                kE2eeRecoveryLost,
                style: ModernGriotTypography.labelSmall(
                  color: cs.onErrorContainer,
                ),
              ),
            ),
          ),
        ];
      case MlsEncryptionUiState.notEncryptedMinor:
        return const [];
    }
  }

  void _ensureTypingPresence() {
    if (_typingListenerAttached) return;
    final me = ref.read(userProvider);
    final peer = _peerNumericId;
    if (me == null || peer == null) return;
    _dmRoomId = WaPrivateChatService.privateRoomIdForNumericUsers(me.id, peer);
    _typingListenerAttached = true;
    _messageController.addListener(_onComposerTypingChanged);
    unawaited(_ensureSocket());
    _startTypingPollingIfNeeded();
  }

  void _startTypingPollingIfNeeded() {
    // When socket is connected, we rely on push events and avoid polling.
    if (_socketReady) return;
    _typingPollTimer?.cancel();
    _typingPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_syncPeerTyping());
    });
  }

  void _stopTypingPolling() {
    _typingPollTimer?.cancel();
    _typingPollTimer = null;
  }

  void _emitSocketPayload(String event, Map<String, dynamic> body) {
    final wrapped = wrapOutboundSocketPayload(body);
    _socket?.emit(event, wrapped);
  }

  Future<void> _ensureSocket() async {
    if (_socketReady || _socketConnecting) return;
    final roomId = _dmRoomId;
    if (roomId == null) return;
    _socketConnecting = true;

    // Token is required by backend socket auth middleware.
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('auth_token') ?? prefs.getString('access_token');
    if (token == null || token.trim().isEmpty) {
      _socketConnecting = false;
      return;
    }

    _myMongoId ??= _mongoIdFromJwt(token);

    final origin = _socketOriginFromBaseUrl(EnvConfig.backendBaseUrl);
    if (origin.trim().isEmpty) {
      _socketConnecting = false;
      return;
    }

    final socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket.onConnect((_) {
      _socketReady = true;
      _socketConnecting = false;
      _stopTypingPolling();
      // Always re-join on reconnect (Socket.IO can reconnect silently).
      final currentRoom = _dmRoomId;
      if (currentRoom != null) {
        _emitSocketPayload('join_room', {'room': currentRoom});
      }
      unawaited(
        WaPrivateChatService.flushTextOutbox(isOnline: () => _socketReady),
      );
      // On connect, do a quick sync so UI feels immediate.
      unawaited(_syncPeerTyping());
    });

    socket.onDisconnect((_) {
      _socketReady = false;
      _socketConnecting = false;
      _startTypingPollingIfNeeded();
    });

    socket.onConnectError((dynamic _) {
      _socketReady = false;
      _socketConnecting = false;
      _startTypingPollingIfNeeded();
    });

    socket.on('chat:typing_indicator', (dynamic payload) {
      if (!mounted) return;
      final p = validateInboundSocketEvent('chat:typing_indicator', payload);
      if (p == null) return;
      final pRoom = p['roomId']?.toString();
      if (pRoom == null || pRoom != roomId) return;
      final from = p['userId']?.toString();
      if (_myMongoId != null && from != null && from == _myMongoId) {
        return; // ignore our own typing echo
      }
      final isTyping = p['isTyping'] == true;
      if (isTyping == _peerTyping) return;
      setState(() => _peerTyping = isTyping);
    });

    socket.on('wa:new_message', (dynamic payload) {
      if (!mounted) return;
      final p = validateInboundSocketEvent('wa:new_message', payload);
      if (p == null) return;
      if (p['roomId']?.toString() != roomId) return;
      final me = ref.read(userProvider);
      setState(() {
        _messages.add(_messageFromApi(p, me));
        _messages.sort((a, b) => a.sortMs.compareTo(b.sortMs));
      });
      _scrollToBottom();
    });

    socket.on('wa:reaction_changed', (dynamic payload) {
      if (!mounted) return;
      final p = validateInboundSocketEvent('wa:reaction_changed', payload);
      if (p == null) return;
      if (p['roomId']?.toString() != roomId) return;
      final messageId = p['messageId']?.toString();
      final emoji = p['emoji']?.toString();
      if (messageId == null || emoji == null) return;
      setState(() {
        for (var i = 0; i < _messages.length; i++) {
          if (_messages[i].id != messageId) continue;
          final next = Map<String, int>.from(_messages[i].reactions);
          next[emoji] = (next[emoji] ?? 0) + 1;
          _messages[i] = _messages[i].copyWith(reactions: next);
          break;
        }
      });
    });

    socket.on('wa:messages_read', (dynamic payload) {
      if (!mounted || !_showReadReceipts) return;
      final p = validateInboundSocketEvent('wa:messages_read', payload);
      if (p == null) return;
      if (p['roomId']?.toString() != roomId) return;
      setState(() {
        for (var i = 0; i < _messages.length; i++) {
          if (_messages[i].isMe) {
            _messages[i] = _messages[i].copyWith(isRead: true);
          }
        }
      });
    });

    _socket = socket;
    socket.connect();
  }

  Future<void> _syncPeerTyping() async {
    final id = _dmRoomId;
    if (id == null || !mounted) return;
    final v = await WaPrivateChatService.fetchOthersTyping(id);
    if (!mounted || v == _peerTyping) return;
    setState(() => _peerTyping = v);
  }

  void _onComposerTypingChanged() {
    final room = _dmRoomId;
    if (room == null) return;
    _typingDebounce?.cancel();
    final text = _messageController.text;
    if (text.trim().isEmpty) {
      _typingIdleTimer?.cancel();
      unawaited(WaPrivateChatService.setTyping(roomId: room, isTyping: false));
      _socket?.emit('chat:typing', wrapOutboundSocketPayload({'roomId': room, 'isTyping': false}));
      return;
    }
    _typingDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(WaPrivateChatService.setTyping(roomId: room, isTyping: true));
      _socket?.emit('chat:typing', wrapOutboundSocketPayload({'roomId': room, 'isTyping': true}));
    });
    _typingIdleTimer?.cancel();
    _typingIdleTimer = Timer(const Duration(seconds: 4), () {
      unawaited(WaPrivateChatService.setTyping(roomId: room, isTyping: false));
      _socket?.emit('chat:typing', wrapOutboundSocketPayload({'roomId': room, 'isTyping': false}));
    });
  }

  @override
  void dispose() {
    _stopTypingPolling();
    _typingDebounce?.cancel();
    _typingIdleTimer?.cancel();
    if (_dmRoomId != null) {
      unawaited(
        WaPrivateChatService.setTyping(roomId: _dmRoomId!, isTyping: false),
      );
      _emitSocketPayload('chat:typing', {'roomId': _dmRoomId!, 'isTyping': false});
      _socket?.emit('leave_room', {'room': _dmRoomId!});
    }
    if (_typingListenerAttached) {
      _messageController.removeListener(_onComposerTypingChanged);
    }
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    try {
      _socket?.disconnect();
    } catch (_) {}
    try {
      _socket?.dispose();
    } catch (_) {}
    unawaited(_voicePlayer.dispose());
    for (final c in _transcriptControllers.values) {
      c.dispose();
    }
    _transcriptControllers.clear();
    super.dispose();
  }

  String _learningLanguageCode(ProfileModel? me) {
    final fromProfile = me?.learningLanguage?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    return 'yo';
  }

  bool get _learningUiEnabled =>
      _learningPolicy == ChatLearningSurfacePolicy.available &&
      _learningService != null;

  Future<void> _refreshLearningSurfaces() async {
    final me = ref.read(userProvider);
    final peer = _peerNumericId;
    if (me == null || peer == null || !mounted) return;
    final service = ChatRoomLearningService(
      languageCode: _learningLanguageCode(me),
      learnerUserId: me.id.toString(),
    );
    final policy = await service.resolveSurfacePolicy();
    var statuses = const <ChatLanguageStatusEntry>[];
    if (policy == ChatLearningSurfacePolicy.available) {
      statuses = await service.fetchPeerLanguageStatus(peer);
    }
    if (!mounted) return;
    setState(() {
      _learningService = service;
      _learningPolicy = policy;
      _peerLanguageStatuses = statuses;
    });
  }

  bool _messageE2eeActive(_ChatMessage msg) {
    final snapshot = _mlsSnapshot;
    if (snapshot == null || !snapshot.e2eeActive) return false;
    return _mlsSession.messageReadableOnDevice(
      snapshot: snapshot,
      messageSortMs: msg.sortMs,
    );
  }

  VoiceNoteTranscriptController _transcriptControllerFor(_ChatMessage msg) {
    final existing = _transcriptControllers[msg.id];
    if (existing != null) return existing;
    final me = ref.read(userProvider);
    final controller = VoiceNoteTranscriptController(
      messageId: msg.id,
      languageCode: _learningLanguageCode(me),
      e2ee: _messageE2eeActive(msg),
    );
    _transcriptControllers[msg.id] = controller;
    return controller;
  }

  Future<void> _openToneLensForMessage(_ChatMessage msg) async {
    final service = _learningService;
    if (service == null || !_learningUiEnabled || msg.isVoice) return;
    final word = msg.text.trim().split(RegExp(r'\s+')).firstWhere(
          (w) => w.isNotEmpty,
          orElse: () => '',
        );
    if (word.isEmpty) return;
    await showToneLensSheet(
      context: context,
      service: service,
      messageId: msg.id,
      word: word,
      e2ee: _messageE2eeActive(msg),
    );
  }

  Future<void> _tapWordGloss(_ChatMessage msg, String word) async {
    final service = _learningService;
    if (service == null || !_learningUiEnabled || word.trim().isEmpty) return;
    await showToneLensSheet(
      context: context,
      service: service,
      messageId: msg.id,
      word: word.trim(),
      e2ee: _messageE2eeActive(msg),
    );
  }

  Future<void> _runMessageCheckBeforeSend() async {
    final service = _learningService;
    if (service == null || !_learningUiEnabled || _messageCheckRunning) return;
    final draft = _messageController.text.trim();
    if (draft.isEmpty) return;
    setState(() => _messageCheckRunning = true);
    try {
      final result = await service.checkMessageBeforeSend(draft);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Check message'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(result.explanation),
                  if (result.hasSuggestion) ...[
                    const SizedBox(height: 12),
                    Text(
                      result.suggestedText,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Keep mine'),
              ),
              if (result.hasSuggestion)
                FilledButton(
                  onPressed: () {
                    _messageController.text = result.suggestedText;
                    _messageController.selection = TextSelection.collapsed(
                      offset: result.suggestedText.length,
                    );
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text('Use suggestion'),
                ),
            ],
          );
        },
      );
    } finally {
      if (mounted) setState(() => _messageCheckRunning = false);
    }
  }

  Future<void> _showPeerReportBlockSheet() async {
    final peer = _peerNumericId;
    if (peer == null || !mounted) return;
    final peerId = peer.toString();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => ReportBlockSheet(
        onReport: (reason) async {
          final response = await ApiService.post(
            'chat/users/$peerId/report',
            data: {'reason': reason},
          );
          final body = response.data;
          final referenceId =
              body is Map ? body['referenceId']?.toString() ?? '' : '';
          if (referenceId.isEmpty) {
            throw StateError('missing reference');
          }
          return referenceId;
        },
        onBlock: () async {
          await ApiService.post(
            Api.connectionBlock(),
            data: {'targetUserId': peerId},
          );
        },
      ),
    );
  }

  void _openContactInfo() {
    final peer = _peerNumericId;
    if (peer == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContactInfoScreen(
          contactName: _contactName,
          contactId: peer.toString(),
        ),
      ),
    );
  }

  Future<void> _refreshFirstDmState({bool showInboundSheet = false}) async {
    final peer = _peerNumericId;
    if (peer == null || !mounted) return;
    try {
      final state = await WaPrivateChatService.fetchFirstDmState(peer);
      final kind = state['kind']?.toString() ?? 'none';
      setState(() => _firstDmKind = kind);
      if (kind == 'pending_inbound' && showInboundSheet && !_inboundRequestSheetShown) {
        _inboundRequestSheetShown = true;
        await _showInboundFirstDmSheet(
          intro: state['intro_message']?.toString(),
          initiatorId: peer,
        );
      }
    } catch (_) {
      // Offline: keep last known state.
    }
  }

  Future<void> _showInboundFirstDmSheet({
    required int initiatorId,
    String? intro,
  }) async {
    if (!mounted) return;
    await showFirstDmPromptSheet<void>(
      context: context,
      sheet: FirstDmPromptSheet(
        mode: FirstDmSheetMode.inboundRequest,
        peerDisplayName: _contactName,
        inboundIntro: intro,
        onAccept: () async {
          await WaPrivateChatService.respondFirstDmRequest(
            initiatorUserId: initiatorId,
            decision: 'accept',
          );
          if (mounted) Navigator.of(context).pop();
          await _refreshFirstDmState();
        },
        onDecline: () async {
          await WaPrivateChatService.respondFirstDmRequest(
            initiatorUserId: initiatorId,
            decision: 'decline',
          );
          if (mounted) Navigator.of(context).pop();
          if (mounted) Navigator.of(context).pop();
        },
        onReport: () async {
          if (!mounted) return;
          await showModalBottomSheet<void>(
            context: context,
            builder: (ctx) => ReportBlockSheet(
              onReport: (_) async => 'first-dm-report',
              onBlock: () async {},
            ),
          );
        },
        onBlock: () async {
          if (!mounted) return;
          await showModalBottomSheet<void>(
            context: context,
            builder: (ctx) => ReportBlockSheet(
              onReport: (_) async => 'first-dm-report',
              onBlock: () async {},
            ),
          );
        },
      ),
    );
  }

  Future<bool> _promptOutboundIntroIfNeeded() async {
    if (_firstDmKind != 'none') return true;
    if (!mounted) return false;
    final peer = _peerNumericId;
    if (peer == null) return false;
    final text = _messageController.text.trim();
    if (text.isEmpty) return false;

    var sent = false;
    await showFirstDmPromptSheet<void>(
      context: context,
      sheet: FirstDmPromptSheet(
        mode: FirstDmSheetMode.outboundIntro,
        peerDisplayName: _contactName,
        onSendIntro: (msg) async {
          await _sendDmText(
            peer: peer,
            message: msg,
            firstDmIntro: true,
          );
          sent = true;
          _messageController.clear();
          if (mounted) Navigator.of(context).pop();
          await _loadMessages();
          await _refreshFirstDmState();
        },
      ),
    );
    return sent;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final peer = _peerNumericId;
    if (text.isEmpty || _sending || peer == null) return;

    if (_firstDmKind == 'none') {
      setState(() => _sending = true);
      try {
        final sent = await _promptOutboundIntroIfNeeded();
        if (!sent) return;
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }
    if (_firstDmKind == 'pending_outbound' || _firstDmKind == 'pending_inbound') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wait for the message request to be accepted.'),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    final room = _dmRoomId;
    if (room != null) {
      unawaited(WaPrivateChatService.setTyping(roomId: room, isTyping: false));
      _socket?.emit('chat:typing', wrapOutboundSocketPayload({'roomId': room, 'isTyping': false}));
    }
    _messageController.clear();
    try {
      await _sendDmText(
        peer: peer,
        message: text,
        replyToId: _replyTarget?.id,
      );
      if (_replyTarget != null) setState(() => _replyTarget = null);
      await _loadMessages();
      await _appendPolieIfMentioned(text);
    } catch (e) {
      if (mounted) {
        final code = e is DioException
            ? (e.response?.data is Map
                ? (e.response!.data as Map)['code']?.toString()
                : null)
            : null;
        if (code == 'NEW_ACCOUNT_LIMIT') {
          final reset = e is DioException && e.response?.data is Map
              ? (e.response!.data as Map)['reset_at']?.toString()
              : null;
          showFirstDmPromptSheet<void>(
            context: context,
            sheet: FirstDmPromptSheet(
              mode: FirstDmSheetMode.limited,
              peerDisplayName: _contactName,
              limitedResetLabel: reset != null
                  ? 'Try again after $reset.'
                  : null,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e is DioException
                    ? TransportErrorPolicy.toUserMessage(e)
                    : 'Message could not be sent.',
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _appendPolieIfMentioned(String userMessage) async {
    final handler = ref.read(polieMentionHandlerProvider);
    if (!handler.hasMention(userMessage)) return;
    final peer = _peerNumericId;
    final me = ref.read(userProvider);
    if (peer == null || me == null) return;

    if (!await PolieRateLimiter.allow('dm_${me.id}_$peer')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Too many @Polie requests. Try again in about a minute.',
            ),
          ),
        );
      }
      return;
    }

    final onboarding = ref.read(onboardingProvider);
    final result = await handler.processMessage(
      message: userMessage,
      userLanguage: onboarding.selectedLanguage ?? 'english',
      chatContext: 'Private chat',
    );
    final formatted = handler.formatResponseForChat(result);
    if (!mounted || formatted.isEmpty) return;
    final now = DateTime.now();
    final t = TimeOfDay.fromDateTime(now).format(context);
    final atMs = now.millisecondsSinceEpoch;
    final entryId = '${atMs}_polie';
    setState(() {
      _messages.add(
        _ChatMessage(
          text: formatted,
          isMe: false,
          time: t,
          isRead: true,
          isFromPolie: true,
          sortMs: atMs,
        ),
      );
      _messages.sort((a, b) => a.sortMs.compareTo(b.sortMs));
    });
    await PolieDmLocalStore.append(
      me.id,
      peer,
      PolieDmStoredBubble(
        id: entryId,
        text: formatted,
        timeLabel: t,
        atMs: atMs,
      ),
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final peer = _peerNumericId;

    return Scaffold(
      backgroundColor: ModernGriotColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildChatAppBar(cs),
      ),
      body: GriotSvgPatternBackground(
        pattern: GriotPattern.triangles,
        opacity: 0.02,
        child: peer == null
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(PanAfricanSpacing.lg),
                  child: Text(
                    'This conversation is missing a valid user id. Go back and open the chat from search or your inbox.',
                    style: ModernGriotTypography.bodyMedium(),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Column(
                children: [
                  if (_requiresModeration)
                    Material(
                      color: cs.secondaryContainer,
                      child: ListTile(
                        dense: true,
                        minVerticalPadding: 12,
                        minLeadingWidth: 48,
                        leading: Icon(
                          Icons.shield_outlined,
                          color: cs.onSecondaryContainer,
                        ),
                        title: Text(
                          kE2eeMinorNotice,
                          style: ModernGriotTypography.labelSmall(
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ..._buildE2eeStatusStrip(cs),
                  if (_replyTarget != null) _buildReplyComposerStrip(cs),
                  if (_loadError != null)
                    Material(
                      color: cs.errorContainer,
                      child: ListTile(
                        leading: Icon(
                          Icons.warning_amber_rounded,
                          color: cs.onErrorContainer,
                        ),
                        title: Text(
                          _loadError!,
                          style: TextStyle(
                            color: cs.onErrorContainer,
                            fontSize: 13.sp,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: _loadMessages,
                          child: const Text('Retry'),
                        ),
                      ),
                    ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: PanAfricanSpacing.sm,
                              vertical: PanAfricanSpacing.md,
                            ),
                            itemCount: _messages.length + (_peerTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _messages.length) {
                                return _buildTypingIndicator(cs);
                              }
                              return _buildMessageBubble(_messages[index], cs, index);
                            },
                          ),
                  ),
                  _buildInputBar(cs),
                ],
              ),
      ),
    );
  }

  Widget _buildChatAppBar(ColorScheme cs) {
    return AppBar(
      backgroundColor: cs.surfaceContainerLow,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          GriotAvatar(
            size: 36,
            status: _contactOnline
                ? GriotAvatarStatus.online
                : GriotAvatarStatus.offline,
            placeholder: CircleAvatar(
              radius: 18.r,
              backgroundColor: ModernGriotColors.primaryContainer.withAlpha(80),
              child: Text(
                _contactInitial,
                style: ModernGriotTypography.titleSmall(
                  color: ModernGriotColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: PanAfricanSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _contactName,
                  style: ModernGriotTypography.titleSmall(color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_learningUiEnabled && _peerLanguageStatuses.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: LanguageStatusChipRow(entries: _peerLanguageStatuses),
                  ),
                Row(
                  children: [
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _contactOnline
                            ? ModernGriotColors.secondary
                            : cs.outlineVariant,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    if (_mlsSnapshot?.showEncryptionIndicator == true) ...[
                      Icon(Icons.lock_rounded, size: 14.sp, color: cs.primary),
                      SizedBox(width: 4.w),
                      Text(
                        kE2eeOnLabel,
                        style: ModernGriotTypography.labelSmall(
                          color: cs.primary,
                        ),
                      ),
                    ] else
                      Text(
                        _contactOnline ? 'Online' : 'Offline',
                        style: ModernGriotTypography.labelSmall(
                          color: _contactOnline
                              ? ModernGriotColors.secondary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.videocam_outlined, color: cs.onSurface),
          tooltip: 'Live classes',
          onPressed: () {
            HapticFeedback.selectionClick();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Group video and voice sessions are in Live Classroom (app drawer → Live Classroom).',
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.call_outlined, color: cs.onSurface),
          tooltip: 'Voice info',
          onPressed: () {
            HapticFeedback.selectionClick();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '1:1 calls are not enabled here yet. Use text chat or join a live class.',
                ),
              ),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: cs.onSurface),
          onSelected: (value) {
            HapticFeedback.selectionClick();
            switch (value) {
              case 'contact':
                _openContactInfo();
              case 'report':
                unawaited(_showPeerReportBlockSheet());
              case 'status':
                Navigator.pushNamed(context, 'wa-status');
              case 'starred':
                Navigator.pushNamed(context, 'wa-starred');
              case 'media':
                Navigator.pushNamed(context, 'wa-media-gallery');
            }
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'contact', child: Text('Contact info')),
            PopupMenuItem(value: 'report', child: Text('Report or block')),
            PopupMenuItem(value: 'status', child: Text('Status updates')),
            PopupMenuItem(value: 'starred', child: Text('Starred messages')),
            PopupMenuItem(value: 'media', child: Text('Media gallery')),
          ],
        ),
      ],
    );
  }

  Future<void> _sendVoiceNote(String path, int durationMs) async {
    final peer = _peerNumericId;
    if (peer == null || _sending) return;
    setState(() => _sending = true);
    try {
      await WaPrivateChatService.sendVoiceNote(
        recipientId: peer.toString(),
        localFilePath: path,
        durationMs: durationMs,
        replyToId: _replyTarget?.id,
      );
      if (_replyTarget != null) setState(() => _replyTarget = null);
      await _loadMessages();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice note could not be sent. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _playVoiceNote(_ChatMessage msg) async {
    final url = msg.audioUrl;
    if (url == null || url.isEmpty) return;
    if (_playingVoiceId == msg.id) {
      await _voicePlayer.stop();
      setState(() => _playingVoiceId = null);
      return;
    }
    setState(() => _playingVoiceId = msg.id);
    try {
      await _voicePlayer.setUrl(url);
      await _voicePlayer.play();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play this voice note.')),
        );
      }
    }
  }

  Future<void> _showMessageActions(_ChatMessage msg) async {
    if (msg.id.isEmpty) return;
    final emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: PanAfricanSpacing.md,
          children: ['👍', '❤️', '😂', '🙏', '🔥'].map((e) {
            return IconButton(
              tooltip: 'React with $e',
              icon: Text(e, style: TextStyle(fontSize: 28.sp)),
              onPressed: () => Navigator.pop(ctx, e),
            );
          }).toList(),
        ),
      ),
    );
    if (emoji != null) {
      await WaPrivateChatService.toggleReaction(messageId: msg.id, emoji: emoji);
      _socket?.emit('wa:reaction', {
        'roomId': _dmRoomId,
        'messageId': msg.id,
        'emoji': emoji,
      });
      await _loadMessages();
    }
  }

  Widget _buildPeerLearningText({
    required _ChatMessage msg,
    required String displayText,
    required Color textColor,
  }) {
    final words = displayText.split(RegExp(r'(\s+)'));
    return Wrap(
      spacing: 0,
      runSpacing: 2,
      children: [
        for (final token in words)
          if (token.trim().isEmpty)
            Text(token, style: ModernGriotTypography.bodyMedium(color: textColor))
          else
            Semantics(
              button: true,
              label: 'Show gloss for $token',
              child: InkWell(
                onTap: () => _tapWordGloss(msg, token),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                  child: Text(
                    token,
                    style: ModernGriotTypography.bodyMedium(
                      color: textColor,
                    ).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: textColor.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildReplyComposerStrip(ColorScheme cs) {
    final target = _replyTarget!;
    return Material(
      color: cs.surfaceContainerHighest,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.reply_rounded),
        title: Text(
          target.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _replyTarget = null),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, ColorScheme cs, int index) {
    final snapshot = _mlsSnapshot;
    final readable = snapshot == null ||
        _mlsSession.messageReadableOnDevice(
          snapshot: snapshot,
          messageSortMs: msg.sortMs,
        );
    final displayText =
        readable ? msg.text : 'Earlier message — not readable on this device';
    final bubbleColor = msg.isFromPolie
        ? ModernGriotColors.primaryContainer.withAlpha(140)
        : msg.isMe
        ? ModernGriotColors.secondary
        : ModernGriotColors.surfaceContainerLow;
    final textColor = msg.isMe
        ? ModernGriotColors.onSecondary
        : ModernGriotColors.onSurface;
    final timeColor = msg.isMe
        ? ModernGriotColors.onSecondary.withAlpha(179)
        : ModernGriotColors.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
      child: Column(
        crossAxisAlignment: msg.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: msg.isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!msg.isMe) SizedBox(width: PanAfricanSpacing.xxl),
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _showMessageActions(msg),
                  onHorizontalDragEnd: (d) {
                    if (d.primaryVelocity != null && d.primaryVelocity! > 200) {
                      setState(() => _replyTarget = msg);
                    }
                  },
                  child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.md,
                    vertical: PanAfricanSpacing.sm,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    border: msg.isFromPolie
                        ? Border.all(
                            color: ModernGriotColors.primary.withAlpha(100),
                            width: 1,
                          )
                        : null,
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(ModernGriotRadius.lg),
                      topRight: const Radius.circular(ModernGriotRadius.lg),
                      bottomLeft: Radius.circular(
                        msg.isMe ? ModernGriotRadius.lg : ModernGriotRadius.xs,
                      ),
                      bottomRight: Radius.circular(
                        msg.isMe ? ModernGriotRadius.xs : ModernGriotRadius.lg,
                      ),
                    ),
                    boxShadow: ModernGriotShadows.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: msg.isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (msg.isFromPolie)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Text(
                            'Polie',
                            style: ModernGriotTypography.labelSmall(
                              color: ModernGriotColors.primary,
                            ),
                          ),
                        ),
                      if (msg.replySnippet != null &&
                          msg.replySnippet!.trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Text(
                            msg.replySnippet!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ModernGriotTypography.labelSmall(
                              color: textColor.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      if (msg.isVoice)
                        InkWell(
                          onTap: () => _playVoiceNote(msg),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _playingVoiceId == msg.id
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_circle_fill,
                                color: textColor,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                displayText,
                                style: ModernGriotTypography.bodyMedium(
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_learningUiEnabled &&
                          !msg.isMe &&
                          readable &&
                          !msg.isFromPolie)
                        _buildPeerLearningText(
                          msg: msg,
                          displayText: displayText,
                          textColor: textColor,
                        )
                      else
                        Text(
                          displayText,
                          style: ModernGriotTypography.bodyMedium(
                            color: textColor,
                          ),
                        ),
                      if (msg.isVoice &&
                          _learningUiEnabled &&
                          msg.id.isNotEmpty &&
                          readable)
                        Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: VoiceNoteTranscriptPanel(
                            controller: _transcriptControllerFor(msg),
                          ),
                        ),
                      if (_learningUiEnabled &&
                          !msg.isMe &&
                          !msg.isVoice &&
                          readable &&
                          displayText.trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _openToneLensForMessage(msg),
                              icon: Icon(Icons.graphic_eq, size: 16.sp),
                              label: const Text('Tone Lens'),
                              style: TextButton.styleFrom(
                                foregroundColor: textColor,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(48, 48),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg.time,
                            style: TextStyle(fontSize: 10.sp, color: timeColor),
                          ),
                          if (msg.isMe && _showReadReceipts) ...[
                            SizedBox(width: 4.w),
                            Semantics(
                              label: msg.isRead ? 'Read' : 'Sent',
                              child: Icon(
                                msg.isRead
                                    ? Icons.done_all_rounded
                                    : Icons.done_rounded,
                                size: 14.sp,
                                color: msg.isRead
                                    ? ModernGriotColors.onSecondary
                                    : timeColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              ),
              if (msg.isMe) SizedBox(width: PanAfricanSpacing.xxl),
            ],
          ),
          if (msg.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 2.h,
                left: msg.isMe ? 0 : PanAfricanSpacing.xxl,
                right: msg.isMe ? PanAfricanSpacing.xxl : 0,
              ),
              child: Wrap(
                spacing: 4,
                children: msg.reactions.entries
                    .map((e) => Text('${e.key}${e.value > 1 ? e.value : ''}'))
                    .toList(),
              ),
            ),
          if (msg.translation != null) _buildTranslationBlock(msg, cs),
          if (msg.vocabWord != null) _buildVocabCard(msg, cs),
        ],
      ),
    );
  }

  Widget _buildTranslationBlock(_ChatMessage msg, ColorScheme cs) {
    return Container(
      margin: EdgeInsets.only(
        top: 4.h,
        left: msg.isMe ? 0 : PanAfricanSpacing.xxl,
        right: msg.isMe ? PanAfricanSpacing.xxl : 0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm,
        vertical: PanAfricanSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(180),
        borderRadius: ModernGriotRadius.borderMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.translate_rounded,
            size: 14.sp,
            color: ModernGriotColors.primary,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              msg.translation!,
              style: ModernGriotTypography.labelSmall(
                color: cs.onSurfaceVariant,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabCard(_ChatMessage msg, ColorScheme cs) {
    return Container(
      margin: EdgeInsets.only(
        top: 6.h,
        left: msg.isMe ? PanAfricanSpacing.xxl : PanAfricanSpacing.xxl,
        right: msg.isMe ? PanAfricanSpacing.xxl : 0,
      ),
      constraints: BoxConstraints(maxWidth: 260.w),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: ModernGriotRadius.borderXl,
        border: Border.all(
          color: ModernGriotColors.primary.withAlpha(50),
          width: 1.5,
        ),
        boxShadow: ModernGriotShadows.sm,
      ),
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GriotBadgePill(
                label: 'Vocabulary',
                color: ModernGriotColors.primaryContainer.withAlpha(60),
                textColor: ModernGriotColors.primary,
                icon: Icons.menu_book_rounded,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => HapticFeedback.selectionClick(),
                child: Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: const BoxDecoration(
                    gradient: ModernGriotGradients.signatureGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 18.sp,
                    color: ModernGriotColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            msg.vocabWord!,
            style: ModernGriotTypography.titleLarge(color: cs.onSurface),
          ),
          SizedBox(height: 2.h),
          Text(
            msg.vocabPronunciation ?? '',
            style: ModernGriotTypography.bodySmall(
              color: ModernGriotColors.primary,
            ),
          ),
          SizedBox(height: PanAfricanSpacing.xs),
          Text(
            msg.vocabMeaning ?? '',
            style: ModernGriotTypography.bodyMedium(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme cs) {
    final l10n = AppLocalizations.of(context);
    final label = l10n?.chatPeerTyping(_contactName) ?? '…';
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(
            left: PanAfricanSpacing.xxl,
            bottom: PanAfricanSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  label,
                  style: ModernGriotTypography.labelSmall(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: PanAfricanSpacing.md,
                      vertical: PanAfricanSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: ModernGriotColors.surfaceContainerLow,
                      borderRadius: ModernGriotRadius.borderLg,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final delay = i * 0.33;
                        final t = (_typingController.value + delay) % 1.0;
                        final y = -4.0 * (t < 0.5 ? t * 2 : (1.0 - t) * 2);
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.w),
                          child: Transform.translate(
                            offset: Offset(0, y),
                            child: Container(
                              width: 7.r,
                              height: 7.r,
                              decoration: BoxDecoration(
                                color: cs.onSurfaceVariant.withAlpha(130),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar(ColorScheme cs) {
    final hasText = _messageController.text.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.only(
        left: PanAfricanSpacing.sm,
        right: PanAfricanSpacing.sm,
        top: PanAfricanSpacing.xs,
        bottom: MediaQuery.of(context).padding.bottom + PanAfricanSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        boxShadow: [
          BoxShadow(
            color: ModernGriotColors.onSurface.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(Icons.attach_file_rounded, color: cs.onSurfaceVariant),
            onPressed: () => HapticFeedback.selectionClick(),
          ),
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: cs.onSurfaceVariant),
            onPressed: () => HapticFeedback.selectionClick(),
          ),
          if (_learningUiEnabled)
            IconButton(
              tooltip: 'Check message',
              icon: _messageCheckRunning
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                    )
                  : Icon(Icons.spellcheck_outlined, color: cs.primary),
              onPressed: _messageCheckRunning
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      unawaited(_runMessageCheckBeforeSend());
                    },
            ),
          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: 120.h),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: ModernGriotRadius.borderXl,
                border: Border.all(
                  color: cs.outlineVariant.withAlpha(38),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                style: ModernGriotTypography.bodyMedium(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Message… (use @Polie for AI help)',
                  hintStyle: ModernGriotTypography.bodyMedium(
                    color: cs.onSurfaceVariant.withAlpha(153),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.md,
                    vertical: PanAfricanSpacing.sm,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: PanAfricanSpacing.xs),
          if (hasText)
            GestureDetector(
              onTap: _sending ? null : _sendMessage,
              child: Opacity(
                opacity: _sending ? 0.5 : 1,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: ModernGriotGradients.signatureGradient,
                    shape: BoxShape.circle,
                    boxShadow: ModernGriotShadows.fab,
                  ),
                  child: _sending
                      ? Padding(
                          padding: EdgeInsets.all(10.r),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ModernGriotColors.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          size: 20.sp,
                          color: ModernGriotColors.onPrimary,
                        ),
                ),
              ),
            )
          else
            VoiceNoteRecorder(
              key: _voiceNoteKey,
              enabled: !_sending && _firstDmKind == 'accepted',
              holdLabel: 'Hold to record, slide left to cancel, up to lock',
              onCompleted: (path, ms) => _sendVoiceNote(path, ms),
              onCancel: () {},
            ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final bool isRead;
  final bool isFromPolie;
  final String messageType;
  final String? audioUrl;
  final Map<String, int> reactions;
  final String? replySnippet;

  /// Milliseconds since epoch for ordering with server messages.
  final int sortMs;
  final String? translation;
  final String? vocabWord;
  final String? vocabPronunciation;
  final String? vocabMeaning;

  bool get isVoice => messageType == 'audio' && (audioUrl?.isNotEmpty ?? false);

  const _ChatMessage({
    this.id = '',
    required this.text,
    required this.isMe,
    required this.time,
    required this.isRead,
    this.isFromPolie = false,
    this.sortMs = 0,
    this.messageType = 'text',
    this.audioUrl,
    this.reactions = const {},
    this.replySnippet,
    this.translation,
    this.vocabWord,
    this.vocabPronunciation,
    this.vocabMeaning,
  });

  _ChatMessage copyWith({
    bool? isRead,
    Map<String, int>? reactions,
  }) {
    return _ChatMessage(
      id: id,
      text: text,
      isMe: isMe,
      time: time,
      isRead: isRead ?? this.isRead,
      isFromPolie: isFromPolie,
      sortMs: sortMs,
      messageType: messageType,
      audioUrl: audioUrl,
      reactions: reactions ?? this.reactions,
      replySnippet: replySnippet,
      translation: translation,
      vocabWord: vocabWord,
      vocabPronunciation: vocabPronunciation,
      vocabMeaning: vocabMeaning,
    );
  }
}
