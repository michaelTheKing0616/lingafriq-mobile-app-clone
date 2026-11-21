import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/app_theme.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/guardian/approvals_screen.dart';
import 'package:lingafriq/screens/guardian/guardian_link_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';

import '../compliance/golden_kit.dart';

class _Hub extends GuardianLinkService {
  _Hub(this.links);
  final List<GuardianHubLink> links;
  bool offline = false;

  @override
  Future<void> flushPending() async {}

  @override
  Future<List<GuardianHubLink>> fetchHubLinks() async {
    if (offline) throw const GuardianOfflineException();
    return links;
  }

  @override
  Future<GuardianSubmitState> createChildInvite({
    required void Function(String token, DateTime expiresAt) onSuccess,
  }) async => GuardianSubmitState.sent;

  @override
  Future<GuardianSubmitState> acceptInvite({
    required String inviteToken,
    required String guardianDisplayName,
  }) async => GuardianSubmitState.sent;
}

class _Approvals extends GuardianApprovalService {
  _Approvals(this.rows);
  final List<GuardianGroupJoinRequestRow> rows;

  @override
  Future<List<GuardianGroupJoinRequestRow>> fetchApprovals() async => rows;
}

void _pin(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

Widget _app({
  required Widget home,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(
      child: MaterialApp(
        theme: lightTheme,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Directionality(textDirection: direction, child: child!),
        ),
        home: home,
      ),
    ),
  );
}

Rect _viewport(WidgetTester t) {
  final size = t.view.physicalSize / t.view.devicePixelRatio;
  return Offset.zero & size;
}

/// Fully inside the logical viewport, not merely built in the scroll cache.
void _expectOnScreen(WidgetTester t, Finder finder, String name) {
  expect(finder, findsOneWidget, reason: '$name missing');
  expect(
    finder.hitTestable(),
    findsOneWidget,
    reason: '$name not hit-testable',
  );
  final rect = t.getRect(finder);
  final view = _viewport(t);
  expect(
    view.contains(rect.topLeft) && view.contains(rect.bottomRight),
    isTrue,
    reason: '$name rect $rect is outside viewport $view',
  );
  // ignore: avoid_print
  print('ONSCREEN $name $rect view=$view');
}

Future<void> _dragUntilOnScreen(
  WidgetTester t,
  Finder target,
  String name,
) async {
  final scroll = find.byType(Scrollable).first;
  for (var i = 0; i < 40; i++) {
    if (target.evaluate().length == 1) {
      final rect = t.getRect(target);
      if (_viewport(t).contains(rect.topLeft) &&
          _viewport(t).contains(rect.bottomRight)) {
        _expectOnScreen(t, target, name);
        return;
      }
    }
    await t.drag(scroll, const Offset(0, -80));
    await t.pump(const Duration(milliseconds: 16));
  }
  fail('$name never entered the viewport');
}

void main() {
  setUpAll(
    () =>
        loadComplianceFonts('test/guardian/offline_copy_and_scroll_test.dart'),
  );

  testWidgets('offline banner is scoped and keeps LTR punctuation', (t) async {
    expect(
      GuardianLinkScreen.offlineBanner,
      'You are offline. Some actions need an internet connection.',
    );
    _pin(t, const Size(320, 568));
    final hub = _Hub([
      GuardianHubLink(childUserId: 42, status: 'active', regime: 'NDPA_2023'),
    ]);
    await t.pumpWidget(
      _app(
        scale: 2,
        direction: TextDirection.rtl,
        home: GuardianLinkScreen(guardianLinkService: hub),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    hub.offline = true;
    await t.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    final banner = find.text(GuardianLinkScreen.offlineBanner);
    _expectOnScreen(t, banner, 'offline banner');
    final paragraph = t.renderObject<RenderParagraph>(
      find.descendant(of: banner, matching: find.byType(RichText)),
    );
    expect(paragraph.textDirection, TextDirection.ltr);
    final text = GuardianLinkScreen.offlineBanner;
    final first = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        )
        .first;
    final periodAt = text.lastIndexOf('.');
    final period = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: periodAt, extentOffset: periodAt + 1),
        )
        .first;
    expect(period.left, greaterThan(first.left));
  });

  testWidgets('320dp 200% RTL can reach Not now and the decided section', (
    t,
  ) async {
    _pin(t, const Size(320, 568));
    await t.pumpWidget(
      _app(
        scale: 2,
        direction: TextDirection.rtl,
        home: GuardianApprovalsScreen(
          approvalService: _Approvals([
            GuardianGroupJoinRequestRow(
              requestId: 'req-1',
              childName: 'Ada',
              childUserId: 42,
              groupKind: 'classroom',
              groupName: 'Yoruba Circle Class',
              memberCount: 12,
              adultMemberCount: 2,
              moderationStatus: 'moderated',
              status: 'pending',
              expiresAt: DateTime.utc(2026, 2, 1),
            ),
            GuardianGroupJoinRequestRow(
              requestId: 'req-2',
              childUserId: 7,
              groupKind: 'circle',
              groupName: 'Study circle',
              memberCount: 5,
              adultMemberCount: 1,
              moderationStatus: 'open',
              status: 'approved',
            ),
          ]),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    await _dragUntilOnScreen(t, find.text('Not now'), 'Not now');
    final decidedAtNotNow = t.getRect(find.text('Decided'));
    // ignore: avoid_print
    print(
      'Decided while Not now is on screen: $decidedAtNotNow '
      'inside=${_viewport(t).contains(decidedAtNotNow.topLeft) && _viewport(t).contains(decidedAtNotNow.bottomRight)}',
    );
    await _dragUntilOnScreen(t, find.text('Decided'), 'Decided');
    await _dragUntilOnScreen(t, find.text('Revoke'), 'Revoke');
  });

  testWidgets('320dp 200% RTL can reach the bottom link action', (t) async {
    _pin(t, const Size(320, 568));
    final hub = _Hub([
      GuardianHubLink(childUserId: 42, status: 'active', regime: 'NDPA_2023'),
    ]);
    await t.pumpWidget(
      _app(
        scale: 2,
        direction: TextDirection.rtl,
        home: GuardianLinkScreen(guardianLinkService: hub),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    hub.offline = true;
    await t.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    await _dragUntilOnScreen(t, find.text('Link learner'), 'Link learner');
  });
}
