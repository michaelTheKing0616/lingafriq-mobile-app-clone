import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/festival/festival_banner.dart';
import 'package:lingafriq/games/festival/festival_theme_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('village festival hub shows theme and games', (tester) async {
    await tester.pumpWidget(
      wrap(
        VillageFestivalHubBanner(
          utcNowOverride: DateTime.utc(2026, 1, 8),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Village Festival'), findsOneWidget);
    expect(find.text('Family & home'), findsOneWidget);
    expect(find.text('Games joining in'), findsOneWidget);
    expect(find.text('Tone Forge'), findsOneWidget);
  });
}
