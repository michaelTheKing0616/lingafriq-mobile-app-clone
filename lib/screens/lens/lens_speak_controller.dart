import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/screens/pronunciation/tone_overlay_view.dart';
import 'package:lingafriq/services/lens/lens_scoring_client.dart';
import 'package:lingafriq/services/offline/point_and_say_queue_service.dart';
import 'package:lingafriq/services/voice/audio_recording_service.dart';
import 'package:lingafriq/widgets/learning_path/polie_path_mascot.dart';

/// Copy key: lens.say.hold (P7-908).
const String lensSayHoldLabel = 'Hold to practice pronunciation';

enum LensSpeakPhase { idle, recording, scoring, result, unsure, error }

/// Hold-to-speak pronunciation flow for Lens word cards (P7-908).
class LensSpeakController extends ChangeNotifier {
  LensSpeakController({
    AudioRecordingService? recorder,
    LensScoringClient? scoringClient,
    LensScorePost? scorePost,
    PointAndSayQueueService? queue,
  })  : _recorder = recorder ?? AudioRecordingService(),
        _scoring = scoringClient ?? const LensScoringClient(),
        _scorePost = scorePost,
        _queue = queue ?? PointAndSayQueueService.instance;

  final AudioRecordingService _recorder;
  final LensScoringClient _scoring;
  final LensScorePost? _scorePost;
  final PointAndSayQueueService _queue;

  LensSpeakPhase _phase = LensSpeakPhase.idle;
  List<SyllableToneOverlayRow> _syllables = const [];
  String? _errorMessage;
  bool _celebrate = false;
  bool _toggleLatched = false;
  String? _recordingPath;

  LensSpeakPhase get phase => _phase;
  List<SyllableToneOverlayRow> get syllables => _syllables;
  String? get errorMessage => _errorMessage;
  bool get celebrate => _celebrate;
  bool get toggleLatched => _toggleLatched;

  ToneOverlayStatus get overlayStatus {
    switch (_phase) {
      case LensSpeakPhase.scoring:
        return ToneOverlayStatus.loading;
      case LensSpeakPhase.unsure:
        return ToneOverlayStatus.unsure;
      case LensSpeakPhase.error:
        return ToneOverlayStatus.error;
      case LensSpeakPhase.result:
        return ToneOverlayStatus.scored;
      case LensSpeakPhase.idle:
      case LensSpeakPhase.recording:
        return ToneOverlayStatus.loading;
    }
  }

  Future<void> onHoldStart({
    required String language,
    required String expectedText,
  }) async {
    if (_phase == LensSpeakPhase.scoring) return;
    _celebrate = false;
    _errorMessage = null;
    _syllables = const [];
    final path = await _recorder.startRecording(sampleRate: 16000, numChannels: 1);
    if (path == null) {
      _phase = LensSpeakPhase.error;
      _errorMessage = 'Microphone permission is required to practice pronunciation.';
      notifyListeners();
      return;
    }
    _recordingPath = path;
    _phase = LensSpeakPhase.recording;
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  Future<void> onHoldEnd({
    required String language,
    required String expectedText,
    Dio? dio,
  }) async {
    if (_phase != LensSpeakPhase.recording) return;
    final path = await _recorder.stopRecording();
    _phase = LensSpeakPhase.scoring;
    notifyListeners();

    final audioPath = path ?? _recordingPath;
    if (audioPath == null || audioPath.isEmpty) {
      _phase = LensSpeakPhase.error;
      _errorMessage = lensSayErrorCopy;
      notifyListeners();
      return;
    }

    final post = _scorePost ??
        (dio == null
            ? null
            : (String p, FormData data) => dio.post(p, data: data));

    if (post == null) {
      await _queue.enqueue(
        language: language,
        expectedText: expectedText,
        audioPath: audioPath,
        evaluateTone: true,
        context: const {'source': 'lens_speak'},
      );
      _phase = LensSpeakPhase.error;
      _errorMessage = lensSayErrorCopy;
      notifyListeners();
      return;
    }

    final outcome = await _scoring.scoreUtterance(
      post: post,
      audioPath: audioPath,
      expectedText: expectedText,
      language: language,
    );
    _applyOutcome(outcome);
  }

  void _applyOutcome(LensScoreOutcome outcome) {
    _syllables = outcome.syllables;
    _errorMessage = outcome.errorMessage;
    _celebrate = outcome.celebrate;
    switch (outcome.phase) {
      case ToneOverlayStatus.unsure:
        _phase = LensSpeakPhase.unsure;
        break;
      case ToneOverlayStatus.error:
        _phase = LensSpeakPhase.error;
        break;
      case ToneOverlayStatus.scored:
        _phase = LensSpeakPhase.result;
        if (outcome.celebrate) {
          HapticFeedback.mediumImpact();
        }
        break;
      case ToneOverlayStatus.loading:
        _phase = LensSpeakPhase.scoring;
        break;
    }
    notifyListeners();
  }

  Future<void> setToggleLatch({
    required bool latched,
    required String language,
    required String expectedText,
    Dio? dio,
  }) async {
    _toggleLatched = latched;
    if (latched) {
      await onHoldStart(language: language, expectedText: expectedText);
    } else {
      await onHoldEnd(language: language, expectedText: expectedText, dio: dio);
    }
  }

  void reset() {
    _phase = LensSpeakPhase.idle;
    _syllables = const [];
    _errorMessage = null;
    _celebrate = false;
    notifyListeners();
  }
}

/// Mic control + result overlay for Lens (hold or tap-toggle latch).
class LensSpeakPracticeLayer extends StatelessWidget {
  const LensSpeakPracticeLayer({
    super.key,
    required this.controller,
    required this.language,
    required this.expectedText,
    this.dio,
    this.useToggleLatch = false,
  });

