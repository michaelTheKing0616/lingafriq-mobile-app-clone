import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/village/square_screen.dart';
import 'package:lingafriq/services/capability_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SquareScreen minor-blocked state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    final gate = CapabilityGate(
      get: (_) async => {
        'ok': true,
        'capabilities': {
          'is_minor': true,
          'public_snap_feed': false,
          'snaps': false,
          'ads': false,
          'purchases': false,
        },
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (_, __) => SquareScreen(capabilityGate: gate),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Language Square'), findsOneWidget);
    expect(find.textContaining('public Square'), findsOneWidget);
    expect(find.text('Share'), findsNothing);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });

  testWidgets('SquareScreen shows feed with language tag', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    final gate = CapabilityGate(
      get: (_) async => {
        'ok': true,
        'capabilities': {
          'is_minor': false,
          'public_snap_feed': true,
        },
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (_, __) => SquareScreen(
                capabilityGate: gate,
                feedLoader: () async => {
                  'ok': true,
                  'read_only': false,
                  'posts': [
                    {
                      'id': 'p1',
                      'author_display': 'Amara',
                      'author_object_id': 'abc',
                      'language_tag': 'yo',
                      'body': 'Ẹ kú àárọ̀',
                    },
                  ],
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('YO'), findsOneWidget);
    expect(find.text('Amara'), findsOneWidget);
    expect(find.bySemanticsLabel('Open Tone Lens for Ẹ'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });
}
