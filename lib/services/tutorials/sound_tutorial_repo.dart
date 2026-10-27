/// Sound tutorial catalogue (P7-933, EP-§11.2-02/04).
///
/// Native mouth video URIs are populated only after EXT-13 native capture;
/// until then entries stay [SoundTutorialAvailability.comingSoon] with no
/// stand-in clip.
library;

/// Copy key: sound.coming_soon (ARB not on this card allowlist).
const String kSoundComingSoonKey = 'sound.coming_soon';

const String kSoundComingSoonFallback = 'Coming soon';

enum SoundTutorialAvailability {
  ready,
  comingSoon,
}

class SoundTutorialEntry {
  const SoundTutorialEntry({
    required this.id,
    required this.languageCode,
    required this.title,
    this.nativeVideoUri,
    this.caption,
    this.slowMotionAvailable = false,
    this.licenceRef,
  });

  final String id;
  final String languageCode;
  final String title;
  final String? nativeVideoUri;
  final String? caption;
  final bool slowMotionAvailable;
  final String? licenceRef;

  SoundTutorialAvailability get availability {
    final uri = nativeVideoUri?.trim();
    if (uri == null || uri.isEmpty) {
      return SoundTutorialAvailability.comingSoon;
    }
    return SoundTutorialAvailability.ready;
  }

  bool get hasNativeVideo => availability == SoundTutorialAvailability.ready;
}

/// Titles trace to ELEVATION §11.2 mapped rows (P7-934…P7-939); no invented drills.
final Map<String, List<SoundTutorialEntry>> _catalogueByLanguage = {
  'yo': const [
    SoundTutorialEntry(
      id: 'yo-sound-tones-subdot',
      languageCode: 'yo',
      title: 'Tones and subdot vowels',
    ),
    SoundTutorialEntry(
      id: 'yo-sound-gb-kp',
      languageCode: 'yo',
      title: 'gb and kp',
    ),
  ],
  'ig': const [
    SoundTutorialEntry(
      id: 'ig-sound-vowel-harmony',
      languageCode: 'ig',
      title: 'Vowel harmony and dotted vowels',
    ),
  ],
  'ha': const [
    SoundTutorialEntry(
      id: 'ha-sound-implosives',
      languageCode: 'ha',
      title: 'Implosives ɓ/ɗ and ejective ƙ',
    ),
  ],
  'sw': const [
    SoundTutorialEntry(
      id: 'sw-sound-noun-classes',
      languageCode: 'sw',
      title: 'Noun classes (class wheel)',
    ),
  ],
  'zu': const [
    SoundTutorialEntry(
      id: 'zu-sound-clicks',
      languageCode: 'zu',
      title: 'Clicks c/q/x',
      slowMotionAvailable: true,
    ),
  ],
  'xh': const [
    SoundTutorialEntry(
      id: 'xh-sound-clicks',
      languageCode: 'xh',
      title: 'Clicks c/q/x',
      slowMotionAvailable: true,
    ),
  ],
  'pcm': const [
    SoundTutorialEntry(
      id: 'pcm-sound-pronunciation',
      languageCode: 'pcm',
      title: 'Nigerian Pidgin sound patterns',
    ),
  ],
};

class SoundTutorialRepo {
  const SoundTutorialRepo({Map<String, List<SoundTutorialEntry>>? catalogue})
      : _catalogue = catalogue;

  final Map<String, List<SoundTutorialEntry>>? _catalogue;

  Map<String, List<SoundTutorialEntry>> get _effective =>
      _catalogue ?? _catalogueByLanguage;

  List<String> supportedLanguageCodes() {
    final keys = _effective.keys.toList(growable: false);
    keys.sort();
    return keys;
  }

  List<SoundTutorialEntry> forLanguage(String languageCode) {
    final code = languageCode.trim().toLowerCase();
    return List<SoundTutorialEntry>.unmodifiable(
      _effective[code] ?? const [],
    );
  }

  SoundTutorialEntry? byId(String id) {
    final key = id.trim();
    for (final list in _effective.values) {
      for (final entry in list) {
        if (entry.id == key) return entry;
      }
    }
    return null;
  }
}

/// Content gate: ready entries must ship native video + captions (test_plan).
void assertReadySoundTutorialsHaveNativeVideo(
  Iterable<SoundTutorialEntry> entries,
) {
  for (final e in entries) {
    if (!e.hasNativeVideo) continue;
    final uri = e.nativeVideoUri?.trim();
    if (uri == null || uri.isEmpty) {
      throw StateError('${e.id}: ready tutorial missing nativeVideoUri');
    }
    final caption = e.caption?.trim();
    if (caption == null || caption.isEmpty) {
      throw StateError('${e.id}: ready tutorial missing caption');
    }
  }
}
