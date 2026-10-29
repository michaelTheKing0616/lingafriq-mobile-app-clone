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
      expect(find.text('Select birth year'), findsOneWidget);
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
      expect(
        find.text('Choose the year you were born to continue.'),
        findsOneWidget,
      );
    });

    testWidgets('blocked retry shows AGE_RETRY_BLOCKED copy', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          AgeGateScreen(
            deviceKeyOverride: 'test-device',
            debugPrefilledBirthYear: 2010,
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

    testWidgets('pending guardian state offers lesson continue', (
      tester,
    ) async {
      var completed = false;
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          AgeGateScreen(
            deviceKeyOverride: 'test-device',
            debugPrefilledBirthYear: 2018,
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
      expect(
        find.text(AgeGateScreen.ageGatePendingGuardianTitle),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Continue to lessons'));
      await tester.tap(find.text('Continue to lessons'));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });
    test('child threshold is 13 by default and 16 where law requires', () {
      expect(AgeGateScreen.childThreshold(null), 13);
      expect(AgeGateScreen.childThreshold('NG'), 13);
      expect(AgeGateScreen.childThreshold('DE'), 16);
    });

    testWidgets('never asks for a month or day', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(const AgeGateScreen(deviceKeyOverride: 'test-device')),
      );
      await tester.pumpAndSettle();
      // A real tap: the year field must be hit-testable, not covered.
      final field = find.ancestor(
        of: find.text('Select birth year'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(field).height, greaterThanOrEqualTo(48));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(find.byType(YearPicker), findsOneWidget);
      expect(find.byType(CalendarDatePicker), findsNothing);
    });
  });
}
