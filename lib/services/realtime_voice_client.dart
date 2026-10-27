import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:livekit_client/livekit_client.dart';

/// Gateway-owned realtime voice (P6-075): LiveKit room + cascaded turn phases.
class RealtimeVoiceClient {
  RealtimeVoiceClient(this._dio);

  final Dio _dio;

  static const String sessionPath = '/api/ai/realtime/session';

  static const List<String> cascadePhases = ['vad', 'stt', 'llm', 'tts'];

  /// P6-079: agent playback must stop within this window after barge-in.
  static const int agentStopDeadlineMs = 300;

  static const String bargeInControlType = 'control.bargeIn';
  static const String cancelTtsControlType = 'control.cancelTts';
  static const String pttControlType = 'control.ptt';

  Room? _room;
  RealtimeBargeInState _bargeIn = const RealtimeBargeInState();
  RealtimePttState _ptt = const RealtimePttState();

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
    _bargeIn = const RealtimeBargeInState();
    _ptt = const RealtimePttState();
    if (room != null) {
      await room.disconnect();
    }
  }

  RealtimeBargeInState get bargeInState => _bargeIn;

  RealtimePttState get pttState => _ptt;

  /// User or auto-offer enabled push-to-talk; gateway VAD is bypassed while active.
  void configurePushToTalk({required bool enabled}) {
    _ptt = applyPushToTalkEnabled(_ptt, enabled: enabled);
  }

  /// AC2: surface when low-bandwidth mode or constrained cellular link is detected.
  bool applyAutoPushToTalkOffer(RealtimeVoiceNetworkProfile profile) {
    if (!shouldOfferPushToTalkAutomatically(profile)) return false;
    configurePushToTalk(enabled: true);
    return true;
  }

  void onPttHoldStart() {
    _ptt = pttHoldStarted(_ptt);
  }

  void onPttHoldEnd() {
    _ptt = pttHoldEnded(_ptt);
  }

  void onPttSendComplete() {
    _ptt = pttSendCompleted(_ptt);
  }

  void onPttSendFailed() {
    _ptt = pttSendFailed(_ptt);
  }

  /// Publishes PTT gate to the room so the agent skips VAD while the button is held.
  Future<void> syncPushToTalkCapture({
    required String sessionId,
    required bool micOpen,
  }) async {
    final room = _room;
    if (room == null) return;
    final payload = buildPttControlEvent(sessionId: sessionId, active: micOpen);
    await _publishControlEvent(room, payload);
  }

  Future<void> beginPttHold({required String sessionId}) async {
    onPttHoldStart();
    if (isMicCaptureOpen(_ptt)) {
      await syncPushToTalkCapture(sessionId: sessionId, micOpen: true);
    }
  }

  Future<void> endPttHold({required String sessionId}) async {
    onPttHoldEnd();
    await syncPushToTalkCapture(sessionId: sessionId, micOpen: false);
  }

  Future<void> setPttToggleLatch({
    required String sessionId,
    required bool latched,
  }) async {
    configurePushToTalk(enabled: true);
    _ptt = pttToggleLatch(_ptt, latched: latched);
    await syncPushToTalkCapture(
      sessionId: sessionId,
      micOpen: isMicCaptureOpen(_ptt),
    );
  }

  /// Call when agent TTS begins so local interrupt timing is bounded.
  void onAgentTtsStarted({required String fullReply}) {
    _bargeIn = RealtimeBargeInState(
      agentSpeaking: true,
      fullReply: fullReply,
      spokenCharIndex: 0,
      playbackStartedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void onAgentTtsProgress(int spokenCharIndex) {
    if (!_bargeIn.agentSpeaking) return;
    final capped = spokenCharIndex.clamp(0, _bargeIn.fullReply.length);
    _bargeIn = _bargeIn.copyWith(spokenCharIndex: capped);
  }

  /// AC2: sub-threshold mic energy does not interrupt agent speech.
  BargeInEvaluation evaluateLocalSpeechWhileAgentSpeaking({
    required double rmsEnergy,
    required double energyFloor,
    required int minSpeechFrames,
    int frameDurationMs = 20,
  }) {
    final result = evaluateRealtimeBargeIn(
      rmsEnergy: rmsEnergy,
      energyFloor: energyFloor,
      minSpeechFrames: minSpeechFrames,
      frameDurationMs: frameDurationMs,
      state: _bargeIn,
    );
    _bargeIn = result.nextState;
    return result;
  }

  /// Stops local agent audio and notifies the gateway (manual or VAD barge-in).
  Future<void> interruptAgentSpeech({
    required String sessionId,
    Future<void> Function()? stopLocalPlayback,
  }) async {
    final started = _bargeIn.playbackStartedAtMs;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (started != null && now - started > agentStopDeadlineMs + 5000) {
      // Stale session guard — still emit control for server parity.
    }
    await stopLocalPlayback?.call();
    final truncated = truncateAssistantHistoryAtSpokenPoint(
      _bargeIn.fullReply,
      _bargeIn.spokenCharIndex,
    );
    _bargeIn = _bargeIn.copyWith(
      agentSpeaking: false,
      fullReply: truncated,
      lastBargeInAtMs: now,
    );
    final room = _room;
    if (room == null) return;
    final payload = buildRealtimeControlEvent(
      type: bargeInControlType,
      sessionId: sessionId,
    );
    final cancel = buildRealtimeControlEvent(
      type: cancelTtsControlType,
      sessionId: sessionId,
    );
    await _publishControlEvent(room, payload);
    await _publishControlEvent(room, cancel);
  }

  Future<void> _publishControlEvent(Room room, Map<String, dynamic> event) async {
    final participant = room.localParticipant;
    if (participant == null) return;
    final encoded = utf8.encode(jsonEncode(event));
    await participant.publishData(encoded, reliable: true);
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

class RealtimeBargeInState {
  const RealtimeBargeInState({
    this.agentSpeaking = false,
    this.fullReply = '',
    this.spokenCharIndex = 0,
    this.playbackStartedAtMs,
    this.consecutiveSpeechFrames = 0,
    this.lastBargeInAtMs,
  });

  final bool agentSpeaking;
  final String fullReply;
  final int spokenCharIndex;
  final int? playbackStartedAtMs;
  final int consecutiveSpeechFrames;
  final int? lastBargeInAtMs;

  RealtimeBargeInState copyWith({
    bool? agentSpeaking,
    String? fullReply,
    int? spokenCharIndex,
    int? playbackStartedAtMs,
    int? consecutiveSpeechFrames,
    int? lastBargeInAtMs,
  }) {
    return RealtimeBargeInState(
      agentSpeaking: agentSpeaking ?? this.agentSpeaking,
      fullReply: fullReply ?? this.fullReply,
      spokenCharIndex: spokenCharIndex ?? this.spokenCharIndex,
      playbackStartedAtMs: playbackStartedAtMs ?? this.playbackStartedAtMs,
      consecutiveSpeechFrames: consecutiveSpeechFrames ?? this.consecutiveSpeechFrames,
      lastBargeInAtMs: lastBargeInAtMs ?? this.lastBargeInAtMs,
    );
  }
}

class BargeInEvaluation {
  const BargeInEvaluation({
    required this.shouldBarge,
    required this.nextState,
  });

  final bool shouldBarge;
  final RealtimeBargeInState nextState;
}

Map<String, dynamic> buildRealtimeControlEvent({
  required String type,
  required String sessionId,
}) {
  return {'type': type, 'sessionId': sessionId};
}

Map<String, dynamic> buildPttControlEvent({
  required String sessionId,
  required bool active,
}) {
  return {
    'type': RealtimeVoiceClient.pttControlType,
    'sessionId': sessionId,
    'active': active,
    'bypassVad': true,
  };
}

enum RealtimeCaptureMode { vad, pushToTalk }

enum RealtimePttPhase { idle, held, sending, error }

/// Inputs for automatic PTT offer (AC2); keep pure for tests.
class RealtimeVoiceNetworkProfile {
  const RealtimeVoiceNetworkProfile({
    required this.lowBandwidthActive,
    required this.cellularOrConstrained,
    this.downlinkKbps,
  });

  final bool lowBandwidthActive;
  final bool cellularOrConstrained;
  final int? downlinkKbps;
}

/// Below this effective downlink the client offers push-to-talk (§7.7 noisy / 2G–3G band).
const int realtimePttBandwidthThresholdKbps = 256;

bool shouldOfferPushToTalkAutomatically(RealtimeVoiceNetworkProfile profile) {
  if (profile.lowBandwidthActive) return true;
  if (profile.cellularOrConstrained) return true;
  final kbps = profile.downlinkKbps;
  if (kbps != null && kbps < realtimePttBandwidthThresholdKbps) return true;
  return false;
}

bool realtimeBypassesVad(RealtimeCaptureMode mode) => mode == RealtimeCaptureMode.pushToTalk;

class RealtimePttState {
  const RealtimePttState({
    this.captureMode = RealtimeCaptureMode.vad,
    this.phase = RealtimePttPhase.idle,
    this.latchHeld = false,
    this.useToggleLatch = false,
  });

  final RealtimeCaptureMode captureMode;
  final RealtimePttPhase phase;
  final bool latchHeld;
  final bool useToggleLatch;

  RealtimePttState copyWith({
    RealtimeCaptureMode? captureMode,
    RealtimePttPhase? phase,
    bool? latchHeld,
    bool? useToggleLatch,
  }) {
    return RealtimePttState(
      captureMode: captureMode ?? this.captureMode,
      phase: phase ?? this.phase,
      latchHeld: latchHeld ?? this.latchHeld,
      useToggleLatch: useToggleLatch ?? this.useToggleLatch,
    );
  }
}

RealtimePttState applyPushToTalkEnabled(RealtimePttState state, {required bool enabled}) {
  if (!enabled) {
    return const RealtimePttState();
  }
  return state.copyWith(
    captureMode: RealtimeCaptureMode.pushToTalk,
    phase: RealtimePttPhase.idle,
    latchHeld: false,
  );
}

RealtimePttState pttHoldStarted(RealtimePttState state) {
  if (state.captureMode != RealtimeCaptureMode.pushToTalk) return state;
  return state.copyWith(phase: RealtimePttPhase.held);
}

RealtimePttState pttHoldEnded(RealtimePttState state) {
  if (state.captureMode != RealtimeCaptureMode.pushToTalk) return state;
  if (state.useToggleLatch) return state;
  return state.copyWith(phase: RealtimePttPhase.sending);
}

RealtimePttState pttSendCompleted(RealtimePttState state) {
  return state.copyWith(phase: RealtimePttPhase.idle, latchHeld: false);
}

RealtimePttState pttSendFailed(RealtimePttState state) {
  return state.copyWith(phase: RealtimePttPhase.error);
}

RealtimePttState pttToggleLatch(RealtimePttState state, {required bool latched}) {
  if (state.captureMode != RealtimeCaptureMode.pushToTalk) return state;
  return state.copyWith(
    useToggleLatch: true,
    latchHeld: latched,
    phase: latched ? RealtimePttPhase.held : RealtimePttPhase.idle,
  );
}

/// AC1: in PTT mode the mic is open only while held (or latched for motor access).
bool isMicCaptureOpen(RealtimePttState state) {
  if (state.captureMode == RealtimeCaptureMode.vad) return true;
  return state.phase == RealtimePttPhase.held;
}

String truncateAssistantHistoryAtSpokenPoint(String fullReply, int spokenCharIndex) {
  if (spokenCharIndex <= 0) return '';
  if (spokenCharIndex >= fullReply.length) return fullReply.trimRight();
  return fullReply.substring(0, spokenCharIndex).trimRight();
}

BargeInEvaluation evaluateRealtimeBargeIn({
  required double rmsEnergy,
  required double energyFloor,
  required int minSpeechFrames,
  required int frameDurationMs,
  required RealtimeBargeInState state,
}) {
  if (!state.agentSpeaking) {
    return BargeInEvaluation(shouldBarge: false, nextState: state);
  }
  if (rmsEnergy < energyFloor) {
    return BargeInEvaluation(
      shouldBarge: false,
      nextState: state.copyWith(consecutiveSpeechFrames: 0),
    );
  }
  final frames = state.consecutiveSpeechFrames + 1;
  final next = state.copyWith(consecutiveSpeechFrames: frames);
  if (frames < minSpeechFrames) {
    return BargeInEvaluation(shouldBarge: false, nextState: next);
  }
  final minDurationMs = minSpeechFrames * frameDurationMs;
  if (minDurationMs <= 0) {
    return BargeInEvaluation(shouldBarge: false, nextState: next);
  }
  return BargeInEvaluation(shouldBarge: true, nextState: next);
}
