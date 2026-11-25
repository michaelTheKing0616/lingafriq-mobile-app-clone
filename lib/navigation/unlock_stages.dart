import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';

/// Bundled stage table. The caller loads this file and passes the text to
/// [UnlockStages.parse]. Evaluation does not read the asset itself.
const String kUnlockStagesAsset = 'assets/config/unlock_stages.json';

/// Inputs the caller already knows. This type does not store progress, and
/// it does not mark anyone a native speaker unless [nativeSpeaker] is passed
/// true.
class UnlockLearner {
  const UnlockLearner({
    this.hasAccount = false,
    this.week1Reached = false,
    this.level,
    this.unit,
    this.nativeSpeaker = false,
    this.minor = false,
  });

  /// True only when the caller says an account exists.
  final bool hasAccount;

  /// True only when the caller says week 1 was reached.
  final bool week1Reached;

  /// CEFR band the caller supplies, such as A1. Null means no level.
  final String? level;

  /// Unit inside [level] the caller supplies. Null means no unit.
  final int? unit;

  /// True only when the caller says this person is a native speaker.
  final bool nativeSpeaker;

  /// True when the caller says this person is a minor.
  ///
  /// A guardian safety gate stays locked for a minor. Open anyway is not
  /// offered on that gate.
  final bool minor;
}

/// How an open feature can be used. A locked feature keeps this for the
/// moment it opens. It is not a score.
enum UnlockAccess {
  open,
  readOnly,
  basic,
  pointSay,
  join,
  read,
  post,
  speak,
  ugc,
}

/// A gate that stays locked for a minor. Adults are not blocked by it.
enum UnlockSafety { none, guardian }

/// One row of the stage table.
class UnlockStage {
  const UnlockStage({
    required this.id,
    required this.requires,
    required this.opens,
    this.level,
  });

  final String id;

  /// none, account, week_1_or_a1_unit_3, level, or native_speaker.
  final String requires;

  /// Set when [requires] is level. A2 and B1 are level names.
  final String? level;

  /// Feature ids this stage opens, in table order.
  final List<String> opens;
}

/// One feature the table can open.
class UnlockFeature {
  const UnlockFeature({
    required this.id,
    required this.access,
    required this.safety,
    required this.adultsOnly,
    required this.stageIds,
    required this.stageId,
    this.day1Count,
    this.allOn,
  });

  final String id;
  final UnlockAccess access;
  final UnlockSafety safety;

  /// Chats are for adults. A minor stays on the guardian gate.
  final bool adultsOnly;

  /// Stages that list this feature, in table order. Empty for a safety gate
  /// that no stage opens.
  final List<String> stageIds;

  /// First stage that lists this feature. Empty when none does.
  final String stageId;

  /// How many caller-supplied games open before an account exists.
  final int? day1Count;

  /// Stage id that opens every caller-supplied game. Null for other features.
  final String? allOn;
}

/// Whether one feature is open for the learner the caller passed.
class UnlockDecision {
  const UnlockDecision({
    required this.id,
    required this.open,
    required this.access,
    required this.stageId,
    required this.safetyLocked,
    required this.canPreview,
    required this.canOpenAnyway,
    required this.allGames,
    this.gameLimit,
  });

  final String id;
  final bool open;
  final UnlockAccess access;
  final String stageId;

  /// A minor is on a guardian safety gate. The feature stays locked.
  final bool safetyLocked;

  /// A locked feature can be previewed. Preview does not open it.
  final bool canPreview;

  /// An adult can open a stage lock. A minor guardian gate cannot.
  final bool canOpenAnyway;

  /// True when an account opens every caller-supplied game.
  final bool allGames;

  /// How many games stay open when [allGames] is false. Null otherwise.
  final int? gameLimit;
}

/// Result of asking to open a feature. This does not change the learner.
class UnlockOpening {
  const UnlockOpening({
    required this.featureId,
    required this.opened,
    required this.anyway,
    required this.safetyLocked,
  });

