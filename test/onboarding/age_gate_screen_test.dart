import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/onboarding/age_gate_screen.dart';
import 'package:lingafriq/services/age_tier_service.dart';

class _FakeAgeTierService extends AgeTierService {
  _FakeAgeTierService(this._assignResult);

  final AgeTierAssignmentResult _assignResult;

  @override
  Future<AgeTierAssignmentResult> assignBirthDate({
    required int birthYear,
    required int birthMonth,
    required int birthDay,
    required String deviceKey,
    String? nationality,
  }) async {
    return _assignResult;
  }
}

Widget wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(child: MaterialApp(home: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AgeGateScreen', () {
    testWidgets('shows default copy and date affordance', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const AgeGateScreen(deviceKeyOverride: 'test-device')),
      );
      await tester.pumpAndSettle();

      expect(find.text(AgeGateScreen.ageGateTitle), findsOneWidget);
      expect(find.text(AgeGateScreen.ageGateBody), findsOneWidget);
      expect(find.text('Select date of birth'), findsOneWidget);
    });

    testWidgets('invalid state when continue without date', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const AgeGateScreen(deviceKeyOverride: 'test-device')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your date of birth to continue.'), findsOneWidget);
    });

    testWidgets('blocked retry shows AGE_RETRY_BLOCKED copy', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          AgeGateScreen(
            deviceKeyOverride: 'test-device',
            debugPrefilledBirthDate: DateTime(2010, 5, 5),
            ageTierService: _FakeAgeTierService(
              AgeTierAssignmentResult(
                ok: false,
                code: 'AGE_RETRY_BLOCKED',
                message: AgeGateScreen.ageGateBlocked,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text(AgeGateScreen.ageGateBlocked), findsOneWidget);
    });

    testWidgets('pending guardian state offers lesson continue', (tester) async {
      var completed = false;
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          AgeGateScreen(
            deviceKeyOverride: 'test-device',
            debugPrefilledBirthDate: DateTime(2018, 1, 1),
            ageTierService: _FakeAgeTierService(
              AgeTierAssignmentResult(
                ok: true,
                tier: 'under_13',
                status: 'pending_guardian',
                pendingGuardian: true,
              ),
            ),
            onCompleted: () => completed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text(AgeGateScreen.ageGatePendingGuardianTitle), findsOneWidget);
      await tester.ensureVisible(find.text('Continue to lessons'));
      await tester.tap(find.text('Continue to lessons'));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });
  });
}
