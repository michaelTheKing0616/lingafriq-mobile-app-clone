import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/hearts_system_model.dart';
import 'package:lingafriq/providers/hearts_provider.dart';
import 'package:lingafriq/screens/village/challenge_mode_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OptInHeartsNotifier extends HeartsNotifier {
  @override
  HeartsState build() => HeartsState(challengeModeEnabled: true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('challenge mode toggle hidden during core flow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(home: ChallengeModeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Challenge mode toggle'), findsOneWidget);
    expect(find.textContaining('Core lessons stay pressure-free'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
  });

  testWidgets('challenge_mode_toggle_golden opt-in shows start run', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          heartsProvider.overrideWith(() => _OptInHeartsNotifier()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(home: ChallengeModeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start Challenge run'), findsOneWidget);
  });
}
