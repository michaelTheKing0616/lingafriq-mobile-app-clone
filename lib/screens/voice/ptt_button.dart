import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/services/realtime_voice_client.dart';

/// Copy key: voice.ptt_hold
const String kVoicePttHoldLabel = 'Hold to talk';

/// Push-to-talk control for realtime voice (P6-083).
class PushToTalkButton extends StatefulWidget {
  const PushToTalkButton({
    super.key,
    required this.enabled,
    required this.sessionId,
    required this.client,
    this.useToggleLatch = false,
  });

  final bool enabled;
  final String sessionId;
  final RealtimeVoiceClient client;
  final bool useToggleLatch;

  @override
  State<PushToTalkButton> createState() => _PushToTalkButtonState();
}

class _PushToTalkButtonState extends State<PushToTalkButton> {
  bool _toggleLatched = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    final phase = widget.client.pttState.phase;
    final held = phase == RealtimePttPhase.held;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.useToggleLatch) {
      return Semantics(
        button: true,
        label: kVoicePttHoldLabel,
        hint: 'Double tap to latch microphone on or off',
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text(kVoicePttHoldLabel),
          subtitle: Text(_toggleLatched ? 'Microphone latched on' : 'Tap to latch'),
          value: _toggleLatched,
          onChanged: (latched) async {
            HapticFeedback.lightImpact();
            setState(() => _toggleLatched = latched);
            await widget.client.setPttToggleLatch(
              sessionId: widget.sessionId,
              latched: latched,
            );
          },
        ),
      );
    }

    return Semantics(
      button: true,
      label: kVoicePttHoldLabel,
      hint: 'Press and hold to speak',
      child: Listener(
        onPointerDown: (_) => _onHoldStart(),
        onPointerUp: (_) => _onHoldEnd(),
        onPointerCancel: (_) => _onHoldEnd(),
        child: Material(
          color: held ? colorScheme.primary : colorScheme.primaryContainer,
          shape: const CircleBorder(),
          elevation: held ? 4 : 1,
          child: SizedBox(
            width: 72,
            height: 72,
            child: Icon(
              held ? Icons.mic : Icons.mic_none,
              color: held ? colorScheme.onPrimary : colorScheme.onPrimaryContainer,
              semanticLabel: kVoicePttHoldLabel,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onHoldStart() async {
    HapticFeedback.mediumImpact();
    await widget.client.beginPttHold(sessionId: widget.sessionId);
    if (mounted) setState(() {});
  }

  Future<void> _onHoldEnd() async {
    await widget.client.endPttHold(sessionId: widget.sessionId);
    if (mounted) setState(() {});
  }
}
