import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/screens/ar/point_and_say_screen.dart';
import 'package:lingafriq/screens/lens/lens_language_chip.dart';
import 'package:lingafriq/screens/lens/lens_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('lensProfileLanguageCodes', () {
    test('uses profile learning language', () {
      final profile = ProfileModel(
        id: 1,
        email: 'a@b.c',
        username: 'u',
        first_name: 'f',
        last_name: 'l',
        is_current_user: true,
        rank: 1,
        nationality: 'ng',
        agree_to_privacy_terms: true,
        avatar: null,
        completed_point: 0,
        learningLanguage: 'igbo',
      );
      expect(
        lensProfileLanguageCodes(profile: profile),
        ['igbo'],
      );
    });

    test('falls back to yoruba when empty', () {
      expect(lensProfileLanguageCodes(), ['yoruba']);
    });
  });

  group('PointAndSayScreen route alias', () {
    testWidgets('builds LensScreen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PointAndSayScreen(language: 'hausa'),
          ),
        ),
      );
      expect(find.text('Lens'), findsOneWidget);
    });
  });

  group('LensScreen', () {
    Future<void> pumpLens(
      WidgetTester tester, {
      List<LensDetection>? detections,
      bool reducedMotion = false,
    }) async {
      SharedPreferences.setMockInitialValues({
        'learning_language': 'yoruba',
        'profile_learning_languages': ['yoruba', 'swahili'],
      });
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: MediaQueryData(
              disableAnimations: reducedMotion,
            ),
            child: MaterialApp(
              home: LensScreen(
                fallbackLanguage: 'yoruba',
                skipCameraInit: true,
                debugPreview: const ColoredBox(color: Color(0xff222222)),
                debugDetections: detections,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('permission denied shows settings action', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _PermissionDeniedStateHarness(),
          ),
        ),
      );
      expect(find.text(lensPermissionDeniedMessage), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('reduced motion uses static detection boxes', (tester) async {
      await pumpLens(
        tester,
        reducedMotion: true,
        detections: const [
          LensDetection(
            boundingBox: Rect.fromLTWH(0.1, 0.2, 0.3, 0.25),
            label: 'cup',
          ),
        ],
      );
      final box = tester.widget<BreathingDetectionBox>(
        find.byType(BreathingDetectionBox),
      );
      expect(box.animate, isFalse);
    });

    testWidgets('language chip switches among profile languages', (tester) async {
      await pumpLens(tester);
      await tester.tap(find.byType(LensLanguageChip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Swahili'));
      await tester.pumpAndSettle();
      expect(find.text('Swahili'), findsWidgets);
    });
  });
}

class _PermissionDeniedStateHarness extends StatelessWidget {
  const _PermissionDeniedStateHarness();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(lensPermissionDeniedMessage),
          FilledButton(onPressed: () {}, child: const Text('Open Settings')),
        ],
      ),
    );
  }
}
