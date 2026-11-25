import 'dart:convert';

import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Weekly Home Safari quest visibility (P7-910).
enum HomeSafariQuestPhase {
  empty,
  active,
  complete,
  expired,
}

/// ML Kit labels treated as kitchen items for quest targets (curated set only).
const Set<String> homeSafariKitchenMlKitLabels = {
  'Cup',
  'Mug',
  'Teacup',
  'Bowl',
  'Plate',
  'Spoon',
  'Pot',
  'Pan',
  'Knife',
  'Fork',
  'Kettle',
};

const int homeSafariQuestTargetCount = 5;

const int homeSafariCompletionCowries = 25;

class HomeSafariRewardGrant {
  const HomeSafariRewardGrant({
    required this.idempotencyKey,
    required this.cowries,
  });

  final String idempotencyKey;
  final int cowries;
}

class HomeSafariQuestSnapshot {
  const HomeSafariQuestSnapshot({
    required this.phase,
    required this.weekKey,
    required this.targetObjectSetIds,
    required this.confirmedObjectSetIds,
    required this.rewardGranted,
  });

  final HomeSafariQuestPhase phase;
  final String weekKey;
  final List<String> targetObjectSetIds;
  final List<String> confirmedObjectSetIds;
  final bool rewardGranted;

  int get targetCount => targetObjectSetIds.length;

  int get confirmedCount => confirmedObjectSetIds.length;

  String progressLabel() => '$confirmedCount of $targetCount';
}

class HomeSafariConfirmResult {
  const HomeSafariConfirmResult({
    required this.snapshot,
    this.reward,
    required this.alreadyCounted,
  });

  final HomeSafariQuestSnapshot snapshot;
  final HomeSafariRewardGrant? reward;
  final bool alreadyCounted;
}

typedef HomeSafariObjectSetLoader = Future<AfricanObjectSet> Function();

String homeSafariWeekKey(DateTime utc) {
  final d = DateTime.utc(utc.year, utc.month, utc.day);
  final weekday = d.weekday;
  final thursday = d.add(Duration(days: 4 - weekday));
  final yearStart = DateTime.utc(thursday.year, 1, 1);
  final week = ((thursday.difference(yearStart).inDays) / 7).floor() + 1;
  return '${thursday.year}-W$week';
}

bool homeSafariEntryIsKitchen(AfricanObjectSetEntry entry) {
  for (final label in entry.mlKitLabels) {
    if (homeSafariKitchenMlKitLabels.contains(label)) {
      return true;
    }
  }
  return false;
}

List<String> homeSafariPickKitchenTargets(
  AfricanObjectSet set, {
  required String weekKey,
  int count = homeSafariQuestTargetCount,
}) {
  final kitchen = set.entries
      .where(homeSafariEntryIsKitchen)
      .map((e) => e.objectSetId)
      .toSet()
      .toList()
    ..sort();
  if (kitchen.length < count) {
    return const [];
  }
  final seed = weekKey.hashCode;
  final picked = <String>[];
  var index = seed.abs();
  final pool = List<String>.from(kitchen);
  while (picked.length < count && pool.isNotEmpty) {
    index = (index * 1103515245 + 12345) & 0x7fffffff;
    final at = index % pool.length;
    picked.add(pool.removeAt(at));
  }
  picked.sort();
  return picked;
}

class HomeSafariService {
  HomeSafariService({
    Future<SharedPreferences> Function()? prefsLoader,
    HomeSafariObjectSetLoader? objectSetLoader,
    DateTime Function()? clock,
  })  : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance,
        _objectSetLoader =
            objectSetLoader ?? AfricanObjectSet.loadFromBundle,
        _clock = clock ?? (() => DateTime.now().toUtc());

  static const storageKeyPrefix = 'home_safari_quest_v1_';

  final Future<SharedPreferences> Function() _prefsLoader;
  final HomeSafariObjectSetLoader _objectSetLoader;
  final DateTime Function() _clock;

  String _storageKey(String userId) => '$storageKeyPrefix$userId';

  Future<HomeSafariQuestSnapshot> loadSnapshot(String userId) async {
    final set = await _objectSetLoader();
    return _loadOrRotate(userId: userId, objectSet: set);
  }

