/// Camera word hunt session logic (P8-934) — on-device labels only, dictionary-gated.
library;

import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/services/lens/on_device_object_classifier.dart';
import 'package:lingafriq/services/lens/point_say_fallback.dart';

/// copy_keys: games.word_hunt.found, games.word_hunt.not_in_dictionary
const String wordHuntFoundAnnouncement = 'Found';
const String wordHuntNotInDictionaryMessage =
    'Not in the dictionary yet — keep hunting with real words.';
const String wordHuntCompleteMessage = 'You found every word on the list. Nice work!';

const int kWordHuntDefaultTargetCount = 5;

/// Minimum classifier confidence to accept a hunt match (same bar as Point and Say).
const double kWordHuntMinConfidence = kPointSayLowConfidenceThreshold;

enum WordHuntItemStatus {
  pending,
  found,
}

enum WordHuntFrameOutcomeKind {
  noMatch,
  notInDictionary,
  found,
  alreadyFound,
  huntComplete,
}

class WordHuntTarget {
  const WordHuntTarget({
    required this.classifierLabel,
    required this.displayLabel,
  });

  final String classifierLabel;
  final String displayLabel;
}

class WordHuntTargetProgress {
  const WordHuntTargetProgress({
    required this.target,
    required this.status,
    this.spokenWord,
  });

  final WordHuntTarget target;
  final WordHuntItemStatus status;
  final String? spokenWord;
}

class WordHuntFrameOutcome {
  const WordHuntFrameOutcome({
    required this.kind,
    this.matchedLabel,
    this.spokenWord,
  });

  final WordHuntFrameOutcomeKind kind;
  final String? matchedLabel;
  final String? spokenWord;
}

class WordHuntSession {
  WordHuntSession({
    required List<WordHuntTarget> targets,
    ObjectSetMapper? mapper,
  })  : _targets = List<WordHuntTarget>.from(targets),
        _mapper = mapper,
        _foundLabels = <String>{},
        _spokenByLabel = <String, String>{};

  final List<WordHuntTarget> _targets;
  final ObjectSetMapper? _mapper;
  final Set<String> _foundLabels;
  final Map<String, String> _spokenByLabel;

  int uploadAttempts = 0;

  List<WordHuntTarget> get targets => List.unmodifiable(_targets);

  bool get isComplete =>
      _targets.isNotEmpty && _foundLabels.length >= _targets.length;

  List<WordHuntTargetProgress> progress() {
    return _targets
        .map(
          (t) => WordHuntTargetProgress(
            target: t,
            status: _foundLabels.contains(_norm(t.classifierLabel))
                ? WordHuntItemStatus.found
                : WordHuntItemStatus.pending,
            spokenWord: _spokenByLabel[_norm(t.classifierLabel)],
          ),
        )
        .toList();
  }

  /// Picks the best on-list label from [top3] without network I/O.
  String? pickListedLabel(List<ObjectClassificationLabel> top3) {
    if (top3.isEmpty) return null;
    final pending = _targets
        .where((t) => !_foundLabels.contains(_norm(t.classifierLabel)))
        .map((t) => _norm(t.classifierLabel))
        .toSet();
    if (pending.isEmpty) return null;

    for (final hit in top3) {
      if (hit.score < kWordHuntMinConfidence) continue;
      final key = _norm(hit.label);
      if (pending.contains(key)) return hit.label;
    }
    return null;
  }

  /// Whether a recognised label is on the hunt list (found or not).
  bool isOnHuntList(String classifierLabel) {
    final key = _norm(classifierLabel);
    return _targets.any((t) => _norm(t.classifierLabel) == key);
  }

  bool isMappedInDictionary(String classifierLabel) {
    final mapper = _mapper;
    if (mapper == null) return false;
    final mapping = mapper.mapLabel(classifierLabel);
    return mapping.kind == LensLabelMappingKind.mapped &&
        mapping.livingDictionaryLexemeId != null;
  }

  WordHuntFrameOutcome applyDictionaryResult({
    required String classifierLabel,
    required bool dictionaryHit,
    String? spokenWord,
  }) {
    final key = _norm(classifierLabel);
    if (!isOnHuntList(classifierLabel)) {
      return const WordHuntFrameOutcome(kind: WordHuntFrameOutcomeKind.noMatch);
    }
    if (_foundLabels.contains(key)) {
      return WordHuntFrameOutcome(
        kind: WordHuntFrameOutcomeKind.alreadyFound,
        matchedLabel: classifierLabel,
        spokenWord: _spokenByLabel[key],
      );
    }
    if (!dictionaryHit) {
      return WordHuntFrameOutcome(
        kind: WordHuntFrameOutcomeKind.notInDictionary,
        matchedLabel: classifierLabel,
      );
    }
    final word = (spokenWord ?? '').trim();
    if (word.isNotEmpty) {
      _spokenByLabel[key] = word;
    }
    _foundLabels.add(key);
    final complete = isComplete;
    return WordHuntFrameOutcome(
      kind: complete
          ? WordHuntFrameOutcomeKind.huntComplete
          : WordHuntFrameOutcomeKind.found,
      matchedLabel: classifierLabel,
      spokenWord: word.isEmpty ? null : word,
    );
  }

  /// Offline hunts never upload frames; callers increment [uploadAttempts] only via [recordUploadAttempt].
  void recordUploadAttempt() {
    uploadAttempts++;
  }

  static String _norm(String label) => label.trim().toLowerCase();

  /// Builds a small hunt from curated kitchen labels present in the object set.
  static List<WordHuntTarget> defaultTargetsFromObjectSet(AfricanObjectSet set) {
    final mapper = ObjectSetMapper(set);
    final labels = collectLicensedObjectGlosses(set);
    final out = <WordHuntTarget>[];
    for (final label in labels) {
      if (out.length >= kWordHuntDefaultTargetCount) break;
      final mapping = mapper.mapLabel(label);
      if (mapping.kind != LensLabelMappingKind.mapped) continue;
      out.add(WordHuntTarget(classifierLabel: label, displayLabel: label));
    }
    return out;
  }
}
