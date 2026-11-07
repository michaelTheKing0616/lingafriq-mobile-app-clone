import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/app_theme.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/classroom/classroom_student_requests_screen.dart';
import 'package:lingafriq/services/guarded_messaging_service.dart';
import 'package:lingafriq/theme/guarded_theme.dart';
import 'package:lingafriq/theme/lingafriq_fonts.dart';

import '../../compliance/golden_kit.dart';
import '../../guarded/fake_guarded.dart';

const _requests = 'GET /api/v2/classroom/guarded/t1/pending-students';

int _navyInk = 0;

class _InkComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    final pixels = data!.buffer.asUint8List();
    var navy = 0;
    for (var i = 0; i < pixels.length; i += 4) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      if (r < 90 && g < 100 && b > 90 && b > r + 30) navy++;
    }
    _navyInk = navy;
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}

  @override
  Uri getTestUri(Uri key, int? version) => key;
}

Future<FakeGuarded> _pumpError(
  WidgetTester t, {
  required Size size,
  required double scale,
  required Locale locale,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  final f = FakeGuarded({_requests: const GuardedResponse(500, {})});
  await t.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => ProviderScope(
        child: MaterialApp(
          theme: lightTheme,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: ClassroomStudentRequestsScreen(
            tribeId: 't1',
            tribeName: 'Yoruba 201',
            service: f.service,
          ),
        ),
      ),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
  return f;
}

void _expectLabelInsideButton(WidgetTester t, String label) {
  final button = find.byType(OutlinedButton);
  final text = find.descendant(of: button, matching: find.text(label));
  expect(text, findsOneWidget);
  final tb = t.getRect(text);
  final bb = t.getRect(button);
  expect(tb.width, greaterThan(24));
  expect(tb.height, greaterThan(12));
  expect(
    bb.inflate(1).contains(tb.topLeft) && bb.inflate(1).contains(tb.bottomRight),
    isTrue,
    reason: 'retry label $tb is outside button $bb',
  );
  final painted = t.renderObject<RenderParagraph>(
    find.descendant(of: text, matching: find.byType(RichText)),
  );
  expect(painted.text.style?.fontFamily, LingAfriqFonts.display);
  expect(
    painted.text.style?.fontFamilyFallback,
    contains(LingAfriqFonts.arabic),
  );
  expect(painted.text.style?.color, kBrandNavy);
  expect(find.byIcon(Icons.refresh), findsOneWidget);
  expect(t.widget<OutlinedButton>(button).onPressed, isNotNull);
}

void main() {
  setUpAll(
    () => loadComplianceFonts(
      'test/screens/classroom/student_requests_retry_visibility_test.dart',
    ),
  );

  testWidgets('320dp 200% Arabic RTL retry label is painted inside the button', (
    t,
  ) async {
    final f = await _pumpError(
      t,
      size: const Size(320, 568),
      scale: 2,
      locale: const Locale('ar'),
    );
    const label = 'حاول مرة أخرى';
    _expectLabelInsideButton(t, label);
    expect(find.bySemanticsLabel(label), findsWidgets);
    goldenFileComparator = _InkComparator();
    await expectLater(
      find.byType(ClassroomStudentRequestsScreen),
      matchesGoldenFile('retry-ink.png'),
    );
    expect(_navyInk, greaterThan(200), reason: 'navy ink count $_navyInk');
    final callsBefore = f.calls.length;
    await t.tap(find.byType(OutlinedButton));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(f.calls.length, greaterThan(callsBefore));
    expect(f.calls.last.path, '/api/v2/classroom/guarded/t1/pending-students');
  });

  testWidgets('1x English retry label stays inside the button', (t) async {
    await _pumpError(
      t,
      size: const Size(390, 844),
      scale: 1,
      locale: const Locale('en'),
    );
    _expectLabelInsideButton(t, 'Try again');
  });

  testWidgets('1x Arabic retry label stays inside the button', (t) async {
    await _pumpError(
      t,
      size: const Size(390, 844),
      scale: 1,
      locale: const Locale('ar'),
    );
    _expectLabelInsideButton(t, 'حاول مرة أخرى');
  });
}
