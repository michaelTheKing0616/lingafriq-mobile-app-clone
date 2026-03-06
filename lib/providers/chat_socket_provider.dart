import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:lingafriq/utils/structured_logger.dart';

/// Chat Socket Provider - Wraps socket service for chat functionality
class ChatSocketNotifier extends Notifier<ChatSocketState> {
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _onlineUsers = [];
  final Set<String> _blockedUserIds = <String>{};
  String _activeRoom = 'general';
  bool _isConnected = false;
  final Map<String, List<Map<String, dynamic>>> _roomMessages = {};
  final Map<String, Map<String, dynamic>> _outboundMessagesById = {};
  final Map<String, int> _messageAttemptCounts = {};
  final Map<String, Timer> _ackTimeoutTimers = {};
  io.Socket? _socket;
  String? _pendingUserId;
  String? _pendingUsername;
  String? _pendingGlobalId;
  static const int _maxSendAttempts = 3;
  static const Duration _ackTimeout = Duration(seconds: 4);
  static const Duration _retryDelay = Duration(seconds: 2);

  @override
  ChatSocketState build() {
    ref.onDispose(_dispose);
    _initializeSocket();
    return ChatSocketState.initial();
  }

  void _dispose() {
    try {
      for (final timer in _ackTimeoutTimers.values) {
        timer.cancel();
      }
      _ackTimeoutTimers.clear();
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
    } catch (e) {
      logger.error('Error disposing chat socket', tag: 'chat-socket', error: e);
    }
  }

