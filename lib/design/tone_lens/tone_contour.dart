import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Pitch shapes. Colour is not part of the kind: one stroke paints every shape.
enum ToneContourKind { high, mid, low, rising, falling, downstep }

/// Spoken name of a contour, lowercase, for a tone sequence.
String toneContourWord(ToneContourKind kind) {
  return switch (kind) {
    ToneContourKind.high => 'high',
    ToneContourKind.mid => 'mid',
    ToneContourKind.low => 'low',
    ToneContourKind.rising => 'rising',
    ToneContourKind.falling => 'falling',
    ToneContourKind.downstep => 'downstep',
  };
}

/// The contour box. One stroke, [LingAfriqTokens.spacing48] tall.
///
/// [unverified] draws the broken centre line (dash [LingAfriqTokens.spacing16],
/// gap [LingAfriqTokens.spacing8]). That line is not the solid mid line.
class ToneContour extends StatelessWidget {
  const ToneContour({
    required this.color,
    required this.background,
    this.kinds = const <ToneContourKind>[],
    this.unverified = false,
    super.key,
  });

  /// Key for the painted mark, without the word or any host chrome.
  static const Key markKey = Key('tone-contour-mark');

  /// Single stroke colour. The same value is used for every kind.
  final Color color;

  /// Surface directly behind the stroke.
  final Color background;

  /// Contours from left to right. Ignored when [unverified] is set.
  final List<ToneContourKind> kinds;

  final bool unverified;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: markKey,
      child: ColoredBox(
        color: background,
        child: SizedBox(
          height: LingAfriqTokens.spacing48,
          width: double.infinity,
          child: CustomPaint(
            painter: ToneContourPainter(
              color: color,
              kinds: kinds,
              unverified: unverified,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the approved contour shapes in one stroke.
///
/// The line sits [LingAfriqTokens.spacing8] in from the box. Caps are round.
/// A sequence splits the span into equal parts with a [LingAfriqTokens.spacing4]
/// gap. The mark is drawn in full on the first frame. It does not animate on.
class ToneContourPainter extends CustomPainter {
  const ToneContourPainter({
    required this.color,
    this.kinds = const <ToneContourKind>[],
    this.unverified = false,
  });

  final Color color;
  final List<ToneContourKind> kinds;
  final bool unverified;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = LingAfriqTokens.strokeregular
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter
      ..isAntiAlias = true;
    final double left = LingAfriqTokens.spacing8;
    final double right = size.width - LingAfriqTokens.spacing8;
    final double top = LingAfriqTokens.spacing8;
    final double bottom = size.height - LingAfriqTokens.spacing8;
    final double midY = size.height / 2;
    if (right <= left) return;
    if (unverified) {
      _broken(canvas, paint, left, right, midY);
      return;
    }
    if (kinds.isEmpty) return;
    final double gap = LingAfriqTokens.spacing4;
    final double span = right - left;
    final double segment = (span - gap * (kinds.length - 1)) / kinds.length;
    if (segment <= 0) return;
    for (var i = 0; i < kinds.length; i++) {
      final double start = left + i * (segment + gap);
      _shape(
        canvas,
        paint,
        kinds[i],
        start,
        start + segment,
        top,
        bottom,
        midY,
      );
    }
  }

  void _shape(
    Canvas canvas,
    Paint paint,
    ToneContourKind kind,
    double start,
    double end,
    double top,
    double bottom,
    double midY,
  ) {
    switch (kind) {
      case ToneContourKind.high:
        canvas.drawLine(Offset(start, top), Offset(end, top), paint);
      case ToneContourKind.mid:
        canvas.drawLine(Offset(start, midY), Offset(end, midY), paint);
      case ToneContourKind.low:
        canvas.drawLine(Offset(start, bottom), Offset(end, bottom), paint);
      case ToneContourKind.rising:
        canvas.drawLine(Offset(start, bottom), Offset(end, top), paint);
      case ToneContourKind.falling:
        canvas.drawLine(Offset(start, top), Offset(end, bottom), paint);
      case ToneContourKind.downstep:
        final double step = (start + end) / 2;
        final Path path = Path()
          ..moveTo(start, top)
          ..lineTo(step, top)
          ..lineTo(step, bottom)
          ..lineTo(end, bottom);
        canvas.drawPath(path, paint);
    }
  }

  void _broken(
    Canvas canvas,
    Paint paint,
    double left,
    double right,
    double y,
  ) {
    var x = left;
    while (x < right) {
      final double end = math.min(x + LingAfriqTokens.spacing16, right);
      if (end > x) {
        canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      }
      x = end + LingAfriqTokens.spacing8;
    }
  }

  @override
  bool shouldRepaint(ToneContourPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.unverified != unverified ||
        !listEquals(oldDelegate.kinds, kinds);
  }
}
