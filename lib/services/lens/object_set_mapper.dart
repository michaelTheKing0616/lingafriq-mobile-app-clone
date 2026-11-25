/// Maps ML Kit generic English labels to the curated African object set (P7-903).
library;

import 'dart:convert';

import 'package:flutter/services.dart';

/// ML Kit coarse categories that must never receive a word card label.
const Set<String> lensCoarseMlKitLabels = {
  'Food',
  'Home good',
  'Fashion good',
  'Plant',
  'Place',
};

/// One row in [assets/lens/african_object_set.json].
class AfricanObjectSetEntry {
  const AfricanObjectSetEntry({
    required this.objectSetId,
    required this.mlKitLabels,
    required this.livingDictionaryLexemeId,
  });

  final String objectSetId;
  final List<String> mlKitLabels;
  final String livingDictionaryLexemeId;

  factory AfricanObjectSetEntry.fromJson(Map<String, dynamic> json) {
    final labels = (json['ml_kit_labels'] as List<dynamic>? ?? const [])
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return AfricanObjectSetEntry(
      objectSetId: (json['object_set_id'] ?? '').toString(),
      mlKitLabels: labels,
      livingDictionaryLexemeId:
          (json['living_dictionary_lexeme_id'] ?? '').toString(),
    );
  }
}

class AfricanObjectSet {
  AfricanObjectSet({required this.version, required this.entries});

  final int version;
  final List<AfricanObjectSetEntry> entries;

  static const String bundleAsset = 'assets/lens/african_object_set.json';

  factory AfricanObjectSet.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'] as List<dynamic>? ?? const [];
    final entries = raw
        .map((e) => AfricanObjectSetEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return AfricanObjectSet(
      version: (json['version'] as num?)?.toInt() ?? 0,
      entries: entries,
    );
  }

  static Future<AfricanObjectSet> loadFromBundle() async {
    final text = await rootBundle.loadString(bundleAsset);
    return AfricanObjectSet.fromJson(
      jsonDecode(text) as Map<String, dynamic>,
    );
  }

  /// Fails when any entry lacks a Living Dictionary lexeme id (content gate).
  static void validateContent(AfricanObjectSet set) {
    for (final e in set.entries) {
      if (e.objectSetId.trim().isEmpty) {
        throw const FormatException('object_set_id missing');
      }
      if (e.livingDictionaryLexemeId.trim().isEmpty) {
        throw FormatException(
          'living_dictionary_lexeme_id missing for ${e.objectSetId}',
        );
      }
    }
  }
}

enum LensLabelMappingKind {
  mapped,
  coarseUnsure,
  unmapped,
}

class LensLabelMapping {
  const LensLabelMapping({
    required this.kind,
    required this.rawMlKitLabel,
    this.objectSetId,
    this.livingDictionaryLexemeId,
  });

  final LensLabelMappingKind kind;
  final String rawMlKitLabel;
  final String? objectSetId;
  final String? livingDictionaryLexemeId;

  bool get isUnsure =>
      kind == LensLabelMappingKind.coarseUnsure ||
      kind == LensLabelMappingKind.unmapped;
}

/// Normalises ML Kit label text for lookup (case-insensitive).
String normaliseMlKitLabel(String label) => label.trim().toLowerCase();

class ObjectSetMapper {
  ObjectSetMapper(this._set) {
    AfricanObjectSet.validateContent(_set);
    _byLabel = {};
    for (final entry in _set.entries) {
      for (final label in entry.mlKitLabels) {
        _byLabel[normaliseMlKitLabel(label)] = entry;
      }
    }
  }

  final AfricanObjectSet _set;
  late final Map<String, AfricanObjectSetEntry> _byLabel;

  LensLabelMapping mapLabel(String rawMlKitLabel) {
    final trimmed = rawMlKitLabel.trim();
    if (trimmed.isEmpty) {
      return LensLabelMapping(
        kind: LensLabelMappingKind.unmapped,
        rawMlKitLabel: rawMlKitLabel,
      );
    }
    if (lensCoarseMlKitLabels.contains(trimmed)) {
      return LensLabelMapping(
        kind: LensLabelMappingKind.coarseUnsure,
        rawMlKitLabel: trimmed,
      );
    }
    final hit = _byLabel[normaliseMlKitLabel(trimmed)];
    if (hit == null) {
      return LensLabelMapping(
        kind: LensLabelMappingKind.unmapped,
        rawMlKitLabel: trimmed,
      );
    }
    return LensLabelMapping(
      kind: LensLabelMappingKind.mapped,
      rawMlKitLabel: trimmed,
      objectSetId: hit.objectSetId,
      livingDictionaryLexemeId: hit.livingDictionaryLexemeId,
    );
  }
}
