import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Copy for an answer check. There is no points total and no percent.
abstract final class LingAnswerFeedbackCopy {
  static const String correct = 'That is right.';
  static const String incorrect = 'Try that again.';

  static String forCorrect(bool isCorrect) {
    return isCorrect ? correct : incorrect;
  }
}

/// Elapsed time from the tap, taken from the binding clock inside [schedule].
///
/// Null haptic or sound means that call was skipped. The visual time is always
/// set. This is the scheduled start, not a reading from a physical phone.
class LingAnswerFeedbackTiming {
  const LingAnswerFeedbackTiming({
    required this.tappedAt,
    required this.hapticAt,
    required this.soundAt,
    required this.visualAt,
  });

  final DateTime tappedAt;
  final DateTime? hapticAt;
  final DateTime? soundAt;
  final DateTime visualAt;

  int? get hapticElapsedMs => _elapsed(hapticAt);

  int? get soundElapsedMs => _elapsed(soundAt);

  int get visualElapsedMs => visualAt.difference(tappedAt).inMilliseconds;

  /// Latest start among the channels that were scheduled.
  int get scheduledStartMs {
    var latest = visualElapsedMs;
    final int? haptic = hapticElapsedMs;
    if (haptic != null && haptic > latest) {
      latest = haptic;
    }
    final int? sound = soundElapsedMs;
    if (sound != null && sound > latest) {
      latest = sound;
    }
    return latest;
  }

  int? _elapsed(DateTime? at) {
    if (at == null) return null;
    return at.difference(tappedAt).inMilliseconds;
  }
}

/// Correct or incorrect answer cue.
///
/// The mark is always on screen. [LingAnswerFeedbackState.schedule] fires the
/// haptic and [onSound] only when those flags are on, and it records each
/// start from the binding clock. The motion length is
/// [LingAfriqTokens.motionProductFast]. Reduced motion keeps the settled cue.
///
/// [onSound] does not play a file. EXT-16 blocks recordings.
class LingAnswerFeedback extends StatefulWidget {
  const LingAnswerFeedback({
    required this.correct,
    required this.hapticsEnabled,
    required this.soundEnabled,
    this.onSound,
    super.key,
  });

  /// Finder for the coloured cue. The words sit on this box.
  static const Key visualCue = ValueKey<String>('answer-feedback-cue');

  /// Finder for the shape. Colour is not the only cue.
  static const Key mark = ValueKey<String>('answer-feedback-mark');

  final bool correct;
  final bool hapticsEnabled;
  final bool soundEnabled;

  /// Called when sound is on. No sound file is played.
  final VoidCallback? onSound;

  @override
  State<LingAnswerFeedback> createState() => LingAnswerFeedbackState();
}

class LingAnswerFeedbackState extends State<LingAnswerFeedback> {
  LingAnswerFeedbackTiming? timing;
  bool _live = false;

  /// Records the elapsed time from this tap to the haptic call, the sound
  /// call, and the visual frame. Skips haptic or sound when that flag is off.
  /// The visual frame is still scheduled.
  LingAnswerFeedbackTiming schedule() {
    final DateTime tappedAt = _bindingNow();
    DateTime? hapticAt;
    DateTime? soundAt;
    if (widget.hapticsEnabled) {
      _hapticCall();
      hapticAt = _bindingNow();
    }
    if (widget.soundEnabled) {
      widget.onSound?.call();
      soundAt = _bindingNow();
    }
    final DateTime visualAt = _bindingNow();
    final LingAnswerFeedbackTiming recorded = LingAnswerFeedbackTiming(
      tappedAt: tappedAt,
      hapticAt: hapticAt,
      soundAt: soundAt,
      visualAt: visualAt,
    );
    timing = recorded;
    _live = true;
    WidgetsBinding.instance.scheduleFrame();
    if (mounted) {
      setState(() {});
    }
    return recorded;
  }