  final String featureId;
  final bool opened;

  /// True when an adult opened a feature the stage has not reached.
  final bool anyway;

  final bool safetyLocked;
}

/// Games from the list the caller passed. Ids the caller did not pass are
/// not added.
class UnlockGameAccess {
  const UnlockGameAccess({
    required this.openIds,
    required this.lockedIds,
    required this.day1Count,
    required this.allOpen,
  });

  final List<String> openIds;
  final List<String> lockedIds;
  final int day1Count;
  final bool allOpen;
}

/// Progressive unlocking from ELEVATION section 17.4.
///
/// [decide] reads the table and the learner the caller passed. It does not
/// read storage, and it does not fill in a level, a week, or a native-speaker
/// flag.
class UnlockStages {
  UnlockStages._({
    required this.version,
    required List<UnlockStage> stages,
    required List<UnlockFeature> features,
  }) : stages = List<UnlockStage>.unmodifiable(stages),
       features = List<UnlockFeature>.unmodifiable(features),
       _stageById = <String, UnlockStage>{
         for (final UnlockStage stage in stages) stage.id: stage,
       },
       _featureById = <String, UnlockFeature>{
         for (final UnlockFeature feature in features) feature.id: feature,
       };

  /// Table version from the JSON object.
  final int version;

  final List<UnlockStage> stages;
  final List<UnlockFeature> features;
  final Map<String, UnlockStage> _stageById;
  final Map<String, UnlockFeature> _featureById;

