import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/tone_lens/tone_contour.dart';
import 'package:lingafriq/design/tone_lens/tone_lens.dart';

/// Cue names from the haptic map.
///
/// Correct, incorrect, hint, microphone open, and microphone close.
/// Each name has one spoken label. The label is the screen-reader line.
enum LingCueName {
  correct('correct', 'That is right.'),
  incorrect('incorrect', 'Try that again.'),
  hint('hint', 'Here is a hint.'),
  microphoneOpen('microphone open', 'Microphone open.'),
  microphoneClose('microphone close', 'Microphone closed.');

  const LingCueName(this.mapName, this.spokenLabel);

  /// Haptic-map name. Microphone cues keep the space from the map.
  final String mapName;

  /// Spoken label. Always on screen. Sound is not required to read it.
  final String spokenLabel;

  /// Deck key under `a11y.cue.*`.
  String get copyKey => 'a11y.cue.$name';
}

/// Visual and haptic alternative for a sound cue.
///
/// The mark and the spoken label are always on screen. [play] calls a
/// haptic only when [hapticsEnabled] is true. Audio is never required.
/// [onSound] runs only when sound is on and [hearingImpaired] is false.
/// No sound file is played.
///
/// When [hearingImpaired] is true, the pitch cue is a [ToneLens] on
/// [greeting] using [greetingContours]. The semantics label reads those
/// tones in words.
class LingCueAlternatives extends StatefulWidget {
  const LingCueAlternatives({
    required this.cue,
    required this.hapticsEnabled,
    this.soundEnabled = false,
    this.hearingImpaired = false,
    this.onSound,
    super.key,
  });

  /// Finder for the coloured cue. The words sit on this box.
  static const Key visualCue = ValueKey<String>('cue-alternative-visual');

  /// Finder for the shape. Colour is not the only cue.
  static const Key mark = ValueKey<String>('cue-alternative-mark');

  /// Finder for the hearing-impaired pitch contour.
  static const Key pitch = ValueKey<String>('cue-alternative-pitch');

  /// Greeting used as the pitch example.
  static const String greeting = 'Ẹ kú àárọ̀';

  /// Contours for [greeting], left to right: mid, high, rising, low.
  static const List<ToneContourKind> greetingContours = <ToneContourKind>[
    ToneContourKind.mid,
    ToneContourKind.high,
    ToneContourKind.rising,
    ToneContourKind.low,
  ];

  /// Screen-reader line for the pitch cue, in words.
  static String get pitchLabel {
    return toneLensLabel(
      word: greeting,
      contours: greetingContours,
      unverified: false,
    );
  }

  final LingCueName cue;
  final bool hapticsEnabled;

  /// When false, [onSound] is not called. The visual mark still shows.
  final bool soundEnabled;

  /// When true, sound is not called and the pitch cue uses [ToneLens].
  final bool hearingImpaired;

  /// Called when sound is on and hearing is not impaired. No file is played.
  final VoidCallback? onSound;

  @override
  State<LingCueAlternatives> createState() => LingCueAlternativesState();
}

class LingCueAlternativesState extends State<LingCueAlternatives> {
  @override
  void initState() {
    super.initState();
    _schedulePlay();
  }

  @override
  void didUpdateWidget(LingCueAlternatives oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool changed =
        oldWidget.cue != widget.cue ||
        oldWidget.hapticsEnabled != widget.hapticsEnabled ||
        oldWidget.soundEnabled != widget.soundEnabled ||
        oldWidget.hearingImpaired != widget.hearingImpaired;
    if (changed) _schedulePlay();
  }

