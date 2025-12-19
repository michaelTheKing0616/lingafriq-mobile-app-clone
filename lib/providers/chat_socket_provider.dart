import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/gamification/socket_service.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/socket_provider.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Chat Socket Provider - Wraps socket service for chat functionality
class ChatSocketNotifier extends Notifier<ChatSocketState> {
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _onlineUsers = [];
  final Set<String> _blockedUserIds = {};
  final List<Map<String, dynamic>> _pendingQueue = [];
  String _activeRoom = 'general';
  bool _isConnected = false;
  final Map<String, List<Map<String, dynamic>>> _roomMessages = {};
  IO.Socket? _socket;

  @override
  ChatSocketState build() {
    _initializeSocket();
    return ChatSocketState.initial();
  }

  void _initializeSocket() {
    final api = ref.read(apiProvider.notifier);
    final token = api.token;
    final user = ref.read(userProvider);
    final apiBaseUrl =
        Api.baseurl.replaceFirst('http://', '').replaceFirst('https://', '');

    final headers = <String, dynamic>{};
    if (user != null) {
      headers['userid'] = user.id.toString();
      headers['username'] = user.username;
    }
    if (token != null) {
      headers['authorization'] = 'Bearer $token';
    }

    _socket = IO.io(
      'http://$apiBaseUrl',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setExtraHeaders(headers)
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      state = state.copyWith(isConnected: true);

      // Load blocked users once on connect so we can filter messages client-side
      api.getBlockedUsers().then((blocked) {
        _blockedUserIds
          ..clear()
          ..addAll(blocked
              .map((u) => (u['userId'] ?? u['id'] ?? '').toString())
              .where((id) => id.isNotEmpty));
      }).catchError((e) {
        // Non-fatal; chat still works without block filtering
      });

      // Flush any messages that were queued while offline.
      if (_pendingQueue.isNotEmpty) {
        for (final msg in List<Map<String, dynamic>>.from(_pendingQueue)) {
          _socket?.emit('send_message', msg);
        }
        _pendingQueue.clear();
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      state = state.copyWith(isConnected: false);
    });

    // New-message stream from backend chat server
    _socket!.on('new_message', (data) {
      final messageData = Map<String, dynamic>.from(data);
      final room = messageData['room'] ?? _activeRoom;
      final senderId = messageData['userId']?.toString();
      if (senderId != null && _blockedUserIds.contains(senderId)) {
        // Skip messages from blocked users
        return;
      }
      if (!_roomMessages.containsKey(room)) {
        _roomMessages[room] = [];
      }
      // Mark messages as delivered once they are echoed back from the server.
      messageData['status'] = messageData['status'] ?? 'delivered';
      _roomMessages[room]!.add(messageData);
      _messages.add(messageData);
      state = state.copyWith(messages: List.from(_messages));
    });

    // Server-side edit propagation
    _socket!.on('message_edited', (data) {
      final payload = Map<String, dynamic>.from(data);
      final id = payload['id']?.toString();
      if (id == null) return;
      for (final list in [_messages, ..._roomMessages.values]) {
        for (final msg in list) {
          if (msg['id']?.toString() == id) {
            msg['message'] = payload['message'] ?? msg['message'];
            msg['edited'] = payload['edited'] ?? true;
            msg['editedAt'] = payload['editedAt'] ?? msg['editedAt'];
          }
        }
      }
      state = state.copyWith(messages: List.from(_messages));
    });

    // Server-side reactions propagation
    _socket!.on('message_reacted', (data) {
      final payload = Map<String, dynamic>.from(data);
      final id = payload['id']?.toString();
      if (id == null) return;
      for (final list in [_messages, ..._roomMessages.values]) {
        for (final msg in list) {
          if (msg['id']?.toString() == id) {
            msg['reactions'] = payload['reactions'] ?? msg['reactions'];
          }
        }
      }
      state = state.copyWith(messages: List.from(_messages));
    });

    // Online users presence from backend
    _socket!.on('online_users', (data) {
      final list = (data as List)
          .map<Map<String, dynamic>>(
              (u) => Map<String, dynamic>.from(u as Map))
          .toList();
      _onlineUsers
        ..clear()
        ..addAll(list);
      state = state.copyWith(onlineUsers: List.from(_onlineUsers));
    });
  }

  void connect(String userId, String username) {
    if (!_isConnected) {
      _socket?.connect();
      // Inform server of the authenticated user for richer presence data
      _socket?.emit('user_connected', {
        'userId': userId,
        'username': username,
      });
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
    String username, {
    String chatType = 'global',
    String messageType = 'text',
    String? recipientId,
    String? replyTo,
    String? fileUrl,
  }) {
    final now = DateTime.now().toIso8601String();
    final messageData = {
      'room': room,
      'message': message,
      'userId': userId,
      'username': username,
      'timestamp': now,
      'chatType': chatType,
      'messageType': messageType,
      if (recipientId != null) 'recipientId': recipientId,
      if (replyTo != null) 'replyTo': replyTo,
      if (fileUrl != null) 'fileUrl': fileUrl,
      // Local status used only until the server echoes back the message.
      'status': 'sending',
    };

    if (_isConnected && _socket != null) {
      _socket!.emit('send_message', messageData);
    } else {
      // Queue the message to be sent when connection is restored.
      _pendingQueue.add(messageData);
    }
  }

  /// Insert a local-only Polie assistant message into a room.
  /// This does not emit to the socket server, but gives the user
  /// an in-chat AI assistant similar to @Meta in WhatsApp.
  void addLocalPolieMessage(String room, String text) {
    final messageData = {
      'room': room,
      'message': text,
      'userId': 'polie',
      'username': 'Polie',
      'timestamp': DateTime.now().toIso8601String(),
      'isPolie': true,
      'status': 'local',
    };
    if (!_roomMessages.containsKey(room)) {
      _roomMessages[room] = [];
    }
    _roomMessages[room]!.add(messageData);
    _messages.add(messageData);
    state = state.copyWith(messages: List.from(_messages));
  }

  List<Map<String, dynamic>> messagesForRoom(String room) {
    return _roomMessages[room] ?? [];
  }

  List<Map<String, dynamic>> get messages => _messages;
  List<Map<String, dynamic>> get onlineUsers => _onlineUsers;
  bool get isConnected => _isConnected;

  bool isUserBlocked(String userId) => _blockedUserIds.contains(userId);

  void markUserBlocked(String userId) {
    _blockedUserIds.add(userId);
  }

  void markUserUnblocked(String userId) {
    _blockedUserIds.remove(userId);
  }

  /// Request an edit of an already-sent message.
  void editMessage(String messageId, String newText) {
    if (_socket == null) return;
    _socket!.emit('edit_message', {
      'id': messageId,
      'message': newText,
    });
  }

  /// React to a message with a simple emoji.
  void reactToMessage(String messageId, String emoji) {
    if (_socket == null) return;
    _socket!.emit('react_message', {
      'id': messageId,
      'emoji': emoji,
    });
  }

  /// Remove a previously-sent reaction.
  void removeReaction(String messageId, String emoji) {
    if (_socket == null) return;
    _socket!.emit('unreact_message', {
      'id': messageId,
      'emoji': emoji,
    });
  }

  void dispose() {
    _socket?.disconnect();
  }
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
final socketProvider = NotifierProvider<ChatSocketNotifier, ChatSocketState>(() {
  return ChatSocketNotifier();
});