  void _initializeSocket() {
    try {
      final token = ref.read(apiProvider.notifier).token;
      // Use the base URL directly - socket.io client handles protocol conversion
      final baseUrl = ApiContract.baseUrl;
      
      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token ?? ''})
            .enableAutoConnect()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setTimeout(20000)
            .build(),
      );
    } catch (e) {
      logger.error('Error initializing socket', tag: 'chat-socket', error: e);
      return;
    }

    _socket!.onConnect((_) {
      _isConnected = true;
      state = state.copyWith(isConnected: true);
      if (_pendingUserId != null) {
        _socket!.emit('user_connected', {
          'userId': _pendingUserId,
          'username': _pendingUsername ?? 'Learner',
          if (_pendingGlobalId != null && _pendingGlobalId!.isNotEmpty)
            'global_id': _pendingGlobalId,
        });
      }
      _flushQueuedMessages();
      logger.info('Chat socket connected', tag: 'chat-socket');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      state = state.copyWith(isConnected: false);
      logger.info('Chat socket disconnected', tag: 'chat-socket');
    });
    
    _socket!.onError((error) {
      logger.error('Chat socket error', tag: 'chat-socket', error: error);
      _isConnected = false;
      state = state.copyWith(isConnected: false);
    });
    
    _socket!.onConnectError((error) {
      logger.error('Chat socket connection error', tag: 'chat-socket', error: error);
      _isConnected = false;
      state = state.copyWith(isConnected: false);
    });

    _socket!.on('message', (data) {
      final messageData = Map<String, dynamic>.from(data);
      final senderId = messageData['userId']?.toString() ?? '';
      if (senderId.isNotEmpty && _blockedUserIds.contains(senderId)) {
        return;
      }
      final room = messageData['room'] ?? _activeRoom;
      if (!_roomMessages.containsKey(room)) {
        _roomMessages[room] = [];
      }
      messageData['lifecycleState'] = messageData['lifecycleState'] ?? 'delivered';
      messageData['pending'] = false;
      _roomMessages[room]!.add(messageData);
      _messages.add(messageData);
      state = state.copyWith(messages: List.from(_messages));
    });

    _socket!.on('new_message', (data) {
      final messageData = Map<String, dynamic>.from(data);
      final senderId = messageData['userId']?.toString() ?? '';
      if (senderId.isNotEmpty && _blockedUserIds.contains(senderId)) {
        return;
      }
      final room = messageData['room'] ?? messageData['channel'] ?? _activeRoom;
      if (!_roomMessages.containsKey(room)) {
        _roomMessages[room] = [];
      }
      final incomingClientMessageId = messageData['clientMessageId']?.toString();
      final incomingSenderId = messageData['userId']?.toString() ?? '';
      if (incomingClientMessageId != null && incomingClientMessageId.isNotEmpty) {
        _markMessageLifecycle(incomingClientMessageId, 'delivered',
            serverMessageId:
                messageData['id']?.toString() ?? messageData['_id']?.toString());
        _outboundMessagesById.remove(incomingClientMessageId);
        _messageAttemptCounts.remove(incomingClientMessageId);
        _ackTimeoutTimers.remove(incomingClientMessageId)?.cancel();
        for (final entry in _roomMessages.entries) {
          entry.value.removeWhere((m) {
            final matchesClientId =
                (m['clientMessageId']?.toString() ?? '') == incomingClientMessageId;
            final matchesSenderId =
                incomingSenderId.isEmpty ||
                (m['userId']?.toString() ?? '') == incomingSenderId;
            return matchesClientId && matchesSenderId && (m['pending'] == true);
          });
        }
        _messages.removeWhere((m) {
          final matchesClientId =
              (m['clientMessageId']?.toString() ?? '') == incomingClientMessageId;
          final matchesSenderId =
              incomingSenderId.isEmpty ||
              (m['userId']?.toString() ?? '') == incomingSenderId;
          return matchesClientId && matchesSenderId && (m['pending'] == true);
        });
      }
      // Avoid duplicates
      final messageId = messageData['_id']?.toString() ?? messageData['id']?.toString() ?? '';
      if (messageId.isNotEmpty && _roomMessages[room]!.any((m) => (m['_id']?.toString() ?? m['id']?.toString()) == messageId)) {
        return;
      }
      messageData['lifecycleState'] = 'delivered';
      messageData['pending'] = false;
      _roomMessages[room]!.add(messageData);
      _messages.add(messageData);
      state = state.copyWith(messages: List.from(_messages));
    });

    _socket!.on('message_ack', _handleMessageAck);
    _socket!.on('send_message_ack', _handleMessageAck);

    _socket!.on('message_deleted', (data) {
      final deleteData = Map<String, dynamic>.from(data);
      final messageId = deleteData['messageId']?.toString() ?? deleteData['id']?.toString() ?? '';
      final room = deleteData['room'] ?? deleteData['channel'] ?? _activeRoom;
      
      if (messageId.isNotEmpty) {
        // Remove from room messages
        if (_roomMessages.containsKey(room)) {
          _roomMessages[room]!.removeWhere((m) => 
            (m['_id']?.toString() ?? m['id']?.toString()) == messageId
          );
        }
        // Remove from all messages
        _messages.removeWhere((m) => 
          (m['_id']?.toString() ?? m['id']?.toString()) == messageId
        );
        state = state.copyWith(messages: List.from(_messages));
      }
    });

    _socket!.on('user_joined', (data) {
      final userData = Map<String, dynamic>.from(data);
      if (!_onlineUsers.any((u) => u['userId'] == userData['userId'])) {
        _onlineUsers.add(userData);
        state = state.copyWith(onlineUsers: List.from(_onlineUsers));
      }
    });

    _socket!.on('user_left', (data) {
      final userId = data['userId'];
      _onlineUsers.removeWhere((u) => u['userId'] == userId);
      state = state.copyWith(onlineUsers: List.from(_onlineUsers));
    });

    _socket!.on('online_users', (data) {
      if (data is List) {
        _onlineUsers
          ..clear()
          ..addAll(data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
        state = state.copyWith(onlineUsers: List.from(_onlineUsers));
      }
    });

    _socket!.on('message_edited', (data) {
      final payload = Map<String, dynamic>.from(data);
      final id = payload['id']?.toString() ?? '';
      if (id.isEmpty) return;
      for (final room in _roomMessages.keys) {
        final idx = _roomMessages[room]!.indexWhere((msg) =>
            (msg['id']?.toString() ?? msg['_id']?.toString()) == id);
        if (idx != -1) {
          _roomMessages[room]![idx]['message'] = payload['message'];
          _roomMessages[room]![idx]['edited'] = true;
          _roomMessages[room]![idx]['editedAt'] = payload['editedAt'];
        }
      }
      final flatIdx = _messages.indexWhere((msg) =>
          (msg['id']?.toString() ?? msg['_id']?.toString()) == id);
      if (flatIdx != -1) {
        _messages[flatIdx]['message'] = payload['message'];
        _messages[flatIdx]['edited'] = true;
        _messages[flatIdx]['editedAt'] = payload['editedAt'];
      }
      state = state.copyWith(messages: List.from(_messages));
    });

    _socket!.on('message_reacted', (data) {
      final payload = Map<String, dynamic>.from(data);
      final id = payload['id']?.toString() ?? '';
      if (id.isEmpty) return;
      for (final room in _roomMessages.keys) {
        final idx = _roomMessages[room]!.indexWhere((msg) =>
            (msg['id']?.toString() ?? msg['_id']?.toString()) == id);
        if (idx != -1) {
          _roomMessages[room]![idx]['reactions'] = payload['reactions'] ?? [];
        }
      }
      final flatIdx = _messages.indexWhere((msg) =>
          (msg['id']?.toString() ?? msg['_id']?.toString()) == id);
      if (flatIdx != -1) {
        _messages[flatIdx]['reactions'] = payload['reactions'] ?? [];
      }
      state = state.copyWith(messages: List.from(_messages));
    });
  }

  void _handleMessageAck(dynamic ackData) {
    if (ackData is! Map) return;
    final payload = Map<String, dynamic>.from(ackData);
    final clientMessageId = payload['clientMessageId']?.toString();
    if (clientMessageId == null || clientMessageId.isEmpty) return;

    final status = payload['status']?.toString() ?? 'sent';
    final isTransient = payload['transient'] == true;
    final messageId = payload['messageId']?.toString();

    if (status == 'delivered') {
      _markMessageLifecycle(clientMessageId, 'delivered', serverMessageId: messageId);
      _outboundMessagesById.remove(clientMessageId);
      _messageAttemptCounts.remove(clientMessageId);
      _ackTimeoutTimers.remove(clientMessageId)?.cancel();
      return;
    }

    if (status == 'sent') {
      _markMessageLifecycle(clientMessageId, 'sent', serverMessageId: messageId);
      return;
    }

    if (isTransient) {
      _scheduleRetry(clientMessageId);
      return;
    }

    _markMessageLifecycle(clientMessageId, 'failed', serverMessageId: messageId);
    _outboundMessagesById.remove(clientMessageId);
    _messageAttemptCounts.remove(clientMessageId);
    _ackTimeoutTimers.remove(clientMessageId)?.cancel();
  }

  void _flushQueuedMessages() {
    final queuedIds = <String>[];
    for (final entry in _outboundMessagesById.entries) {
      final lifecycleState = entry.value['lifecycleState']?.toString() ?? 'queued';
      if (lifecycleState == 'queued') {
        queuedIds.add(entry.key);
      }
    }
    for (final clientMessageId in queuedIds) {
      _attemptSend(clientMessageId);
    }
  }

  void _upsertLocalMessage(Map<String, dynamic> messageData) {
    final room = messageData['room'] ?? _activeRoom;
    if (!_roomMessages.containsKey(room)) {
      _roomMessages[room] = [];
    }

    final clientMessageId = messageData['clientMessageId']?.toString();
    if (clientMessageId != null && clientMessageId.isNotEmpty) {
      final roomIndex = _roomMessages[room]!.indexWhere(
        (msg) => (msg['clientMessageId']?.toString() ?? '') == clientMessageId,
      );
      if (roomIndex != -1) {
        _roomMessages[room]![roomIndex] = {
          ..._roomMessages[room]![roomIndex],
          ...messageData,
        };
      } else {
        _roomMessages[room]!.add(messageData);
      }

      final flatIndex = _messages.indexWhere(
        (msg) => (msg['clientMessageId']?.toString() ?? '') == clientMessageId,
      );
      if (flatIndex != -1) {
        _messages[flatIndex] = {
          ..._messages[flatIndex],
          ...messageData,
        };
      } else {
        _messages.add(messageData);
      }
      state = state.copyWith(messages: List.from(_messages));
      return;
    }

    _roomMessages[room]!.add(messageData);
    _messages.add(messageData);
    state = state.copyWith(messages: List.from(_messages));
  }

  void _markMessageLifecycle(
    String clientMessageId,
    String lifecycleState, {
    String? serverMessageId,
  }) {
    if (_outboundMessagesById.containsKey(clientMessageId)) {
      _outboundMessagesById[clientMessageId] = {
        ..._outboundMessagesById[clientMessageId]!,
        'lifecycleState': lifecycleState,
        'pending': lifecycleState != 'delivered',
        if (serverMessageId != null && serverMessageId.isNotEmpty) 'id': serverMessageId,
      };
    }

    for (final room in _roomMessages.keys) {
      final index = _roomMessages[room]!.indexWhere(
        (msg) => (msg['clientMessageId']?.toString() ?? '') == clientMessageId,
      );
      if (index != -1) {
        _roomMessages[room]![index]['lifecycleState'] = lifecycleState;
        _roomMessages[room]![index]['pending'] = lifecycleState != 'delivered';
        if (serverMessageId != null && serverMessageId.isNotEmpty) {
          _roomMessages[room]![index]['id'] = serverMessageId;
        }
      }
    }

    final flatIndex = _messages.indexWhere(
      (msg) => (msg['clientMessageId']?.toString() ?? '') == clientMessageId,
    );
    if (flatIndex != -1) {
      _messages[flatIndex]['lifecycleState'] = lifecycleState;
      _messages[flatIndex]['pending'] = lifecycleState != 'delivered';
      if (serverMessageId != null && serverMessageId.isNotEmpty) {
        _messages[flatIndex]['id'] = serverMessageId;
      }
      state = state.copyWith(messages: List.from(_messages));
    }
  }

  void _scheduleRetry(String clientMessageId) {
    final attempts = _messageAttemptCounts[clientMessageId] ?? 0;
    if (attempts >= _maxSendAttempts) {
      _markMessageLifecycle(clientMessageId, 'failed');
      _outboundMessagesById.remove(clientMessageId);
      _ackTimeoutTimers.remove(clientMessageId)?.cancel();
      return;
    }

    _markMessageLifecycle(clientMessageId, 'queued');
    Future.delayed(_retryDelay, () {
      if (_outboundMessagesById.containsKey(clientMessageId)) {
        _attemptSend(clientMessageId);
      }
    });
  }

  void _startAckTimeout(String clientMessageId) {
    _ackTimeoutTimers.remove(clientMessageId)?.cancel();
    _ackTimeoutTimers[clientMessageId] = Timer(_ackTimeout, () {
      final outbound = _outboundMessagesById[clientMessageId];
      if (outbound == null) return;
      final lifecycle = outbound['lifecycleState']?.toString();
      if (lifecycle == 'delivered' || lifecycle == 'failed') return;
      _scheduleRetry(clientMessageId);
    });
  }

  void _attemptSend(String clientMessageId) {
    final outbound = _outboundMessagesById[clientMessageId];
    if (outbound == null) return;

    final nextAttempt = (_messageAttemptCounts[clientMessageId] ?? 0) + 1;
    _messageAttemptCounts[clientMessageId] = nextAttempt;
    if (nextAttempt > _maxSendAttempts) {
      _markMessageLifecycle(clientMessageId, 'failed');
      _outboundMessagesById.remove(clientMessageId);
      _ackTimeoutTimers.remove(clientMessageId)?.cancel();
      return;
    }

    if (!_isConnected || _socket == null) {
      _markMessageLifecycle(clientMessageId, 'queued');
      _scheduleRetry(clientMessageId);
      return;
    }
    _markMessageLifecycle(clientMessageId, 'sent');
    _startAckTimeout(clientMessageId);

    try {
      final payload = {
        ...outbound,
        'messageId': clientMessageId,
        'clientMessageId': clientMessageId,
      };
      _socket!.emitWithAck('send_message', payload, ack: (dynamic ackPayload) {
        _handleMessageAck(ackPayload);
      });
    } catch (e) {
      logger.error('Error sending message', tag: 'chat-socket', error: e);
      _scheduleRetry(clientMessageId);
    }
  }

  void connect(String userId, String username, {String? globalId}) {
    try {
      _pendingUserId = userId;
      _pendingUsername = username;
      _pendingGlobalId = globalId;
      if (!_isConnected && _socket != null) {
        _socket!.connect();
        logger.info('Attempting to connect chat socket', tag: 'chat-socket', context: {'userId': userId});
      } else if (_socket == null) {
        // Reinitialize if socket is null
        _initializeSocket();
      }
    } catch (e) {
      logger.error('Error connecting chat socket', tag: 'chat-socket', error: e);
    }
  }

  void joinRoom(String room) {
    _activeRoom = room;
    if (!_roomMessages.containsKey(room)) {
      _roomMessages[room] = [];
    }
    _socket?.emit('join_room', {'room': room});
  }

  void leaveRoom(String room) {
    _socket?.emit('leave_room', {'room': room});
    if (room == _activeRoom) {
      _activeRoom = 'general';
    }
  }

  void setActiveRoom(String room) {
    _activeRoom = room;
  }

  void sendMessage(
    String room,
    String message,
    String userId,
    String username, [
    String? messageId,
    String? userGlobalId,
  ]) {
    try {
      final clientMessageId = (messageId != null && messageId.isNotEmpty)
          ? messageId
          : 'local_${DateTime.now().microsecondsSinceEpoch}_$userId';
      final messageData = {
        'room': room,
        'message': message,
        'userId': userId,
        'username': username,
        'timestamp': DateTime.now().toIso8601String(),
        'chatType': room.startsWith('private_') ? 'private' : 'global',
        if (userGlobalId != null && userGlobalId.isNotEmpty) 'global_id': userGlobalId,
        'clientMessageId': clientMessageId,
        'messageId': clientMessageId,
        'lifecycleState': _isConnected ? 'sent' : 'queued',
        'pending': true,
      };

      _outboundMessagesById[clientMessageId] = messageData;
      _upsertLocalMessage(messageData);
      _attemptSend(clientMessageId);
    } catch (e) {
      logger.error('Error sending message', tag: 'chat-socket', error: e);
    }
  }

  List<Map<String, dynamic>> messagesForRoom(String room) {
    return _roomMessages[room] ?? [];
  }

  /// Get last message text for a room
  String? lastMessageTextForRoom(String roomId) {
    final messages = _roomMessages[roomId] ?? [];
    if (messages.isEmpty) return null;
    final lastMessage = messages.last;
    return lastMessage['message']?.toString() ?? lastMessage['text']?.toString();
  }

  /// Get last message timestamp for a room
  DateTime? lastMessageTimestampForRoom(String roomId) {
    final messages = _roomMessages[roomId] ?? [];
    if (messages.isEmpty) return null;
    final lastMessage = messages.last;
    final timestamp = lastMessage['timestamp']?.toString();
    if (timestamp == null) return null;
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Get unread count for a room
  int unreadCountForRoom(String roomId, String currentUserId) {
    final messages = _roomMessages[roomId] ?? [];
    // Count messages that are not from current user and not read
    return messages.where((msg) {
      final senderId = msg['userId']?.toString() ?? msg['senderId']?.toString();
      final isRead = msg['isRead'] ?? false;
      return senderId != currentUserId &&
          !_blockedUserIds.contains(senderId) &&
          !isRead;
    }).length;
  }

  /// Mark a user as blocked
  void markUserBlocked(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;
    _blockedUserIds.add(normalizedUserId);
    for (final room in _roomMessages.keys) {
      _roomMessages[room]!
          .removeWhere((msg) => (msg['userId']?.toString() ?? '') == normalizedUserId);
    }
    _messages.removeWhere((msg) => (msg['userId']?.toString() ?? '') == normalizedUserId);
    _onlineUsers.removeWhere((user) => (user['userId']?.toString() ?? '') == normalizedUserId);
    state = state.copyWith(
      messages: List.from(_messages),
      onlineUsers: List.from(_onlineUsers),
    );
    logger.info('User blocked', tag: 'chat-socket', context: {'userId': userId});
  }

  /// React to a message
  void reactToMessage(String messageId, String emoji) {
    if (!_isConnected || _socket == null) {
      logger.warn('Cannot react to message: Socket not connected', tag: 'chat-socket');
      return;
    }
    
    try {
      _socket!.emit('react_message', {
        'id': messageId,
        'emoji': emoji,
        'timestamp': DateTime.now().toIso8601String(),
      });
      logger.info('Reacted to message', tag: 'chat-socket', context: {'messageId': messageId, 'emoji': emoji});
    } catch (e) {
      logger.error('Error reacting to message', tag: 'chat-socket', error: e);
    }
  }

  /// Edit a message
  void editMessage(String messageId, String newText) {
    if (!_isConnected || _socket == null) {
      logger.warn('Cannot edit message: Socket not connected', tag: 'chat-socket');
      return;
    }
    
    try {
      _socket!.emit('edit_message', {
        'id': messageId,
        'message': newText,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Update local state
      for (final room in _roomMessages.keys) {
        final index = _roomMessages[room]!.indexWhere((msg) => msg['id'] == messageId || msg['messageId'] == messageId);
        if (index != -1) {
          _roomMessages[room]![index]['message'] = newText;
          _roomMessages[room]![index]['text'] = newText;
          _roomMessages[room]![index]['edited'] = true;
          _roomMessages[room]![index]['editedAt'] = DateTime.now().toIso8601String();
        }
      }
      
      logger.info('Edited message', tag: 'chat-socket', context: {'messageId': messageId});
    } catch (e) {
      logger.error('Error editing message', tag: 'chat-socket', error: e);
    }
  }

  /// Add a local Polie message (optimistic update)
  void addLocalPolieMessage(Map<String, dynamic> messageData) {
    final room = messageData['room'] ?? _activeRoom;
    if (!_roomMessages.containsKey(room)) {
      _roomMessages[room] = [];
    }
    _roomMessages[room]!.add(messageData);
    _messages.add(messageData);
    state = state.copyWith(messages: List.from(_messages));
    logger.info('Added local Polie message', tag: 'chat-socket', context: {'room': room});
  }

  List<Map<String, dynamic>> get messages => _messages;
  List<Map<String, dynamic>> get onlineUsers => _onlineUsers;
  bool get isConnected => _isConnected;

}

class ChatSocketState {
  final bool isConnected;
  final List<Map<String, dynamic>> messages;
  final List<Map<String, dynamic>> onlineUsers;

  ChatSocketState({
    required this.isConnected,
    required this.messages,
    required this.onlineUsers,
  });

  factory ChatSocketState.initial() => ChatSocketState(
        isConnected: false,
        messages: [],
        onlineUsers: [],
      );

  ChatSocketState copyWith({
    bool? isConnected,
    List<Map<String, dynamic>>? messages,
    List<Map<String, dynamic>>? onlineUsers,
  }) {
    return ChatSocketState(
      isConnected: isConnected ?? this.isConnected,
      messages: messages ?? this.messages,
      onlineUsers: onlineUsers ?? this.onlineUsers,
    );
  }
}

/// Chat Socket Provider
final chatSocketProvider = NotifierProvider<ChatSocketNotifier, ChatSocketState>(() {
  return ChatSocketNotifier();
});

/// Backward-compatible alias
final socketProvider = chatSocketProvider;

