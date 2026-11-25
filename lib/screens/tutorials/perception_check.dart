import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/pan_african_design_system.dart';

/// Fixed duration for tutorial perception checks (EP-§11.2-12/13).
const Duration perceptionCheckDuration = Duration(seconds: 30);

const int perceptionCheckDurationSeconds = 30;

/// Copy key: tutorial.check.title (localised string fallback below).
const String kTutorialCheckTitleKey = 'tutorial.check.title';

enum PerceptionCheckPhase { running, result, abandoned }

/// Learner-only outcome; no cohort or fabricated benchmark fields.
class PerceptionCheckLearnerResult {
  const PerceptionCheckLearnerResult({
    required this.checkId,
    required this.selectedResponse,
    required this.listeningSeconds,
  });

  final String checkId;
  final String selectedResponse;
  final int listeningSeconds;
}

/// In-memory guard: never persists partial runs (AC3).
class PerceptionCheckSessionGuard {
  PerceptionCheckSessionGuard._();

  static final Map<String, bool> _inFlight = {};

  static void markStarted(String checkId) {
    _inFlight[checkId] = true;
  }

  static void markCompleted(String checkId) {
    _inFlight.remove(checkId);
  }

  static void markAbandoned(String checkId) {
    _inFlight.remove(checkId);
  }

  static bool wasInFlight(String checkId) => _inFlight[checkId] == true;

  @visibleForTesting
  static void resetForTest() => _inFlight.clear();
}

/// Pure timer math for unit tests.
int perceptionCheckSecondsRemaining({
  required Duration elapsed,
  Duration total = perceptionCheckDuration,
}) {
  final left = total - elapsed;
  if (left.isNegative || left == Duration.zero) return 0;
  return left.inSeconds.clamp(0, perceptionCheckDurationSeconds);
}

bool perceptionCheckTimerComplete(Duration elapsed) =>
    elapsed >= perceptionCheckDuration;

/// 30-second perception check shown after a sound tutorial (P7-931).
class TutorialPerceptionCheck extends StatefulWidget {
  const TutorialPerceptionCheck({
    super.key,
    required this.checkId,
    required this.prompt,
    required this.nonAudioDescription,
    required this.responseOptions,
    this.onFinished,
    this.checkDuration,
  });

  final String checkId;
  final String prompt;
  final String nonAudioDescription;
  final List<String> responseOptions;
  final ValueChanged<PerceptionCheckLearnerResult>? onFinished;

  /// Defaults to [perceptionCheckDuration] (30 s). Tests may shorten.
  final Duration? checkDuration;

  @override
  State<TutorialPerceptionCheck> createState() =>
      _TutorialPerceptionCheckState();
}

class _TutorialPerceptionCheckState extends State<TutorialPerceptionCheck> {
  PerceptionCheckPhase _phase = PerceptionCheckPhase.running;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  String? _selectedResponse;
  int _lastAnnouncedSecond = -1;

  Duration get _total => widget.checkDuration ?? perceptionCheckDuration;

  @override
  void initState() {
    super.initState();
    if (PerceptionCheckSessionGuard.wasInFlight(widget.checkId)) {
      PerceptionCheckSessionGuard.markAbandoned(widget.checkId);
    }
    PerceptionCheckSessionGuard.markStarted(widget.checkId);
    _startTimer();
  }

  void _startTimer() {
    _elapsed = Duration.zero;
    _phase = PerceptionCheckPhase.running;
    _selectedResponse = null;
    _lastAnnouncedSecond = -1;
    _timer?.cancel();
    _scheduleNextSecond();
  }

  void _scheduleNextSecond() {
    _timer = Timer(const Duration(seconds: 1), _onSecondElapsed);
  }

  void _onSecondElapsed() {
    if (!mounted) return;
    setState(() {
      _elapsed += const Duration(seconds: 1);
      if (_elapsed >= _total) {
        _timer?.cancel();
        _timer = null;
        _phase = PerceptionCheckPhase.result;
        SemanticsService.announce(
          'Perception check finished. Choose what you noticed.',
          TextDirection.ltr,
        );
      }
    });
    _maybeAnnounceCountdown();
    if (_phase == PerceptionCheckPhase.running && mounted) {
      _scheduleNextSecond();
    }
  }

  void _maybeAnnounceCountdown() {
    final remaining = perceptionCheckSecondsRemaining(
      elapsed: _elapsed,
      total: _total,
    );
    if (remaining == _lastAnnouncedSecond) return;
    if (remaining == 30 || remaining == 15 || remaining <= 5 && remaining > 0) {
      _lastAnnouncedSecond = remaining;
      SemanticsService.announce(
        '$remaining seconds left in perception check',
        TextDirection.ltr,
      );
    }
  }

