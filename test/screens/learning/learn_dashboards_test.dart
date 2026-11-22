import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/models/review_progress_model.dart';
import 'package:lingafriq/models/vocabulary_progress_model.dart';
import 'package:lingafriq/my_app.dart';
import 'package:lingafriq/navigation/hub_learn.dart';
import 'package:lingafriq/providers/offline_download_provider.dart';
import 'package:lingafriq/screens/ai_chat/review_dashboard_screen.dart';
import 'package:lingafriq/screens/ai_chat/vocabulary_dashboard_screen.dart';
import 'package:lingafriq/screens/learning/learn_hub_pages.dart';
import 'package:lingafriq/screens/learning/lesson_recap_screen.dart';
import 'package:lingafriq/screens/review/gamified_review_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('app registers the revived Learn routes', () {
    expect(ReviewDashboardScreen.routePath, '/learn/review-dashboard');
    expect(ReviewDashboardScreen.routeKey, 'learn/review-dashboard');
    expect(VocabularyDashboardScreen.routePath, '/learn/vocab-dashboard');
    expect(LessonRecapScreen.routePath, '/learn/recap');
    expect(OfflineDownloadsScreen.routePath, '/learn/downloads');
    expect(LearnRoutes.reviewDashboard, ReviewDashboardScreen.routePath);
    expect(LearnRoutes.vocabDashboard, VocabularyDashboardScreen.routePath);
    expect(LearnRoutes.recap, LessonRecapScreen.routePath);
    expect(LearnRoutes.reviewRush, '/learn/review-rush');
    expect(LearnRoutes.downloads, OfflineDownloadsScreen.routePath);

    final String app = File('lib/my_app.dart').readAsStringSync();
    expect(app, contains('ReviewDashboardScreen.routeKey'));
    expect(app, contains('VocabularyDashboardScreen.routeKey'));
    expect(app, contains('LessonRecapScreen.routeKey'));
    expect(app, contains("'learn/review-rush'"));
    expect(app, contains('OfflineDownloadsScreen.routeKey'));
    expect(app, contains('onGenerateRoute: generateAppRoute'));
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains("import 'my_app.dart'"),
    );

    final String recap = File(
      'lib/screens/learning/lesson_recap_screen.dart',
    ).readAsStringSync();
    expect(recap, isNot(contains('92%')));
    expect(recap, isNot(contains('+85')));
    expect(recap, isNot(contains('Greetings & Introductions')));
    expect(recap, isNot(contains('Greetings Totem')));
  });

  test('a failed download clears that progress and keeps a known size', () {
    const OfflineDownloadState before = OfflineDownloadState(
      downloadProgress: <String, double>{'pack': 0.4},
      isDownloading: true,
      currentDownloadingLessonId: 'pack',
      storageBytes: 2048,
      downloadedLessonIds: <String>{'kept'},
    );
    final OfflineDownloadState after = markDownloadFailed(before, 'pack');
    expect(after.downloadFailed, isTrue);
    expect(after.isDownloading, isFalse);
    expect(after.downloadProgress, isEmpty);
    expect(after.currentDownloadingLessonId, isNull);
    expect(after.storageBytes, 2048);
    expect(after.downloadedLessonIds, <String>{'kept'});
    expect(formatStorageUse(2048), '2.0 KB');
    expect(formatStorageUse(0), '0 B');
  });

  testWidgets('the route table builds each revived screen', (
    WidgetTester tester,
  ) async {
    final Map<String, Type> expected = <String, Type>{
      ReviewDashboardScreen.routePath: ReviewDashboardScreen,
      VocabularyDashboardScreen.routePath: VocabularyDashboardScreen,
      LessonRecapScreen.routePath: LessonRecapScreen,
      '/learn/review-rush': GamifiedReviewScreen,
      OfflineDownloadsScreen.routePath: OfflineDownloadsScreen,
    };
    for (final MapEntry<String, Type> entry in expected.entries) {
      late Widget built;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              final Route<dynamic>? route = generateAppRoute(
                RouteSettings(name: entry.key),
              );
              expect(route, isA<MaterialPageRoute<dynamic>>());
              built = (route! as MaterialPageRoute<dynamic>).builder(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(built.runtimeType, entry.value);
    }
  });

  testWidgets('Learn hub entries open the revived routes', (
    WidgetTester tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(_host(const LearnHub()));
    await tester.pumpAndSettle();

    const List<LearnPlace> places = <LearnPlace>[
      LearnPlace.reviewDashboard,
      LearnPlace.vocabDashboard,
      LearnPlace.recap,
      LearnPlace.reviewRush,
      LearnPlace.downloads,
    ];
    for (final LearnPlace place in places) {
      final Finder row = find.byKey(LearnHubKeys.row(place));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      final ModalRoute<dynamic> route = ModalRoute.of(
        tester.element(find.byType(LearnNotAvailablePage)),
      )!;
      expect(route.settings.name, learnRouteFor(place));
      await tester.tap(find.text('Back to Learn'));
      await tester.pumpAndSettle();
      expect(find.byKey(LearnHubKeys.route(LearnRoutes.hub)), findsOneWidget);
    }
  });

  testWidgets('an empty review stays empty and a load error drops the stats', (
    WidgetTester tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(_host(const ReviewDashboardScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(ReviewDashboardScreen.emptyKey), findsOneWidget);
    expect(find.text('No review is saved.'), findsOneWidget);
    expect(find.text('42.0%'), findsNothing);

    final ReviewStatistics stats = ReviewStatistics(
      language: 'yo',
      totalReviews: 2,
      totalItemsReviewed: 4,
      averageAccuracy: 42,
    );
    await tester.pumpWidget(
      _host(
        ReviewDashboardScreen(
          load: () async => ReviewDashboardView.ready(stats),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ReviewDashboardScreen.contentKey), findsOneWidget);
    expect(find.text('42.0%'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        ReviewDashboardScreen(load: () async => const ReviewDashboardView.error()),
      ),
    );
    await tester.pump();
    expect(find.text('42.0%'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(ReviewDashboardScreen.errorKey), findsOneWidget);
    expect(find.byKey(ReviewDashboardScreen.contentKey), findsNothing);
    expect(find.text('42.0%'), findsNothing);
  });

  testWidgets('an empty word list stays empty', (WidgetTester tester) async {
    _wide(tester);
    await tester.pumpWidget(_host(const VocabularyDashboardScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(VocabularyDashboardScreen.emptyKey), findsOneWidget);
    expect(find.text('No saved word yet.'), findsOneWidget);
    expect(find.text('ẹkáàbọ'), findsNothing);
  });

  testWidgets('a load error drops the word list', (WidgetTester tester) async {
    _wide(tester);
    final VocabularyProgress progress = VocabularyProgress(
      language: 'yo',
      words: <String, WordMastery>{
        'ẹkáàbọ': WordMastery(word: 'ẹkáàbọ', language: 'yo'),
      },
      totalWordsLearned: 1,
    );
    await tester.pumpWidget(
      _host(
        VocabularyDashboardScreen(
          load: () async => VocabularyDashboardView.ready(progress),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(VocabularyDashboardScreen.contentKey), findsOneWidget);
    expect(find.text('ẹkáàbọ'), findsWidgets);
    try {
      await GoogleFonts.pendingFonts();
    } catch (_) {}
    await tester.pump();

    await tester.pumpWidget(
      _host(
        VocabularyDashboardScreen(
          load: () async => const VocabularyDashboardView.error(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('ẹkáàbọ'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(VocabularyDashboardScreen.errorKey), findsOneWidget);
    expect(find.byKey(VocabularyDashboardScreen.contentKey), findsNothing);
    expect(find.text('ẹkáàbọ'), findsNothing);
  });

  testWidgets('an empty recap stays empty and a load error drops the lesson', (
    WidgetTester tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(_host(const LessonRecapScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(LessonRecapScreen.emptyKey), findsOneWidget);
    expect(find.text('No recap yet'), findsOneWidget);
    expect(find.text('Market greetings'), findsNothing);
    expect(find.text('92%'), findsNothing);

    await tester.pumpWidget(
      _host(
        LessonRecapScreen(
          load: () async => const LessonRecapView.ready(
            LessonRecapData(title: 'Market greetings', words: <String>['ẹkáàbọ']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(LessonRecapScreen.contentKey), findsOneWidget);
    expect(find.text('Market greetings'), findsOneWidget);
    expect(find.text('ẹkáàbọ'), findsOneWidget);
    expect(find.text('92%'), findsNothing);

    await tester.pumpWidget(
      _host(
        LessonRecapScreen(load: () async => const LessonRecapView.error()),
      ),
    );
    await tester.pump();
    expect(find.text('Market greetings'), findsNothing);
    expect(find.text('ẹkáàbọ'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(LessonRecapScreen.errorKey), findsOneWidget);
    expect(find.byKey(LessonRecapScreen.contentKey), findsNothing);
    expect(find.text('Market greetings'), findsNothing);
  });

  testWidgets('downloads show progress, failure, and storage only when known', (
    WidgetTester tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(
      _host(
        const OfflineDownloadsScreen(state: OfflineDownloadState()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(OfflineDownloadsScreen.emptyKey), findsOneWidget);
    expect(find.text('Storage use is unknown.'), findsOneWidget);
    expect(find.textContaining('0 B'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pumpWidget(
      _host(
        const OfflineDownloadsScreen(
          state: OfflineDownloadState(
            isDownloading: true,
            downloadProgress: <String, double>{'pack': 0.4},
            currentDownloadingLessonId: 'pack',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(OfflineDownloadsScreen.progressKey), findsOneWidget);
    expect(find.text('Download in progress.'), findsOneWidget);
    expect(find.text('pack'), findsOneWidget);
    final LinearProgressIndicator bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.4);
    expect(find.byKey(OfflineDownloadsScreen.emptyKey), findsNothing);
    expect(find.text('Storage use is unknown.'), findsOneWidget);

    final OfflineDownloadState failed = markDownloadFailed(
      const OfflineDownloadState(
        downloadProgress: <String, double>{'pack': 0.4},
        isDownloading: true,
        downloadedLessonIds: <String>{'kept-lesson'},
        storageBytes: 2048,
      ),
      'pack',
    );
    await tester.pumpWidget(
      _host(OfflineDownloadsScreen(state: failed)),
    );
    await tester.pump();
    expect(find.text('pack'), findsNothing);
    expect(find.text('kept-lesson'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(OfflineDownloadsScreen.errorKey), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('pack'), findsNothing);
    expect(find.text('kept-lesson'), findsNothing);
    expect(find.text('The download did not finish.'), findsOneWidget);
    expect(find.text('Storage use: 2.0 KB'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const OfflineDownloadsScreen(
          state: OfflineDownloadState(storageBytes: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Storage use: 0 B'), findsOneWidget);
    expect(find.text('Storage use is unknown.'), findsNothing);
  });

  testWidgets('empty and error titles stay visible at 200 percent text', (
    WidgetTester tester,
  ) async {
    _wide(tester);
    await tester.pumpWidget(_host(const ReviewDashboardScreen(), scale: 2));
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'Review dashboard');
    _expectUnclipped(tester, 'No review is saved.');

    await tester.pumpWidget(
      _host(
        ReviewDashboardScreen(load: () async => const ReviewDashboardView.error()),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'The review did not open.');

    await tester.pumpWidget(_host(const VocabularyDashboardScreen(), scale: 2));
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'Vocabulary dashboard');
    _expectUnclipped(tester, 'No saved word yet.');

    await tester.pumpWidget(
      _host(
        VocabularyDashboardScreen(
          load: () async => const VocabularyDashboardView.error(),
        ),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'The word list did not open.');

    await tester.pumpWidget(_host(const LessonRecapScreen(), scale: 2));
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'No recap yet');

    await tester.pumpWidget(
      _host(
        LessonRecapScreen(load: () async => const LessonRecapView.error()),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'The recap did not open.');

    await tester.pumpWidget(
      _host(const OfflineDownloadsScreen(state: OfflineDownloadState()), scale: 2),
    );
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'Nothing is saved');

    await tester.pumpWidget(
      _host(
        const OfflineDownloadsScreen(
          state: OfflineDownloadState(downloadFailed: true),
        ),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    _expectUnclipped(tester, 'The download did not finish.');
    expect(tester.takeException(), isNull);
  });
}

void _wide(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _expectUnclipped(WidgetTester tester, String title) {
  final Finder finder = find.text(title);
  expect(finder, findsWidgets);
  for (final Element element in finder.evaluate()) {
    final Text text = element.widget as Text;
    expect(text.overflow, TextOverflow.visible);
    expect(text.maxLines, isNull);
    expect(
      tester.getSize(find.byWidget(text)).height,
      greaterThanOrEqualTo(LingAfriqType.bodySize),
    );
  }
  expect(tester.takeException(), isNull);
}

Widget _host(Widget child, {double scale = 1}) {
  return ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(390, 1600),
      builder: (BuildContext context, Widget? _) {
        return MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (BuildContext context, Widget? routed) {
            final MediaQueryData data = MediaQuery.of(context);
            return MediaQuery(
              data: data.copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: routed ?? const SizedBox.shrink(),
            );
          },
          home: child,
        );
      },
    ),
  );
}
