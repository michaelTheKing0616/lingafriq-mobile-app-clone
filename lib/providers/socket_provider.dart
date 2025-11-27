import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:lingafriq/utils/api.dart';
import 'base_provider.dart';

final socketProvider = NotifierProvider<SocketProvider, BaseProviderState>(() {
  return SocketProvider();
});

class SocketProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  IO.Socket? _socket;
  bool _isConnected = false;
  final List<Map<String, dynamic>> _onlineUsers = [];
  final List<Map<String, dynamic>> _messages = [];

  bool get isConnected => _isConnected;
  List<Map<String, dynamic>> get onlineUsers => List.unmodifiable(_onlineUsers);
  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);

  @override
  BaseProviderState build() {
    return BaseProviderState();
  }

  Future<void> connect(String userId, String username) async {
    try {
      // Replace with your actual Socket.io server URL
      final serverUrl = Api.baseurl.replaceFirst('http://', '').replaceFirst('https://', '');
      
      _socket = IO.io(
        'https://$serverUrl', // or your Socket.io server URL
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setExtraHeaders({'userId': userId})
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('Socket connected');
        _isConnected = true;
        _socket!.emit('user_connected', {
          'userId': userId,
          'username': username,
        });
        state = state.copyWith();
      });

      _socket!.onDisconnect((_) {
        debugPrint('Socket disconnected');
        _isConnected = false;
        state = state.copyWith();
      });

      _socket!.on('online_users', (data) {
        if (data is List) {
          _onlineUsers.clear();
          _onlineUsers.addAll(data.map((e) => Map<String, dynamic>.from(e)));
          state = state.copyWith();
        }
      });

      _socket!.on('new_message', (data) {
        if (data is Map) {
          _messages.add(Map<String, dynamic>.from(data));
          state = state.copyWith();
        }
      });

      _socket!.on('user_joined', (data) {
        if (data is Map) {
          _onlineUsers.add(Map<String, dynamic>.from(data));
          state = state.copyWith();
        }
      });

      _socket!.on('user_left', (data) {
        if (data is Map) {
          final userId = data['userId'];
          _onlineUsers.removeWhere((user) => user['userId'] == userId);
          state = state.copyWith();
        }
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('Socket connection error: $e');
    }
  }

  void sendMessage(String room, String message, String userId, String username) {
    if (_socket != null && _isConnected) {
      _socket!.emit('send_message', {
        'room': room,
        'message': message,
        'userId': userId,
        'username': username,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void joinRoom(String room) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_room', {'room': room});
    }
  }

  void leaveRoom(String room) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave_room', {'room': room});
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _onlineUsers.clear();
      _messages.clear();
      state = state.copyWith();
    }
  }
}

