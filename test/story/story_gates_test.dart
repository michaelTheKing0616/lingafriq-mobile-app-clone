import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/story/story_library.dart';
import 'package:lingafriq/screens/story/story_tts_policy.dart';
import 'package:lingafriq/screens/story/story_types.dart';

void main() {
  setUp(() {
    StoryLibraryStore.instance.reset();
  });

  test('pending shared stories are not listed publicly', () {
    const session = StorySession(
      storyId: 's1',
      title: 'T',
      storyText: 'Body',
      glosses: const [
        StoryGlossEntry(surface: 'A', glossL1: 'a', lexemeId: 'yo.lex.a'),
      ],
      comprehension: const [
        StoryComprehensionQuestion(
          questionL1: 'Q?',
          optionsL1: ['A', 'B'],
          correctIndex: 0,
        ),
      ],
      language: 'yo',
      aiGeneratedLabel: storyAiGeneratedLabelEn,
      visibility: StoryVisibility.personal,
    );
    StoryLibraryStore.instance.submitForSharedLibrary(session);
    expect(StoryLibraryStore.instance.listPublicShared(), isEmpty);
    StoryLibraryStore.instance.markApproved('s1');
    expect(StoryLibraryStore.instance.listPublicShared(language: 'yo'), hasLength(1));
  });

  test('story session exposes AI-generated label key', () {
    expect(storyAiGeneratedLabelKey, 'story.ai_generated_label');
    expect(storyAiGeneratedLabelEn, isNotEmpty);
  });

  test('xh story TTS stays blocked per EXT-12', () {
    final route = resolveStoryTtsRoute('xh');
    expect(route.blocked, isTrue);
    expect(storyAudioUsesServerTts(route), isFalse);
  });

  test('yo story TTS uses server chain', () {
    final route = resolveStoryTtsRoute('yo');
    expect(route.primary, 'intron');
    expect(storyAudioUsesServerTts(route), isTrue);
  });
}
