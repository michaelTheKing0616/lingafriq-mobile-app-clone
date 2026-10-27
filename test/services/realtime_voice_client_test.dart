import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/realtime_voice_client.dart';

void main() {
  group('RealtimeVoiceClient', () {
    test('cascade phase order matches gateway agent', () {
      expect(RealtimeVoiceClient.cascadePhases, ['vad', 'stt', 'llm', 'tts']);
    });

    test('quota_exceeded maps to user message', () {
      final msg = RealtimeVoiceClient.userMessageFor(
        DioException(
          requestOptions: RequestOptions(path: RealtimeVoiceClient.sessionPath),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 429,
            data: {'error': 'quota_exceeded'},
          ),
        ),
      );
      expect(msg.toLowerCase(), contains('limit'));
    });

    test('startSession parses gateway token payload', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'livekit_token': 'jwt-fixture',
                  'livekit_url': 'wss://example.livekit.cloud',
                  'room_name': 'ai-realtime::u1::yo::sess',
                },
              ),
            );
          },
        ),
      );
      final client = RealtimeVoiceClient(dio);
      final creds = await client.startSession(language: 'yo', mode: 'conversation');
      expect(creds.livekitToken, 'jwt-fixture');
      expect(creds.roomName, contains('ai-realtime::'));
    });

    test('P6-079 truncates assistant history at spoken index', () {
      const full = 'Ẹ ṣeun. Jẹ́ kí a tún sọ̀rọ̀.';
      expect(truncateAssistantHistoryAtSpokenPoint(full, 8), 'Ẹ ṣeun.');
    });

    test('P6-079 low energy does not barge while agent speaks', () {
      const state = RealtimeBargeInState(agentSpeaking: true, fullReply: 'Hi.');
      final ev = evaluateRealtimeBargeIn(
        rmsEnergy: 0.01,
        energyFloor: 0.02,
        minSpeechFrames: 4,
        frameDurationMs: 20,
        state: state,
      );
      expect(ev.shouldBarge, isFalse);
      expect(ev.nextState.consecutiveSpeechFrames, 0);
    });

    test('P6-079 agent stop deadline is 300ms', () {
      expect(RealtimeVoiceClient.agentStopDeadlineMs, 300);
    });

    test('P6-083 PTT capture window only while held', () {
      var state = applyPushToTalkEnabled(const RealtimePttState(), enabled: true);
      expect(realtimeBypassesVad(state.captureMode), isTrue);
      expect(isMicCaptureOpen(state), isFalse);
      state = pttHoldStarted(state);
      expect(isMicCaptureOpen(state), isTrue);
      state = pttHoldEnded(state);
      expect(isMicCaptureOpen(state), isFalse);
      expect(state.phase, RealtimePttPhase.sending);
    });

    test('P6-083 auto-offer on low bandwidth or constrained link', () {
      expect(
        shouldOfferPushToTalkAutomatically(
          const RealtimeVoiceNetworkProfile(
            lowBandwidthActive: true,
            cellularOrConstrained: false,
          ),
        ),
        isTrue,
      );
      expect(
        shouldOfferPushToTalkAutomatically(
          RealtimeVoiceNetworkProfile(
            lowBandwidthActive: false,
            cellularOrConstrained: false,
            downlinkKbps: realtimePttBandwidthThresholdKbps - 1,
          ),
        ),
        isTrue,
      );
      expect(
        shouldOfferPushToTalkAutomatically(
          const RealtimeVoiceNetworkProfile(
            lowBandwidthActive: false,
            cellularOrConstrained: false,
            downlinkKbps: 1000,
          ),
        ),
        isFalse,
      );
    });

    test('P6-083 buildPttControlEvent bypasses VAD', () {
      final ev = buildPttControlEvent(sessionId: 'sess-1', active: true);
      expect(ev['type'], RealtimeVoiceClient.pttControlType);
      expect(ev['bypassVad'], isTrue);
      expect(ev['active'], isTrue);
    });

    test('P6-083 applyAutoPushToTalkOffer enables PTT', () {
      final dio = Dio();
      final client = RealtimeVoiceClient(dio);
      final offered = client.applyAutoPushToTalkOffer(
        const RealtimeVoiceNetworkProfile(
          lowBandwidthActive: true,
          cellularOrConstrained: false,
        ),
      );
      expect(offered, isTrue);
      expect(client.pttState.captureMode, RealtimeCaptureMode.pushToTalk);
    });

    test('P6-084 Opus bitrate clamped to 16–24 kbps', () {
      expect(clampOpusBitrateKbps(10), RealtimeVoiceClient.opusBitrateMinKbps);
      expect(clampOpusBitrateKbps(22), 22);
      expect(clampOpusBitrateKbps(48), RealtimeVoiceClient.opusBitrateMaxKbps);
      expect(negotiateRealtimeCodec(preferredBitrateKbps: 20).codec, 'opus');
    });

    test('P6-084 text fallback on 2G/3G with notice', () {
      final dio = Dio();
      final client = RealtimeVoiceClient(dio);
      final notice = client.applyNetworkTransport(
        const RealtimeCellularProfile(effectiveType: '3g'),
      );
      expect(notice, isNotNull);
      expect(client.transportState.mode, RealtimeTransportMode.textFallback);
      expect(
        client.tryResumeVoiceTransport(const RealtimeCellularProfile(effectiveType: '3g')),
        isFalse,
      );
      expect(
        client.tryResumeVoiceTransport(const RealtimeCellularProfile(effectiveType: '4g')),
        isTrue,
      );
      expect(client.transportState.mode, RealtimeTransportMode.voice);
    });

    test('P6-084 packet loss at 10% completes or errors', () {
      final dio = Dio();
      final client = RealtimeVoiceClient(dio);
      final ok = client.evaluateTurnPacketLoss(
        packetLossRatio: RealtimeVoiceClient.packetLossFailRatio,
        turnCompleted: true,
      );
      expect(ok.ok, isTrue);
      final fail = client.evaluateTurnPacketLoss(
        packetLossRatio: RealtimeVoiceClient.packetLossFailRatio,
        turnCompleted: false,
      );
      expect(fail.ok, isFalse);
      expect(fail.errorCode, 'realtime_packet_loss');
    });

    test('P6-084 startSession parses optional codec hints', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'livekit_token': 'jwt-fixture',
                  'livekit_url': 'wss://example.livekit.cloud',
                  'opus_bitrate_kbps': 18,
                },
              ),
            );
          },
        ),
      );
      final client = RealtimeVoiceClient(dio);
      final creds = await client.startSession(language: 'yo', mode: 'conversation');
      expect(creds.codec?.bitrateKbps, 18);
    });
  });
}
