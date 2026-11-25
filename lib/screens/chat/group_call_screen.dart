import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:livekit_client/livekit_client.dart';

/// P9-942 — Circle group voice/video call. Reference: WhatsApp group call.
const String kCallJoinCopy = 'Join call';
const String kCallDegradedCopy =
    'Connection is unstable. Switch to audio-only to keep talking.';
const String kCallDeniedCopy =
    'You cannot join this call. Check circle membership and guardian approval.';
const String kCallEndedCopy = 'Call ended';
const String kCallRingingCopy = 'Ringing…';

enum GroupCallPhase { ringing, connected, degraded, ended, denied }

class GroupCallScreen extends ConsumerStatefulWidget {
  const GroupCallScreen({
    super.key,
    required this.circleId,
    required this.circleName,
    this.callId,
    this.startCall = false,
  });

  final String circleId;
  final String circleName;
  final String? callId;
  final bool startCall;

  @override
  ConsumerState<GroupCallScreen> createState() => GroupCallScreenState();
}

class GroupCallScreenState extends ConsumerState<GroupCallScreen> {
  GroupCallPhase phase = GroupCallPhase.ringing;
  String? errorCode;
  String? activeCallId;
  Room? room;
  bool audioOnly = false;
  double packetLossEstimate = 0;
  Timer? pollTimer;
  bool loading = true;
  Map<String, dynamic>? policy;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    unawaited(_disconnect());
    super.dispose();
  }

  String get _apiBase => '/api/v2/circle-group-calls/${widget.circleId}';

  Future<void> _bootstrap() async {
    try {
      if (widget.startCall || widget.callId == null) {
        final res = await ApiService.post('$_apiBase/start', data: const {});
        final data = res.data;
        if (data is! Map || data['ok'] != true) {
          _deny('start_failed');
          return;
        }
        activeCallId = data['callId']?.toString();
        policy = data['policy'] is Map
            ? Map<String, dynamic>.from(data['policy'] as Map)
            : null;
      } else {
        activeCallId = widget.callId;
      }
      if (activeCallId == null || activeCallId!.isEmpty) {
        _deny('call_missing');
        return;
      }
      await _joinLiveKit(activeCallId!);
    } catch (e) {
      if (mounted) {
        final code = e.toString();
        if (code.contains('CALL_DENIED') || code.contains('403')) {
          _deny(GROUP_CALL_DENIED);
        } else {
          ErrorHandler.showError(context, e);
          _deny('error');
        }
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  static const String groupCallDenied = 'CALL_DENIED';

  void _deny(String code) {
    setState(() {
      phase = GroupCallPhase.denied;
      errorCode = code;
      loading = false;
    });
  }

  Future<void> _joinLiveKit(String callId) async {
    final jti = _newJti();
    final res = await ApiService.post(
      '$_apiBase/$callId/join',
      data: {'jti': jti},
    );
    final data = res.data;
    if (data is! Map || data['ok'] != true) {
      _deny(data is Map ? data['code']?.toString() ?? 'join_failed' : 'join_failed');
      return;
    }
    policy = data['policy'] is Map
        ? Map<String, dynamic>.from(data['policy'] as Map)
        : policy;
    final token = data['livekitToken']?.toString() ?? data['livekit_token']?.toString();
    final url = data['livekitUrl']?.toString() ?? data['livekit_url']?.toString();
    if (token == null || url == null) {
      _deny('token_missing');
      return;
    }

    final lkRoom = Room();
    room = lkRoom;
    lkRoom.events.listen(_onRoomEvent);
    await lkRoom.connect(
      url,
      token,
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );
    await lkRoom.localParticipant?.setMicrophoneEnabled(true);
    if (!audioOnly) {
      await lkRoom.localParticipant?.setCameraEnabled(true);
    }
    if (!mounted) return;
    setState(() => phase = GroupCallPhase.connected);
    _startRemovalPoll(callId);
  }

  String _newJti() {
    final now = DateTime.now().microsecondsSinceEpoch.toString();
    return sha256.convert(now.codeUnits).toString().substring(0, 32);
  }

  void _startRemovalPoll(String callId) {
    pollTimer?.cancel();
    pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final res = await ApiService.get('$_apiBase/$callId/state');
        final data = res.data;
        if (data is Map && data['removed'] == true) {
          await _endCall(showMessage: kCallEndedCopy);
        }
      } catch (_) {}
    });
  }

  void _onRoomEvent(RoomEvent event) {
    if (event is RoomDisconnectedEvent) {
      if (mounted) setState(() => phase = GroupCallPhase.ended);
    }
    if (event is ParticipantConnectionQualityUpdatedEvent) {
      final q = event.connectionQuality;
      if (q == ConnectionQuality.poor || q == ConnectionQuality.lost) {
        if (mounted) {
          setState(() {
            packetLossEstimate = 0.15;
            phase = GroupCallPhase.degraded;
          });
        }
      }
    }
  }

  Future<void> _switchAudioOnly() async {
    final lkRoom = room;
    if (lkRoom == null) return;
    await lkRoom.localParticipant?.setCameraEnabled(false);
    if (mounted) {
      setState(() {
        audioOnly = true;
        phase = GroupCallPhase.connected;
        packetLossEstimate = 0;
      });
    }
  }

  Future<void> _disconnect() async {
    pollTimer?.cancel();
    final lkRoom = room;
    room = null;
    if (lkRoom != null) {
      await lkRoom.disconnect();
    }
  }

  Future<void> _endCall({String? showMessage}) async {
    await _disconnect();
    if (!mounted) return;
    setState(() => phase = GroupCallPhase.ended);
    if (showMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(showMessage)));
    }
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moderated = policy?['moderated'] == true;

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.circleName, style: PanAfricanTypography.titleMedium(context)),
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (moderated)
                      Semantics(
                        label: 'Moderated call for guardian-approved circle',
                        child: Container(
                          padding: EdgeInsets.all(PanAfricanSpacing.sm),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                          ),
                          child: Text(
                            'This call is moderated and not end-to-end encrypted.',
                            style: PanAfricanTypography.bodySmall(context),
                          ),
                        ),
                      ),
                    SizedBox(height: PanAfricanSpacing.lg),
                    Expanded(child: Center(child: _phaseBody(context))),
                    _controls(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _phaseBody(BuildContext context) {
    switch (phase) {
      case GroupCallPhase.ringing:
        return Text(kCallRingingCopy, style: PanAfricanTypography.headlineSmall(context));
      case GroupCallPhase.connected:
        return Text(
          audioOnly ? 'Audio only' : kCallJoinCopy,
          style: PanAfricanTypography.headlineSmall(context),
          textAlign: TextAlign.center,
        );
      case GroupCallPhase.degraded:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_wifi_bad, size: 48, color: Theme.of(context).colorScheme.error),
            SizedBox(height: PanAfricanSpacing.md),
            Text(kCallDegradedCopy, style: PanAfricanTypography.bodyLarge(context), textAlign: TextAlign.center),
          ],
        );
      case GroupCallPhase.denied:
        return Text(kCallDeniedCopy, style: PanAfricanTypography.bodyLarge(context), textAlign: TextAlign.center);
      case GroupCallPhase.ended:
        return Text(kCallEndedCopy, style: PanAfricanTypography.bodyLarge(context));
    }
  }

  Widget _controls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (phase == GroupCallPhase.degraded)
          Semantics(
            button: true,
            label: 'Switch to audio only',
            child: SizedBox(
              height: 48,
              child: FilledButton.tonal(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  unawaited(_switchAudioOnly());
                },
                child: const Text('Audio only'),
              ),
            ),
          ),
        Semantics(
          button: true,
          label: 'Leave call',
          child: SizedBox(
            height: 48,
            width: 48,
            child: Material(
              color: Theme.of(context).colorScheme.error,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  unawaited(_endCall());
                },
                child: Icon(Icons.call_end, color: Theme.of(context).colorScheme.onError),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const String GROUP_CALL_DENIED = GroupCallScreenState.groupCallDenied;

/// UI gate helper for tests.
bool groupCallShouldOfferAudioOnly(double packetLoss) => packetLoss >= 0.12;
