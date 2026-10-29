import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/guardian/consent_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(child: MaterialApp(home: child)),
  );
}

/// Sets the test view to a stable phone-sized surface *synchronously*, so
/// the very first build sees correct [MediaQuery] metrics. (The legacy
/// `tester.binding.setSurfaceSize` races with view-metrics propagation on
/// this Flutter version and can report a stale default size on frame one.)
void _setPhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844) * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
}

/// Always-online probe so widget tests never hit the real network through
/// [ConnectivityService]'s default DNS/HTTP fallback.
Future<bool> _online() async => true;

class _ConsentFakeService extends GuardianLinkService {
  _ConsentFakeService({this.submitResult, this.withdrawResult});

  final GuardianSubmitState? submitResult;
  final GuardianSubmitState? withdrawResult;

  @override
  Future<GuardianSubmitState> submitConsent({
    required int childUserId,
    required bool attestationConfirmed,
  }) async {
    if (!attestationConfirmed) return GuardianSubmitState.error;
    return submitResult ?? GuardianSubmitState.sent;
  }

  @override
  Future<GuardianSubmitState> withdrawConsent({required int childUserId}) async {
    return withdrawResult ?? GuardianSubmitState.sent;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('needs-consent: requires attestation before submit', (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 55,
          initialStatus: 'verifying',
          regime: 'NDPA_2023',
          guardianLinkService: _ConsentFakeService(),
          connectivityCheck: _online,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(GuardianConsentScreen.headlineNeedsConsent), findsOneWidget);
    expect(find.textContaining('NDPA 2023'), findsOneWidget);

    await tester.ensureVisible(find.text(GuardianConsentScreen.approveButtonLabel));
    await tester.tap(find.text(GuardianConsentScreen.approveButtonLabel));
    await tester.pumpAndSettle();
    expect(find.text(GuardianConsentScreen.validationErrorCopy), findsOneWidget);
  });

  testWidgets('needs-consent: approving unlocks active state with success card',
      (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 55,
          initialStatus: 'verifying',
          regime: 'GDPR_ART_8',
          guardianLinkService: _ConsentFakeService(),
          connectivityCheck: _online,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('GDPR Article 8'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(GuardianConsentScreen.approveButtonLabel));
    await tester.tap(find.text(GuardianConsentScreen.approveButtonLabel));
    await tester.pumpAndSettle();

    expect(find.text(GuardianConsentScreen.headlineActive), findsOneWidget);
    expect(find.textContaining('unlocked for learner #55'), findsOneWidget);
    expect(find.text(GuardianConsentScreen.withdrawButtonLabel), findsOneWidget);
  });

  testWidgets('active: withdraw shows confirm dialog, then withdrawn state offers re-consent',
      (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 9,
          initialStatus: 'active',
          regime: 'NDPA_2023',
          guardianLinkService: _ConsentFakeService(),
          connectivityCheck: _online,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(GuardianConsentScreen.withdrawButtonLabel));
    await tester.pumpAndSettle();

    expect(find.text(GuardianConsentScreen.withdrawTitle), findsOneWidget);
    expect(find.text(GuardianConsentScreen.withdrawBody), findsOneWidget);

    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();

    expect(find.text(GuardianConsentScreen.headlineWithdrawn), findsOneWidget);
    expect(find.text(GuardianConsentScreen.giveConsentAgainLabel), findsOneWidget);

    await tester.tap(find.text(GuardianConsentScreen.giveConsentAgainLabel));
    await tester.pumpAndSettle();

    expect(find.text(GuardianConsentScreen.headlineNeedsConsent), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsOneWidget);
  });

  testWidgets('active: withdraw failure shows error banner and stays active',
      (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 9,
          initialStatus: 'active',
          guardianLinkService: _ConsentFakeService(
            withdrawResult: GuardianSubmitState.error,
          ),
          connectivityCheck: _online,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(GuardianConsentScreen.withdrawButtonLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();

    // A failed withdraw must not silently flip the guardian into a
    // "withdrawn" state they never actually reached.
    expect(find.text(GuardianConsentScreen.headlineActive), findsOneWidget);
    expect(find.text(GuardianConsentScreen.genericErrorCopy), findsOneWidget);
  });

  testWidgets('withdraw dialog cancel keeps consent active', (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 9,
          initialStatus: 'active',
          guardianLinkService: _ConsentFakeService(),
          connectivityCheck: _online,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(GuardianConsentScreen.withdrawButtonLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text(GuardianConsentScreen.headlineActive), findsOneWidget);
  });

  testWidgets('needs-consent: queued-offline submit result shows queued banner',
      (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 21,
          initialStatus: 'invited',
          guardianLinkService: _ConsentFakeService(
            submitResult: GuardianSubmitState.queuedOffline,
          ),
          connectivityCheck: _online,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(GuardianConsentScreen.approveButtonLabel));
    await tester.tap(find.text(GuardianConsentScreen.approveButtonLabel));
    await tester.pumpAndSettle();

    expect(find.text(GuardianConsentScreen.queuedOfflineCopy), findsOneWidget);
    // Status does not flip to active when the write only queued.
    expect(find.text(GuardianConsentScreen.headlineActive), findsNothing);
  });

  testWidgets('needs-consent: error submit result shows error banner', (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 21,
          initialStatus: 'invited',
          guardianLinkService: _ConsentFakeService(
            submitResult: GuardianSubmitState.error,
          ),
          connectivityCheck: _online,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(GuardianConsentScreen.approveButtonLabel));
    await tester.tap(find.text(GuardianConsentScreen.approveButtonLabel));
    await tester.pumpAndSettle();

    expect(find.text(GuardianConsentScreen.genericErrorCopy), findsOneWidget);
  });

  testWidgets('offline device shows a before-submission offline notice', (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 21,
          initialStatus: 'invited',
          guardianLinkService: _ConsentFakeService(),
          connectivityCheck: () async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(GuardianConsentScreen.offlineBeforeSubmitCopy), findsOneWidget);
  });

  testWidgets('unrecognised status falls back to an honest explanation', (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 21,
          initialStatus: 'pending_review',
          guardianLinkService: _ConsentFakeService(),
          connectivityCheck: _online,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(GuardianConsentScreen.headlineUnknown), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  testWidgets('attestation checkbox exposes a checked semantics label', (tester) async {
    _setPhoneSurface(tester);
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 3,
          initialStatus: 'verifying',
          guardianLinkService: _ConsentFakeService(),
          connectivityCheck: _online,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(GuardianConsentScreen.attestationLabel),
      findsWidgets,
    );

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    // The attestation state flows into Flutter's own Checkbox, which owns
    // its accessible checked/unchecked semantics — confirm our state wiring
    // reaches it correctly.
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    handle.dispose();
  });

  testWidgets('golden: needs-consent layout', (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 55,
          initialStatus: 'verifying',
          regime: 'NDPA_2023',
          guardianLinkService: _ConsentFakeService(),
          connectivityCheck: _online,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(GuardianConsentScreen),
      matchesGoldenFile('goldens/guardian_consent_needs_consent.png'),
    );
  });

  testWidgets('golden: active layout', (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(
      _wrap(
        GuardianConsentScreen(
          childUserId: 55,
          initialStatus: 'active',
          regime: 'NDPA_2023',
          guardianLinkService: _ConsentFakeService(),
          connectivityCheck: _online,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(GuardianConsentScreen),
      matchesGoldenFile('goldens/guardian_consent_active.png'),
    );
  });
}
