/// Per-language tone inventories for the Tone Gym (P5-027, ELEVATION §6.2 / §7.4).
library;

import 'dart:convert';

import 'package:flutter/services.dart';

abstract final class ToneModelCodes {
  static const missing = 'ToneModelMissing';
}

/// Raised when no per-language model exists — trainer must stay hidden (no 3-tone default).
class ToneModelMissing implements Exception {
  ToneModelMissing(this.languageCode, [this.detail = ''])
      : code = ToneModelCodes.missing;

  final String languageCode;
  final String detail;
  final String code;

  @override
  String toString() =>
      '$code: $languageCode${detail.isEmpty ? '' : ' — $detail'}';
}

class ToneLanguageModel {
  const ToneLanguageModel({
    required this.languageCode,
    required this.systemId,
    required this.levels,
    required this.contourKinds,
    this.hasDownstep = false,
    required this.sourceId,
  });

  final String languageCode;
  final String systemId;
  final List<String> levels;
  final List<String> contourKinds;
  final bool hasDownstep;
  final String sourceId;

  bool get isThreeLevelHml =>
      levels.length == 3 &&
      levels.contains('H') &&
      levels.contains('M') &&
      levels.contains('L') &&
      !levels.contains('F');
}

class ToneModelsCatalog {
  const ToneModelsCatalog({
    required this.cardId,
    required this.entries,
  });

  final String cardId;
  final Map<String, _ToneModelEntry> entries;
}

class _ToneModelEntry {
  const _ToneModelEntry({
    required this.tonal,
    this.systemId,
    this.levels = const [],
    this.contourKinds = const [],
    this.hasDownstep = false,
    required this.sourceId,
  });

  final bool tonal;
  final String? systemId;
  final List<String> levels;
  final List<String> contourKinds;
  final bool hasDownstep;
  final String sourceId;
}

const _assetPath = 'assets/data/tone/models.json';

ToneModelsCatalog parseToneModelsCatalog(Map<String, dynamic> root) {
  final langs = root['languages'];
  if (langs is! Map<String, dynamic>) {
    throw const FormatException('languages must be a map');
  }
  final entries = <String, _ToneModelEntry>{};
  for (final e in langs.entries) {
    final block = e.value as Map<String, dynamic>;
    final tonal = block['tonal'] as bool? ?? false;
    final levels = (block['levels'] as List<dynamic>? ?? const [])
        .map((v) => v as String)
        .toList();
    final contours = (block['contour_kinds'] as List<dynamic>? ?? const [])
        .map((v) => v as String)
        .toList();
    entries[e.key] = _ToneModelEntry(
      tonal: tonal,
      systemId: block['system_id'] as String?,
      levels: levels,
      contourKinds: contours,
      hasDownstep: block['has_downstep'] as bool? ?? false,
      sourceId: (block['source_id'] as String?)?.trim() ?? '',
    );
  }
  return ToneModelsCatalog(
    cardId: root['card'] as String? ?? 'P5-027',
    entries: entries,
  );
}

ToneModelsCatalog loadToneModelsCatalogFromJson(String json) {
  return parseToneModelsCatalog(
    jsonDecode(json) as Map<String, dynamic>,
  );
}

Future<ToneModelsCatalog> loadToneModelsCatalogFromAsset([
  String assetPath = _assetPath,
]) async {
  final json = await rootBundle.loadString(assetPath);
  return loadToneModelsCatalogFromJson(json);
}

bool isToneTrainerAvailable(ToneModelsCatalog catalog, String languageCode) {
  final code = languageCode.trim().toLowerCase();
  final entry = catalog.entries[code];
  if (entry == null) return false;
  if (!entry.tonal) return false;
  if (entry.systemId == null || entry.systemId!.isEmpty) return false;
  if (entry.levels.isEmpty) return false;
  if (entry.sourceId.isEmpty) return false;
  return true;
}

ToneLanguageModel resolveToneModel(
  ToneModelsCatalog catalog,
  String languageCode,
) {
  final code = languageCode.trim().toLowerCase();
  final entry = catalog.entries[code];
  if (entry == null) {
    throw ToneModelMissing(code, 'language not in tone model register');
  }
  if (!entry.tonal) {
    throw ToneModelMissing(code, 'language is not tonal in Stage 1 trainer');
  }
  if (entry.systemId == null ||
      entry.systemId!.isEmpty ||
      entry.levels.isEmpty ||
      entry.sourceId.isEmpty) {
    throw ToneModelMissing(code, 'tonal model incomplete');
  }
  return ToneLanguageModel(
    languageCode: code,
    systemId: entry.systemId!,
    levels: List.unmodifiable(entry.levels),
    contourKinds: List.unmodifiable(
      entry.contourKinds.isNotEmpty ? entry.contourKinds : entry.levels,
    ),
    hasDownstep: entry.hasDownstep,
    sourceId: entry.sourceId,
  );
}

/// Guards against silently applying Yoruba H/M/L to every language.
bool wouldUseGlobalThreeToneFallback(
  ToneModelsCatalog catalog,
  String languageCode,
) {
  try {
    final model = resolveToneModel(catalog, languageCode);
    if (!model.isThreeLevelHml) return false;
    return model.languageCode != 'yo';
  } on ToneModelMissing {
    return false;
  }
}
