import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/cast/cast_file_cache.dart';
import 'package:rive/rive.dart';

import '../screens/onboarding/unified_onboarding_screen_test.dart' hide main;

/// WCAG relative-luminance contrast of [fg] over [bg] (both opaque).
double contrast(Color fg, Color bg) {
  final a = fg.computeLuminance(), b = bg.computeLuminance();
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

/// Backgrounds painted behind [e], nearest first, until one is opaque.
List<List<Color>> _backgroundsBehind(Element e) {
  final layers = <List<Color>>[];
  e.visitAncestorElements((a) {
    final w = a.widget;
    List<Color>? c;
    if (w is ColoredBox) c = [w.color];
    if (w is Material && w.type != MaterialType.transparency) {
      c = [w.color ?? Colors.white];
    }
    if (w is DecoratedBox && w.decoration is BoxDecoration) {
      final d = w.decoration as BoxDecoration;
      c = d.color != null ? [d.color!] : d.gradient?.colors;
    }
    if (c != null && c.any((x) => x.a > 0)) {
      layers.add(c);
      if (c.every((x) => x.a >= 1)) return false;
    }
    return true;
  });
  return layers;
}

/// Worst-case opaque colours the text sits on (gradient stops expanded).
List<Color> _composite(List<List<Color>> layers) {
  var result = <Color>[Colors.white];
  for (final layer in layers.reversed) {
    result = [
      for (final under in result)
        for (final c in layer) Color.alphaBlend(c, under),
    ];
  }
  return result;
}

Future<void> audit(WidgetTester tester, String step) async {
  await tester.pump(const Duration(milliseconds: 400));
  // 1. Every text/background pair meets 4.5:1 (3:1 for large text).
  var checked = 0;
  for (final e in find.byType(RichText).evaluate()) {
    final rich = e.widget as RichText;
    final render = e.renderObject! as RenderParagraph;
    if (!render.attached || render.size.isEmpty) continue;
    final text = rich.text.toPlainText().trim();
    if (text.isEmpty) continue;
    final style = rich.text.style;
    final fg = style?.color;
    if (fg == null || fg.a == 0) continue;
    final size = (style?.fontSize ?? 14) * rich.textScaler.scale(1);
    final bold = (style?.fontWeight?.value ?? 400) >= 700;
    final large = size >= 24 || (bold && size >= 18.66);
    final min = large ? 3.0 : 4.5;
    for (final bg in _composite(_backgroundsBehind(e))) {
      final solidFg = Color.alphaBlend(fg, bg);
      final ratio = contrast(solidFg, bg);
      checked++;
      expect(
        ratio,
        greaterThanOrEqualTo(min),
        reason:
            '[$step] "$text" ${solidFg.toARGB32().toRadixString(16)} on '
            '${bg.toARGB32().toRadixString(16)} = ${ratio.toStringAsFixed(2)}',
      );
    }
  }
  expect(checked, greaterThan(3), reason: '[$step] audit saw no text');
  // 2. Every tap target is labelled and at least 48dp.
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  // 3. Decorative paint and icons are excluded or carry a label.
  final root = tester
      .binding
      .renderViews
      .first
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  void visit(SemanticsNode n) {
    final d = n.getSemanticsData();
    final interactive = d.hasAction(SemanticsAction.tap);
    if (interactive) {
      expect(
        d.label.isNotEmpty || d.value.isNotEmpty,
        isTrue,
        reason: '[$step] unlabeled tappable node $d',
      );
    }
    if (d.flagsCollection.isImage) {
      expect(d.label, isNotEmpty, reason: '[$step] unlabeled image $d');
    }
    // A leaf the reader lands on must say something (no empty stops).
    if (!n.hasChildren && !n.isMergedIntoParent) {
      expect(
        d.label.isNotEmpty || d.value.isNotEmpty || d.hint.isNotEmpty,
        isTrue,
        reason: '[$step] empty semantics leaf $d',
      );
    }
    n.visitChildren((c) {
      visit(c);
      return true;
    });
  }

  visit(root);
}

void main() {
  CastFileCache.instance.renderer = Factory.flutter;

  for (final (online, rtl, scale) in [
    (true, false, 1.0),
    (false, false, 1.0),
    (true, true, 2.0),
  ]) {
    testWidgets('every step: contrast + semantics audit '
        '(online=$online, rtl=$rtl, text=${scale}x)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpOnboarding(
        tester,
        reducedMotion: true,
        online: online,
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        textScaler: TextScaler.linear(scale),
      );
      await settleOnce(tester);
      await audit(tester, 'welcome');
      await next(tester, 'Get started');
      await tapVisible(tester, label('Yoruba'));
      await audit(tester, 'language');
      await next(tester);
      await tapVisible(tester, label('Talk to family'));
      await audit(tester, 'reason');
      await next(tester);
      await tapVisible(tester, label("I'm new"));
      await audit(tester, 'level');
      await next(tester);
      await tapVisible(tester, label('Steady'));
      await audit(tester, 'daily goal');
      await next(tester);
      await audit(tester, 'first win hear');
      await tapVisible(tester, label('Play greeting'));
      await tester.pump(const Duration(milliseconds: 50));
      await next(tester);
      await tapVisible(tester, label('Báwo ni'));
      await audit(tester, 'first win tap');
      await next(tester);
      await audit(tester, 'first win say');
      await tapVisible(tester, label('I said it'));
      await next(tester, 'Finish lesson');
      await audit(tester, 'celebration');
      await next(tester, 'Keep going');
      await enterBirthYear(tester, 25);
      await audit(tester, 'birth year');
      await tapVisible(tester, label('Continue').first);
      await settleOnce(tester);
      await audit(tester, 'reminders');
      await next(tester, 'Not now');
      await tapVisible(tester, label('Listening'));
      await audit(tester, 'style');
      await next(tester);
      await tapVisible(tester, label('Friendly'));
      await audit(tester, 'tone');
      await next(tester);
      await audit(tester, 'profile');
      await next(tester, 'Skip for now');
      await audit(tester, 'save progress');
      await tapVisible(tester, label('Continue with Google'));
      await tester.pump(const Duration(milliseconds: 50));
      await audit(tester, online ? 'saving overlay' : 'sign-in error');
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      handle.dispose();
    });
  }
}