  /// Parses [source]. A table that is not the expected shape throws
  /// [FormatException]. A string that contains an em dash is refused.
  factory UnlockStages.parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Unlock stages are not JSON: ${error.message}');
    }
    final Map<String, Object?> root = _asMap(decoded, 'root');
    _scanCopy(root, 'root');
    _rejectUnknown(root.keys, _rootKeys, 'root');
    final int version = _asInt(root['version'], 'version');
    if (version < 1) {
      throw const FormatException('version must be at least 1');
    }
    final List<UnlockStage> stages = _parseStages(root['stages']);
    final List<_FeatureDraft> drafts = _parseFeatures(root['features']);
    final Map<String, List<String>> listed = <String, List<String>>{};
    final Map<String, UnlockFeature> draftById = <String, UnlockFeature>{
      for (final _FeatureDraft draft in drafts) draft.id: draft.shell,
    };
    for (final UnlockStage stage in stages) {
      for (final String id in stage.opens) {
        if (!draftById.containsKey(id)) {
          throw FormatException('Unknown feature $id in stage ${stage.id}');
        }
        listed.putIfAbsent(id, () => <String>[]).add(stage.id);
      }
    }
    final List<UnlockFeature> features = <UnlockFeature>[];
    for (final _FeatureDraft draft in drafts) {
      final List<String> stageIds = List<String>.unmodifiable(
        listed[draft.id] ?? const <String>[],
      );
      features.add(draft.finish(stageIds));
    }
    _checkLinks(stages, features);
    return UnlockStages._(version: version, stages: stages, features: features);
  }

  UnlockStage stage(String id) {
    final UnlockStage? found = _stageById[id];
    if (found == null) {
      throw ArgumentError.value(id, 'id', 'Unknown stage');
    }
    return found;
  }

  UnlockFeature feature(String id) {
    final UnlockFeature? found = _featureById[id];
    if (found == null) {
      throw ArgumentError.value(id, 'featureId', 'Unknown feature');
    }
    return found;
  }

  /// One decision per feature, in table order.
  List<UnlockDecision> decideAll(UnlockLearner learner) {
    return List<UnlockDecision>.unmodifiable(
      features.map((UnlockFeature feature) => decide(learner, feature.id)),
    );
  }

  UnlockDecision decide(UnlockLearner learner, String featureId) {
    final UnlockFeature feature = this.feature(featureId);
    final bool safetyLocked = _safetyLocked(feature, learner);
    var open = false;
    if (!safetyLocked) {
      for (final String stageId in feature.stageIds) {
        if (_stageMet(stage(stageId), learner)) {
          open = true;
          break;
        }
      }
    }
    final bool counted = feature.day1Count != null;
    final bool allGames = counted && open && _allGamesOpen(feature, learner);
    return UnlockDecision(
      id: feature.id,
      open: open,
      access: feature.access,
      stageId: feature.stageId,
      safetyLocked: safetyLocked,
      canPreview: !open,
      canOpenAnyway: !open && !safetyLocked && !learner.minor,
      allGames: allGames,
      gameLimit: counted && open && !allGames ? feature.day1Count : null,
    );
  }

  /// Opens [featureId] when the stage is met.
  ///
  /// [anyway] opens a stage lock for an adult. It does not change [learner],
  /// and it does not open a guardian safety gate for a minor.
  UnlockOpening open(
    UnlockLearner learner,
    String featureId, {
    bool anyway = false,
  }) {
    final UnlockDecision decision = decide(learner, featureId);
    if (decision.safetyLocked) {
      return UnlockOpening(
        featureId: featureId,
        opened: false,
        anyway: false,
        safetyLocked: true,
      );
    }
    if (decision.open) {
      return UnlockOpening(
        featureId: featureId,
        opened: true,
        anyway: false,
        safetyLocked: false,
      );
    }
    if (anyway && decision.canOpenAnyway) {
      return UnlockOpening(
        featureId: featureId,
        opened: true,
        anyway: true,
        safetyLocked: false,
      );
    }
    return UnlockOpening(
      featureId: featureId,
      opened: false,
      anyway: false,
      safetyLocked: false,
    );
  }

  /// The counted game list. [gameIds] is the caller's order.
  ///
  /// Before an account exists, the first [UnlockGameAccess.day1Count] ids
  /// are open. The rest stay locked. An account opens every id the caller
  /// passed. An empty list stays empty.
  UnlockGameAccess games(UnlockLearner learner, List<String> gameIds) {
    final UnlockFeature counted = _countedGames();
    final int day1Count = counted.day1Count ?? 0;
    final List<String> ordered = _gameIds(gameIds);
    final UnlockDecision decision = decide(learner, counted.id);
    if (!decision.open || day1Count < 1) {
      return UnlockGameAccess(
        openIds: const <String>[],
        lockedIds: ordered,
        day1Count: day1Count,
        allOpen: false,
      );
    }
    if (decision.allGames) {
      return UnlockGameAccess(
        openIds: ordered,
        lockedIds: const <String>[],
        day1Count: day1Count,
        allOpen: true,
      );
    }
    final int count = ordered.length < day1Count ? ordered.length : day1Count;
    return UnlockGameAccess(
      openIds: List<String>.unmodifiable(ordered.sublist(0, count)),
      lockedIds: List<String>.unmodifiable(ordered.sublist(count)),
      day1Count: day1Count,
      allOpen: false,
    );
  }

  UnlockFeature _countedGames() {
    final List<UnlockFeature> found = features
        .where((UnlockFeature feature) => feature.day1Count != null)
        .toList(growable: false);
    if (found.length != 1) {
      throw StateError('The table needs one counted game list');
    }
    return found.single;
  }

  bool _allGamesOpen(UnlockFeature feature, UnlockLearner learner) {
    final String? allOn = feature.allOn;
    if (allOn == null) return false;
    return _stageMet(stage(allOn), learner);
  }

  bool _safetyLocked(UnlockFeature feature, UnlockLearner learner) {
    if (!learner.minor) return false;
    return feature.safety == UnlockSafety.guardian || feature.adultsOnly;
  }

  bool _stageMet(UnlockStage stage, UnlockLearner learner) {
    switch (stage.requires) {
      case 'none':
        return true;
      case 'account':
        return learner.hasAccount;
      case 'week_1_or_a1_unit_3':
        return learner.week1Reached || _reachedA1Unit3(learner);
      case 'level':
        final String? need = stage.level;
        if (need == null) return false;
        return _levelAtLeast(learner.level, need);
      case 'native_speaker':
        return learner.nativeSpeaker;
      default:
        return false;
    }
  }
}

