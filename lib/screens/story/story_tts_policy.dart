/// P6-027: story narration follows licensed server TTS routing (AC4).
library;

/// Server-side chain labels — must stay aligned with [AfricanTtsService] Silver tier.
class StoryTtsRoute {
  const StoryTtsRoute({
    required this.languageCode,
    required this.primary,
    required this.fallbacks,
    required this.blocked,
    this.blockReason,
  });

  final String languageCode;
  final String primary;
  final List<String> fallbacks;
  final bool blocked;
  final String? blockReason;
}

StoryTtsRoute resolveStoryTtsRoute(String languageCode) {
  final lang = languageCode.trim().toLowerCase();
  switch (lang) {
    case 'yo':
    case 'yoruba':
      return const StoryTtsRoute(
        languageCode: 'yo',
        primary: 'intron',
        fallbacks: ['spitch'],
        blocked: false,
      );
    case 'ig':
    case 'igbo':
      return const StoryTtsRoute(
        languageCode: 'ig',
        primary: 'intron',
        fallbacks: ['spitch'],
        blocked: false,
      );
    case 'ha':
    case 'hausa':
      return const StoryTtsRoute(
        languageCode: 'ha',
        primary: 'intron',
        fallbacks: ['spitch', 'elevenlabs'],
        blocked: false,
      );
    case 'sw':
    case 'swahili':
      return const StoryTtsRoute(
        languageCode: 'sw',
        primary: 'chirp3_hd',
        fallbacks: ['intron', 'azure'],
        blocked: false,
      );
    case 'zu':
    case 'zulu':
      return const StoryTtsRoute(
        languageCode: 'zu',
        primary: 'azure',
        fallbacks: [],
        blocked: false,
      );
    case 'xh':
    case 'xhosa':
      return const StoryTtsRoute(
        languageCode: 'xh',
        primary: 'none',
        fallbacks: [],
        blocked: true,
        blockReason: 'voice_coming',
      );
    case 'pcm':
    case 'pidgin':
      return const StoryTtsRoute(
        languageCode: 'pcm',
        primary: 'intron',
        fallbacks: ['spitch'],
        blocked: false,
      );
    default:
      return StoryTtsRoute(
        languageCode: lang,
        primary: 'server_tts',
        fallbacks: const [],
        blocked: false,
      );
  }
}

/// Polie story audio is always dynamic / synthetic-labelled (P5-075).
bool storyAudioUsesServerTts(StoryTtsRoute route) => !route.blocked;
