import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/tone_lens.dart';

/// Tone pattern + syllables parsed from a verified lexeme entry (P7-907).
class LensLemmaToneData {
  const LensLemmaToneData({
    this.tonePattern = const [],
    this.syllables = const [],
  });

  final List<String> tonePattern;
  final List<String> syllables;

  bool get hasContour => tonePattern.isNotEmpty;
}

LensLemmaToneData lensLemmaToneFromEntry(Map<String, dynamic> entry) {
  final rawPattern = entry['tone_pattern'];
  final rawSyllables = entry['syllables'];
  final pattern = rawPattern is List
      ? rawPattern.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList()
      : <String>[];
  final syllables = rawSyllables is List
      ? rawSyllables.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList()
      : <String>[];
  return LensLemmaToneData(tonePattern: pattern, syllables: syllables);
}

/// Continuous contour under [syllables] driven by [tonePattern] (color.tone.contour).
class ToneContourLine extends StatelessWidget {
  const ToneContourLine({
    super.key,
    required this.tonePattern,
    this.syllables,
    this.verified = true,
    this.height = 36,
  });

  final List<String> tonePattern;
  final List<String>? syllables;
  final bool verified;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (tonePattern.isEmpty) return const SizedBox.shrink();

    final labels = syllables != null && syllables!.length == tonePattern.length
        ? syllables!
        : List<String>.generate(tonePattern.length, (i) => '');

    final palette = ToneLensColors.of(context);
    final stroke = verified ? palette.mid : palette.mid.withValues(alpha: 0.35);

    return Semantics(
      label: _semanticsSummary(tonePattern),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _ToneContourLinePainter(
                tonePattern: tonePattern,
                stroke: stroke,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < tonePattern.length; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (labels[i].isNotEmpty)
                          Text(
                            labels[i],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        const SizedBox(height: 4),
                        ToneLens(
                          kind: ToneContourKind.parse(tonePattern[i]),
                          verified: verified,
                          size: const Size(32, 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _semanticsSummary(List<String> pattern) {
    final parts = pattern.map((p) => _kindLabel(ToneContourKind.parse(p)));
    return 'Tone contour: ${parts.join(', ')}';
  }

  static String _kindLabel(ToneContourKind kind) {
    switch (kind) {
      case ToneContourKind.high:
        return 'high';
      case ToneContourKind.mid:
        return 'mid';
      case ToneContourKind.low:
        return 'low';
      case ToneContourKind.rising:
        return 'rising';
      case ToneContourKind.falling:
        return 'falling';
      case ToneContourKind.downstep:
        return 'downstep';
      case ToneContourKind.unknown:
        return 'unknown';
    }
  }
}

class _ToneContourLinePainter extends CustomPainter {
  _ToneContourLinePainter({
    required this.tonePattern,
    required this.stroke,
  });

  final List<String> tonePattern;
  final Color stroke;

  double _yForKind(ToneContourKind kind, double h) {
    switch (kind) {
      case ToneContourKind.high:
        return h * 0.22;
      case ToneContourKind.mid:
        return h * 0.45;
      case ToneContourKind.low:
        return h * 0.72;
      case ToneContourKind.rising:
        return h * 0.55;
      case ToneContourKind.falling:
        return h * 0.4;
      case ToneContourKind.downstep:
        return h * 0.35;
      case ToneContourKind.unknown:
        return h * 0.5;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (tonePattern.length < 2) return;
    final paint = Paint()
      ..color = stroke.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final segment = size.width / tonePattern.length;
    final path = Path();
    for (var i = 0; i < tonePattern.length; i++) {
      final kind = ToneContourKind.parse(tonePattern[i]);
      final x = segment * i + segment / 2;
      final y = _yForKind(kind, size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ToneContourLinePainter oldDelegate) =>
      oldDelegate.tonePattern != tonePattern || oldDelegate.stroke != stroke;
}
