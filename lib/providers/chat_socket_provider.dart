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
    final token = ref.read(apiProvider.notifier).token;
    final apiBaseUrl = Api.baseurl.replaceFirst('http://', '').replaceFirst('https://', '');
    
    _socket = IO.io(
      'http://$apiBaseUrl',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      state = state.copyWith(isConnected: true);
    });

    _socket!.onDisconnect((_) {
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
    if (!_isConnected) {
      _socket?.connect();
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
    final messageData = {
      'room': room,
      'message': message,
      'userId': userId,
      'username': username,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _socket?.emit('message', messageData);
    
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

