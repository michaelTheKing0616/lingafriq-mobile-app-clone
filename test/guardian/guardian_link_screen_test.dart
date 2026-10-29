import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/guardian/guardian_link_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(child: MaterialApp(home: child)),
  );
}

// The ListView's own Scrollable is the first match in tree order; the
// accept-invite form's two TextFields each carry an internal Scrollable too,
// so without `.first` this finder is ambiguous (StateError: Too many elements).
Finder _hubScrollable() {
  return find
      .descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(Scrollable),
      )
      .first;
}

/// A fully scriptable fake so every hub/invite/accept outcome can be driven
/// from a single, readable service per test (AC: cover loading, empty,
/// error, offline, success for both the hub list and the two sub-flows).
class _ScriptedGuardianService extends GuardianLinkService {
  _ScriptedGuardianService({
    this.hubLinks = const [],
    this.hubError,
    this.hubOffline = false,
    this.hubLoadingGate,
    this.createInviteToken,
    this.createInviteFails = false,
    this.acceptInviteState = GuardianSubmitState.sent,
  });

  final List<GuardianHubLink> hubLinks;
  final GuardianApiException? hubError;
  // Mutable so a single test can flip connectivity mid-flow (e.g. go offline
  // on a pull-to-refresh after an initial successful load) without needing a
  // second scripted service instance.
  bool hubOffline;
  final Completer<void>? hubLoadingGate;
  final String? createInviteToken;
  final bool createInviteFails;
  final GuardianSubmitState acceptInviteState;

  int acceptInviteCalls = 0;

  @override
  Future<void> flushPending() async {}

  @override
  Future<List<GuardianHubLink>> fetchHubLinks() async {
    if (hubLoadingGate != null) {
      await hubLoadingGate!.future;
    }
    if (hubOffline) throw const GuardianOfflineException();
    if (hubError != null) throw hubError!;
    return hubLinks;
  }

  @override
  Future<GuardianSubmitState> createChildInvite({
    required void Function(String token, DateTime expiresAt) onSuccess,
  }) async {
    if (createInviteFails) return GuardianSubmitState.error;
    onSuccess(createInviteToken ?? 'ABCD-1234', DateTime.utc(2026, 12, 1));
    return GuardianSubmitState.sent;
  }

  @override
  Future<GuardianSubmitState> acceptInvite({
    required String inviteToken,
    required String guardianDisplayName,
  }) async {
    acceptInviteCalls += 1;
    return acceptInviteState;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loading state shows a spinner with an accessible label', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    final gate = Completer<void>();
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(
          guardianLinkService: _ScriptedGuardianService(hubLoadingGate: gate),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Loading your family hub'), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    handle.dispose();
  });