/// A band above A1 means the caller already placed the learner past A1.
/// The unit number is not filled in.
bool _reachedA1Unit3(UnlockLearner learner) {
  final int? rank = _cefrRank(learner.level);
  final int? a1 = _cefrRank('A1');
  if (rank == null || a1 == null) return false;
  if (rank > a1) return true;
  return rank == a1 && learner.unit != null && learner.unit! >= 3;
}

bool _levelAtLeast(String? level, String minimum) {
  final int? have = _cefrRank(level);
  final int? need = _cefrRank(minimum);
  if (have == null || need == null) return false;
  return have >= need;
}

const List<String> _cefrOrder = <String>['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

int? _cefrRank(String? level) {
  if (level == null) return null;
  var band = level.trim().toUpperCase();
  if (band.isEmpty) return null;
  if (band.endsWith('+') && band.length > 1) {
    band = band.substring(0, band.length - 1);
  }
  final int index = _cefrOrder.indexOf(band);
  if (index < 0) return null;
  return index;
}

List<String> _gameIds(List<String> gameIds) {
  final List<String> ordered = <String>[];
  final Set<String> seen = <String>{};
  for (final String raw in gameIds) {
    final String id = raw.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(raw, 'gameIds', 'A game id was empty');
    }
    if (seen.add(id)) ordered.add(id);
  }
  return List<String>.unmodifiable(ordered);
}

const Set<String> _rootKeys = <String>{'version', 'stages', 'features'};

const Set<String> _stageKeys = <String>{'id', 'requires', 'level', 'opens'};

const Set<String> _featureKeys = <String>{
  'id',
  'access',
  'safety',
  'audience',
  'day1_count',
  'all_on',
};

const Set<String> _requires = <String>{
  'none',
  'account',
  'week_1_or_a1_unit_3',
  'level',
  'native_speaker',
};

const Map<String, UnlockAccess> _accessByName = <String, UnlockAccess>{
  'open': UnlockAccess.open,
  'read_only': UnlockAccess.readOnly,
  'basic': UnlockAccess.basic,
  'point_say': UnlockAccess.pointSay,
  'join': UnlockAccess.join,
  'read': UnlockAccess.read,
  'post': UnlockAccess.post,
  'speak': UnlockAccess.speak,
  'ugc': UnlockAccess.ugc,
};

class _FeatureDraft {
  const _FeatureDraft({
    required this.id,
    required this.access,
    required this.safety,
    required this.adultsOnly,
    required this.day1Count,
    required this.allOn,
  });

  final String id;
  final UnlockAccess access;
  final UnlockSafety safety;
  final bool adultsOnly;
  final int? day1Count;
  final String? allOn;

  UnlockFeature get shell => UnlockFeature(
    id: id,
    access: access,
    safety: safety,
    adultsOnly: adultsOnly,
    stageIds: const <String>[],
    stageId: '',
    day1Count: day1Count,
    allOn: allOn,
  );

  UnlockFeature finish(List<String> stageIds) {
    return UnlockFeature(
      id: id,
      access: access,
      safety: safety,
      adultsOnly: adultsOnly,
      stageIds: stageIds,
      stageId: stageIds.isEmpty ? '' : stageIds.first,
      day1Count: day1Count,
      allOn: allOn,
    );
  }
}

