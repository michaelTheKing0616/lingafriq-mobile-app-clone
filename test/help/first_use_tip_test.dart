import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/help/features_guide_screen.dart';
import 'package:lingafriq/widgets/first_use_tip.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('FirstUseTipStore', () {
    test('first show is shown; after dismiss the same id is hidden', () {
      final store = FirstUseTipStore.inMemory();
      const id = FirstUseTipIds.games;

      expect(store.firstUseTip(id), FirstUseTipPhase.shown);
      store.dismiss(id);
      expect(store.firstUseTip(id), FirstUseTipPhase.hidden);
    });

    test('dismissing one tip does not hide the other three', () {
      final store = FirstUseTipStore.inMemory();

      store.dismiss(FirstUseTipIds.games);

      expect(store.firstUseTip(FirstUseTipIds.games), FirstUseTipPhase.hidden);
      expect(store.firstUseTip(FirstUseTipIds.gamification), FirstUseTipPhase.shown);
      expect(store.firstUseTip(FirstUseTipIds.polie), FirstUseTipPhase.shown);
      expect(store.firstUseTip(FirstUseTipIds.features), FirstUseTipPhase.shown);
    });

    test('dismissal survives a new store on shared in-memory map', () {
      final map = <String, bool>{};
      final store1 = FirstUseTipStore.inMemory(map);
      store1.dismiss(FirstUseTipIds.games);
      final store2 = FirstUseTipStore.inMemory(map);
      expect(store2.firstUseTip(FirstUseTipIds.games), FirstUseTipPhase.hidden);
    });

    test('dismissal survives a new store backed by SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store1 = FirstUseTipStore(
        FirstUseTipDismissStorage.sharedPreferences(prefs),
      );
      store1.dismiss(FirstUseTipIds.polie);
      final store2 = FirstUseTipStore(
        FirstUseTipDismissStorage.sharedPreferences(prefs),
      );
      expect(store2.firstUseTip(FirstUseTipIds.polie), FirstUseTipPhase.hidden);
    });
  });

  testWidgets('FirstUseTip shows games sentence and dismiss control', (tester) async {
    final store = FirstUseTipStore.inMemory();

    Widget tip({VoidCallback? onDismiss}) => FirstUseTip(
          store: store,
          tipId: FirstUseTipIds.games,
          sentence: FirstUseTipCopy.games,
          onDismiss: onDismiss,
        );

    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => tip(onDismiss: () => setState(() {})),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('phase-shown')), findsOneWidget);
    expect(find.text(FirstUseTipCopy.games), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
    expect(find.bySemanticsLabel('Dismiss tip'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('phase-hidden')), findsOneWidget);
    expect(store.firstUseTip(FirstUseTipIds.games), FirstUseTipPhase.hidden);
  });

  test('settingsHelpLinks contains features guide and game onboarding overlay', () {
    final links = settingsHelpLinks();
    final names = links.map((l) => l.screenOrRoute).toList();
    final labels = links.map((l) => l.label).join(' ');

    expect(names, contains('FeaturesGuideScreen'));
    expect(names, contains('GameOnboardingOverlay'));
    expect(tourScreens, contains('FeaturesGuideScreen'));
    expect(tourScreens, contains('GameOnboardingOverlay'));
    expect(labels, contains('Features Guide'));
    expect(labels, contains('Game onboarding overlay'));
  });

  testWidgets('settings help rows expose both tour link labels', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SettingsHelpLinks(
          tileBuilder: (context, link, onTap) => ListTile(
            title: Text(link.label),
            onTap: onTap,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final link in settingsHelpLinks()) {
      expect(find.text(link.label), findsOneWidget);
    }
  });
}
