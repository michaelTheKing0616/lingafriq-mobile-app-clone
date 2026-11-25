import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/a11y/text_scale.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/navigation/app_shell.dart';
import 'package:lingafriq/navigation/lens_entry.dart';
import 'package:lingafriq/navigation/tab_routes.dart';
import 'package:lingafriq/screens/ar/point_and_say_screen.dart';
import 'package:lingafriq/screens/media/import_media_screen.dart';
import 'package:lingafriq/screens/translate/live_translate_screen.dart';
import 'package:lingafriq/services/lens/on_device_object_classifier.dart';
import 'package:lingafriq/services/search_index_service.dart';
import 'package:lingafriq/widgets/word_card_sheet.dart';
import 'package:permission_handler/permission_handler.dart';

Widget _host(Widget child, {bool reduced = false}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) {
      final MediaQueryData data = MediaQuery.of(context);
      return MediaQuery(
        data: data.copyWith(disableAnimations: reduced),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}

Widget _shell({
  bool offline = false,
  bool reduced = false,
  LensCameraAccess camera = LensCameraAccess.allowed,
  bool recognizerPresent = false,
  SearchWord? dictionaryWord,
  Future<bool> Function()? openSettings,
}) {
  return _host(
    Builder(
      builder: (BuildContext context) {
        return AppShell(
          onLens: () {
            LensEntry.open(
              context,
              offline: offline,
              camera: camera,
              recognizerPresent: recognizerPresent,
              dictionaryWord: dictionaryWord,
              openSettings: openSettings,
            );
          },
        );
      },
    ),
    reduced: reduced,
  );
}

Future<void> _openLens(WidgetTester tester) async {
  await tester.tap(find.byKey(AppShell.toolKey(ShellTool.lens)));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('camera access is allowed only when granted', () {
    expect(lensAccessFor(PermissionStatus.granted), LensCameraAccess.allowed);
    expect(lensAccessFor(PermissionStatus.denied), LensCameraAccess.denied);
    expect(
      lensAccessFor(PermissionStatus.permanentlyDenied),
      LensCameraAccess.denied,
    );
    expect(
      lensAccessFor(PermissionStatus.restricted),
      LensCameraAccess.denied,
    );
  });

  test('the recognizer is present only when the bundled model loads', () async {
    String? loaded;
    expect(
      await lensRecognizerIsPresent(
        loadAsset: (String asset) async {
          loaded = asset;
          return ByteData(8);
        },
      ),
      isTrue,
    );
    expect(loaded, PointSayModelLicence.bundledAsset);

    expect(
      await lensRecognizerIsPresent(
        loadAsset: (String asset) async => ByteData(0),
      ),
      isFalse,
    );
    expect(
      await lensRecognizerIsPresent(
        loadAsset: (String asset) async => throw StateError('missing'),
      ),
      isFalse,
    );
  });

  test('destinations open existing screens and do not invent a recognizer', () async {
    final Widget onlinePoint = lensDestination(
      action: LensAction.pointSay,
      offline: false,
      recognizerPresent: false,
    );
    expect(onlinePoint, isA<PointAndSayScreen>());
    expect((onlinePoint as PointAndSayScreen).classifier, isNull);
    expect(onlinePoint.hasInternet, isNull);

    final Widget offlinePoint = lensDestination(
      action: LensAction.pointSay,
      offline: true,
      recognizerPresent: true,
    );
    expect(offlinePoint, isA<PointAndSayScreen>());
    expect((offlinePoint as PointAndSayScreen).classifier, isNull);
    expect(await offlinePoint.hasInternet!.call(), isFalse);

    final Widget missing = lensDestination(
      action: LensAction.pointSay,
      offline: true,
      recognizerPresent: false,
    );
    expect(missing, isA<LensRecognizerMissingPage>());
    expect(missing, isNot(isA<PointAndSayScreen>()));

    expect(
      lensDestination(
        action: LensAction.liveTranslate,
        offline: false,
        recognizerPresent: false,
      ),
      isA<LiveTranslateWithConfidenceScreen>(),
    );
    expect(
      lensDestination(
        action: LensAction.conversationBridge,
        offline: false,
        recognizerPresent: false,
      ),
      isA<LiveTranslateWithConfidenceScreen>(),
    );
    expect(
      lensDestination(
        action: LensAction.liveTranslate,
        offline: true,
        recognizerPresent: true,
      ),
      isA<LensOfflinePage>(),
    );
    expect(
      lensDestination(
        action: LensAction.conversationBridge,
        offline: true,
        recognizerPresent: true,
      ),
      isA<LensOfflinePage>(),
    );
    expect(
      lensDestination(
        action: LensAction.importMedia,
        offline: true,
        recognizerPresent: false,
      ),
      isA<ImportMediaScreen>(),
    );
  });

  testWidgets('the camera action offers the four Lens actions from any tab', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_shell());
    await tester.pumpAndSettle();

    const List<(LensAction, String)> actions = <(LensAction, String)>[
      (LensAction.pointSay, 'Point & Say'),
      (LensAction.liveTranslate, 'Live translate'),
      (LensAction.importMedia, 'Import Media'),
      (LensAction.conversationBridge, 'Conversation Bridge'),
    ];

    for (final ShellTab tab in ShellTab.values) {
      await tester.tap(find.byKey(AppShell.tabKey(tab)));
      await tester.pumpAndSettle();
      await _openLens(tester);

      expect(find.byType(LensSheet), findsOneWidget);
      expect(find.text('Lens'), findsWidgets);
      double previous = -1;
      for (final (LensAction action, String label) in actions) {
        final Finder button = find.byKey(LensSheet.actionKey(action));
        expect(button, findsOneWidget);
        expect(find.text(label), findsOneWidget);
        expect(tester.getSemantics(button).label, label);
        final double top = tester.getTopLeft(button).dy;
        expect(top, greaterThan(previous));
        previous = top;
      }
      expect(find.text('Living Dictionary'), findsOneWidget);

      await tester.tap(find.byKey(LensSheet.closeKey));
      await tester.pumpAndSettle();
      expect(find.byType(LensSheet), findsNothing);
    }
    handle.dispose();
  });

  testWidgets('denied camera permission explains why and opens settings', (
    WidgetTester tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      _shell(
        camera: LensCameraAccess.denied,
        openSettings: () async {
          opened += 1;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();
    await _openLens(tester);

    expect(find.byKey(LensSheet.permissionKey), findsOneWidget);
    expect(find.text('The camera is blocked.'), findsOneWidget);
    expect(
      find.text('LingAfriq does not have permission to use the camera.'),
      findsOneWidget,
    );
    expect(find.text('Open Settings and allow the camera.'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
    expect(find.byKey(LensSheet.actionKey(LensAction.pointSay)), findsNothing);

    await tester.tap(find.text('Open Settings'));
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('offline Live Translate and bridge show the offline state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _shell(offline: true, recognizerPresent: false),
    );
    await tester.pumpAndSettle();
    await _openLens(tester);

    await tester.tap(find.byKey(LensSheet.actionKey(LensAction.liveTranslate)));
    await tester.pumpAndSettle();
    expect(find.byType(LensOfflinePage), findsOneWidget);
    expect(find.byType(LiveTranslateWithConfidenceScreen), findsNothing);
    expect(find.text('The phone has no network.'), findsOneWidget);
    expect(
      find.text('Live Translate needs the network to listen and translate.'),
      findsOneWidget,
    );
    expect(find.text('Connect, then try again.'), findsOneWidget);
    expect(
      ModalRoute.of(tester.element(find.byType(LensOfflinePage)))!.settings.name,
      LensAction.liveTranslate.routeName,
    );

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await _openLens(tester);
    await tester.tap(
      find.byKey(LensSheet.actionKey(LensAction.conversationBridge)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LensOfflinePage), findsOneWidget);
    expect(find.byType(LiveTranslateWithConfidenceScreen), findsNothing);
    expect(find.text('Conversation Bridge'), findsOneWidget);
    expect(
      ModalRoute.of(tester.element(find.byType(LensOfflinePage)))!.settings.name,
      LensAction.conversationBridge.routeName,
    );
  });

  testWidgets('offline Point & Say does not invent a missing recognizer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _shell(offline: true, recognizerPresent: false),
    );
    await tester.pumpAndSettle();
    await _openLens(tester);
    await tester.tap(find.byKey(LensSheet.actionKey(LensAction.pointSay)));
    await tester.pumpAndSettle();

    expect(find.byType(LensRecognizerMissingPage), findsOneWidget);
    expect(find.byType(PointAndSayScreen), findsNothing);
    expect(find.text('Point & Say cannot name this offline.'), findsOneWidget);
    expect(
      find.text('The on-device recognizer is not on this phone.'),
      findsOneWidget,
    );
    expect(find.text('Similar object'), findsNothing);
    expect(find.text('Household item'), findsNothing);
    expect(find.text('Plantain'), findsNothing);
  });

  testWidgets('Living Dictionary from Lens opens the Search word card', (
    WidgetTester tester,
  ) async {
    const SearchWord word = SearchWord(
      id: 'yo',
      surface: 'sànnú',
      gloss: 'hello',
    );
    await tester.pumpWidget(_shell(dictionaryWord: word));
    await tester.pumpAndSettle();
    await _openLens(tester);
    await tester.tap(find.byKey(LensSheet.dictionaryKey));
    await tester.pumpAndSettle();

    expect(find.byType(WordCardSheet), findsOneWidget);
    expect(find.text('sànnú'), findsOneWidget);
  });

  testWidgets('Living Dictionary without a word does not invent a card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_shell());
    await tester.pumpAndSettle();
    await _openLens(tester);
    await tester.tap(find.byKey(LensSheet.dictionaryKey));
    await tester.pumpAndSettle();

    expect(find.byType(LensDictionaryEmptyPage), findsOneWidget);
    expect(find.byType(WordCardSheet), findsNothing);
    expect(find.text('No word is open.'), findsOneWidget);
    expect(find.text('Point & Say has not named a word.'), findsOneWidget);
  });

  testWidgets('reduced motion still opens the sheet', (WidgetTester tester) async {
    await tester.pumpWidget(_shell(reduced: true));
    await tester.pumpAndSettle();
    await _openLens(tester);
    expect(find.text('Point & Say'), findsOneWidget);
    expect(find.text('Conversation Bridge'), findsOneWidget);
  });

  testWidgets('lens copy does not clip at 200 percent text', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(
      const Size(textScaleCatalogueWidth, textScaleSurfaceHeight),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(
      textScaleCatalogueWidth,
      textScaleSurfaceHeight,
    );
    addTearDown(tester.view.reset);

    Future<void> check(Widget child, String useCaseId) async {
      await tester.pumpWidget(LingTextScale(child: child));
      await tester.pumpAndSettle();
      final LingTextScaleReport report = LingTextScale.report(
        tester.renderObject(find.byType(LingTextScale)),
      );
      expect(report.isClean, isTrue, reason: report.failure(useCaseId));
    }

    await check(
      const LensSheet(
        camera: LensCameraAccess.allowed,
        offline: false,
        recognizerPresent: false,
        openSettings: _unusedSettings,
      ),
      'lens-idle-200',
    );
    await tester.scrollUntilVisible(
      find.text('Living Dictionary'),
      48,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Conversation Bridge'), findsOneWidget);
    expect(find.text('Living Dictionary'), findsOneWidget);
    final LingTextScaleReport scrolled = LingTextScale.report(
      tester.renderObject(find.byType(LingTextScale)),
    );
    expect(scrolled.isClean, isTrue, reason: scrolled.failure('lens-idle-200-end'));

    await check(
      const LensSheet(
        camera: LensCameraAccess.denied,
        offline: false,
        recognizerPresent: false,
        openSettings: _unusedSettings,
      ),
      'lens-permission-200',
    );
    expect(find.text('Open Settings and allow the camera.'), findsOneWidget);

    await check(
      const LensOfflinePage(action: LensAction.liveTranslate),
      'lens-offline-200',
    );
    await check(
      const LensRecognizerMissingPage(),
      'lens-recognizer-200',
    );
  });
}

Future<bool> _unusedSettings() async => false;
