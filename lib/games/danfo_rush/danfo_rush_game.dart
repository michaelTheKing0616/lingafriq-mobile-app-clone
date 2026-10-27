/// Danfo / Matatu Rush listening logic (P8-923): stop lexicon, human-audio gate.
library;

import 'dart:math';

import 'speed_curve.dart';

/// One conductor call tied to a bus stop (human recording required for play).
class DanfoStopCall {
  const DanfoStopCall({
    required this.callId,
    required this.stopLabel,
    required this.conductorPhrase,
    required this.displayHintEn,
    required this.sourceRef,
    this.humanRecordingPath,
    this.speakerId,
    this.accentTag,
  });

  final String callId;
  final String stopLabel;
  final String conductorPhrase;
  final String displayHintEn;
  final String sourceRef;
  final String? humanRecordingPath;
  final String? speakerId;
  final String? accentTag;

  bool get hasLicensedHumanRecording {
    final path = humanRecordingPath?.trim() ?? '';
    if (path.isEmpty) return false;
    final lower = path.toLowerCase();
    if (lower.contains('tts') ||
        lower.contains('synthetic') ||
        lower.startsWith('http')) {
      return false;
    }
    final speaker = speakerId?.trim() ?? '';
    final accent = accentTag?.trim() ?? '';
    return speaker.isNotEmpty && accent.isNotEmpty;
  }
}

/// Stop-name rows awaiting native conductor recordings (EXT-13).
const Map<String, List<DanfoStopCall>> kDanfoRushStopLexicon = {
  'sw': [
    DanfoStopCall(
      callId: 'sw.stop.sokoni',
      stopLabel: 'Sokoni',
      conductorPhrase: 'Sokoni! Sokoni!',
      displayHintEn: 'Central market',
      sourceRef: 'assets/data/dialogues/sw.json#transport',
    ),
    DanfoStopCall(
      callId: 'sw.stop.kariakoo',
      stopLabel: 'Kariakoo',
      conductorPhrase: 'Kariakoo!',
      displayHintEn: 'Downtown market',
      sourceRef: 'assets/data/dialogues/sw.json#transport',
    ),
    DanfoStopCall(
      callId: 'sw.stop.ubungo',
      stopLabel: 'Ubungo',
      conductorPhrase: 'Ubungo!',
      displayHintEn: 'Bus terminal',
      sourceRef: 'assets/data/dialogues/sw.json#transport',
    ),
    DanfoStopCall(
      callId: 'sw.stop.kinondoni',
      stopLabel: 'Kinondoni',
      conductorPhrase: 'Kinondoni!',
      displayHintEn: 'North district',
      sourceRef: 'assets/data/dialogues/sw.json#transport',
    ),
  ],
  'pcm': [
    DanfoStopCall(
      callId: 'pcm.stop.yaba',
      stopLabel: 'Yaba',
      conductorPhrase: 'Yaba! Enter with your change.',
      displayHintEn: 'Lagos mainland',
      sourceRef: 'assets/data/dialogues/pcm.json#transport',
    ),
    DanfoStopCall(
      callId: 'pcm.stop.oshodi',
      stopLabel: 'Oshodi',
      conductorPhrase: 'Oshodi! Oshodi!',
      displayHintEn: 'Major interchange',
      sourceRef: 'assets/data/dialogues/pcm.json#transport',
    ),
    DanfoStopCall(
      callId: 'pcm.stop.ikeja',
      stopLabel: 'Ikeja',
      conductorPhrase: 'Ikeja under bridge!',
      displayHintEn: 'Terminal stop',
      sourceRef: 'assets/data/dialogues/pcm.json#transport',
    ),
  ],
};

List<DanfoStopCall> filterCallsWithHumanAudio(List<DanfoStopCall> calls) {
  return calls.where((c) => c.hasLicensedHumanRecording).toList(growable: false);
}

List<DanfoStopCall> lexiconForLanguage(String languageCode) {
  final key = languageCode.toLowerCase();
  return List<DanfoStopCall>.from(
    kDanfoRushStopLexicon[key] ?? const [],
  );
}

class DanfoRushRound {
  const DanfoRushRound({
    required this.target,
    required this.busOptions,
    required this.level,
    required this.decisionWindow,
    required this.accentTag,
  });

  final DanfoStopCall target;
  final List<DanfoStopCall> busOptions;
  final int level;
  final Duration decisionWindow;
  final String accentTag;
}

DanfoRushRound buildDanfoRound({
  required List<DanfoStopCall> playablePool,
  required int level,
  required Random rng,
}) {
  if (playablePool.length < 4) {
    throw StateError('insufficient_playable_calls');
  }
  final pool = List<DanfoStopCall>.from(playablePool)..shuffle(rng);
  final target = pool.first;
  final distractors = pool.skip(1).take(3).toList();
  final options = [target, ...distractors]..shuffle(rng);
  final accents = playablePool
      .map((c) => c.accentTag)
      .whereType<String>()
      .where((a) => a.isNotEmpty)
      .toSet()
      .toList();
  return DanfoRushRound(
    target: target,
    busOptions: options,
    level: level,
    decisionWindow: danfoDecisionWindowMs(level),
    accentTag: danfoAccentForLevel(level, accents, rng.nextInt(999)),
  );
}

bool danfoTapIsCorrect({
  required DanfoStopCall tapped,
  required DanfoStopCall target,
}) {
  return tapped.callId == target.callId;
}
