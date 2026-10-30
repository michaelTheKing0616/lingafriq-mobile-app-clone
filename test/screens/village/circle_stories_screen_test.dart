import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/village/circle_stories_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CircleStoriesScreen shows copy warning and empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (_, __) => CircleStoriesScreen(
                circleId: 'circle-1',
                circleName: 'Yoruba circle',
                storiesLoader: (_) async => {'ok': true, 'stories': []},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Circle stories'), findsOneWidget);
    expect(find.textContaining('Screenshots and reshares'), findsOneWidget);
    expect(find.textContaining('No stories yet'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });

  testWidgets('CircleStoriesScreen lists story row', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (_, __) => CircleStoriesScreen(
                circleId: 'circle-1',
                storiesLoader: (_) async => {
                  'ok': true,
                  'stories': [
                    {
                      'id': 's1',
                      'uploader_display': 'Amara',
                      'language_tag': 'yo',
                      'caption': 'Ẹ kú àárọ̀',
                      'media_kind': 'image',
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

    expect(find.text('Amara'), findsOneWidget);
    expect(find.text('Ẹ kú àárọ̀'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });
}
