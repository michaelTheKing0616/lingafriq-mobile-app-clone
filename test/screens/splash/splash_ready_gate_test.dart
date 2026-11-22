import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/splash/splash_ready_gate.dart';
import 'package:lingafriq/screens/splash/splash_screen_material3.dart';

void main() {
  Future<void> pumpSplash(WidgetTester tester, Future<void> ready) {
    return tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(428, 926),
          minTextAdapt: true,
          builder: (context, _) {
            return MaterialApp(
              builder: (context, child) {
                ScreenUtil.init(context, designSize: const Size(428, 926));
                return child ?? const SizedBox.shrink();
              },
              home: SplashScreenMaterial3(ready: ready),
            );
          },
        ),
      ),
    );
  }

  testWidgets('a ready app leaves the splash without waiting out a fixed delay', (tester) async {
    final ready = Completer<void>();
    await pumpSplash(tester, ready.future);
    await tester.pump(Duration.zero);

    expect(find.byKey(SplashReadyGate.surfaceKey), findsOneWidget);
    expect(find.text('Connecting Africa Through Language'), findsOneWidget);
    expect(find.byKey(SplashReadyGate.progressKey), findsNothing);

    ready.complete();
    await tester.pump();

    expect(find.byKey(SplashReadyGate.surfaceKey), findsNothing);
    expect(find.text('Connecting Africa Through Language'), findsNothing);
    expect(find.byKey(SplashReadyGate.progressKey), findsNothing);
  });

  testWidgets('a slow start keeps the splash and shows a progress cue', (tester) async {
    final ready = Completer<void>();
    await pumpSplash(tester, ready.future);

    await tester.pump(splashProgressCueDelay - const Duration(milliseconds: 1));
    expect(find.byKey(SplashReadyGate.surfaceKey), findsOneWidget);
    expect(find.text('Connecting Africa Through Language'), findsOneWidget);
    expect(find.byKey(SplashReadyGate.progressKey), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(SplashReadyGate.surfaceKey), findsOneWidget);
    expect(find.byKey(SplashReadyGate.progressKey), findsOneWidget);
    expect(
      tester.getSize(find.byKey(SplashReadyGate.progressKey)).shortestSide,
      greaterThan(0),
    );

    ready.complete();
    await tester.pump();
    expect(find.byKey(SplashReadyGate.surfaceKey), findsNothing);
  });
}
