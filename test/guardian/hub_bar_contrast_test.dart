import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/app_theme.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/generated/app_localizations_ar.dart';
import 'package:lingafriq/l10n/generated/app_localizations_en.dart';
import 'package:lingafriq/screens/guardian/guardian_link_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';
import 'package:lingafriq/theme/lingafriq_fonts.dart';

import '../compliance/golden_kit.dart';

class _Hub extends GuardianLinkService {
  _Hub({this.gate});
  final Completer<void>? gate;
  int calls = 0;

  @override
  Future<void> flushPending() async {}

  @override
  Future<List<GuardianHubLink>> fetchHubLinks() async => const [];

  @override
  Future<GuardianSubmitState> acceptInvite({
    required String inviteToken,
    required String guardianDisplayName,
  }) async {
    calls += 1;
    if (gate != null) await gate!.future;
    return GuardianSubmitState.sent;
  }
}

double _channel(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _contrast(Color a, Color b) {
  final l1 =
      0.2126 * _channel(a.r) + 0.7152 * _channel(a.g) + 0.0722 * _channel(a.b);
  final l2 =
      0.2126 * _channel(b.r) + 0.7152 * _channel(b.g) + 0.0722 * _channel(b.b);
  final hi = math.max(l1, l2);
  final lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

Widget _app({
  required Widget home,
  required Locale locale,
  TextDirection? direction,
}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(
      child: MaterialApp(
        theme: lightTheme,
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: direction == null
              ? child!
              : Directionality(textDirection: direction, child: child!),
        ),
        home: home,
      ),
    ),
  );
}

void _pin(WidgetTester t) {
  t.view.physicalSize = const Size(320, 568);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

Future<void> _scrollTo(WidgetTester t, Finder target) async {
  final scroll = find
      .descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(Scrollable),
      )
      .first;
  await t.scrollUntilVisible(target, 200, scrollable: scroll);
  await t.pump();
}

Future<void> _pump(
  WidgetTester t, {
  required Locale locale,
  TextDirection? direction,
  GuardianLinkService? service,
}) async {
  _pin(t);
  await t.pumpWidget(
    _app(
      locale: locale,
      direction: direction,
      home: GuardianLinkScreen(guardianLinkService: service ?? _Hub()),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 200));
}

void _expectTitleFits(WidgetTester t, String title) {
  final view = const Rect.fromLTWH(0, 0, 320, 568);
  final paragraph = t.renderObject<RenderParagraph>(find.text(title));
  expect(paragraph.text.toPlainText(), title);
  expect(paragraph.didExceedMaxLines, isFalse);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: title.length),
  );
  expect(boxes, isNotEmpty);
  final bar = t.getRect(find.byType(AppBar));
  for (final box in boxes) {
    final rect = box.toRect().shift(t.getTopLeft(find.text(title)));
    expect(
      view.contains(rect.topLeft) && view.contains(rect.bottomRight),
      isTrue,
    );
    expect(rect.right, lessThanOrEqualTo(bar.right + 0.5));
    expect(rect.bottom, lessThanOrEqualTo(bar.bottom + 0.5));
    expect(rect.left, greaterThanOrEqualTo(bar.left - 0.5));
  }
}

void _expectActionsReachable(WidgetTester t, String hubTip, String inviteTip) {
  final view = const Rect.fromLTWH(0, 0, 320, 568);
  for (final tip in [hubTip, inviteTip]) {
    final finder = find.byTooltip(tip);
    expect(finder.hitTestable(), findsOneWidget, reason: tip);
    final rect = t.getRect(finder);
    expect(
      view.contains(rect.topLeft) && view.contains(rect.bottomRight),
      isTrue,
    );
  }
}

void main() {
  setUpAll(
    () => loadComplianceFonts('test/guardian/hub_bar_contrast_test.dart'),
  );

  testWidgets('enabled Link learner uses onPrimary immediately', (t) async {
    final en = AppLocalizationsEn();
    await _pump(t, locale: const Locale('en'), direction: TextDirection.rtl);
    await _scrollTo(t, find.text(en.gfamLinkLearner));
    final button = find.widgetWithText(FilledButton, en.gfamLinkLearner);
    expect(t.widget<FilledButton>(button).onPressed, isNull);
    final disabled = t.renderObject<RenderParagraph>(
      find.text(en.gfamLinkLearner),
    );
    expect(disabled.text.style?.color, isNot(kEqualsWhite));

    await t.enterText(
      find.byKey(GuardianLinkScreen.inviteCodeFieldKey),
      'tok-9',
    );
    await t.enterText(
      find.byKey(GuardianLinkScreen.guardianNameFieldKey),
      'Ada Obi',
    );
    await t.pump();
    expect(t.widget<FilledButton>(button).onPressed, isNotNull);
    final paragraph = t.renderObject<RenderParagraph>(
      find.text(en.gfamLinkLearner),
    );
    final fg = paragraph.text.style!.color!;
    final bg = t
        .widget<Material>(
          find
              .ancestor(
                of: find.text(en.gfamLinkLearner),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;
    final buttonScheme = Theme.of(t.element(button)).colorScheme;
    expect(fg, buttonScheme.onPrimary);
    expect(bg, buttonScheme.primary);
    expect(
      paragraph.text.style?.fontFamilyFallback,
      contains(LingAfriqFonts.arabic),
    );
    final ratio = _contrast(fg, bg);
    expect(
      ratio,
      greaterThanOrEqualTo(4.5),
      reason: 'contrast $ratio fg $fg bg $bg',
    );
  });

  testWidgets('busy submit disables the button and shows the spinner', (
    t,
  ) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    final hub = _Hub(gate: gate);
    await _pump(
      t,
      locale: const Locale('en'),
      direction: TextDirection.rtl,
      service: hub,
    );
    await _scrollTo(t, find.text('Link learner'));
    await t.enterText(
      find.byKey(GuardianLinkScreen.inviteCodeFieldKey),
      'tok-9',
    );
    await t.enterText(
      find.byKey(GuardianLinkScreen.guardianNameFieldKey),
      'Ada Obi',
    );
    await t.pump();
    await t.tap(find.text('Link learner'));
    await t.pump();
    expect(hub.calls, 1);
    expect(
      t.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('320dp 200% English RTL title and actions fit', (t) async {
    final en = AppLocalizationsEn();
    await _pump(t, locale: const Locale('en'), direction: TextDirection.rtl);
    _expectTitleFits(t, en.gfamHubTitle);
    _expectActionsReachable(t, en.gfamModeHub, en.gfamModeInvite);
  });

  testWidgets('320dp 200% English LTR title and actions fit', (t) async {
    final en = AppLocalizationsEn();
    await _pump(t, locale: const Locale('en'));
    _expectTitleFits(t, en.gfamHubTitle);
    _expectActionsReachable(t, en.gfamModeHub, en.gfamModeInvite);
  });

  testWidgets('320dp 200% Arabic title and actions fit', (t) async {
    final ar = AppLocalizationsAr();
    await _pump(t, locale: const Locale('ar'));
    _expectTitleFits(t, ar.gfamHubTitle);
    _expectActionsReachable(t, ar.gfamModeHub, ar.gfamModeInvite);
  });
}

const Color kEqualsWhite = Color(0xFFFFFFFF);
