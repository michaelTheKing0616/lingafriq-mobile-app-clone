import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/user_gamification_model.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/screens/village/preservation_fund_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FundNotifier extends GamificationProvider {
  @override
  BaseProviderState build() => BaseProviderState();

  @override
  UserGamificationModel get gamification =>
      UserGamificationModel(cowries: 250);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('fund screen empty impact and donate affordance', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamificationProvider.overrideWith(() => _FundNotifier()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: PreservationFundScreen(
              initialSummaryForTest: {
                'total_cowries_received': 0,
                'total_cowries_disbursed': 0,
                'disbursements': [],
                'your_donations_count': 0,
                'impact_recorded': false,
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text(
        'Community impact will appear here once funded projects are recorded in our ledger. Nothing has been funded yet.',
      ),
      findsOneWidget,
    );
    expect(find.text('Heritage Fund'), findsOneWidget);
  });
}
