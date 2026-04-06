import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Audio waveform bar visualization.
///
/// Takes a list of amplitude values (0.0–1.0) and renders vertical bars.
/// Colors from the primary palette with optional animation.
///
/// ```dart
/// GriotWaveformVisualizer(
///   amplitudes: _currentAmplitudes,
///   animate: _isPlaying,
///   barWidth: 3,
///   gap: 2,
/// )
/// ```
class GriotWaveformVisualizer extends StatefulWidget {
  const GriotWaveformVisualizer({
    super.key,
    required this.amplitudes,
    this.height = 48,
    this.barWidth = 3,
    this.gap = 2,
    this.animate = false,
    this.activeColor,
    this.inactiveColor,
  });

  /// Normalized amplitude values (0.0–1.0).
  final List<double> amplitudes;

  /// Widget height.
  final double height;

  /// Individual bar width.
  final double barWidth;

  /// Gap between bars.
  final double gap;

  /// When true, bars animate with a subtle pulse.
  final bool animate;

  /// Active bar color. Defaults to primary.
  final Color? activeColor;

  /// Inactive bar color. Defaults to surfaceContainerHighest.
  final Color? inactiveColor;

  @override
  State<GriotWaveformVisualizer> createState() =>
      _GriotWaveformVisualizerState();
}

class _GriotWaveformVisualizerState extends State<GriotWaveformVisualizer>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(GriotWaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) _setupAnimation();
  }

  void _setupAnimation() {
    if (widget.animate) {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true);
    } else {
      _controller?.stop();
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = widget.activeColor ?? cs.primary;
    final inactiveColor =
        widget.inactiveColor ?? cs.surfaceContainerHighest;
    final barW = widget.barWidth.w;
    final gapW = widget.gap.w;
    final totalHeight = widget.height.h;
    final minBarHeight = 4.h;

    Widget bars = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(widget.amplitudes.length, (i) {
        final amp = widget.amplitudes[i].clamp(0.0, 1.0);
        final barHeight =
            minBarHeight + (totalHeight - minBarHeight) * amp;
        final isActive = amp > 0.05;

        Widget bar = AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: barW,
          height: barHeight,
          margin: EdgeInsets.only(right: i < widget.amplitudes.length - 1 ? gapW : 0),
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(barW / 2),
          ),
        );

        return bar;
      }),
    );

    if (_controller != null) {
      return AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) => Opacity(
          opacity: 0.7 + 0.3 * _controller!.value,
          child: child,
        ),
        child: SizedBox(height: totalHeight, child: bars),
      );
    }

    return SizedBox(height: totalHeight, child: bars);
  }
}

