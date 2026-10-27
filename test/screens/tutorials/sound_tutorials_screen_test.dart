import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/screens/tutorials/sound_tutorials_screen.dart';
import 'package:lingafriq/services/tutorials/sound_tutorial_repo.dart';
import 'package:lingafriq/widgets/mouth_video_player.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: child),
  );
}

SoundTutorialRepo _repoWithFixtureVideo() {
  return SoundTutorialRepo(
    catalogue: {
      'yo': [
        const SoundTutorialEntry(
          id: 'yo-fixture',
          languageCode: 'yo',
          title: 'Fixture tones',
          nativeVideoUri: 'https://example.com/native-mouth.mp4',
          caption: 'High tone on the first syllable.',
          slowMotionAvailable: true,
          licenceRef: 'test-fixture',
        ),
        const SoundTutorialEntry(
          id: 'yo-soon',
          languageCode: 'yo',
          title: 'Pending capture',
        ),
      ],
    },
  );
}

void main() {
  group('sound tutorial repo', () {
    test('catalogue by language lists yo sound tutorials', () {
      const repo = SoundTutorialRepo();
      final yo = repo.forLanguage('yo');
      expect(yo, isNotEmpty);
      expect(yo.every((e) => e.languageCode == 'yo'), isTrue);
      expect(yo.every((e) => !e.hasNativeVideo), isTrue);
    });

    test('ready entries require native video and caption', () {
      final entries = _repoWithFixtureVideo().forLanguage('yo');
      assertReadySoundTutorialsHaveNativeVideo(entries);
      expect(
        () => assertReadySoundTutorialsHaveNativeVideo([
          const SoundTutorialEntry(
            id: 'bad',
            languageCode: 'yo',
            title: 'x',
            nativeVideoUri: 'https://example.com/v.mp4',
          ),
        ]),
        throwsStateError,
      );
    });
  });

  group('sound tutorials screen', () {
    testWidgets('lists language catalogue and opens coming soon without player',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SoundTutorialsScreen(
            languageCode: 'yo',
            repo: const SoundTutorialRepo(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tones and subdot vowels'), findsOneWidget);
      await tester.tap(find.text('Tones and subdot vowels'));
      await tester.pumpAndSettle();

      expect(find.text(kSoundComingSoonFallback), findsWidgets);
      expect(find.byType(MouthVideoPlayer), findsNothing);
    });

    testWidgets('plays native video with caption and slow-motion control',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SoundTutorialsScreen(
            languageCode: 'yo',
            repo: _repoWithFixtureVideo(),
            mouthVideoPlayerBuilder: ({
              required videoUrl,
              required caption,
              required offersSlowMotion,
            }) {
              return Column(
                children: [
                  Text('video:$videoUrl'),
                  Text('caption:$caption'),
                  if (offersSlowMotion)
                    TextButton(
                      onPressed: () {},
                      child: const Text('Slow motion'),
                    ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fixture tones'));
      await tester.pumpAndSettle();

      expect(
        find.text('video:https://example.com/native-mouth.mp4'),
        findsOneWidget,
      );
      expect(find.text('caption:High tone on the first syllable.'), findsOneWidget);
      expect(find.text('Slow motion'), findsOneWidget);
    });
  });
}
