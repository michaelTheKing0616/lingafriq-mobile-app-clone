import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:lingafriq/utils/api.dart';
import 'base_provider.dart';

final socketProvider = NotifierProvider<SocketProvider, BaseProviderState>(() {
  return SocketProvider();
});

class SocketProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  io.Socket? _socket;
  bool _isConnected = false;
  final List<Map<String, dynamic>> _onlineUsers = [];
  final Map<String, List<Map<String, dynamic>>> _messagesByRoom = {};
  String _activeRoom = 'general';
  final Random _secureRandom = Random.secure();

  bool get isConnected => _isConnected;
  List<Map<String, dynamic>> get onlineUsers => List.unmodifiable(_onlineUsers);
  List<Map<String, dynamic>> get messages =>
      List.unmodifiable(_messagesByRoom[_activeRoom] ?? const []);

  @override
  BaseProviderState build() {
    return BaseProviderState();
  }

  void setActiveRoom(String room) {
    _activeRoom = room;
    _messagesByRoom.putIfAbsent(room, () => []);
    state = state.copyWith();
  }

  List<Map<String, dynamic>> messagesForRoom(String room) {
    return List.unmodifiable(_messagesByRoom[room] ?? const []);
  }

  Future<void> connect(String userId, String username) async {
    try {
      final baseUrl = Api.baseurl.replaceAll(RegExp(r'/+$'), '');
      _messagesByRoom.putIfAbsent('general', () => []);
      _activeRoom = 'general';
      
      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setExtraHeaders({'userId': userId, 'username': username})
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
          final parsed = Map<String, dynamic>.from(data);
          final room = parsed['room']?.toString() ?? 'general';
          final text = parsed['message']?.toString() ?? '';
          parsed['message'] = _decryptIfNeeded(room, text);
          _appendMessage(room, parsed);
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
      final payload = room.startsWith('private_')
          ? _encryptPayload(room, message)
          : message;
      _socket!.emit('send_message', {
        'room': room,
        'message': payload,
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
      _messagesByRoom.clear();
      _activeRoom = 'general';
      state = state.copyWith();
    }
  }

  void _appendMessage(String room, Map<String, dynamic> message) {
    final bucket = _messagesByRoom.putIfAbsent(room, () => []);
    bucket.add(message);
    if (room == _activeRoom) {
      state = state.copyWith();
    }
  }

  String _encryptPayload(String room, String text) {
    final ivBytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    final key = encrypt.Key(Uint8List.fromList(_deriveKey(room)));
    final iv = encrypt.IV(Uint8List.fromList(ivBytes));
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(text, iv: iv);
    return 'e2e::${base64Encode(ivBytes)}::${encrypted.base64}';
  }

  String _decryptIfNeeded(String room, String message) {
    if (!message.startsWith('e2e::')) return message;
    final parts = message.split('::');
    if (parts.length != 3) return message;
    try {
      final ivBytes = base64Decode(parts[1]);
      final cipher = parts[2];
      final key = encrypt.Key(Uint8List.fromList(_deriveKey(room)));
      final iv = encrypt.IV(ivBytes);
      final encrypter =
          encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
      return encrypter.decrypt64(cipher, iv: iv);
    } catch (_) {
      return '[Unable to decrypt message]';
    }
  }

  List<int> _deriveKey(String room) {
    final seed = 'polie-secure-room::$room';
    final digest = sha256.convert(utf8.encode(seed));
    return digest.bytes;
  }
}