  void _submitResponse(String value) {
    setState(() {
      _selectedResponse = value;
      _phase = PerceptionCheckPhase.result;
    });
    PerceptionCheckSessionGuard.markCompleted(widget.checkId);
    final result = PerceptionCheckLearnerResult(
      checkId: widget.checkId,
      selectedResponse: value,
      listeningSeconds: _total.inSeconds,
    );
    widget.onFinished?.call(result);
  }

  @override
  void dispose() {
    if (_phase == PerceptionCheckPhase.running) {
      PerceptionCheckSessionGuard.markAbandoned(widget.checkId);
      _phase = PerceptionCheckPhase.abandoned;
    }
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final title = kTutorialCheckTitleKey;

    return Scaffold(
      backgroundColor: PanAfricanColors.surface,
      appBar: AppBar(
        title: Text(title == kTutorialCheckTitleKey ? 'Perception check' : title),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_phase == PerceptionCheckPhase.running) ...[
                _RunningPanel(
                  prompt: widget.prompt,
                  nonAudioDescription: widget.nonAudioDescription,
                  secondsRemaining: perceptionCheckSecondsRemaining(
                    elapsed: _elapsed,
                    total: _total,
                  ),
                  totalSeconds: _total.inSeconds,
                  reducedMotion: reducedMotion,
                ),
              ] else if (_phase == PerceptionCheckPhase.result) ...[
                _ResultPanel(
                  prompt: widget.prompt,
                  selectedResponse: _selectedResponse,
                  responseOptions: widget.responseOptions,
                  onSelect: _submitResponse,
                  showPicker: _selectedResponse == null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RunningPanel extends StatelessWidget {
  const _RunningPanel({
    required this.prompt,
    required this.nonAudioDescription,
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.reducedMotion,
  });

  final String prompt;
  final String nonAudioDescription;
  final int secondsRemaining;
  final int totalSeconds;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            label:
                'Perception check running. $secondsRemaining seconds remaining. $prompt',
            child: Text(
              prompt,
              style: PanAfricanTypography.titleMedium(context),
            ),
          ),
          SizedBox(height: 12.h),
          Semantics(
            label: 'Non-audio alternative: $nonAudioDescription',
            child: Text(
              nonAudioDescription,
              style: const TextStyle(color: PanAfricanColors.neutralMedium),
            ),
          ),
          SizedBox(height: 24.h),
          Expanded(
            child: Center(
              child: reducedMotion
                  ? Text(
                      '$secondsRemaining s',
                      style: PanAfricanTypography.headlineLarge(context),
                    )
                  : _TimerRing(
                      secondsRemaining: secondsRemaining,
                      totalSeconds: totalSeconds,
                    ),
            ),
          ),
          Semantics(
            label: 'Timer $secondsRemaining of $totalSeconds seconds',
            child: LinearProgressIndicator(
              value: 1 -
                  (secondsRemaining / totalSeconds).clamp(0.0, 1.0),
              backgroundColor: PanAfricanColors.cardDark,
              minHeight: 6.h,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  final int secondsRemaining;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120.w,
      height: 120.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: secondsRemaining / totalSeconds,
            strokeWidth: 6,
            backgroundColor: PanAfricanColors.cardDark,
          ),
          Text(
            '$secondsRemaining',
            style: PanAfricanTypography.headlineMedium(context),
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.prompt,
    required this.selectedResponse,
    required this.responseOptions,
    required this.onSelect,
    required this.showPicker,
  });

  final String prompt;
  final String? selectedResponse;
  final List<String> responseOptions;
  final ValueChanged<String> onSelect;
  final bool showPicker;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your result',
            style: PanAfricanTypography.titleMedium(context),
          ),
          SizedBox(height: 8.h),
          Text(
            prompt,
            style: const TextStyle(color: PanAfricanColors.neutralMedium),
          ),
          SizedBox(height: 16.h),
          if (showPicker) ...[
            const Text('What did you notice?'),
            SizedBox(height: 8.h),
            ...responseOptions.map(
              (option) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: OutlinedButton(
                  onPressed: () => onSelect(option),
                  child: Text(option),
                ),
              ),
            ),
          ] else ...[
            Semantics(
              label: 'Your answer: $selectedResponse',
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Text(
                    selectedResponse!,
                    style: PanAfricanTypography.bodyLarge(context),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Only your response is shown — no class average or benchmark.',
              style: TextStyle(
                fontSize: 12.sp,
                color: PanAfricanColors.neutralMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
