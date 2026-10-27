import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import '../../utils/pan_african_design_system.dart';
import 'danfo_rush_game.dart';
import 'speed_curve.dart';

enum DanfoRushPhase {
  loading,
  recordingsPending,
  ready,
  playing,
  correct,
  wrong,
  whyWrong,
  results,
  error,
  offline,
  practiceMode,
}

/// Flagship Danfo / Matatu Rush (P8-923): listen for the stop, tap the bus.
class DanfoRushScreen extends StatefulWidget {
  const DanfoRushScreen({
    super.key,
    required this.language,
    this.onBack,
    this.initialPlayableCalls,
  });

  final String language;
  final VoidCallback? onBack;

  /// Test hook: inject calls that include licensed human recordings.
  final List<DanfoStopCall>? initialPlayableCalls;

  @override
  State<DanfoRushScreen> createState() => _DanfoRushScreenState();
}

class _DanfoRushScreenState extends State<DanfoRushScreen> {
  static const title = 'Danfo / Matatu Rush';
  static const instructions =
      'Listen for the conductor’s stop name, then tap the matching bus before it pulls away.';
  static const whyWrongCopy =
      'That bus was heading somewhere else. Replay the call and match the stop you heard.';
  static const practiceLabel =
      'Practice — scores are for learning only until native recordings ship.';
  static const errorCopy =
      'We could not load this round. Check your connection and try again.';
  static const recordingsPendingCopy =
      'Conductor recordings are still on the way. We will not use synthetic voice here — check back after the native audio drop.';