  testWidgets('empty hub shows honest empty state (AC5)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(
          guardianLinkService: _ScriptedGuardianService(hubLinks: const []),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(GuardianLinkScreen.guardianHubEmptyTitle),
      400,
      scrollable: _hubScrollable(),
    );
    expect(find.text(GuardianLinkScreen.guardianHubEmptyTitle), findsOneWidget);
    expect(find.textContaining('invite code'), findsWidgets);
  });

  testWidgets('error state shows a retry affordance that reloads the hub', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(
          guardianLinkService: _ScriptedGuardianService(
            hubError: GuardianApiException(message: 'Server hiccup. Try again.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Server hiccup. Try again.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    final retryButtonSize = tester.getSize(find.widgetWithText(FilledButton, 'Try again'));
    expect(retryButtonSize.height, greaterThanOrEqualTo(48));

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    // Same scripted error persists after retry — the panel must still be
    // showing a clear message rather than silently failing or crashing.
    expect(find.text('Server hiccup. Try again.'), findsOneWidget);
  });

  testWidgets('offline with no cached links shows the offline banner', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(
          guardianLinkService: _ScriptedGuardianService(hubOffline: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(GuardianLinkScreen.offlineBanner), findsOneWidget);
  });

  testWidgets('linked learner tile is tappable with semantics', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(
          guardianLinkService: _ScriptedGuardianService(
            hubLinks: [
              GuardianHubLink(childUserId: 100, status: 'verifying', regime: 'NDPA_2023'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Learner #100'),
      400,
      scrollable: _hubScrollable(),
    );
    expect(find.text('Learner #100'), findsOneWidget);
    expect(find.bySemanticsLabel('Learner 100, Needs your consent'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('child-invite view creates and displays a copyable code', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(
          initialChildInviteMode: true,
          guardianLinkService: _ScriptedGuardianService(createInviteToken: 'XYZ-9988'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Create invite code'), findsOneWidget);

    await tester.tap(find.text('Create invite code'));
    await tester.pumpAndSettle();

    expect(find.text('XYZ-9988'), findsOneWidget);
    expect(find.text('Copy code'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Invite code XYZ-9988')), findsOneWidget);
  });

  testWidgets('child-invite view surfaces an error when invite creation fails', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(
          initialChildInviteMode: true,
          guardianLinkService: _ScriptedGuardianService(createInviteFails: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create invite code'));
    await tester.pumpAndSettle();

    expect(
      find.text('We could not create an invite right now. Try again in a moment.'),
      findsOneWidget,
    );
    // No silent failure: the create button must still be present to retry.
    expect(find.text('Create invite code'), findsOneWidget);
  });

  testWidgets('Link learner stays disabled until both fields are filled', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(
          guardianLinkService: _ScriptedGuardianService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    FilledButton linkButton() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Link learner'));
    expect(linkButton().onPressed, isNull);

    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, 'Invite code'),
      400,
      scrollable: _hubScrollable(),
    );
    await tester.enterText(find.widgetWithText(TextField, 'Invite code'), 'tok-1');
    await tester.pump();
    expect(linkButton().onPressed, isNull, reason: 'guardian name is still empty');

    await tester.enterText(
      find.widgetWithText(TextField, GuardianLinkScreen.guardianYourNameHint),
      'Ada',
    );
    await tester.pump();
    expect(linkButton().onPressed, isNotNull);
  });

  testWidgets('accept-invite success clears the form and reloads the hub', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    final service = _ScriptedGuardianService(acceptInviteState: GuardianSubmitState.sent);
    await tester.pumpWidget(
      _wrap(GuardianLinkScreen(guardianLinkService: service)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, 'Invite code'),
      400,
      scrollable: _hubScrollable(),
    );
    await tester.enterText(find.widgetWithText(TextField, 'Invite code'), 'tok-1');
    await tester.enterText(
      find.widgetWithText(TextField, GuardianLinkScreen.guardianYourNameHint),
      'Ada',
    );
    await tester.pump();

    await tester.tap(find.text('Link learner'));
    await tester.pumpAndSettle();

    expect(service.acceptInviteCalls, 1);
    expect(find.text('Check the code and your name, then try again.'), findsNothing);
    final tokenField =
        tester.widget<TextField>(find.widgetWithText(TextField, 'Invite code'));
    expect(tokenField.controller?.text, isEmpty);
  });

  testWidgets('accept-invite error is shown inline, not silently dropped', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(
          guardianLinkService: _ScriptedGuardianService(
            acceptInviteState: GuardianSubmitState.error,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, 'Invite code'),
      400,
      scrollable: _hubScrollable(),
    );
    await tester.enterText(find.widgetWithText(TextField, 'Invite code'), 'bad-tok');
    await tester.enterText(
      find.widgetWithText(TextField, GuardianLinkScreen.guardianYourNameHint),
      'Ada',
    );
    await tester.pump();

    await tester.tap(find.text('Link learner'));
    await tester.pumpAndSettle();

    expect(find.text('Check the code and your name, then try again.'), findsOneWidget);
  });

  testWidgets('accept-invite queued-offline tells the guardian what happens next', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(
          guardianLinkService: _ScriptedGuardianService(
            acceptInviteState: GuardianSubmitState.queuedOffline,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, 'Invite code'),
      400,
      scrollable: _hubScrollable(),
    );
    await tester.enterText(find.widgetWithText(TextField, 'Invite code'), 'tok-2');
    await tester.enterText(
      find.widgetWithText(TextField, GuardianLinkScreen.guardianYourNameHint),
      'Bola',
    );
    await tester.pump();

    await tester.tap(find.text('Link learner'));
    await tester.pumpAndSettle();

    expect(
      find.text('Saved on this device. We will finish linking when you are online.'),
      findsOneWidget,
    );
  });

  testWidgets('RTL flips the learner tile chevron direction', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => ProviderScope(
          child: MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: GuardianLinkScreen(
                guardianLinkService: _ScriptedGuardianService(
                  hubLinks: [
                    GuardianHubLink(childUserId: 7, status: 'active', regime: 'GDPR_ART_8'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Learner #7'),
      400,
      scrollable: _hubScrollable(),
    );
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('mode toggle segments meet the 48dp minimum tap target', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(guardianLinkService: _ScriptedGuardianService()),
      ),
    );
    await tester.pumpAndSettle();

    final handle = tester.ensureSemantics();
    final hubSegment = find.bySemanticsLabel('Guardian hub, show linked learners');
    final inviteSegment = find.bySemanticsLabel('Learner invite, create a code to share');
    expect(hubSegment, findsOneWidget);
    expect(inviteSegment, findsOneWidget);
    expect(tester.getSize(hubSegment).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(inviteSegment).height, greaterThanOrEqualTo(48));
    handle.dispose();

    await tester.tap(inviteSegment);
    await tester.pumpAndSettle();
    expect(find.text('Create invite code'), findsOneWidget);
  });

  testWidgets('golden: loaded hub with offline banner and a linked learner', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await ScreenUtil.ensureScreenSize();
    final service = _ScriptedGuardianService(
      hubLinks: [
        GuardianHubLink(childUserId: 42, status: 'active', regime: 'NDPA_2023'),
      ],
    );
    await tester.pumpWidget(
      _wrap(GuardianLinkScreen(guardianLinkService: service)),
    );
    await tester.pumpAndSettle();

    // This golden's name promises BOTH the offline banner AND a cached
    // linked learner on screen at once. That combination only happens when
    // a guardian who already loaded their hub goes offline on a later
    // refresh (AC: offline-first — cached links must not disappear just
    // because the next fetch failed). Drive that refresh for real, through
    // the same `onRefresh` callback the pull-to-refresh gesture uses,
    // instead of only ever testing the "online from the first load" case.
    service.hubOffline = true;
    final indicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await indicator.onRefresh();
    await tester.pumpAndSettle();

    expect(find.text(GuardianLinkScreen.offlineBanner), findsOneWidget);
    expect(find.text('Learner #42'), findsOneWidget);

    await expectLater(
      find.byType(GuardianLinkScreen),
      matchesGoldenFile('goldens/guardian_link_screen_loaded.png'),
    );
  });
}
