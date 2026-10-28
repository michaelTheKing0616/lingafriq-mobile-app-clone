import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/tutorials/speaking_try_client.dart';
import '../../services/voice/audio_recording_service.dart';
import '../../screens/pronunciation/tone_overlay_view.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/pan_african_components.dart';

/// Micro-lesson try step with real gateway scoring (P7-932).
class TutorialSpeakingTryStep extends StatefulWidget {
  const TutorialSpeakingTryStep({
    super.key,
    required this.stepId,
    required this.prompt,
    required this.expectedText,
    required this.language,
    this.client,
    this.recorder,
    this.dio,
    this.onFinished,
  });

  final String stepId;
  final String prompt;
  final String expectedText;
  final String language;
  final SpeakingTryClient? client;
  final AudioRecordingService? recorder;
  final Dio? dio;
  final ValueChanged<SpeakingTryResult>? onFinished;

  @override
  State<TutorialSpeakingTryStep> createState() => _TutorialSpeakingTryStepState();
}

class _TutorialSpeakingTryStepState extends State<TutorialSpeakingTryStep> {
  late final SpeakingTryClient _client;
  late final AudioRecordingService _recorder;

  SpeakingTryPhase _phase = SpeakingTryPhase.idle;
  List<SyllableToneOverlayRow> _syllables = const [];
  String? _errorMessage;
  bool _toggleLatched = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? const SpeakingTryClient();
    _recorder = widget.recorder ?? AudioRecordingService();
  }

  ToneOverlayStatus get _overlayStatus {
    switch (_phase) {
      case SpeakingTryPhase.recording:
        return ToneOverlayStatus.loading;
      case SpeakingTryPhase.result:
        return ToneOverlayStatus.scored;
      case SpeakingTryPhase.unsure:
        return ToneOverlayStatus.unsure;
      case SpeakingTryPhase.error:
        return ToneOverlayStatus.error;
      case SpeakingTryPhase.idle:
      case SpeakingTryPhase.skipped:
        return ToneOverlayStatus.loading;
    }
  }

  Future<void> _onHoldStart() async {
    if (_phase == SpeakingTryPhase.recording) return;
    _errorMessage = null;
    _syllables = const [];
    final path = await _recorder.startRecording(sampleRate: 16000, numChannels: 1);
    if (path == null) {
      setState(() {
        _phase = SpeakingTryPhase.error;
        _errorMessage = 'Microphone permission is required to practice.';
      });
      return;
    }
    _recordingPath = path;
    setState(() => _phase = SpeakingTryPhase.recording);
    HapticFeedback.lightImpact();
  }

  Future<void> _onHoldEnd() async {
    if (_phase != SpeakingTryPhase.recording) return;
    setState(() => _phase = SpeakingTryPhase.idle);
    final path = await _recorder.stopRecording();
    final audioPath = path ?? _recordingPath;
    if (audioPath == null || audioPath.isEmpty) {
      setState(() {
        _phase = SpeakingTryPhase.error;
        _errorMessage = kTutorialTryErrorCopy;
      });
      return;
    }

    final dio = widget.dio;
    if (dio == null) {
      setState(() {
        _phase = SpeakingTryPhase.error;
        _errorMessage = kTutorialTryErrorCopy;
      });
      return;
    }

    Future<Response<dynamic>> post(String p, FormData data) => dio.post(p, data: data);
    final result = await _client.scoreAttempt(
      post: post,
      audioPath: audioPath,
      expectedText: widget.expectedText,
      language: widget.language,
    );
    _applyResult(result);
  }

  void _applyResult(SpeakingTryResult result) {
    _syllables = result.syllables;
    _errorMessage = result.errorMessage;
    setState(() => _phase = result.phase);
    SemanticsService.announce(
      speakingTryAccessibilitySummary(result),
      TextDirection.ltr,
    );
    widget.onFinished?.call(result);
  }

  void _skip() {
    final skipped = const SpeakingTryResult(
      completion: SpeakingTryCompletion.skipped,
    );
    _client.recordSkip(stepId: widget.stepId);
    setState(() => _phase = SpeakingTryPhase.skipped);
    SemanticsService.announce('Speaking step skipped.', TextDirection.ltr);
    widget.onFinished?.call(skipped);
  }

  Future<void> _onToggleLatch(bool latched) async {
    _toggleLatched = latched;
    if (latched) {
      await _onHoldStart();
    } else {
      await _onHoldEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.prompt,
          style: TextStyle(
            fontSize: 16.sp,
            color: PanAfricanColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        if (_phase == SpeakingTryPhase.skipped)
          const Text(
            kTutorialTrySkipLabel,
            style: TextStyle(color: PanAfricanColors.neutralMedium),
          )
        else ...[
          if (_phase != SpeakingTryPhase.idle &&
              _phase != SpeakingTryPhase.recording)
            ToneOverlayView(
              status: _overlayStatus,
              syllables: _syllables,
              errorMessage: _errorMessage,
              height: 140.h,
            ),
          if (_phase == SpeakingTryPhase.unsure)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: const Text(
                kTutorialTryUnsureCopy,
                style: TextStyle(color: PanAfricanColors.neutralMedium),
              ),
            ),
          SizedBox(height: 16.h),
          Semantics(
            button: true,
            label: kTutorialTrySpeakLabel,
            hint: 'Tap to latch recording, or press and hold',
            child: GestureDetector(
              onLongPressStart: (_) => _onHoldStart(),
              onLongPressEnd: (_) => _onHoldEnd(),
              onTap: () => _onToggleLatch(!_toggleLatched),
              child: PanAfricanCard(
                child: SizedBox(
                  height: 72.h,
                  child: Center(
                    child: Text(
                      _phase == SpeakingTryPhase.recording
                          ? 'Recording…'
                          : kTutorialTrySpeakLabel,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: 12.h),
        TextButton(
          onPressed: _phase == SpeakingTryPhase.skipped ? null : _skip,
          child: const Text(kTutorialTrySkipLabel),
        ),
        if (reducedMotion && _phase == SpeakingTryPhase.recording)
          const SizedBox.shrink(),
      ],
    );
  }
}
