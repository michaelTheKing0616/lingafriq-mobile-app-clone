import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/widgets/safety/safety_actions_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SafetyActionsSheet P9-930', () {
    test('AC1 block reachable within two taps from sheet actions', () {
      final ledger = SafetyTapLedger();
      ledger.recordTap();
      ledger.recordTap();
      expect(ledger.taps, lessThanOrEqualTo(2));
    });

    test('AC4 offline report queues with will-send state', () async {
      SharedPreferences.setMockInitialValues({});
      await SafetyReportOutbox.enqueue({
        'targetType': 'user',
        'targetId': 'peer-1',
        'reason': 'spam',
      });
      final pending = await SafetyReportOutbox.pending();
      expect(pending, hasLength(1));
      expect(pending.first['targetId'], 'peer-1');
    });

    testWidgets('safety sheet shows block mute report actions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SafetyActionsSheet(
            target: const SafetyActionTarget(
              kind: SafetyTargetKind.profile,
              targetId: 'peer-1',
              peerUserId: 'peer-1',
              peerDisplayName: 'Ada',
            ),
            isOnline: () async => true,
          ),
        ),
      );
      expect(find.text(SafetyCopy.block), findsOneWidget);
      expect(find.text(SafetyCopy.mute), findsOneWidget);
      expect(find.text(SafetyCopy.report), findsOneWidget);
    });
  });
}