  final LensSpeakController controller;
  final String language;
  final String expectedText;
  final Dio? dio;
  final bool useToggleLatch;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final reduced = MediaQuery.disableAnimationsOf(context);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.phase != LensSpeakPhase.idle &&
                    controller.phase != LensSpeakPhase.recording)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      label: buildToneOverlayAccessibilitySummary(controller.syllables),
                      child: ToneOverlayView(
                        status: controller.overlayStatus,
                        syllables: controller.syllables,
                        errorMessage: controller.errorMessage,
                        height: 120,
                      ),
                    ),
                  ),
                if (controller.phase == LensSpeakPhase.unsure)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      lensSayUnsureCopy,
                      key: const ValueKey('lens.say.unsure'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (controller.phase == LensSpeakPhase.error && controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      controller.errorMessage!,
                      key: const ValueKey('lens.say.error'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                _LensHoldMic(
                  phase: controller.phase,
                  useToggleLatch: useToggleLatch,
                  latched: controller.toggleLatched,
                  onHoldStart: () => controller.onHoldStart(
                    language: language,
                    expectedText: expectedText,
                  ),
                  onHoldEnd: () => controller.onHoldEnd(
                    language: language,
                    expectedText: expectedText,
                    dio: dio,
                  ),
                  onToggle: (v) => controller.setToggleLatch(
                    latched: v,
                    language: language,
                    expectedText: expectedText,
                    dio: dio,
                  ),
                ),
              ],
            ),
            if (controller.celebrate && controller.phase == LensSpeakPhase.result)
              Positioned(
                right: 0,
                bottom: 56,
                child: _LensCelebrationAvatar(reducedMotion: reduced),
              ),
          ],
        );
      },
    );
  }
}

class _LensHoldMic extends StatelessWidget {
  const _LensHoldMic({
    required this.phase,
    required this.useToggleLatch,
    required this.latched,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.onToggle,
  });

  final LensSpeakPhase phase;
  final bool useToggleLatch;
  final bool latched;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final held = phase == LensSpeakPhase.recording;
    final busy = phase == LensSpeakPhase.scoring;

    if (useToggleLatch) {
      return Semantics(
        button: true,
        label: lensSayHoldLabel,
        hint: 'Double tap to latch microphone on or off',
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(lensSayHoldLabel, key: ValueKey('lens.say.hold')),
          value: latched,
          onChanged: busy ? null : onToggle,
        ),
      );
    }

    return Semantics(
      button: true,
      label: lensSayHoldLabel,
      hint: 'Press and hold to speak',
      child: Listener(
        onPointerDown: (_) {
          if (!busy) onHoldStart();
        },
        onPointerUp: (_) {
          if (held) onHoldEnd();
        },
        onPointerCancel: (_) {
          if (held) onHoldEnd();
        },
        child: Material(
          color: held ? theme.colorScheme.primary : theme.colorScheme.primaryContainer,
          shape: const CircleBorder(),
          elevation: held ? 4 : 1,
          child: SizedBox(
            width: 48,
            height: 48,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    held ? Icons.mic : Icons.mic_none,
                    color: held
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onPrimaryContainer,
                  ),
          ),
        ),
      ),
    );
  }
}

class _LensCelebrationAvatar extends StatelessWidget {
  const _LensCelebrationAvatar({required this.reducedMotion});

  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 84,
      child: PoliePathStillFrame(
        mood: PoliePathMood.cheer,
        label: reducedMotion ? 'Great pronunciation' : 'Polie celebrates your pronunciation',
      ),
    );
  }
}