List<UnlockStage> _parseStages(Object? value) {
  final List<Object?> rows = _asList(value, 'stages');
  if (rows.isEmpty) {
    throw const FormatException('Expected at least one stage');
  }
  final List<UnlockStage> stages = <UnlockStage>[];
  final Set<String> seen = <String>{};
  for (var index = 0; index < rows.length; index += 1) {
    final String path = 'stages[$index]';
    final Map<String, Object?> row = _asMap(rows[index], path);
    _rejectUnknown(row.keys, _stageKeys, path);
    final String id = _asId(row['id'], '$path.id');
    if (!seen.add(id)) {
      throw FormatException('Duplicate stage $id');
    }
    final String requires = _asId(row['requires'], '$path.requires');
    if (!_requires.contains(requires)) {
      throw FormatException('Unknown requires $requires at $path.requires');
    }
    String? level;
    if (requires == 'level') {
      level = _asId(row['level'], '$path.level').toUpperCase();
      if (!_cefrOrder.contains(level)) {
        throw FormatException('Unknown level $level at $path.level');
      }
    } else if (row.containsKey('level')) {
      throw FormatException('level needs requires level at $path');
    }
    final List<Object?> rawOpens = _asList(row['opens'], '$path.opens');
    if (rawOpens.isEmpty) {
      throw FormatException('Expected at least one feature at $path.opens');
    }
    final List<String> opens = <String>[];
    final Set<String> openIds = <String>{};
    for (var openIndex = 0; openIndex < rawOpens.length; openIndex += 1) {
      final String featureId = _asId(
        rawOpens[openIndex],
        '$path.opens[$openIndex]',
      );
      if (!openIds.add(featureId)) {
        throw FormatException('Duplicate feature $featureId at $path.opens');
      }
      opens.add(featureId);
    }
    stages.add(
      UnlockStage(
        id: id,
        requires: requires,
        level: level,
        opens: List<String>.unmodifiable(opens),
      ),
    );
  }
  return stages;
}

List<_FeatureDraft> _parseFeatures(Object? value) {
  final List<Object?> rows = _asList(value, 'features');
  if (rows.isEmpty) {
    throw const FormatException('Expected at least one feature');
  }
  final List<_FeatureDraft> features = <_FeatureDraft>[];
  final Set<String> seen = <String>{};
  var counted = 0;
  for (var index = 0; index < rows.length; index += 1) {
    final String path = 'features[$index]';
    final Map<String, Object?> row = _asMap(rows[index], path);
    _rejectUnknown(row.keys, _featureKeys, path);
    final String id = _asId(row['id'], '$path.id');
    if (!seen.add(id)) {
      throw FormatException('Duplicate feature $id');
    }
    final UnlockAccess access = _parseAccess(row['access'], path);
    final UnlockSafety safety = _parseSafety(row['safety'], path);
    final bool adultsOnly = _parseAudience(row['audience'], path);
    int? day1Count;
    if (row.containsKey('day1_count')) {
      day1Count = _asInt(row['day1_count'], '$path.day1_count');
      if (day1Count < 1) {
        throw FormatException('day1_count must be at least 1 at $path');
      }
      counted += 1;
    }
    String? allOn;
    if (row.containsKey('all_on')) {
      allOn = _asId(row['all_on'], '$path.all_on');
    }
    if (day1Count != null && allOn == null) {
      throw FormatException('day1_count needs all_on at $path');
    }
    if (allOn != null && day1Count == null) {
      throw FormatException('all_on needs day1_count at $path');
    }
    features.add(
      _FeatureDraft(
        id: id,
        access: access,
        safety: safety,
        adultsOnly: adultsOnly,
        day1Count: day1Count,
        allOn: allOn,
      ),
    );
  }
  if (counted > 1) {
    throw const FormatException('Only one feature can count games');
  }
  return features;
}

