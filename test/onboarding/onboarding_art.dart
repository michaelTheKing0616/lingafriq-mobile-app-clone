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

/// Pins the Rive frame: waits until every [CastStage] shows its [RiveWidget]
/// (not the still), then advances a fixed 1 s so the intro has settled
/// before a golden is taken. Fails if Rive never loads.
Future<void> settleRive(WidgetTester tester) async {
  for (var i = 0; i < 80; i++) {
    final stages = find.byType(CastStage).evaluate().toList();
    final loaded = stages.every(
      (e) => find
          .descendant(
            of: find.byWidget(e.widget),
            matching: find.byType(RiveWidget),
          )
          .evaluate()
          .isNotEmpty,
    );
    if (stages.isNotEmpty && loaded) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byType(CastStage), findsWidgets, reason: 'welcome shows Polie');
  for (final e in find.byType(CastStage).evaluate()) {
    expect(
      find.descendant(
        of: find.byWidget(e.widget),
        matching: find.byType(RiveWidget),
      ),
      findsOneWidget,
      reason: 'golden must capture the settled Rive frame, not the still',
    );
  }
}

/// Scrolls [bodyKey]'s scrollable to its end and proves the lowest button
/// in it is on screen, clear of the bar/fade, and actually receives taps.
Future<void> expectLastButtonReachable(
  WidgetTester tester,
  String where, {
  Key bodyKey = const ValueKey('step-body'),
}) async {
  final body = find.byKey(bodyKey);
  expect(body, findsOneWidget, reason: '[$where] no scroll body');
  final st = tester.state<ScrollableState>(
    find.descendant(of: body, matching: find.byType(Scrollable)).first,
  );
  for (var i = 0; i < 3; i++) {
    st.position.jumpTo(st.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 100));
  }
  final buttons = find.descendant(
    of: body,
    matching: find.byWidgetPredicate(
      (w) => w is ButtonStyleButton || w is InkWell,
    ),
  );
  Element? last;
  var lowest = double.negativeInfinity;
  for (final e in buttons.evaluate()) {
    final box = e.renderObject as RenderBox?;
    if (box == null || !box.hasSize) continue;
    final b = box.localToGlobal(Offset.zero).dy + box.size.height;
    if (b > lowest) (lowest, last) = (b, e);
  }
  if (last == null) return;
  final viewport = tester.getRect(body);
  final bar = find.byKey(const ValueKey('step-bottom'));
  // Only a step body has the step's CTA bar (sign-in may sit above one).
  final limit = bar.evaluate().isEmpty || bodyKey != const ValueKey('step-body')
      ? viewport.bottom
      : tester.getRect(bar).top;
  expect(
    lowest <= limit + 0.5,
    isTrue,
    reason:
        '[$where] last button ends at $lowest, visible area ends $limit (scroll ${st.position.pixels}/${st.position.maxScrollExtent}, body $viewport)',
  );
  expect(
    find.byWidget(last.widget).hitTestable(),
    findsOneWidget,
    reason: '[$where] last button is covered and cannot be tapped',
  );
}
