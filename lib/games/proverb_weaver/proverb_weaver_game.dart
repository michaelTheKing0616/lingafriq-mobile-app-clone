/// Proverb Weaver flagship logic (P8-924): fragment assembly + situation match.
library;

import 'dart:math';

/// CEFR rank for B1+ gate (EP-§10.3-05a).
int cefrRank(String? level) {
  final normalized = (level ?? 'A1').trim().toUpperCase();
  const order = ['A0', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  final idx = order.indexOf(normalized);
  if (idx < 0) return 1;
  return idx;
}

bool proverbWeaverUnlockedForLevel(String? level) =>
    cefrRank(level) >= cefrRank('B1');

/// Review gate: elder or linguist id required (AC3).
bool proverbHasReviewer(ProverbWeaverRecord record) {
  final id = record.reviewedBy?.trim() ?? '';
  if (id.isEmpty) return false;
  final role = record.reviewerRole.trim().toLowerCase();
  return role == 'linguist' || role == 'elder';
}

/// Audio may play only for licensed human clips or tone-verified TTS (AC4).
bool proverbAudioPlayable(ProverbWeaverRecord record) {
  final human = record.humanRecordingPath?.trim() ?? '';
  if (human.isNotEmpty) {
    final lower = human.toLowerCase();
    if (!lower.contains('tts') &&
        !lower.contains('synthetic') &&
        !lower.startsWith('http')) {
      return true;
    }
  }
  return record.toneVerifiedTts;
}

class ProverbSituationChoice {
  const ProverbSituationChoice({
    required this.id,
    required this.labelEn,
    required this.isCorrect,
  });

  final String id;
  final String labelEn;
  final bool isCorrect;
}

class ProverbWeaverRecord {
  const ProverbWeaverRecord({
    required this.id,
    required this.languageCode,
    required this.text,
    required this.translationEn,
    required this.fragments,
    required this.situations,
    required this.reviewedBy,
    required this.reviewerRole,
    required this.sourceRef,
    this.humanRecordingPath,
    this.toneVerifiedTts = false,
    this.usageNoteEn = '',
  });

  final String id;
  final String languageCode;
  final String text;
  final String translationEn;
  final List<String> fragments;
  final List<ProverbSituationChoice> situations;
  final String reviewedBy;
  final String reviewerRole;
  final String sourceRef;
  final String? humanRecordingPath;
  final bool toneVerifiedTts;
  final String usageNoteEn;
}

/// Pool entries mirror P5-035 `_valid_proverb` + curated register citations only.
const Map<String, List<ProverbWeaverRecord>> kProverbWeaverLibrary = {
  'zu': [
    ProverbWeaverRecord(
      id: 'zu.proverb.izandla',
      languageCode: 'zu',
      text: 'Izandla ziyagezana',
      translationEn: 'Hands wash each other.',
      fragments: ['Izandla', 'ziyagezana'],
      reviewedBy: 'zu-linguist-1',
      reviewerRole: 'linguist',
      sourceRef: 'register:peace-corps-zu',
      humanRecordingPath: 'assets/audio/proverbs/zu/izandla_ziyagezana.wav',
      usageNoteEn: 'Mutual help when neighbours share work.',
      situations: [
        ProverbSituationChoice(
          id: 'cooperation',
          labelEn: 'Neighbours helping each other finish a task',
          isCorrect: true,
        ),
        ProverbSituationChoice(
          id: 'solo',
          labelEn: 'Bragging that you never need anyone',
          isCorrect: false,
        ),
        ProverbSituationChoice(
          id: 'market',
          labelEn: 'Haggling for a lower price at the market',
          isCorrect: false,
        ),
      ],
    ),
  ],
};

List<ProverbWeaverRecord> poolForLanguage(String languageCode) {
  final key = languageCode.toLowerCase();
  final raw = kProverbWeaverLibrary[key] ?? const <ProverbWeaverRecord>[];
  return raw
      .where((record) => proverbHasReviewer(record) && proverbAudioPlayable(record))
      .toList(growable: false);
}

List<String> shuffledFragments(ProverbWeaverRecord record, Random rng) {
  final copy = List<String>.from(record.fragments);
  copy.shuffle(rng);
  return copy;
}

bool assemblyMatches(ProverbWeaverRecord record, List<String> assembled) {
  if (assembled.length != record.fragments.length) return false;
  for (var i = 0; i < record.fragments.length; i++) {
    if (assembled[i] != record.fragments[i]) return false;
  }
  return true;
}

class ProverbWeaverRound {
  const ProverbWeaverRound({
    required this.record,
    required this.shuffledFragments,
    required this.situationOrder,
  });

  final ProverbWeaverRecord record;
  final List<String> shuffledFragments;
  final List<ProverbSituationChoice> situationOrder;
}

ProverbWeaverRound buildRound({
  required ProverbWeaverRecord record,
  required Random rng,
}) {
  final situations = List<ProverbSituationChoice>.from(record.situations)
    ..shuffle(rng);
  return ProverbWeaverRound(
    record: record,
    shuffledFragments: shuffledFragments(record, rng),
    situationOrder: situations,
  );
}

ProverbWeaverRecord? pickRecordForLanguage(String languageCode, Random rng) {
  final pool = poolForLanguage(languageCode);
  if (pool.isEmpty) return null;
  return pool[rng.nextInt(pool.length)];
}
