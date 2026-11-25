import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';

/// Recipe motion timings (REFERENCE.md · path v3). Reduce Motion → 150 ms fade.
abstract final class PathMotion {
  static const Duration press = PathLayout.pressDuration; // 80 ms
  static const Duration popover = PathLayout.popoverDuration; // 200 ms
  static const Duration doneGoldFill = Duration(milliseconds: 300);
  static const Duration trailDraw = Duration(milliseconds: 400);
  static const Duration polieHop = Duration(milliseconds: 500);
  static const Duration unitUnlockShine = Duration(milliseconds: 700);
  static const Duration flameBurst = Duration(milliseconds: 600);
  static const Duration streakFlicker = Duration(milliseconds: 2000);
  static const Duration reduced = PathLayout.reducedMotionCrossfade; // 150 ms

  static Duration resolve(Duration full, {required bool reducedMotion}) =>
      reducedMotion ? reduced : full;
}

/// Dotted trail that draws from a completed node toward the next (400 ms).
///
/// Used on connectors during lesson-completion choreography. Reduce Motion
/// snaps [progress] to 1 via a 150 ms crossfade.
class PathTrailDrawOverlay extends StatefulWidget {
  const PathTrailDrawOverlay({
    super.key,
    required this.play,
    required this.reducedMotion,
    required this.child,
    this.onCompleted,
  });

  final bool play;
  final bool reducedMotion;
  final Widget child;
  final VoidCallback? onCompleted;

  @override
  State<PathTrailDrawOverlay> createState() => _PathTrailDrawOverlayState();
}

class _PathTrailDrawOverlayState extends State<PathTrailDrawOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PathMotion.resolve(
        PathMotion.trailDraw,
        reducedMotion: widget.reducedMotion,
      ),
    );
    if (widget.play) {
      _run();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant PathTrailDrawOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _run();
    } else if (!widget.play && oldWidget.play) {
      _controller.value = 1;
    }
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      _controller.duration = PathMotion.resolve(
        PathMotion.trailDraw,
        reducedMotion: widget.reducedMotion,
      );
    }
  }

  void _run() {
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) widget.onCompleted?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _TrailProgressScope(
          progress: _controller.value.clamp(0.0, 1.0),
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

/// Inherited draw progress for [PathRowConnector] / painters under a trail.
class _TrailProgressScope extends InheritedWidget {
  const _TrailProgressScope({
    required this.progress,
    required super.child,
  });

  final double progress;

  static double of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_TrailProgressScope>();
    return scope?.progress ?? 1.0;
  }

  @override
  bool updateShouldNotify(covariant _TrailProgressScope oldWidget) =>
      oldWidget.progress != progress;
}

/// Public accessor so connectors can read trail progress without exporting
/// the inherited widget type.
double pathTrailDrawProgressOf(BuildContext context) =>
    _TrailProgressScope.of(context);

/// Gold fill that sweeps a done-node face over 300 ms (or 150 ms reduced).
class PathDoneGoldFill extends StatefulWidget {
  const PathDoneGoldFill({
    super.key,
    required this.play,
    required this.reducedMotion,
    required this.child,
  });

  final bool play;
  final bool reducedMotion;
  final Widget child;

  @override
  State<PathDoneGoldFill> createState() => _PathDoneGoldFillState();
}