  void _schedulePlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) play();
    });
  }

  /// Fires the haptic when haptics are on. Calls [LingCueAlternatives.onSound]
  /// only when sound is on and hearing is not impaired. The mark is already
  /// on screen, so this never waits on audio.
  void play() {
    if (widget.hapticsEnabled) {
      _haptic(widget.cue);
    }
    if (widget.hearingImpaired || !widget.soundEnabled) return;
    widget.onSound?.call();
  }

  void _haptic(LingCueName cue) {
    switch (cue) {
      case LingCueName.correct:
        unawaited(HapticFeedback.successNotification());
      case LingCueName.incorrect:
        unawaited(HapticFeedback.mediumImpact());
      case LingCueName.hint:
        unawaited(HapticFeedback.lightImpact());
      case LingCueName.microphoneOpen:
        unawaited(HapticFeedback.lightImpact());
      case LingCueName.microphoneClose:
        unawaited(HapticFeedback.selectionClick());
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    final _Ramp ramp = _Ramp.of(brightness, widget.cue);
    final String copy = widget.cue.spokenLabel;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            container: true,
            label: copy,
            child: DecoratedBox(
              key: LingCueAlternatives.visualCue,
              decoration: BoxDecoration(
                color: ramp.fill,
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
                      child: _CueMark(cue: widget.cue, color: ramp.ink),
                    ),
                    const SizedBox(width: LingAfriqTokens.spacing12),
                    Flexible(
                      child: ExcludeSemantics(
                        child: Text(
                          copy,
                          style: lingBody(ramp.ink),
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
          if (widget.hearingImpaired) ...<Widget>[
            const SizedBox(height: LingAfriqTokens.spacing12),
            const ToneLens(
              key: LingCueAlternatives.pitch,
              word: LingCueAlternatives.greeting,
              contours: LingCueAlternatives.greetingContours,
              source: ToneSource.orthography,
            ),
          ],
        ],
      ),
    );
  }
}

class _Ramp {
  const _Ramp({required this.fill, required this.ink});

  final Color fill;
  final Color ink;

  static _Ramp of(Brightness brightness, LingCueName cue) {
    final bool dark = brightness == Brightness.dark;
    return switch (cue) {
      LingCueName.correct => _Ramp(
        fill: dark
            ? LingAfriqTokens.roleDarkSuccess
            : LingAfriqTokens.roleLightSuccess,
        ink: dark
            ? LingAfriqTokens.roleDarkOnSuccess
            : LingAfriqTokens.roleLightOnSuccess,
      ),
      LingCueName.incorrect => _Ramp(
        fill: dark
            ? LingAfriqTokens.roleDarkDanger
            : LingAfriqTokens.roleLightDanger,
        ink: dark
            ? LingAfriqTokens.roleDarkOnDanger
            : LingAfriqTokens.roleLightOnDanger,
      ),
      LingCueName.hint => _Ramp(
        fill: dark
            ? LingAfriqTokens.roleDarkInfo
            : LingAfriqTokens.roleLightInfo,
        ink: dark
            ? LingAfriqTokens.roleDarkOnInfo
            : LingAfriqTokens.roleLightOnInfo,
      ),
      LingCueName.microphoneOpen => _Ramp(
        fill: dark
            ? LingAfriqTokens.roleDarkAccent
            : LingAfriqTokens.roleLightAccent,
        ink: dark
            ? LingAfriqTokens.roleDarkOnAccent
            : LingAfriqTokens.roleLightOnAccent,
      ),
      LingCueName.microphoneClose => _Ramp(
        fill: dark
            ? LingAfriqTokens.roleDarkSurfaceContainer
            : LingAfriqTokens.roleLightSurfaceContainer,
        ink: dark
            ? LingAfriqTokens.roleDarkOnSurface
            : LingAfriqTokens.roleLightOnSurface,
      ),
    };
  }
}

class _CueMark extends StatelessWidget {
  const _CueMark({required this.cue, required this.color});

  final LingCueName cue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double side = MediaQuery.textScalerOf(context)
        .scale(LingAfriqTokens.spacing24);
    return SizedBox(
      key: LingCueAlternatives.mark,
      width: side,
      height: side,
      child: CustomPaint(
        painter: _CuePainter(cue: cue, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CuePainter extends CustomPainter {
  const _CuePainter({required this.cue, required this.color});

  final LingCueName cue;
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
    switch (cue) {
      case LingCueName.correct:
        canvas.drawPath(_check, paint);
      case LingCueName.incorrect:
        canvas.drawLine(const Offset(6, 6), const Offset(18, 18), paint);
        canvas.drawLine(const Offset(18, 6), const Offset(6, 18), paint);
      case LingCueName.hint:
        canvas.drawCircle(const Offset(12, 12), 8, paint);
        canvas.drawLine(const Offset(12, 11), const Offset(12, 16), paint);
        canvas.drawCircle(
          const Offset(12, 8),
          1.1,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      case LingCueName.microphoneOpen:
        _mic(canvas, paint, open: true);
      case LingCueName.microphoneClose:
        _mic(canvas, paint, open: false);
    }
    canvas.restore();
  }

  void _mic(Canvas canvas, Paint paint, {required bool open}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 3, 8, 10),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawArc(const Rect.fromLTWH(5, 7, 14, 10), 0, math.pi, false, paint);
    canvas.drawLine(const Offset(12, 17), const Offset(12, 20), paint);
    canvas.drawLine(const Offset(8, 20), const Offset(16, 20), paint);
    if (!open) {
      canvas.drawLine(const Offset(5, 5), const Offset(19, 19), paint);
    }
  }

  @override
  bool shouldRepaint(_CuePainter oldDelegate) {
    return oldDelegate.cue != cue || oldDelegate.color != color;
  }
}

final Path _check = Path()
  ..moveTo(5, 12)
  ..lineTo(10, 17)
  ..lineTo(19, 7);