void _checkLinks(List<UnlockStage> stages, List<UnlockFeature> features) {
  final Map<String, UnlockStage> byId = <String, UnlockStage>{
    for (final UnlockStage stage in stages) stage.id: stage,
  };
  for (final UnlockFeature feature in features) {
    if (feature.day1Count != null) {
      final String? allOn = feature.allOn;
      final UnlockStage? account = allOn == null ? null : byId[allOn];
      if (account == null || account.requires != 'account') {
        throw FormatException(
          '${feature.id} all_on must be a stage that requires an account',
        );
      }
      if (!account.opens.contains(feature.id)) {
        throw FormatException(
          '${feature.id} must be listed on the account stage',
        );
      }
      final bool dayOne = feature.stageIds.any((String id) {
        return byId[id]?.requires == 'none';
      });
      if (!dayOne) {
        throw FormatException(
          '${feature.id} must be listed on the day 1 stage',
        );
      }
      continue;
    }
    if (feature.stageIds.length > 1) {
      throw FormatException('${feature.id} is listed on more than one stage');
    }
    if (feature.stageIds.isEmpty && feature.safety != UnlockSafety.guardian) {
      throw FormatException('${feature.id} is not on a stage');
    }
    if (feature.stageId == 'native_speaker' && feature.stageIds.length != 1) {
      throw FormatException('${feature.id} is open only for native speakers');
    }
  }
}

UnlockAccess _parseAccess(Object? value, String path) {
  if (value == null) return UnlockAccess.open;
  final String name = _asId(value, '$path.access');
  final UnlockAccess? access = _accessByName[name];
  if (access == null) {
    throw FormatException('Unknown access $name at $path.access');
  }
  return access;
}

UnlockSafety _parseSafety(Object? value, String path) {
  if (value == null) return UnlockSafety.none;
  final String name = _asId(value, '$path.safety');
  if (name == 'guardian') return UnlockSafety.guardian;
  throw FormatException('Unknown safety $name at $path.safety');
}

bool _parseAudience(Object? value, String path) {
  if (value == null) return false;
  final String name = _asId(value, '$path.audience');
  if (name == 'adult') return true;
  throw FormatException('Unknown audience $name at $path.audience');
}

void _rejectUnknown(Iterable<String> keys, Set<String> allowed, String path) {
  for (final String key in keys) {
    if (!allowed.contains(key)) {
      throw FormatException('Unknown field $key at $path');
    }
  }
}

void _scanCopy(Object? value, String path) {
  if (value is String) {
    _rejectCopy(value, path);
    return;
  }
  if (value is Map) {
    value.forEach((Object? key, Object? item) {
      _scanCopy(item, '$path.${key ?? ''}');
    });
    return;
  }
  if (value is List) {
    for (var index = 0; index < value.length; index += 1) {
      _scanCopy(value[index], '$path[$index]');
    }
  }
}

bool _hasBannedWord(String value) {
  final String lower = value.toLowerCase();
  const List<List<int>> banned = <List<int>>[
    <int>[119, 111, 114, 108, 100, 45, 99, 108, 97, 115, 115],
    <int>[119, 111, 114, 108, 100, 32, 99, 108, 97, 115, 115],
    <int>[101, 108, 105, 116, 101],
    <int>[115, 101, 97, 109, 108, 101, 115, 115],
  ];
  for (final List<int> codes in banned) {
    final String word = String.fromCharCodes(codes);
    if (RegExp('\\b$word\\b').hasMatch(lower)) return true;
  }
  return false;
}

void _rejectCopy(String value, String path) {
  if (value.runes.contains(0x2014)) {
    throw FormatException('User-visible text at $path uses a disallowed dash');
  }
  if (_hasBannedWord(value)) {
    throw FormatException('User-visible text at $path uses a banned word');
  }
  if (value.toLowerCase().contains('confidence') &&
      RegExp(r'\d').hasMatch(value)) {
    throw FormatException('User-visible text at $path uses a fake score');
  }
}

Map<String, Object?> _asMap(Object? value, String path) {
  if (value is Map) {
    return value.map(
      (Object? key, Object? item) =>
          MapEntry<String, Object?>(key.toString(), item),
    );
  }
  throw FormatException('Expected an object at $path');
}

List<Object?> _asList(Object? value, String path) {
  if (value is List) return value.cast<Object?>();
  throw FormatException('Expected a list at $path');
}

String _asId(Object? value, String path) {
  final String text = _asText(value, path);
  if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(text)) {
    throw FormatException('Expected an id at $path');
  }
  return text;
}

String _asText(Object? value, String path) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('Expected text at $path');
}

