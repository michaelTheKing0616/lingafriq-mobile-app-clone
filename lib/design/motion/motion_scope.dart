import 'package:flutter/widgets.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Fade or scale. Reduced motion plays one of these and then rests.
enum LingMotionMove { fade, scale }

/// Resolved duration for the current reduce-motion setting.
///
/// [duration] is [LingAfriqTokens.motionProductSlow] when [reduced] is true,
/// and the caller's fast duration otherwise. Product motion stays at most
/// 300 ms.
class LingMotionPlan {
  const LingMotionPlan({
    required this.reduced,
    required this.duration,
    required this.move,
  });

  final bool reduced;
  final Duration duration;
  final LingMotionMove move;

  /// [fast] is used only when [reduced] is false. Null and a zero duration
  /// both use [LingAfriqTokens.motionProductFast].
  static LingMotionPlan resolve({
    required bool reduced,
    Duration? fast,
    LingMotionMove move = LingMotionMove.fade,
  }) {
    if (reduced) {
      return LingMotionPlan(
        reduced: true,
        duration: _reducedDuration(),
        move: move,
      );
    }
    return LingMotionPlan(
      reduced: false,
      duration: _openDuration(fast),
      move: move,
    );
  }
}

/// Reads [MediaQuery.disableAnimations] for a celebration or a transition.
///
/// When reduced motion is on, [child] stays mounted and reaches a visible
/// end state. The move is a fade or a scale no longer than
/// [LingAfriqTokens.motionProductSlow]. It is not removed and not a blank.
///
/// When reduced motion is off, [of] reports [fast], or
/// [LingAfriqTokens.motionProductFast] when [fast] is omitted, so the caller
/// can use that duration.
class LingMotionScope extends StatelessWidget {
  const LingMotionScope({
    required this.child,
    this.fast,
    this.move = LingMotionMove.fade,
    super.key,
  });

  /// Finder for the reduced-motion fade. The child sits inside it.
  static const Key fadeMark = ValueKey<String>('ling-motion-fade');

  /// Finder for the reduced-motion scale. The child sits inside it.
  static const Key scaleMark = ValueKey<String>('ling-motion-scale');

  /// Shown in both settings. Reduced motion does not replace it.
  final Widget child;

  /// Duration the caller uses when reduced motion is off.
  final Duration? fast;

  /// Fade or scale played when reduced motion is on.
  final LingMotionMove move;

  /// Plan for [context]. This reads [MediaQuery.disableAnimationsOf].
  static LingMotionPlan of(BuildContext context) {
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    final _LingMotionMark? mark = context
        .dependOnInheritedWidgetOfExactType<_LingMotionMark>();
    return LingMotionPlan.resolve(
      reduced: reduced,
      fast: mark?.fast,
      move: mark?.move ?? LingMotionMove.fade,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    final LingMotionPlan plan = LingMotionPlan.resolve(
      reduced: reduced,
      fast: fast,
      move: move,
    );
    final Widget marked = _LingMotionMark(fast: fast, move: move, child: child);
    if (!plan.reduced) {
      return marked;
    }
    if (plan.move == LingMotionMove.scale) {
      return TweenAnimationBuilder<double>(
        tween: _scaleTween,
        duration: plan.duration,
        curve: _productCurve,
        builder: (BuildContext context, double scale, Widget? child) {
          return Transform.scale(
            key: scaleMark,
            scale: scale,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: marked,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: _fadeTween,
      duration: plan.duration,
      curve: _productCurve,
      builder: (BuildContext context, double opacity, Widget? child) {
        return Opacity(key: fadeMark, opacity: opacity, child: child);
      },
      child: marked,
    );
  }
}

class _LingMotionMark extends InheritedWidget {
  const _LingMotionMark({
    required this.fast,
    required this.move,
    required super.child,
  });

  final Duration? fast;
  final LingMotionMove move;

  @override
  bool updateShouldNotify(_LingMotionMark oldWidget) {
    return fast != oldWidget.fast || move != oldWidget.move;
  }
}

/// Faint, not clear. A zero fade would be a blank frame.
final Tween<double> _fadeTween = Tween<double>(begin: 0.25, end: 1);

/// Smaller, not gone. A zero scale would be a blank frame.
final Tween<double> _scaleTween = Tween<double>(begin: 0.92, end: 1);

final Curve _productCurve = _curveFrom(LingAfriqTokens.motionProductEasing);

Duration _reducedDuration() {
  final int token = LingAfriqTokens.motionProductSlow;
  var ms = token;
  if (ms > 300) {
    ms = 300;
  }
  if (ms < 1) {
    ms = 1;
  }
  assert(token > 0 && token <= 300, 'product motion must stay within 300 ms');
  return Duration(milliseconds: ms);
}

Duration _openDuration(Duration? fast) {
  if (fast == null || fast <= Duration.zero) {
    final int token = LingAfriqTokens.motionProductFast;
    var ms = token;
    if (ms > 300) {
      ms = 300;
    }
    if (ms < 1) {
      ms = 1;
    }
    assert(token > 0 && token <= 300, 'product motion must stay within 300 ms');
    return Duration(milliseconds: ms);
  }
  return fast;
}

Curve _curveFrom(String raw) {
  final int open = raw.indexOf('(');
  final int close = raw.indexOf(')');
  final List<String> parts = raw.substring(open + 1, close).split(',');
  return Cubic(
    double.parse(parts[0]),
    double.parse(parts[1]),
    double.parse(parts[2]),
    double.parse(parts[3]),
  );
}
