import 'package:dio/dio.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/env_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Live (hybrid) translate: create an HTTP session, then stream on-device STT
/// text segments over the existing Socket.IO connection used by the backend.
class LiveTranslateSessionResponse {
  LiveTranslateSessionResponse({
    required this.sessionId,
    required this.socketToken,
    required this.socketPath,
    required this.expiresAtMs,
  });

  final String sessionId;
  final String socketToken;
  final String socketPath;
  final int expiresAtMs;

  factory LiveTranslateSessionResponse.fromJson(Map<String, dynamic> json) {
    return LiveTranslateSessionResponse(
      sessionId: json['sessionId']?.toString() ?? '',
      socketToken: json['token']?.toString() ?? '',
      socketPath: json['socketPath']?.toString() ?? '/socket.io',
      expiresAtMs: (json['expiresAt'] is num)
          ? (json['expiresAt'] as num).toInt()
          : int.tryParse(json['expiresAt']?.toString() ?? '') ?? 0,
    );
  }
}

typedef LiveTranslateServerCallback = void Function(Map<String, dynamic> event);

/// Thin Socket.IO wrapper aligned with `live_translate_event` on the server.
class LiveTranslateRealtimeClient {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected == true;

  /// Origin only, e.g. `https://admin.lingafriq.com` (no path).
  static String socketOrigin() {
    final base = EnvConfig.backendBaseUrl.trim();
    final uri = Uri.parse(base);
    if (uri.hasScheme && uri.host.isNotEmpty) {
      return uri.origin;
    }
    return base;
  }

  void connect({
    required String socketToken,
    void Function(dynamic data)? onAnyError,
    void Function()? onConnect,
    void Function(dynamic reason)? onDisconnect,
    void Function(dynamic error)? onConnectError,
    required LiveTranslateServerCallback onServerEvent,
  }) {
    disconnect();
    final origin = socketOrigin();
    _socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': socketToken})
          .enableReconnection()
          .build(),
    );

    _socket!.on('connect', (_) => onConnect?.call());
    _socket!.on('disconnect', (reason) => onDisconnect?.call(reason));
    _socket!.on('error', (e) => onAnyError?.call(e));
    _socket!.on('connect_error', (e) => onConnectError?.call(e));
    _socket!.on(
      'live_translate_event',
      (dynamic data) {
        if (data is Map<String, dynamic>) {
          onServerEvent(data);
        } else if (data is Map) {
          onServerEvent(Map<String, dynamic>.from(data));
        }
      },
    );
    _socket!.connect();
  }

  void disconnect() {
    try {
      _socket?.disconnect();
    } catch (_) {}
    _socket = null;
  }

  void emitClientEvent(Map<String, dynamic> payload) {
    final s = _socket;
    if (s == null || !s.connected) {
      throw StateError('Socket not connected');
    }
    s.emit('live_translate_event', payload);
  }

  /// POST `/api/live-translate/session` — requires authenticated Dio (Bearer).
  static Future<LiveTranslateSessionResponse> createSession(
    Dio dio, {
    required Map<String, dynamic> body,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      ApiContract.liveTranslate.session,
      data: body,
    );
    final data = res.data;
    if (data == null) {
      throw StateError('Empty session response');
    }
    return LiveTranslateSessionResponse.fromJson(data);
  }
}
