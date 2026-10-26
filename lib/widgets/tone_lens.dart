import 'package:flutter/material.dart';

/// Visual tone contour (shape + optional colour). Never colour-only (P3-034 / P4-140).
enum ToneContourKind {
  high('H'),
  mid('M'),
  low('L'),
  rising('R'),
  falling('F'),
  downstep('D'),
  unknown('?');

  const ToneContourKind(this.code);
  final String code;

  static ToneContourKind parse(String? raw) {
    if (raw == null) return ToneContourKind.unknown;
    final n = raw.trim().toUpperCase();
    for (final k in ToneContourKind.values) {
      if (k.code == n) return k;
    }
    if (n == 'RISE' || n == 'RISING') return ToneContourKind.rising;
    if (n == 'FALL' || n == 'FALLING') return ToneContourKind.falling;
    if (n == 'DOWNSTEP') return ToneContourKind.downstep;
    return ToneContourKind.unknown;
  }
}

/// Tokens: color.tone.high / color.tone.low (D10 Andika target text companion).
class ToneLensColors {
  const ToneLensColors({required this.high, required this.low, required this.mid});

  final Color high;
  final Color low;
  final Color mid;

  static ToneLensColors of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ToneLensColors(
      high: scheme.primary,
      mid: scheme.onSurface.withValues(alpha: 0.72),
      low: scheme.tertiary,
    );
  }
}

class ToneLens extends StatelessWidget {
  const ToneLens({
    super.key,
    required this.kind,
    this.colors,
    this.size = const Size(28, 14),
    this.verified = true,
  });

  final ToneContourKind kind;
  final ToneLensColors? colors;
  final Size size;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final palette = colors ?? ToneLensColors.of(context);
    final stroke = verified ? palette.mid : palette.mid.withValues(alpha: 0.35);
    return Semantics(
      label: _semanticsLabel(kind),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: CustomPaint(
          painter: _ToneContourPainter(kind: kind, stroke: stroke, accent: palette.high),
        ),
      ),
    );
  }

  static String _semanticsLabel(ToneContourKind kind) {
    switch (kind) {
      case ToneContourKind.high:
        return 'High tone';
      case ToneContourKind.mid:
        return 'Mid tone';
      case ToneContourKind.low:
        return 'Low tone';
      case ToneContourKind.rising:
        return 'Rising tone';
      case ToneContourKind.falling:
        return 'Falling tone';
      case ToneContourKind.downstep:
        return 'Downstep';
      case ToneContourKind.unknown:
        return 'Unverified tone';
    }
  }
}

class _ToneContourPainter extends CustomPainter {
  _ToneContourPainter({required this.kind, required this.stroke, required this.accent});

  final ToneContourKind kind;
  final Color stroke;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stroke
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();

    switch (kind) {
      case ToneContourKind.high:
        path.moveTo(2, h * 0.25);
        path.lineTo(w - 2, h * 0.25);
        break;
      case ToneContourKind.mid:
        path.moveTo(2, h * 0.5);
        path.lineTo(w - 2, h * 0.5);
        break;
      case ToneContourKind.low:
        path.moveTo(2, h * 0.78);
        path.lineTo(w - 2, h * 0.78);
        break;
      case ToneContourKind.rising:
        path.moveTo(2, h * 0.78);
        path.lineTo(w - 2, h * 0.22);
        break;
      case ToneContourKind.falling:
        path.moveTo(2, h * 0.22);
        path.lineTo(w - 2, h * 0.78);
        break;
      case ToneContourKind.downstep:
        path.moveTo(2, h * 0.28);
        path.lineTo(w * 0.45, h * 0.28);
        path.lineTo(w * 0.55, h * 0.62);
        path.lineTo(w - 2, h * 0.62);
        break;
      case ToneContourKind.unknown:
        canvas.drawLine(Offset(2, h * 0.5), Offset(w - 2, h * 0.5), paint..style = PaintingStyle.stroke);
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), 2, Paint()..color = accent);
        return;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ToneContourPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.stroke != stroke;
}

/// Row of tone contours aligned under [syllables] or one contour per [tonePattern] code.
class ToneLensRow extends StatelessWidget {
  const ToneLensRow({
    super.key,
    required this.tonePattern,
    this.syllables,
    this.verified = true,
  });

  final List<String> tonePattern;
  final List<String>? syllables;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    if (tonePattern.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tonePattern.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ToneLens(
              kind: ToneContourKind.parse(tonePattern[i]),
              verified: verified,
            ),
          ),
      ],
    );
  }
}
