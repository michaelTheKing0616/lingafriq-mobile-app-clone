import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../models/profile_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/chat/wa_private_chat_service.dart';
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

  @override
  void initState() {
    super.initState();
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
    return _ChatMessage(
      text: text,
      isMe: isMe,
      time: timeStr,
      isRead: read,
      sortMs: sortMs,
    );
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
        socket.emit('join_room', {'room': currentRoom});
      }
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
      if (payload is! Map) return;
      final p = Map<String, dynamic>.from(payload as Map);
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
      _socket?.emit('chat:typing', {'roomId': room, 'isTyping': false});
      return;
    }
    _typingDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(WaPrivateChatService.setTyping(roomId: room, isTyping: true));
      _socket?.emit('chat:typing', {'roomId': room, 'isTyping': true});
    });
    _typingIdleTimer?.cancel();
    _typingIdleTimer = Timer(const Duration(seconds: 4), () {
      unawaited(WaPrivateChatService.setTyping(roomId: room, isTyping: false));
      _socket?.emit('chat:typing', {'roomId': room, 'isTyping': false});
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
      _socket?.emit('chat:typing', {'roomId': _dmRoomId!, 'isTyping': false});
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
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final peer = _peerNumericId;
    if (text.isEmpty || _sending || peer == null) return;
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    final room = _dmRoomId;
    if (room != null) {
      unawaited(WaPrivateChatService.setTyping(roomId: room, isTyping: false));
      _socket?.emit('chat:typing', {'roomId': room, 'isTyping': false});
    }
    _messageController.clear();
    try {
      await WaPrivateChatService.sendTextMessage(
        recipientId: peer.toString(),
        message: text,
      );
      await _loadMessages();
      await _appendPolieIfMentioned(text);
    } catch (e) {
      if (mounted) {
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
        preferredSize: Size.fromHeight(kToolbarHeight),
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
                              return _buildMessageBubble(_messages[index], cs);
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
        IconButton(
          icon: Icon(Icons.more_vert_rounded, color: cs.onSurface),
          onPressed: () => HapticFeedback.selectionClick(),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, ColorScheme cs) {
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
                      topLeft: Radius.circular(ModernGriotRadius.lg),
                      topRight: Radius.circular(ModernGriotRadius.lg),
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
                      Text(
                        msg.text,
                        style: ModernGriotTypography.bodyMedium(
                          color: textColor,
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
                          if (msg.isMe) ...[
                            SizedBox(width: 4.w),
                            Icon(
                              msg.isRead
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 14.sp,
                              color: msg.isRead
                                  ? ModernGriotColors.onSecondary
                                  : timeColor,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (msg.isMe) SizedBox(width: PanAfricanSpacing.xxl),
            ],
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
                  decoration: BoxDecoration(
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
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: PanAfricanSpacing.xs),
          GestureDetector(
            onTap: _sending ? null : _sendMessage,
            child: Opacity(
              opacity: _sending ? 0.5 : 1,
              child: Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  gradient: ModernGriotGradients.signatureGradient,
                  shape: BoxShape.circle,
                  boxShadow: ModernGriotShadows.fab,
                ),
                child: _sending
                    ? Padding(
                        padding: EdgeInsets.all(10.r),
                        child: CircularProgressIndicator(
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
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final bool isRead;
  final bool isFromPolie;

  /// Milliseconds since epoch for ordering with server messages.
  final int sortMs;
  final String? translation;
  final String? vocabWord;
  final String? vocabPronunciation;
  final String? vocabMeaning;

  const _ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    required this.isRead,
    this.isFromPolie = false,
    this.sortMs = 0,
    this.translation,
    this.vocabWord,
    this.vocabPronunciation,
    this.vocabMeaning,
  });
}