  Future<HomeSafariConfirmResult> confirmRecognisedItem({
    required String userId,
    required String objectSetId,
  }) async {
    final set = await _objectSetLoader();
    final snapshot = await _loadOrRotate(userId: userId, objectSet: set);
    if (snapshot.phase != HomeSafariQuestPhase.active) {
      return HomeSafariConfirmResult(
        snapshot: snapshot,
        alreadyCounted: false,
      );
    }
    if (!snapshot.targetObjectSetIds.contains(objectSetId)) {
      return HomeSafariConfirmResult(
        snapshot: snapshot,
        alreadyCounted: false,
      );
    }
    if (snapshot.confirmedObjectSetIds.contains(objectSetId)) {
      return HomeSafariConfirmResult(
        snapshot: snapshot,
        alreadyCounted: true,
      );
    }

    final confirmed = [...snapshot.confirmedObjectSetIds, objectSetId]..sort();
    var phase = HomeSafariQuestPhase.active;
    HomeSafariRewardGrant? reward;
    var rewardGranted = snapshot.rewardGranted;

    if (confirmed.length >= snapshot.targetCount) {
      phase = HomeSafariQuestPhase.complete;
      if (!rewardGranted) {
        rewardGranted = true;
        reward = HomeSafariRewardGrant(
          idempotencyKey:
              '$userId:${snapshot.weekKey}:home_safari_complete',
          cowries: homeSafariCompletionCowries,
        );
      }
    }

    final next = HomeSafariQuestSnapshot(
      phase: phase,
      weekKey: snapshot.weekKey,
      targetObjectSetIds: snapshot.targetObjectSetIds,
      confirmedObjectSetIds: confirmed,
      rewardGranted: rewardGranted,
    );
    await _persist(userId, next);
    return HomeSafariConfirmResult(
      snapshot: next,
      reward: reward,
      alreadyCounted: false,
    );
  }

  Future<HomeSafariQuestSnapshot> _loadOrRotate({
    required String userId,
    required AfricanObjectSet objectSet,
  }) async {
    final now = _clock();
    final currentWeek = homeSafariWeekKey(now);
    final prefs = await _prefsLoader();
    final raw = prefs.getString(_storageKey(userId));
    HomeSafariQuestSnapshot? stored;
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        stored = _decode(raw);
      } catch (_) {
        stored = null;
      }
    }

    if (stored != null && stored.weekKey != currentWeek) {
      if (stored.phase == HomeSafariQuestPhase.active) {
        final expired = HomeSafariQuestSnapshot(
          phase: HomeSafariQuestPhase.expired,
          weekKey: stored.weekKey,
          targetObjectSetIds: stored.targetObjectSetIds,
          confirmedObjectSetIds: stored.confirmedObjectSetIds,
          rewardGranted: stored.rewardGranted,
        );
        await _persist(userId, expired);
      }
      stored = null;
    }

    if (stored != null) {
      return stored;
    }

    final targets = homeSafariPickKitchenTargets(
      objectSet,
      weekKey: currentWeek,
    );
    if (targets.isEmpty) {
      final empty = HomeSafariQuestSnapshot(
        phase: HomeSafariQuestPhase.empty,
        weekKey: currentWeek,
        targetObjectSetIds: const [],
        confirmedObjectSetIds: const [],
        rewardGranted: false,
      );
      await _persist(userId, empty);
      return empty;
    }

    final active = HomeSafariQuestSnapshot(
      phase: HomeSafariQuestPhase.active,
      weekKey: currentWeek,
      targetObjectSetIds: targets,
      confirmedObjectSetIds: const [],
      rewardGranted: false,
    );
    await _persist(userId, active);
    return active;
  }

  Future<void> _persist(String userId, HomeSafariQuestSnapshot snapshot) async {
    final prefs = await _prefsLoader();
    await prefs.setString(_storageKey(userId), _encode(snapshot));
  }

  static Map<String, dynamic> _toJson(HomeSafariQuestSnapshot s) => {
        'week_key': s.weekKey,
        'phase': s.phase.name,
        'targets': s.targetObjectSetIds,
        'confirmed': s.confirmedObjectSetIds,
        'reward_granted': s.rewardGranted,
      };

  static String _encode(HomeSafariQuestSnapshot s) =>
      jsonEncode(_toJson(s));

  static HomeSafariQuestSnapshot _decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final phase = HomeSafariQuestPhase.values.byName(
      (json['phase'] ?? 'empty').toString(),
    );
    final targets = (json['targets'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    final confirmed = (json['confirmed'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    return HomeSafariQuestSnapshot(
      phase: phase,
      weekKey: (json['week_key'] ?? '').toString(),
      targetObjectSetIds: targets,
      confirmedObjectSetIds: confirmed,
      rewardGranted: json['reward_granted'] == true,
    );
  }
}
