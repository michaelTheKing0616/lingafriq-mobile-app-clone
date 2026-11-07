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

import '../compliance/golden_kit.dart';

class _FakeHub extends GuardianLinkService {
  GuardianSubmitState acceptState = GuardianSubmitState.sent;
  int acceptCalls = 0;
  String? token;
  String? name;

  @override
  Future<void> flushPending() async {}

  @override
  Future<List<GuardianHubLink>> fetchHubLinks() async => const [];

  @override
  Future<GuardianSubmitState> acceptInvite({
    required String inviteToken,
    required String guardianDisplayName,
  }) async {
    acceptCalls += 1;
    token = inviteToken;
    name = guardianDisplayName;
    return acceptState;
  }
}

void _pin(WidgetTester t) {
  t.view.physicalSize = const Size(320, 568);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
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

Finder _hubScrollable() {
  return find
      .descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(Scrollable),
      )
      .first;
}

void _expectRun(WidgetTester t, String text, TextDirection direction) {
  final paragraph = t.renderObject<RenderParagraph>(find.text(text));
  expect(paragraph.textDirection, direction);
  expect(paragraph.text.toPlainText(), text);
  expect(
    paragraph.size.width,
    lessThanOrEqualTo(paragraph.constraints.maxWidth + 0.1),
  );
  final markAt = text.lastIndexOf(RegExp('[?.؟]'));
  if (markAt > 0) {
    final before = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: markAt - 1, extentOffset: markAt),
        )
        .first;
    final mark = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: markAt, extentOffset: markAt + 1),
        )
        .first;
    if (direction == TextDirection.ltr) {
      expect(mark.left, greaterThan(before.left));
    } else {
      expect(mark.left, lessThan(before.left));
    }
  }
  final rect = t.getRect(find.text(text));
  expect(rect.left, greaterThanOrEqualTo(-0.1));
  expect(rect.right, lessThanOrEqualTo(320.1));
}

Future<void> _scrollTo(WidgetTester t, Finder target) async {
  await t.scrollUntilVisible(target, 200, scrollable: _hubScrollable());
  await t.pump();
}

void main() {
  setUpAll(
    () => loadComplianceFonts('test/guardian/invite_form_labels_test.dart'),
  );

  testWidgets('320dp 200% RTL keeps English invite copy and full labels', (
    t,
  ) async {
    final en = AppLocalizationsEn();
    _pin(t);
    final hub = _FakeHub();
    await t.pumpWidget(
      _app(
        locale: const Locale('en'),
        direction: TextDirection.rtl,
        home: GuardianLinkScreen(guardianLinkService: hub),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    await _scrollTo(t, find.text(en.gfamInviteSectionTitle));
    _expectRun(t, en.gfamInviteSectionTitle, TextDirection.ltr);
    _expectRun(t, en.gfamAcceptInviteHint, TextDirection.ltr);
    _expectRun(t, en.gfamInviteCodeLabel, TextDirection.ltr);
    _expectRun(t, en.gfamYourNameHint, TextDirection.ltr);
    final nameBoxes = t
        .renderObject<RenderParagraph>(find.text(en.gfamYourNameHint))
        .getBoxesForSelection(
          TextSelection(
            baseOffset: 0,
            extentOffset: en.gfamYourNameHint.length,
          ),
        );
    expect(
      nameBoxes.map((box) => box.top.round()).toSet().length,
      greaterThan(1),
    );

    await t.enterText(
      find.byKey(GuardianLinkScreen.inviteCodeFieldKey),
      'tok-9',
    );
    await t.enterText(
      find.byKey(GuardianLinkScreen.guardianNameFieldKey),
      'Ada Obi',
    );
    await t.pump();
    expect(find.text(en.gfamInviteCodeLabel), findsOneWidget);
    expect(find.text(en.gfamYourNameHint), findsOneWidget);
    expect(
      t
          .widget<TextField>(find.byKey(GuardianLinkScreen.inviteCodeFieldKey))
          .controller
          ?.text,
      'tok-9',
    );
    expect(find.bySemanticsLabel(en.gfamInviteCodeLabel), findsWidgets);
    expect(find.bySemanticsLabel(en.gfamYourNameHint), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('Arabic invite title keeps its own question mark', (t) async {
    final ar = AppLocalizationsAr();
    _pin(t);
    await t.pumpWidget(
      _app(
        locale: const Locale('ar'),
        home: GuardianLinkScreen(guardianLinkService: _FakeHub()),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    await _scrollTo(t, find.text(ar.gfamInviteSectionTitle));
    _expectRun(t, ar.gfamInviteSectionTitle, TextDirection.rtl);
    expect(find.text(ar.gfamYourNameHint), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'link stays off until both fields have text, then reports errors',
    (t) async {
      _pin(t);
      final hub = _FakeHub()..acceptState = GuardianSubmitState.error;
      await t.pumpWidget(
        _app(
          locale: const Locale('en'),
          direction: TextDirection.rtl,
          home: GuardianLinkScreen(guardianLinkService: hub),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));

      FilledButton button() => t.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Link learner'),
      );

      await _scrollTo(t, find.text('Link learner'));
      expect(button().onPressed, isNull);

      await t.enterText(
        find.byKey(GuardianLinkScreen.inviteCodeFieldKey),
        '   ',
      );
      await t.enterText(
        find.byKey(GuardianLinkScreen.guardianNameFieldKey),
        '  ',
      );
      await t.pump();
      expect(button().onPressed, isNull);

      await t.enterText(
        find.byKey(GuardianLinkScreen.inviteCodeFieldKey),
        'tok-9',
      );
      await t.pump();
      expect(button().onPressed, isNull);

      await t.enterText(
        find.byKey(GuardianLinkScreen.guardianNameFieldKey),
        'Ada Obi',
      );
      await t.pump();
      expect(button().onPressed, isNotNull);

      await t.tap(find.text('Link learner'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(hub.acceptCalls, 1);
      expect(hub.token, 'tok-9');
      expect(hub.name, 'Ada Obi');
      expect(
        find.text('Check the code and your name, then try again.'),
        findsOneWidget,
      );
      expect(find.text('Your name (shown to the learner)'), findsOneWidget);
      expect(button().onPressed, isNotNull);
      expect(t.takeException(), isNull);
    },
  );
}
