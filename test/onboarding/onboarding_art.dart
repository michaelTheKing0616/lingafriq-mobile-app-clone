import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/cast/cast_stage.dart';
import 'package:lingafriq/avatars/onboarding/onboarding_avatar_widget.dart';
import 'package:rive/rive.dart';

/// Decodes every on-screen image (Polie stills included) so a capture shows
/// the art, not the empty frame before the asset loads.
Future<void> settleArt(WidgetTester tester) async {
  final images = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    for (final e in images) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump();
}

/// Every Polie on screen draws real art: a Rive artboard or a decoded still.
/// The empty placeholder surface must never render.
void expectNoBlankCast(WidgetTester tester, String where) {
  for (final avatar in find.byType(OnboardingAvatarWidget).evaluate()) {
    final of = find.byElementPredicate((e) => e == avatar);
    if (find
        .descendant(of: of, matching: find.byType(CastStage))
        .evaluate()
        .isNotEmpty) {
      continue;
    }
    final stills = find
        .descendant(of: of, matching: find.byType(RawImage))
        .evaluate()
        .map((e) => e.widget as RawImage);
    expect(
      stills.any((r) => r.image != null),
      isTrue,
      reason: '$where: Polie fell back to a blank portrait',
    );
  }
  for (final stage in find.byType(CastStage).evaluate()) {
    final of = find.byElementPredicate((e) => e == stage);
    final rive = find.descendant(of: of, matching: find.byType(RiveWidget));
    if (rive.evaluate().isNotEmpty) continue;
    final raws = find
        .descendant(of: of, matching: find.byType(RawImage))
        .evaluate()
        .map((e) => e.widget as RawImage);
    expect(
      raws.any((r) => r.image != null),
      isTrue,
      reason: '$where: Polie rendered the blank placeholder',
    );
  }
}

/// Golden captures start at the top so the question is always in frame.
Future<void> scrollToTop(WidgetTester tester) async {
  for (final s in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
    if (s.position.axis == Axis.vertical &&
        s.position.hasPixels &&
        s.position.pixels != 0) {
      s.position.jumpTo(0);
    }
  }
  await tester.pump();
}

/// Bottom-most visible text in the step body sits above the CTA bar.
void expectLastItemAboveBar(WidgetTester tester, String where) {
  final bar = find.byKey(const ValueKey('step-bottom'));
  final body = find.byKey(const ValueKey('step-body'));
  if (bar.evaluate().isEmpty || body.evaluate().isEmpty) return;
  final barTop = tester.getRect(bar).top;
  double lowest = -1;
  var lowestText = '';
  for (final e
      in find
          .descendant(of: body, matching: find.byType(RichText))
          .evaluate()) {
    final box = e.renderObject! as RenderBox;
    if (!box.hasSize || !box.attached) continue;
    final r = box.localToGlobal(Offset.zero) & box.size;
    if (r.bottom > lowest) {
      lowest = r.bottom;
      lowestText = (e.widget as RichText).text.toPlainText();
    }
  }
  expect(
    lowest <= barTop + 0.5,
    isTrue,
    reason: '[$where] "$lowestText" ends at $lowest, bar starts at $barTop',
  );
}
