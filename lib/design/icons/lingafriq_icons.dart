import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Drawn marks. No emoji is used as an icon.
///
/// Lock, check, and warning are included. The error cross and the info disc
/// are not: those marks belong with the error state.
enum LingIconName {
  today,
  learn,
  speak,
  play,
  village,
  me,
  search,
  lens,
  wordCard,
  shelf,
  loading,
  lock,
  check,
  warning,
}

/// Spoken name for [name]. The words stay when the mark is selected or disabled.
String lingIconLabel(LingIconName name) {
  return switch (name) {
    LingIconName.today => 'Today',
    LingIconName.learn => 'Learn',
    LingIconName.speak => 'Speak',
    LingIconName.play => 'Play',
    LingIconName.village => 'Village',
    LingIconName.me => 'Me',
    LingIconName.search => 'Search',
    LingIconName.lens => 'Lens',
    LingIconName.wordCard => 'Word Card',
    LingIconName.shelf => 'Shelf',
    LingIconName.loading => 'Loading',
    LingIconName.lock => 'Lock',
    LingIconName.check => 'Check',
    LingIconName.warning => 'Warning',
  };
}

/// Copy key `icon.label.*` for [name].
String lingIconCopyKey(LingIconName name) {
  return 'icon.label.${name.name}';
}

/// One drawn mark at [LingAfriqTokens.spacing24].
///
/// [color] is the current onSurface or onAccent role. [accent] is the accent
/// role. [selected] strokes a ring in that role. [disabled] lowers opacity and
/// sets semantics enabled to false. The loading mark is a still arc: it does
/// not spin, so reduced motion has nothing to soften.
class LingIcon extends StatelessWidget {
  const LingIcon({
    required this.name,
    required this.color,
    required this.accent,
    this.selected = false,
    this.disabled = false,
    super.key,
  });

  /// Disabled ink keeps [color] and uses this fraction of it.
  static const double disabledOpacity = 0.38;

  final LingIconName name;

  /// onSurface or onAccent. The mark is stroked or filled in this colour.
  final Color color;

  /// Accent role. Painted only when [selected] is set.
  final Color accent;

  final bool selected;
  final bool disabled;

  String get label => lingIconLabel(name);

  @override
  Widget build(BuildContext context) {
    Widget mark = SizedBox(
      width: LingAfriqTokens.spacing24,
      height: LingAfriqTokens.spacing24,
      child: CustomPaint(
        painter: _IconPainter(
          name: name,
          color: color,
          accent: accent,
          selected: selected,
        ),
      ),
    );
    if (disabled) {
      mark = Opacity(opacity: disabledOpacity, child: mark);
    }
    return Semantics(
      container: true,
      label: label,
      enabled: disabled ? false : null,
      selected: selected ? true : null,
      child: mark,
    );
  }
}

class _IconPainter extends CustomPainter {
  const _IconPainter({
    required this.name,
    required this.color,
    required this.accent,
    required this.selected,
  });

  final LingIconName name;
  final Color color;
  final Color accent;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(
      size.width / LingAfriqTokens.spacing24,
      size.height / LingAfriqTokens.spacing24,
    );
    if (selected) {
      _ring(canvas, accent);
    }
    _mark(canvas, name, color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IconPainter oldDelegate) {
    return oldDelegate.name != name ||
        oldDelegate.color != color ||
        oldDelegate.accent != accent ||
        oldDelegate.selected != selected;
  }
}

Paint _stroke(Color color) {
  return Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = LingAfriqTokens.strokeregular
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;
}

Paint _fill(Color color) {
  return Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;
}

void _ring(Canvas canvas, Color accent) {
  final double inset = LingAfriqTokens.strokeregular;
  final double side = LingAfriqTokens.spacing24 - inset * 2;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, side, side),
      const Radius.circular(LingAfriqTokens.radiusxs),
    ),
    _stroke(accent),
  );
}

void _mark(Canvas canvas, LingIconName name, Color color) {
  final Paint stroke = _stroke(color);
  final Paint fill = _fill(color);
  switch (name) {
    case LingIconName.today:
      _today(canvas, stroke);
    case LingIconName.learn:
      _learn(canvas, stroke);
    case LingIconName.speak:
      _speak(canvas, stroke);
    case LingIconName.play:
      _play(canvas, fill);
    case LingIconName.village:
      _village(canvas, stroke);
    case LingIconName.me:
      _me(canvas, stroke);
    case LingIconName.search:
      _search(canvas, stroke);
    case LingIconName.lens:
      _lens(canvas, stroke);
    case LingIconName.wordCard:
      _wordCard(canvas, stroke);
    case LingIconName.shelf:
      _shelf(canvas, stroke);
    case LingIconName.loading:
      _loading(canvas, stroke);
    case LingIconName.lock:
      _lock(canvas, stroke);
    case LingIconName.check:
      _check(canvas, stroke);
    case LingIconName.warning:
      _warning(canvas, stroke, fill);
  }
}

void _today(Canvas canvas, Paint stroke) {
  canvas.drawCircle(const Offset(12, 12), 2.7, stroke);
  for (var ray = 0; ray < 8; ray++) {
    final double angle = ray * math.pi / 4;
    canvas.drawLine(
      Offset(12 + 4.8 * math.cos(angle), 12 + 4.8 * math.sin(angle)),
      Offset(12 + 6.4 * math.cos(angle), 12 + 6.4 * math.sin(angle)),
      stroke,
    );
  }
}

