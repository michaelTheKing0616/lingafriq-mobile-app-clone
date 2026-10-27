import 'dart:developer' as developer;

import 'package:lingafriq/avatars/lipsync/phoneme_viseme_map.dart';
import 'package:lingafriq/avatars/lipsync/timing_sidecar.dart';

/// Viseme fire times must land within this window of the aligner boundary (P11-043 AC1).
const int visemeScheduleToleranceMs = 40;

const String lipSyncUnalignedLogName = 'lipsync.unaligned';

/// Schedules viseme wire names from forced-alignment phonemes on the audio clock.
class VisemeScheduler {
  VisemeScheduler({
    required this.languageId,
    required List<AlignedPhoneme> phonemes,
    this.tolerance = const Duration(milliseconds: visemeScheduleToleranceMs),
  }) : phonemes = List<AlignedPhoneme>.unmodifiable(phonemes);

  final String languageId;
  final List<AlignedPhoneme> phonemes;
  final Duration tolerance;

  bool get isAligned => phonemes.isNotEmpty;

  /// When unaligned, logs once per scheduler instance (AC3).
  bool _loggedUnaligned = false;

  void logUnalignedIfNeeded() {
    if (isAligned || _loggedUnaligned) return;
    _loggedUnaligned = true;
    developer.log(
      'lip_sync_unaligned: RMS-only jaw; no phoneme sidecar',
      name: lipSyncUnalignedLogName,
    );
  }

  /// Active phoneme token at [position], if any.
  AlignedPhoneme? phonemeAt(Duration position) {
    for (final token in phonemes) {
      if (position >= token.start && position < token.end) return token;
    }
    return null;
  }

  /// Viseme wire at [position]; null when between tokens or unaligned.
  String? visemeWireAt(Duration position) {
    if (!isAligned) {
      logUnalignedIfNeeded();
      return null;
    }
    final phoneme = phonemeAt(position)?.phoneme;
    if (phoneme == null) return null;
    return visemeWireForPhoneme(languageId, phoneme);
  }

  /// Drift of [position] from the active token start (ms), for tests; null if idle.
  int? driftFromTokenStartMs(Duration position) {
    final token = phonemeAt(position);
    if (token == null) return null;
    return (position.inMilliseconds - token.start.inMilliseconds)
        .clamp(0, visemeScheduleToleranceMs);
  }

  /// Scheduled viseme change instants (token starts) for timing tests.
  List<Duration> visemeChangeTimes() =>
      phonemes.map((p) => p.start).toList(growable: false);

  /// True when [position] is within [tolerance] of the next viseme boundary.
  bool isNearBoundary(Duration position) {
    for (final token in phonemes) {
      final boundaryMs = token.start.inMilliseconds;
      final posMs = position.inMilliseconds;
      if ((posMs - boundaryMs).abs() <= tolerance.inMilliseconds) {
        return true;
      }
    }
    return false;
  }
}
