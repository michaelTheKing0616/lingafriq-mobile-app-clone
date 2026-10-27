/// Licence-cleared echo pieces for Echo Karaoke (P8-929).
library;

import 'dart:convert';

import 'package:flutter/services.dart';

/// Commercial or public-domain clearance required for catalogue listing (AC4).
enum EchoSongLicenceKind {
  publicDomain,
  commissioned,
  unlicensed,
}

class EchoSongLicence {
  const EchoSongLicence({
    required this.kind,
    required this.licenceId,
    required this.citation,
  });

  final EchoSongLicenceKind kind;
  final String licenceId;
  final String citation;

  bool get isListable =>
      kind == EchoSongLicenceKind.publicDomain ||
      kind == EchoSongLicenceKind.commissioned;
}

/// One short rhyme / praise phrase the learner sings along with.
class EchoKaraokePiece {
  const EchoKaraokePiece({
    required this.id,
    required this.languageCode,
    required this.lyrics,
    required this.translationEn,
    required this.tonePattern,
    required this.licence,
  });

  final String id;
  final String languageCode;
  final String lyrics;
  final String translationEn;

  /// Inventory tone codes per syllable (H/M/L etc.) for target contour.
  final List<String> tonePattern;
  final EchoSongLicence licence;

  List<String> syllableLabels() {
    return lyrics
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
  }
}

/// Built-in catalogue (FSI public-domain citations only; no commissioned music yet).
const List<EchoKaraokePiece> kEchoKaraokeSeedCatalog = [
  EchoKaraokePiece(
    id: 'yo.echo.mo-n-ko-edè',
    languageCode: 'yo',
    lyrics: 'Mo ń kọ́ èdè Yorùbá',
    translationEn: 'I am learning Yoruba',
    tonePattern: ['L', 'M', 'H', 'M', 'L', 'M'],
    licence: EchoSongLicence(
      kind: EchoSongLicenceKind.publicDomain,
      licenceId: 'fsi-yoruba',
      citation: 'register:fsi-yoruba; assets/data/patterns/yo.json#yo.pat.progressive',
    ),
  ),
  EchoKaraokePiece(
    id: 'yo.echo.oko-vehicle',
    languageCode: 'yo',
    lyrics: 'ọkọ̀',
    translationEn: 'vehicle (tone practice)',
    tonePattern: ['M', 'L'],
    licence: EchoSongLicence(
      kind: EchoSongLicenceKind.publicDomain,
      licenceId: 'fsi-yoruba',
      citation: 'assets/data/tone/minimal_pairs.json#yo.tone.oko_hoe_vehicle',
    ),
  ),
];

List<EchoKaraokePiece> licensedPiecesForLanguage(String languageCode) {
  final code = languageCode.trim().toLowerCase();
  return kEchoKaraokeSeedCatalog
      .where(
        (p) =>
            p.languageCode == code &&
            p.licence.isListable &&
            p.tonePattern.isNotEmpty,
      )
      .toList(growable: false);
}

/// Optional JSON extension path (same schema as seed); unlicensed rows are dropped.
Future<List<EchoKaraokePiece>> loadEchoCatalogFromAsset(
  String assetPath,
) async {
  try {
    final raw = await rootBundle.loadString(assetPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final items = map['pieces'];
    if (items is! List) return const [];
    final out = <EchoKaraokePiece>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final piece = _pieceFromJson(item);
      if (piece != null && piece.licence.isListable) out.add(piece);
    }
    return out;
  } catch (_) {
    return const [];
  }
}

EchoKaraokePiece? _pieceFromJson(Map<String, dynamic> json) {
  final licenceRaw = json['licence'];
  if (licenceRaw is! Map<String, dynamic>) return null;
  final kindStr = (licenceRaw['kind'] ?? '').toString();
  final kind = switch (kindStr) {
    'public-domain' => EchoSongLicenceKind.publicDomain,
    'commissioned' => EchoSongLicenceKind.commissioned,
    _ => EchoSongLicenceKind.unlicensed,
  };
  final licence = EchoSongLicence(
    kind: kind,
    licenceId: (licenceRaw['licence_id'] ?? '').toString(),
    citation: (licenceRaw['citation'] ?? '').toString(),
  );
  final tones = json['tone_pattern'];
  final pattern = tones is List
      ? tones.map((e) => e.toString()).toList(growable: false)
      : const <String>[];
  final lyrics = (json['lyrics'] ?? '').toString();
  if (lyrics.isEmpty || pattern.isEmpty) return null;
  return EchoKaraokePiece(
    id: (json['id'] ?? lyrics).toString(),
    languageCode: (json['language'] ?? 'yo').toString().toLowerCase(),
    lyrics: lyrics,
    translationEn: (json['translation_en'] ?? '').toString(),
    tonePattern: pattern,
    licence: licence,
  );
}

bool passesLicenceFilter(EchoKaraokePiece piece) => piece.licence.isListable;