void _learn(Canvas canvas, Paint stroke) {
  final Path book = Path()
    ..moveTo(12, 6)
    ..lineTo(6, 8.2)
    ..lineTo(6, 17.2)
    ..lineTo(12, 15)
    ..moveTo(12, 6)
    ..lineTo(12, 15)
    ..moveTo(12, 6)
    ..lineTo(18, 8.2)
    ..lineTo(18, 17.2)
    ..lineTo(12, 15);
  canvas.drawPath(book, stroke);
}

void _speak(Canvas canvas, Paint stroke) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(9.4, 5.2, 5.2, 7.2),
      const Radius.circular(2.6),
    ),
    stroke,
  );
  canvas.drawArc(
    Rect.fromCircle(center: const Offset(12, 11.6), radius: 4.4),
    0,
    math.pi,
    false,
    stroke,
  );
  canvas.drawLine(const Offset(12, 16), const Offset(12, 18), stroke);
  canvas.drawLine(const Offset(8.4, 18), const Offset(15.6, 18), stroke);
}

void _play(Canvas canvas, Paint fill) {
  final Path triangle = Path()
    ..moveTo(7.4, 6)
    ..lineTo(7.4, 18)
    ..lineTo(17.6, 12)
    ..close();
  canvas.drawPath(triangle, fill);
}

void _village(Canvas canvas, Paint stroke) {
  _house(canvas, stroke, 5, 11.2, 8, 12.6, 18.6);
  _house(canvas, stroke, 12.8, 19, 9.2, 13.4, 18.6);
}

void _house(
  Canvas canvas,
  Paint stroke,
  double left,
  double right,
  double top,
  double wallTop,
  double bottom,
) {
  final double mid = (left + right) / 2;
  final Path roof = Path()
    ..moveTo(left, wallTop)
    ..lineTo(mid, top)
    ..lineTo(right, wallTop);
  canvas.drawPath(roof, stroke);
  canvas.drawRect(
    Rect.fromLTRB(left + 0.4, wallTop, right - 0.4, bottom),
    stroke,
  );
}

void _me(Canvas canvas, Paint stroke) {
  canvas.drawCircle(const Offset(12, 7.8), 2.5, stroke);
  canvas.drawArc(
    Rect.fromCircle(center: const Offset(12, 18.2), radius: 6.2),
    math.pi,
    math.pi,
    false,
    stroke,
  );
}

void _search(Canvas canvas, Paint stroke) {
  canvas.drawCircle(const Offset(10.2, 10.2), 3.8, stroke);
  canvas.drawLine(const Offset(13.4, 13.4), const Offset(18.2, 18.2), stroke);
}

void _lens(Canvas canvas, Paint stroke) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(5.2, 8.2, 13.6, 10.2),
      const Radius.circular(LingAfriqTokens.strokeregular),
    ),
    stroke,
  );
  canvas.drawCircle(const Offset(12, 13.4), 2.5, stroke);
  final Path finder = Path()
    ..moveTo(8.2, 8.2)
    ..lineTo(8.2, 5.8)
    ..lineTo(12.4, 5.8)
    ..lineTo(12.4, 8.2);
  canvas.drawPath(finder, stroke);
}

void _wordCard(Canvas canvas, Paint stroke) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(6.2, 5, 11.6, 14),
      const Radius.circular(LingAfriqTokens.strokeregular),
    ),
    stroke,
  );
  canvas.drawLine(const Offset(8.6, 10), const Offset(15.4, 10), stroke);
  canvas.drawLine(const Offset(8.6, 13.4), const Offset(13.2, 13.4), stroke);
}

void _shelf(Canvas canvas, Paint stroke) {
  canvas.drawLine(const Offset(5, 17.6), const Offset(19, 17.6), stroke);
  const List<Rect> books = <Rect>[
    Rect.fromLTWH(6, 10.2, 2.4, 7.4),
    Rect.fromLTWH(9.2, 12.2, 2.5, 5.4),
    Rect.fromLTWH(12.4, 9.4, 2.2, 8.2),
    Rect.fromLTWH(15.4, 11.6, 2.4, 6),
  ];
  for (final Rect book in books) {
    canvas.drawRect(book, stroke);
  }
}

void _loading(Canvas canvas, Paint stroke) {
  canvas.drawArc(
    Rect.fromCircle(center: const Offset(12, 12), radius: 6),
    -math.pi / 2,
    math.pi * 1.65,
    false,
    stroke,
  );
}

void _lock(Canvas canvas, Paint stroke) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(7.2, 11.2, 9.6, 7.4),
      const Radius.circular(LingAfriqTokens.strokehairline),
    ),
    stroke,
  );
  canvas.drawArc(
    Rect.fromCircle(center: const Offset(12, 11.2), radius: 3.4),
    math.pi,
    math.pi,
    false,
    stroke,
  );
}

void _check(Canvas canvas, Paint stroke) {
  final Path mark = Path()
    ..moveTo(6, 12.4)
    ..lineTo(10.3, 16.8)
    ..lineTo(18.2, 7.2);
  canvas.drawPath(mark, stroke);
}

void _warning(Canvas canvas, Paint stroke, Paint fill) {
  final Path triangle = Path()
    ..moveTo(12, 5.2)
    ..lineTo(5.4, 18.6)
    ..lineTo(18.6, 18.6)
    ..close();
  canvas.drawPath(triangle, stroke);
  canvas.drawLine(const Offset(12, 9.2), const Offset(12, 13.4), stroke);
  canvas.drawCircle(const Offset(12, 16.1), 0.9, fill);
}