int _asInt(Object? value, String path) {
  if (value is int) return value;
  throw FormatException('Expected an integer at $path');
}

/// Learner-facing name for a table id.
String unlockFeatureName(AppLocalizations l10n, String id) {
  return switch (id) {
    'today' => l10n.unlockFeatureToday,
    'first_unit' => l10n.unlockFeatureFirstUnit,
    'polie_basic' => l10n.unlockFeaturePolieBasic,
    'lens' => l10n.unlockFeatureLens,
    'games' => l10n.unlockFeatureGames,
    'word_card' => l10n.unlockFeatureWordCard,
    'magazine' => l10n.unlockFeatureMagazine,
    'events' => l10n.unlockFeatureEvents,
    'streaks' => l10n.unlockFeatureStreaks,
    'circles' => l10n.unlockFeatureCircles,
    'square' => l10n.unlockFeatureSquare,
    'global_handle' => l10n.unlockFeatureGlobalHandle,
    'personas' => l10n.unlockFeaturePersonas,
    'scenarios' => l10n.unlockFeatureScenarios,
    'chats' => l10n.unlockFeatureChats,
    'status' => l10n.unlockFeatureStatus,
    'practice' => l10n.unlockFeaturePractice,
    'clips' => l10n.unlockFeatureClips,
    'native_corrections' => l10n.unlockFeatureNativeCorrections,
    'passport' => l10n.unlockFeaturePassport,
    'code_switch' => l10n.unlockFeatureCodeSwitch,
    'respect' => l10n.unlockFeatureRespect,
    'radio' => l10n.unlockFeatureRadio,
    'create' => l10n.unlockFeatureCreate,
    'host_rooms' => l10n.unlockFeatureHostRooms,
    'mentoring' => l10n.unlockFeatureMentoring,
    'contribute' => l10n.unlockFeatureContribute,
    'verify' => l10n.unlockFeatureVerify,
    'calls' => l10n.unlockFeatureCalls,
    'public_post' => l10n.unlockFeaturePublicPost,
    _ => l10n.unlockFeatureUnknown,
  };
}

/// Locked line for [decision]. A minor guardian gate uses the safety line.
String unlockLine(AppLocalizations l10n, UnlockDecision decision) {
  if (decision.safetyLocked) return l10n.unlockSafety;
  switch (decision.stageId) {
    case 'day_1':
      return l10n.unlockUnlocksAt(l10n.unlockStageDay1);
    case 'account':
      return l10n.unlockUnlocksAt(l10n.unlockStageAccount);
    case 'week_1_or_a1_unit_3':
      return l10n.unlockUnlocksAt(l10n.unlockStageWeek1);
    case 'a2':
      return l10n.unlockUnlocksAt(l10n.unlockStageA2);
    case 'b1':
      return l10n.unlockUnlocksAt(l10n.unlockStageB1);
    case 'native_speaker':
      return l10n.unlockNative;
    default:
      return l10n.unlockLocked;
  }
}

/// Keys for the locked feature gate.
abstract final class UnlockGate {
  static Key featureKey(String id) => ValueKey<String>('unlock-feature-$id');

  static const Key gateKey = ValueKey<String>('unlock-gate');

  static const Key previewKey = ValueKey<String>('unlock-preview');

  static const Key openAnywayKey = ValueKey<String>('unlock-open-anyway');

  static const Key previewBodyKey = ValueKey<String>('unlock-preview-body');

  static const Key openedKey = ValueKey<String>('unlock-opened');

  static const Key backKey = ValueKey<String>('unlock-back');
}

enum _UnlockPane { entry, gate, preview, opened }

/// One feature. A tap on a lock shows the unlock line, Preview, and, for an
/// adult, Open anyway. Open anyway opens that feature.
class UnlockFeatureEntry extends StatefulWidget {
  const UnlockFeatureEntry({
    required this.stages,
    required this.learner,
    required this.featureId,
    super.key,
  });

  final UnlockStages stages;
  final UnlockLearner learner;
  final String featureId;