  final AudioPlayer _player = AudioPlayer();
  DanfoRushPhase _phase = DanfoRushPhase.loading;
  String? _loadError;
  List<DanfoStopCall> _playable = const [];
  DanfoRushRound? _round;
  int _level = 1;
  int _roundIndex = 0;
  static const _maxRounds = 5;
  int _correctCount = 0;
  Timer? _departureTimer;
  double _timerProgress = 1;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _departureTimer?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final injected = widget.initialPlayableCalls;
      if (injected != null) {
        _playable = filterCallsWithHumanAudio(injected);
      } else {
        _playable = filterCallsWithHumanAudio(lexiconForLanguage(widget.language));
      }
      if (_playable.isEmpty) {
        setState(() => _phase = DanfoRushPhase.recordingsPending);
        return;
      }
      await _startRound();
    } catch (_) {
      setState(() {
        _phase = DanfoRushPhase.error;
        _loadError = errorCopy;
      });
    }
  }

  Future<void> _startRound() async {
    if (_roundIndex >= _maxRounds) {
      setState(() => _phase = DanfoRushPhase.results);
      return;
    }
    _roundIndex++;
    _answered = false;
    _timerProgress = 1;
    _departureTimer?.cancel();
    final round = buildDanfoRound(
      playablePool: _playable,
      level: _level,
      rng: Random(_roundIndex + _level),
    );
    _round = round;
    setState(() => _phase = DanfoRushPhase.playing);
    await _playCall(round.target);
    _startDepartureClock(round.decisionWindow);
  }

  Future<void> _playCall(DanfoStopCall call) async {
    final path = call.humanRecordingPath!;
    try {
      await _player.setAsset(path);
      await _player.play();
    } catch (_) {
      setState(() {
        _phase = DanfoRushPhase.offline;
      });
    }
  }

  void _startDepartureClock(Duration window) {
    final started = DateTime.now();
    _departureTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted || _answered) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(started);
      final remaining = window - elapsed;
      if (remaining <= Duration.zero) {
        t.cancel();
        _onMissedDeparture();
        return;
      }
      setState(() {
        _timerProgress = remaining.inMilliseconds / window.inMilliseconds;
      });
    });
  }

  void _onMissedDeparture() {
    if (_answered) return;
    _answered = true;
    HapticFeedback.heavyImpact();
    setState(() => _phase = DanfoRushPhase.wrong);
  }

  void _tapBus(DanfoStopCall option) {
    if (_answered || _round == null) return;
    _answered = true;
    _departureTimer?.cancel();
    HapticFeedback.selectionClick();
    final correct = danfoTapIsCorrect(tapped: option, target: _round!.target);
    if (correct) {
      _correctCount++;
      if (_level < 12) _level++;
      setState(() => _phase = DanfoRushPhase.correct);
    } else {
      setState(() => _phase = DanfoRushPhase.whyWrong);
    }
  }

  void _advance() {
    unawaited(_startRound());
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('$title · $_roundIndex / $_maxRounds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: switch (_phase) {
        DanfoRushPhase.loading =>
          const Center(child: CircularProgressIndicator()),
        DanfoRushPhase.recordingsPending => _StateMessage(
            message: recordingsPendingCopy,
            actionLabel: 'Back to Arcade',
            onAction: widget.onBack ?? () => Navigator.of(context).pop(),
          ),
        DanfoRushPhase.error => _StateMessage(
            message: _loadError ?? errorCopy,
            actionLabel: 'Try again',
            onAction: () {
              setState(() => _phase = DanfoRushPhase.loading);
              unawaited(_bootstrap());
            },
          ),
        DanfoRushPhase.offline => _StateMessage(
            message:
                'Audio could not play offline. Connect and try again when recordings are available.',
            actionLabel: 'Back',
            onAction: widget.onBack ?? () => Navigator.of(context).pop(),
          ),
        DanfoRushPhase.results => _buildResults(context),
        _ => Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PracticeBanner(label: practiceLabel),
                Text(
                  instructions,
                  style: PanAfricanTypography.bodyMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                if (_round != null)
                  _ConductorPanel(
                    phrase: _round!.target.conductorPhrase,
                    accent: _round!.accentTag,
                    progress: reducedMotion ? 1.0 : _timerProgress,
                  ),
                SizedBox(height: PanAfricanSpacing.md),
                Expanded(child: _bodyForPhase(context)),
              ],
            ),
          ),
      },
    );
  }

  Widget _bodyForPhase(BuildContext context) {
    switch (_phase) {
      case DanfoRushPhase.playing:
      case DanfoRushPhase.ready:
      case DanfoRushPhase.practiceMode:
        return _busPicker(context);
      case DanfoRushPhase.whyWrong:
        return _whyWrong(context);
      case DanfoRushPhase.correct:
      case DanfoRushPhase.wrong:
        return _roundSummary(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _busPicker(BuildContext context) {
    final options = _round?.busOptions ?? const [];
    return ListView(
      children: [
        Text(
          'Which bus matches the call?',
          style: PanAfricanTypography.titleMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        ...options.map((stop) {
          return Padding(
            padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
            child: Semantics(
              button: true,
              label: 'Bus to ${stop.stopLabel}. ${stop.displayHintEn}',
              child: FilledButton.tonal(
                onPressed: () => _tapBus(stop),
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(52.h),
                ),
                child: Column(
                  children: [
                    Text(stop.stopLabel, style: PanAfricanTypography.titleMedium(context)),
                    Text(
                      stop.displayHintEn,
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            final target = _round?.target;
            if (target != null) unawaited(_playCall(target));
          },
          icon: const Icon(Icons.replay),
          label: const Text('Replay call'),
        ),
      ],
    );
  }

  Widget _whyWrong(BuildContext context) {
    return _StateMessage(
      message: whyWrongCopy,
      actionLabel: 'Next bus',
      onAction: _advance,
    );
  }

  Widget _roundSummary(BuildContext context) {
    final won = _phase == DanfoRushPhase.correct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          won ? Icons.check_circle : Icons.directions_bus_filled,
          size: 48,
          color: won
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
          semanticLabel: won ? 'Correct stop' : 'Missed stop',
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(
          won ? 'You caught the right bus!' : 'That bus left without you.',
          style: PanAfricanTypography.titleMedium(context),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        FilledButton(
          onPressed: _advance,
          child: Text(_roundIndex >= _maxRounds ? 'See results' : 'Next call'),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Route complete',
            style: PanAfricanTypography.headlineSmall(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Text(
            '$_correctCount of $_maxRounds stops matched',
            style: PanAfricanTypography.titleMedium(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: PanAfricanSpacing.lg),
          FilledButton(
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
            child: const Text('Back to Arcade'),
          ),
        ],
      ),
    );
  }
}

class _ConductorPanel extends StatelessWidget {
  const _ConductorPanel({
    required this.phrase,
    required this.accent,
    required this.progress,
  });

  final String phrase;
  final String accent;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Conductor calls $phrase',
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Conductor · $accent', style: PanAfricanTypography.labelLarge(context)),
              SizedBox(height: PanAfricanSpacing.xs),
              Text(phrase, style: PanAfricanTypography.titleMedium(context)),
              SizedBox(height: PanAfricanSpacing.sm),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeBanner extends StatelessWidget {
  const _PracticeBanner({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Material(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md,
            vertical: PanAfricanSpacing.sm,
          ),
          child: Text(label, style: PanAfricanTypography.bodySmall(context)),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: PanAfricanTypography.bodyLarge(context), textAlign: TextAlign.center),
          SizedBox(height: PanAfricanSpacing.lg),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

/// Golden/widget preview shell (P8-923).
class DanfoRushPreview extends StatelessWidget {
  const DanfoRushPreview({
    super.key,
    required this.phaseLabel,
    required this.conductorLine,
    required this.timerProgress,
    required this.body,
  });

  final String phaseLabel;
  final String conductorLine;
  final double timerProgress;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(phaseLabel, style: theme.textTheme.titleMedium),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Conductor · Lagos', style: theme.textTheme.labelLarge),
                    Text(conductorLine, style: theme.textTheme.titleMedium),
                    LinearProgressIndicator(value: timerProgress),
                  ],
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
