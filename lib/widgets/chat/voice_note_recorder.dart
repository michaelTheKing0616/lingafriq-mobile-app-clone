import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../utils/modern_griot_design_system.dart';
import '../../utils/pan_african_design_system.dart' show PanAfricanSpacing;

/// Slide thresholds (dp) for cancel / lock gestures.
abstract final class VoiceNoteGestureThresholds {
  static const double cancelSlideX = -72;
  static const double lockSlideY = -56;
}

/// WhatsApp-style hold-to-record with slide-left cancel and slide-up lock.
class VoiceNoteRecorder extends StatefulWidget {
  const VoiceNoteRecorder({
    super.key,
    required this.enabled,
    required this.holdLabel,
    required this.onCompleted,
    required this.onCancel,
    this.minDurationMs = 400,
  });

  final bool enabled;
  final String holdLabel;
  final Future<void> Function(String filePath, int durationMs) onCompleted;
  final VoidCallback onCancel;
  final int minDurationMs;

  @override
  State<VoiceNoteRecorder> createState() => VoiceNoteRecorderState();
}

class VoiceNoteRecorderState extends State<VoiceNoteRecorder> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  bool _locked = false;
  bool _cancelling = false;
  double _slideX = 0;
  double _slideY = 0;
  DateTime? _startedAt;
  Timer? _waveTimer;
  final List<double> _waveSamples = List<double>.filled(24, 0.15);
  StreamSubscription<Amplitude>? _ampSub;

  @override
  void dispose() {
    _waveTimer?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _beginRecord() async {
    if (!widget.enabled || _recording) return;
    if (!await _recorder.hasPermission()) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/vn_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );
    _startedAt = DateTime.now();
    _recording = true;
    _locked = false;
    _cancelling = false;
    _slideX = 0;
    _slideY = 0;
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted || !_recording) return;
      setState(() {
        for (var i = 0; i < _waveSamples.length - 1; i++) {
          _waveSamples[i] = _waveSamples[i + 1];
        }
        _waveSamples[_waveSamples.length - 1] =
            0.12 + math.Random().nextDouble() * 0.88;
      });
    });
    _ampSub?.cancel();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((amp) {
      if (!mounted || !_recording) return;
      final norm = ((amp.current + 45) / 45).clamp(0.12, 1.0);
      setState(() {
        _waveSamples[_waveSamples.length - 1] = norm;
      });
    });
    setState(() {});
  }

  Future<void> _finishRecord({required bool discard}) async {
    if (!_recording) return;
    _waveTimer?.cancel();
    _ampSub?.cancel();
    final path = await _recorder.stop();
    final started = _startedAt;
    _recording = false;
    _locked = false;
    _cancelling = false;
    _startedAt = null;
    if (!mounted) return;
    setState(() {});

    if (discard || path == null || path.isEmpty) {
      widget.onCancel();
      return;
    }
    final ms = started == null
        ? 0
        : DateTime.now().difference(started).inMilliseconds;
    if (ms < widget.minDurationMs) {
      widget.onCancel();
      return;
    }
    await widget.onCompleted(path, ms);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_recording || _locked) return;
    _slideX += d.delta.dx;
    _slideY += d.delta.dy;
    final cancel = _slideX <= VoiceNoteGestureThresholds.cancelSlideX;
    final lock = _slideY <= VoiceNoteGestureThresholds.lockSlideY;
    if (cancel != _cancelling || lock != _locked) {
      setState(() {
        _cancelling = cancel;
        if (lock) _locked = true;
      });
      if (cancel) HapticFeedback.lightImpact();
      if (lock) HapticFeedback.mediumImpact();
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_recording) return;
    if (_cancelling) {
      unawaited(_finishRecord(discard: true));
      return;
    }
    if (!_locked) {
      unawaited(_finishRecord(discard: false));
    }
  }

  Future<void> sendLockedRecording() async {
    await _finishRecord(discard: false);
  }

  Future<void> cancelLockedRecording() async {
    await _finishRecord(discard: true);
  }

  bool get isRecording => _recording;
  bool get isLocked => _locked;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: widget.holdLabel,
      button: true,
      enabled: widget.enabled,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (_recording)
            Positioned(
              bottom: 56,
              left: -200,
              right: -200,
              child: _RecordingHud(
                waveSamples: _waveSamples,
                cancelling: _cancelling,
                locked: _locked,
                holdLabel: widget.holdLabel,
                onCancelLocked: () => unawaited(cancelLockedRecording()),
                onSendLocked: () => unawaited(sendLockedRecording()),
              ),
            ),
          GestureDetector(
            onLongPressStart: (_) => unawaited(_beginRecord()),
            onLongPressEnd: (_) {
              if (!_locked && _recording) {
                unawaited(_finishRecord(discard: _cancelling));
              }
            },
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _recording
                    ? cs.error.withValues(alpha: _cancelling ? 0.9 : 0.75)
                    : ModernGriotColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _recording ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _recording ? cs.onError : ModernGriotColors.primary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingHud extends StatelessWidget {
  const _RecordingHud({
    required this.waveSamples,
    required this.cancelling,
    required this.locked,
    required this.holdLabel,
    required this.onCancelLocked,
    required this.onSendLocked,
  });

  final List<double> waveSamples;
  final bool cancelling;
  final bool locked;
  final String holdLabel;
  final VoidCallback onCancelLocked;
  final VoidCallback onSendLocked;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
      color: cs.surfaceContainerHigh,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              cancelling ? Icons.delete_outline : Icons.mic,
              color: cancelling ? cs.error : ModernGriotColors.primary,
            ),
            SizedBox(width: PanAfricanSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cancelling
                        ? 'Release to cancel'
                        : locked
                            ? 'Recording locked — tap send when ready'
                            : holdLabel,
                    style: ModernGriotTypography.labelMedium(
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 28,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final h in waveSamples)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 60),
                              width: 3,
                              height: 4 + h * 22,
                              decoration: BoxDecoration(
                                color: ModernGriotColors.primary.withValues(
                                  alpha: 0.85,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (locked) ...[
              IconButton(
                tooltip: 'Discard recording',
                onPressed: onCancelLocked,
                icon: Icon(Icons.close, color: cs.onSurfaceVariant),
              ),
              IconButton(
                tooltip: 'Send voice note',
                onPressed: onSendLocked,
                icon: Icon(Icons.send_rounded, color: cs.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pure helpers for gesture thresholds (unit-tested).
class VoiceNoteGestureLogic {
  static bool shouldCancelOnRelease({
    required double totalSlideX,
    required bool cancellingFlag,
  }) =>
      cancellingFlag ||
      totalSlideX <= VoiceNoteGestureThresholds.cancelSlideX;

  static bool shouldLock({
    required double totalSlideY,
    required bool alreadyLocked,
  }) =>
      alreadyLocked || totalSlideY <= VoiceNoteGestureThresholds.lockSlideY;
}