  @override
  State<UnlockFeatureEntry> createState() => _UnlockFeatureEntryState();
}

class _UnlockFeatureEntryState extends State<UnlockFeatureEntry> {
  _UnlockPane _pane = _UnlockPane.entry;

  void _tapFeature() {
    final UnlockOpening opening = widget.stages.open(
      widget.learner,
      widget.featureId,
    );
    setState(() {
      _pane = opening.opened ? _UnlockPane.opened : _UnlockPane.gate;
    });
  }

  void _openAnyway() {
    final UnlockOpening opening = widget.stages.open(
      widget.learner,
      widget.featureId,
      anyway: true,
    );
    if (!opening.opened) return;
    setState(() => _pane = _UnlockPane.opened);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String name = unlockFeatureName(l10n, widget.featureId);
    final UnlockDecision decision = widget.stages.decide(
      widget.learner,
      widget.featureId,
    );
    final Widget body = switch (_pane) {
      _UnlockPane.entry => _entry(l10n, name),
      _UnlockPane.gate => _gate(l10n, palette, name, decision),
      _UnlockPane.preview => _preview(l10n, palette, name),
      _UnlockPane.opened => _opened(l10n, palette, name),
    };
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(child: body),
    );
  }

  Widget _entry(AppLocalizations l10n, String name) {
    return ListView(
      padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
      children: <Widget>[
        LingButton(
          key: UnlockGate.featureKey(widget.featureId),
          label: name,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: _tapFeature,
        ),
      ],
    );
  }

  Widget _gate(
    AppLocalizations l10n,
    LingPalette palette,
    String name,
    UnlockDecision decision,
  ) {
    final String line = unlockLine(l10n, decision);
    return Semantics(
      key: UnlockGate.gateKey,
      container: true,
      explicitChildNodes: true,
      label: l10n.unlockSemantics(name, line),
      child: ListView(
        padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
        children: <Widget>[
          _text(name, lingBody(palette.onSurface)),
          const SizedBox(height: LingAfriqTokens.spacing16),
          _text(l10n.unlockLocked, lingBody(palette.onSurface)),
          const SizedBox(height: LingAfriqTokens.spacing16),
          _text(line, lingBody(palette.onSurfaceVariant)),
          const SizedBox(height: LingAfriqTokens.spacing16),
          if (decision.canPreview)
            LingButton(
              key: UnlockGate.previewKey,
              label: l10n.unlockPreview,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: () => setState(() => _pane = _UnlockPane.preview),
              role: LingButtonRole.quiet,
            ),
          if (decision.canOpenAnyway) ...<Widget>[
            const SizedBox(height: LingAfriqTokens.spacing8),
            LingButton(
              key: UnlockGate.openAnywayKey,
              label: l10n.unlockOpenAnyway,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: _openAnyway,
            ),
          ],
        ],
      ),
    );
  }

  Widget _preview(AppLocalizations l10n, LingPalette palette, String name) {
    return ListView(
      padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
      children: <Widget>[
        _text(l10n.unlockPreview, lingBody(palette.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _text(name, lingBody(palette.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _text(
          l10n.unlockPreviewNote,
          lingBody(palette.onSurfaceVariant),
          key: UnlockGate.previewBodyKey,
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        LingButton(
          key: UnlockGate.backKey,
          label: l10n.unlockBack,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: () => setState(() => _pane = _UnlockPane.gate),
          role: LingButtonRole.quiet,
        ),
      ],
    );
  }

  Widget _opened(AppLocalizations l10n, LingPalette palette, String name) {
    return ListView(
      key: UnlockGate.openedKey,
      padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
      children: <Widget>[
        _text(name, lingBody(palette.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _text(l10n.unlockOpened(name), lingBody(palette.onSurface)),
      ],
    );
  }
}

Widget _text(String text, TextStyle style, {Key? key}) {
  return Text(
    key: key,
    text,
    style: style,
    softWrap: true,
    overflow: TextOverflow.visible,
  );
}
