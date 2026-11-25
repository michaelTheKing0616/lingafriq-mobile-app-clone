import 'package:lingafriq/avatars/lipsync/phoneme_viseme_map.dart';
import 'package:lingafriq/avatars/lipsync/rms_jaw.dart';
import 'package:lingafriq/avatars/lipsync/timing_sidecar.dart';
import 'package:lingafriq/avatars/lipsync/viseme_scheduler.dart';

export 'package:lingafriq/avatars/lipsync/phoneme_viseme_map.dart';
export 'package:lingafriq/avatars/lipsync/rms_jaw.dart';
export 'package:lingafriq/avatars/lipsync/timing_sidecar.dart'
    show AlignedPhoneme, LipSyncTimingSidecar, LipSyncSample, RmsSample;
export 'package:lingafriq/avatars/lipsync/viseme_scheduler.dart';

const Map<String, double> visemeOpenness = visemeOpennessByWire;

/// Legacy aliases for tests and callers.
const Duration lipSyncAttack = rmsJawAttack;
const Duration lipSyncRelease = rmsJawRelease;
const double rmsGate = rmsJawGate;

/// Audio-clock lip sync. [at] is the playback position, not a letter index.
class LipSyncTrack {
  LipSyncTrack({
    required this.language,
    required List<AlignedPhoneme> phonemes,
    List<RmsSample> rms = const [],
  })  : phonemes = List<AlignedPhoneme>.unmodifiable(phonemes),
        rms = List<RmsSample>.unmodifiable(rms),
        _scheduler = VisemeScheduler(languageId: language, phonemes: phonemes),
        _rmsJaw = RmsJawDriver(samples: rms);

  final String language;
  final List<AlignedPhoneme> phonemes;
  final List<RmsSample> rms;

  final VisemeScheduler _scheduler;
  final RmsJawDriver _rmsJaw;

  LipSyncSample at(
    Duration position, {
    Duration delta = const Duration(milliseconds: 16),
  }) {
    final smoothedRms = _rmsJaw.advance(position, delta);

    if (!_scheduler.isAligned) {
      _scheduler.logUnalignedIfNeeded();
      final viseme = smoothedRms >= rmsJawGate ? 'aa' : 'sil';
      return LipSyncSample(viseme: viseme, jawOpen: smoothedRms);
    }

    final mapped = _scheduler.visemeWireAt(position);
    final viseme = mapped ?? 'sil';
    final openness = visemeOpenness[viseme] ?? 0;
    final jawOpen = combineJawOpen(
      visemeOpenness: openness,
      smoothedRms: smoothedRms,
    );
    return LipSyncSample(viseme: viseme, jawOpen: jawOpen);
  }
}