  void _hapticCall() {
    if (widget.correct) {
      unawaited(HapticFeedback.successNotification());
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    final _Roles roles = _Roles.of(brightness, widget.correct);
    final String copy = LingAnswerFeedbackCopy.forCorrect(widget.correct);
    final double begin = reduced ? 1 : 0.98;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: 1),
      duration: const Duration(milliseconds: LingAfriqTokens.motionProductFast),
      curve: lingProductCurve,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: child,
        );
      },
      child: Semantics(
        container: true,
        liveRegion: _live,
        label: copy,
        child: DecoratedBox(
          key: LingAnswerFeedback.visualCue,
          decoration: BoxDecoration(
            color: roles.fill,
            borderRadius: const BorderRadius.all(
              Radius.circular(LingAfriqTokens.radiussm),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LingAfriqTokens.spacing16,
              vertical: LingAfriqTokens.spacing12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ExcludeSemantics(
                  child: _CueMark(correct: widget.correct, color: roles.ink),
                ),
                const SizedBox(width: LingAfriqTokens.spacing12),
                Flexible(
                  child: ExcludeSemantics(
                    child: Text(
                      copy,
                      style: lingBody(roles.ink),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reads the test binding clock when the active binding exposes one.
/// Production bindings do not, so the fallback is wall time. A widget test
/// therefore does not pretend to read a phone.
DateTime _bindingNow() {
  final WidgetsBinding binding = WidgetsBinding.instance;
  try {
    final dynamic clock = (binding as dynamic).clock;
    final dynamic now = clock?.now();
    if (now is DateTime) return now;
  } on NoSuchMethodError {
    return DateTime.now();
  }
  return DateTime.now();
}

class _Roles {
  const _Roles({required this.fill, required this.ink});

  final Color fill;
  final Color ink;

  static _Roles of(Brightness brightness, bool correct) {
    if (brightness == Brightness.dark) {
      if (correct) {
        return const _Roles(
          fill: LingAfriqTokens.roleDarkSuccess,
          ink: LingAfriqTokens.roleDarkOnSuccess,
        );
      }
      return const _Roles(
        fill: LingAfriqTokens.roleDarkDanger,
        ink: LingAfriqTokens.roleDarkOnDanger,
      );
    }
    if (correct) {
      return const _Roles(
        fill: LingAfriqTokens.roleLightSuccess,
        ink: LingAfriqTokens.roleLightOnSuccess,
      );
    }
    return const _Roles(
      fill: LingAfriqTokens.roleLightDanger,
      ink: LingAfriqTokens.roleLightOnDanger,
    );
  }
}

class _CueMark extends StatelessWidget {
  const _CueMark({required this.correct, required this.color});

  final bool correct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double side = MediaQuery.textScalerOf(
      context,
    ).scale(LingAfriqTokens.spacing24);
    return SizedBox(
      key: LingAnswerFeedback.mark,
      width: side,
      height: side,
      child: CustomPaint(
        painter: _CuePainter(correct: correct, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CuePainter extends CustomPainter {
  const _CuePainter({required this.correct, required this.color});

  final bool correct;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = size.width / LingAfriqTokens.spacing24;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = LingAfriqTokens.strokeregular * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.scale(unit);
    if (correct) {
      canvas.drawPath(_check, paint);
    } else {
      canvas.drawPath(_again, paint);
      canvas.drawPath(_againHead, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CuePainter oldDelegate) {
    return oldDelegate.correct != correct || oldDelegate.color != color;
  }
}

final Path _check = Path()
  ..moveTo(5, 12)
  ..lineTo(10, 17)
  ..lineTo(19, 7);

final Path _again = Path()..addArc(const Rect.fromLTWH(5, 5, 14, 14), 0.8, 4.6);

final Path _againHead = Path()
  ..moveTo(17, 5)
  ..lineTo(19, 8)
  ..lineTo(15, 9);
