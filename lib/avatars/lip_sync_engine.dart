export 'cast/phoneme_viseme.dart';

import 'cast/phoneme_viseme.dart';

/// Alignment clock. This engine does not read letters.
class LipSyncEngine {
  LipSyncTrack track({
    required String language,
    required List<AlignedPhoneme> phonemes,
    List<RmsSample> rms = const [],
  }) {
    return LipSyncTrack(language: language, phonemes: phonemes, rms: rms);
  }
}
