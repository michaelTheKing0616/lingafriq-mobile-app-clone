import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

/// WCAG contrast ratio of two opaque colours.
double contrastRatio(Color a, Color b) {
  final x = _lum(a), y = _lum(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

Color _over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

/// Measures every visible text run under [root]: the text colour (blended
/// through ancestor Opacity) against the nearest opaque painted ancestor
/// (Material, ColoredBox, BoxDecoration colour), falling back to [page].
/// Returns (text, ratio) for runs below [min].
List<(String, double)> lowContrastTexts(
  WidgetTester t,
  Finder root, {
  double min = 4.5,
  Color page = Colors.white,
}) {
  final bad = <(String, double)>[];
  for (final e
      in find
          .descendant(of: root, matching: find.byType(RichText))
          .evaluate()) {
    final ro = e.renderObject;
    if (ro is! RenderParagraph || !ro.hasSize || ro.size.isEmpty) continue;
    final text = ro.text.toPlainText().trim();
    if (text.isEmpty) continue;
    final fg0 = ro.text.style?.color;
    if (fg0 == null) continue;
    var opacity = 1.0;
    Color? bg;
    e.visitAncestorElements((a) {
      final w = a.widget;
      if (w is Opacity) opacity *= w.opacity;
      if (w is FadeTransition) opacity *= w.opacity.value;
      Color? c;
      if (w is Material && w.type != MaterialType.transparency) c = w.color;
      if (w is ColoredBox) c = w.color;
      if (w is DecoratedBox && w.decoration is BoxDecoration) {
        c = (w.decoration as BoxDecoration).color;
      }
      if (w is Scaffold) c = w.backgroundColor;
      if (c != null && c.a > 0) {
        bg = c.a < 1 ? _over(c, page) : c;
        return false;
      }
      return true;
    });
    final back = bg ?? page;
    final fg = _over(fg0.withValues(alpha: fg0.a * opacity), back);
    final r = contrastRatio(fg, back);
    if (r < min) bad.add((text, double.parse(r.toStringAsFixed(2))));
  }
  return bad;
}
