import 'dart:math' as math;

/// One aligner token. [phoneme] is an IPA or MFA symbol, never an orthographic letter.
class AlignedPhoneme {
  const AlignedPhoneme({
    required this.phoneme,
    required this.start,
    required this.end,
  });

  final String phoneme;
  final Duration start;
  final Duration end;
}

class RmsSample {
  const RmsSample({required this.at, required this.level});

  final Duration at;

  /// Linear amplitude, 0..1.
  final double level;
}

class LipSyncSample {
  const LipSyncSample({required this.viseme, required this.jawOpen});

  final String viseme;
  final double jawOpen;
}

/// Per-language phoneme → viseme. Unknown tokens stay unresolved so orthography
/// cannot leak into the mouth. Tone is ignored by the caller: do not pass tone marks.
const Map<String, Map<String, String>> phonemeVisemeTables = {
  'yo': _yoruba,
  'zu': _zulu,
  'am': _ethiopian,
  'ti': _ethiopian,
  'default': _shared,
};

const Map<String, double> visemeOpenness = {
  'sil': 0,
  'PP': 0.12,
  'FF': 0.18,
  'TH': 0.22,
  'DD': 0.28,
  'kk': 0.22,
  'CH': 0.24,
  'SS': 0.16,
  'nn': 0.2,
  'RR': 0.34,
  'aa': 0.85,
  'E': 0.42,
  'I': 0.28,
  'O': 0.5,
  'U': 0.32,
  'KP': 0.12,
  'GB': 0.14,
  'C': 0.2,
  'Q': 0.3,
  'X': 0.16,
  'Nnasal': 0.36,
};

const Duration lipSyncAttack = Duration(milliseconds: 30);
const Duration lipSyncRelease = Duration(milliseconds: 80);
const double rmsGate = 0.08;

String? visemeForPhoneme(String language, String phoneme) {
  final table =
      phonemeVisemeTables[language] ?? phonemeVisemeTables['default']!;
  return table[phoneme] ?? phonemeVisemeTables['default']![phoneme];
}

/// Audio-clock lip sync. [at] is the playback position, not a letter index.
class LipSyncTrack {
  LipSyncTrack({
    required this.language,
    required List<AlignedPhoneme> phonemes,
    List<RmsSample> rms = const [],
  }) : phonemes = List<AlignedPhoneme>.unmodifiable(phonemes),
       rms = List<RmsSample>.unmodifiable(rms);

  final String language;
  final List<AlignedPhoneme> phonemes;
  final List<RmsSample> rms;

  double _jaw = 0;

  LipSyncSample at(
    Duration position, {
    Duration delta = const Duration(milliseconds: 16),
  }) {
    final raw = _rmsAt(position);
    final phoneme = _phonemeAt(position);
    final mapped = phoneme == null ? null : visemeForPhoneme(language, phoneme);
    final String viseme;
    final double target;
    if (phonemes.isEmpty) {
      viseme = raw >= rmsGate ? 'aa' : 'sil';
      target = _smooth(raw, delta);
    } else {
      viseme = mapped ?? 'sil';
      final openness = visemeOpenness[viseme] ?? 0;
      target = _smooth((raw * openness).clamp(0, 1), delta);
    }
    return LipSyncSample(viseme: viseme, jawOpen: target);
  }

  String? _phonemeAt(Duration position) {
    for (final token in phonemes) {
      if (position >= token.start && position < token.end) return token.phoneme;
    }
    return null;
  }

  double _rmsAt(Duration position) {
    if (rms.isEmpty) return 0;
    var chosen = rms.first.level;
    for (final sample in rms) {
      if (sample.at > position) break;
      chosen = sample.level;
    }
    return chosen.clamp(0, 1);
  }

  double _smooth(double target, Duration delta) {
    final tau = target >= _jaw ? lipSyncAttack : lipSyncRelease;
    final dt = delta.inMicroseconds / 1000000;
    final time = tau.inMicroseconds / 1000000;
    final alpha = time <= 0 ? 1.0 : 1 - math.exp(-dt / time);
    _jaw = (_jaw + (target - _jaw) * alpha).clamp(0, 1);
    return _jaw;
  }
}

const Map<String, String> _shared = {
  'sil': 'sil',
  'a': 'aa',
  'ɑ': 'aa',
  'e': 'E',
  'ɛ': 'E',
  'i': 'I',
  'ɪ': 'I',
  'o': 'O',
  'ɔ': 'O',
  'u': 'U',
  'ʊ': 'U',
  'p': 'PP',
  'b': 'PP',
  'm': 'PP',
  'f': 'FF',
  'v': 'FF',
  'θ': 'TH',
  'ð': 'TH',
  't': 'DD',
  'd': 'DD',
  'k': 'kk',
  'g': 'kk',
  's': 'SS',
  'z': 'SS',
  'ʃ': 'CH',
  'ʒ': 'CH',
  'tʃ': 'CH',
  'dʒ': 'CH',
  'n': 'nn',
  'ŋ': 'nn',
  'ɲ': 'nn',
  'r': 'RR',
  'ɾ': 'RR',
  'l': 'DD',
  'h': 'aa',
  'w': 'U',
  'j': 'I',
};

const Map<String, String> _yoruba = {
  'kp': 'KP',
  'gb': 'GB',
  'ã': 'Nnasal',
  'ɛ̃': 'Nnasal',
  'ĩ': 'Nnasal',
  'ɔ̃': 'Nnasal',
  'ũ': 'Nnasal',
};

const Map<String, String> _zulu = {'ǀ': 'C', 'ǃ': 'C', 'ǁ': 'C', 'ǂ': 'C'};

const Map<String, String> _ethiopian = {
  'kʼ': 'Q',
  'tʼ': 'Q',
  'pʼ': 'Q',
  'sʼ': 'Q',
  'tʃʼ': 'Q',
  'x': 'X',
  'χ': 'X',
};
