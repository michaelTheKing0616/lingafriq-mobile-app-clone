import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:lingafriq/utils/structured_logger.dart';

/// Chat Socket Provider - Wraps socket service for chat functionality
class ChatSocketNotifier extends Notifier<ChatSocketState> {
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _onlineUsers = [];
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
    try {
      final token = ref.read(apiProvider.notifier).token;
      // Use the base URL directly - socket.io client handles protocol conversion
      final baseUrl = Api.baseurl.replaceAll(RegExp(r'/$'), ''); // Remove trailing slashes
      
      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
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
      final room = messageData['room'] ?? _activeRoom;
      if (!_roomMessages.containsKey(room)) {
        _roomMessages[room] = [];
      }
      _roomMessages[room]!.add(messageData);
      _messages.add(messageData);
      state = state.copyWith(messages: List.from(_messages));
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
  }

  void connect(String userId, String username) {
    try {
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
    _socket?.emit('join', room);
  }

  void leaveRoom(String room) {
    _socket?.emit('leave', room);
    if (room == _activeRoom) {
      _activeRoom = 'general';
    }
  }

  void setActiveRoom(String room) {
    _activeRoom = room;
  }

  void sendMessage(String room, String message, String userId, String username) {
    if (!_isConnected || _socket == null) {
      logger.warn('Cannot send message: Socket not connected', tag: 'chat-socket');
      return;
    }
    
    try {
      final messageData = {
        'room': room,
        'message': message,
        'userId': userId,
        'username': username,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _socket!.emit('message', messageData);
      
      // Optimistically add to local state for immediate UI feedback
      if (!_roomMessages.containsKey(room)) {
        _roomMessages[room] = [];
      }
      _roomMessages[room]!.add(messageData);
      _messages.add(messageData);
      state = state.copyWith(messages: List.from(_messages));
    } catch (e) {
      logger.error('Error sending message', tag: 'chat-socket', error: e);
      // Don't update state if send fails - server will not receive it
    }
  }

  List<Map<String, dynamic>> messagesForRoom(String room) {
    return _roomMessages[room] ?? [];
  }

  List<Map<String, dynamic>> get messages => _messages;
  List<Map<String, dynamic>> get onlineUsers => _onlineUsers;
  bool get isConnected => _isConnected;

  void dispose() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
    } catch (e) {
      logger.error('Error disposing chat socket', tag: 'chat-socket', error: e);
    }
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

