import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/lesson/models/lesson_content.dart';
import 'package:lingafriq/screens/lesson/widgets/tutorial_section_widget.dart';

Widget _wrap(Widget child, {TextDirection textDirection = TextDirection.ltr}) {
  final locale = textDirection == TextDirection.rtl ? const Locale('ar') : null;
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('TutorialSectionWidget', () {
    testWidgets('renders tutorial text and triggers onContinue', (tester) async {
      var continued = false;
      final content = LessonContent(
        id: 1,
        sectionId: 1,
        title: 'Greetings',
        type: LessonSectionType.tutorial,
        score: 10,
        isCompleted: false,
        text: 'Hello means a friendly greeting.',
      );

      await tester.pumpWidget(
        _wrap(
          TutorialSectionWidget(
            content: content,
            onContinue: () => continued = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello means a friendly greeting.'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(continued, isTrue);
    });

    testWidgets('Continue button is accessible and has a forward arrow in LTR', (tester) async {
      final handle = tester.ensureSemantics();
      final content = LessonContent(
        id: 1,
        sectionId: 1,
        title: 'Greetings',
        type: LessonSectionType.tutorial,
        score: 10,
        isCompleted: false,
        text: 'Content',
      );

      await tester.pumpWidget(
        _wrap(TutorialSectionWidget(content: content, onContinue: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Continue to next section'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      handle.dispose();
    });

    testWidgets('mirrors the Continue arrow for RTL locales', (tester) async {
      final content = LessonContent(
        id: 1,
        sectionId: 1,
        title: 'Greetings',
        type: LessonSectionType.tutorial,
        score: 10,
        isCompleted: false,
        text: 'Content',
      );

      await tester.pumpWidget(
        _wrap(
          TutorialSectionWidget(content: content, onContinue: () {}),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      // The forward arrow must visually point left in RTL. It is
      // auto-mirrored (matchTextDirection) under an RTL Directionality.
      // A manual swap to arrow_back would mirror it a second time.
      final icon = find.byIcon(Icons.arrow_forward_rounded);
      expect(icon, findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(Icons.arrow_forward_rounded.matchTextDirection, isTrue);
      expect(Directionality.of(tester.element(icon)), TextDirection.rtl);
    });
  });
}