class _PathDoneGoldFillState extends State<PathDoneGoldFill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PathMotion.resolve(
        PathMotion.doneGoldFill,
        reducedMotion: widget.reducedMotion,
      ),
      value: widget.play ? 0 : 1,
    );
    if (widget.play) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant PathDoneGoldFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            PathBrandColors.gold.withValues(alpha: (1 - t) * 0.35),
            BlendMode.srcATop,
          ),
          child: Opacity(opacity: 0.55 + (t * 0.45), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Unit-banner unlock shine sweep (~700 ms) — Flutter stand-in for
/// unit_banner.riv `unlock` when the sticky ribbon is Material, not Rive.
class PathUnitUnlockShine extends StatefulWidget {
  const PathUnitUnlockShine({
    super.key,
    required this.play,
    required this.reducedMotion,
    required this.child,
    this.onCompleted,
  });

  final bool play;
  final bool reducedMotion;
  final Widget child;
  final VoidCallback? onCompleted;

  @override
  State<PathUnitUnlockShine> createState() => _PathUnitUnlockShineState();
}

class _PathUnitUnlockShineState extends State<PathUnitUnlockShine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PathMotion.resolve(
        PathMotion.unitUnlockShine,
        reducedMotion: widget.reducedMotion,
      ),
    );
    if (widget.play) _run();
  }

  @override
  void didUpdateWidget(covariant PathUnitUnlockShine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) _run();
  }

  void _run() {
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) widget.onCompleted?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            child!,
            if (t > 0 && t < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.2 + (t * 2.4), -0.2),
                        end: Alignment(-0.4 + (t * 2.4), 0.4),
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                        stops: const [0.35, 0.5, 0.65],
                      ),
                    ),
                  ),
                ),
              ),
            if (t > 0.55 && t < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: PathBrandColors.gold.withValues(
                          alpha: (1 - t) * 1.6,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// Day-1 streak flame burst (600 ms) + week-dot fill (recipe 09).
class PathStreakFlameBurst extends StatefulWidget {
  const PathStreakFlameBurst({
    super.key,
    required this.play,
    required this.reducedMotion,
    required this.streakCount,
    required this.child,
  });

  final bool play;
  final bool reducedMotion;
  final int streakCount;
  final Widget child;

  @override
  State<PathStreakFlameBurst> createState() => _PathStreakFlameBurstState();
}

class _PathStreakFlameBurstState extends State<PathStreakFlameBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PathMotion.resolve(
        PathMotion.flameBurst,
        reducedMotion: widget.reducedMotion,
      ),
    );
    if (widget.play) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant PathStreakFlameBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(_controller.value.clamp(0.0, 1.0));
        final scale = widget.play ? (1.0 + (1 - t) * 0.55) : 1.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (widget.play && t < 1)
                    ...List.generate(5, (i) {
                      final angle = (i / 5) * 6.28;
                      final dist = 10.w * (1 - t);
                      return Transform.translate(
                        offset: Offset(
                          dist * (i.isEven ? 1 : -1) * (0.4 + i * 0.1),
                          -dist * (0.6 + (angle % 1)),
                        ),
                        child: Opacity(
                          opacity: (1 - t).clamp(0.0, 1.0),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 8.sp,
                            color: PathBrandColors.gold,
                          ),
                        ),
                      );
                    }),
                  child!,
                ],
              ),
            ),
            if (widget.play)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: _WeekDots(
                  filled: widget.streakCount.clamp(0, 7),
                  progress: _controller.value,
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.filled, required this.progress});

  final int filled;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final target = i < filled;
        final lit = target && (i < filled - 1 || progress > 0.35);
        return Container(
          width: 4.w,
          height: 4.w,
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lit
                ? PathBrandColors.coral
                : PathBrandColors.lockedLip.withValues(alpha: 0.55),
          ),
        );
      }),
    );
  }
}

/// Clay pedestal under the current node (Candy Crush "you are here" mass).
class PathCurrentPedestal extends StatelessWidget {
  const PathCurrentPedestal({
    super.key,
    required this.size,
    this.reducedMotion = false,
  });

  final double size;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reducedMotion ? 1 : 0.85, end: 1),
      duration: PathMotion.resolve(
        PathMotion.popover,
        reducedMotion: reducedMotion,
      ),
      curve: Curves.easeOut,
      builder: (context, t, child) =>
          Transform.scale(scale: t, child: Opacity(opacity: t, child: child)),
      child: Container(
        width: size * 1.15,
        height: size * 0.28,
        decoration: BoxDecoration(
          color: PathBrandColors.parchment,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: PathBrandColors.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: PathBrandColors.gold.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
