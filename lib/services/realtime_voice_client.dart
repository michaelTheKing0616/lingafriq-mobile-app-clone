import 'package:dio/dio.dart';
import 'package:livekit_client/livekit_client.dart';

/// Gateway-owned realtime voice (P6-075): LiveKit room + cascaded turn phases.
class RealtimeVoiceClient {
  RealtimeVoiceClient(this._dio);

  final Dio _dio;

  static const String sessionPath = '/api/ai/realtime/session';

  static const List<String> cascadePhases = ['vad', 'stt', 'llm', 'tts'];

  Room? _room;

  /// Fetches a scoped LiveKit token from the gateway (never a vendor key).
  Future<RealtimeSessionCredentials> startSession({
    required String language,
    required String mode,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      sessionPath,
      data: {
        'language': language,
        'mode': mode,
      },
    );
    final data = response.data ?? {};
    final token = data['livekit_token']?.toString() ?? data['livekitToken']?.toString();
    final url = data['livekit_url']?.toString() ?? data['livekitUrl']?.toString();
    final roomName = data['room_name']?.toString() ?? data['roomName']?.toString();
    if (token == null || token.isEmpty || url == null || url.isEmpty) {
      throw RealtimeVoiceException(
        'realtime_session_invalid',
        statusCode: response.statusCode,
      );
    }
    return RealtimeSessionCredentials(
      livekitToken: token,
      livekitUrl: url,
      roomName: roomName ?? '',
    );
  }

  Future<Room> connect(RealtimeSessionCredentials credentials) async {
    final room = Room();
    await room.connect(credentials.livekitUrl, credentials.livekitToken);
    _room = room;
    return room;
  }

  Future<void> disconnect() async {
    final room = _room;
    _room = null;
    if (room != null) {
      await room.disconnect();
    }
  }

  static String userMessageFor(DioException error) {
    final code = _errorCode(error);
    if (code == 'quota_exceeded') {
      return 'Daily voice AI limit reached. Try again after the reset time.';
    }
    if (code == 'unauthenticated') {
      return 'Sign in again to use voice conversation.';
    }
    if (code == 'livekit_unconfigured') {
      return 'Voice rooms are not available right now.';
    }
    return 'Voice conversation is unavailable. Please try again.';
  }

  static String? _errorCode(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return null;
  }

  static RealtimeVoiceException fromDio(DioException error) {
    return RealtimeVoiceException(
      _errorCode(error) ?? 'realtime_request_failed',
      statusCode: error.response?.statusCode,
    );
  }
}

class RealtimeSessionCredentials {
  const RealtimeSessionCredentials({
    required this.livekitToken,
    required this.livekitUrl,
    required this.roomName,
  });

  final String livekitToken;
  final String livekitUrl;
  final String roomName;
}

class RealtimeVoiceException implements Exception {
  RealtimeVoiceException(this.errorCode, {this.statusCode});

  final String errorCode;
  final int? statusCode;

  @override
  String toString() => 'RealtimeVoiceException($errorCode)';
}
