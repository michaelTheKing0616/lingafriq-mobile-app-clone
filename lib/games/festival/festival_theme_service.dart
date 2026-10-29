import 'package:flutter/foundation.dart';
import 'package:lingafriq/games/festival/festival_lexicon_weighting.dart';
import 'package:lingafriq/models/game/game_content_models.dart';
import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Weekly Village Festival theme ids (P8-931).
enum VillageFestivalThemeId {
  food,
  family,
  travel,
}

class VillageFestivalSnapshot {
  const VillageFestivalSnapshot({
    required this.weekKey,
    required this.themeId,
    required this.themeLabel,
    required this.daysLeftInWeek,
    required this.supportedGameIds,
    required this.fromServer,
  });

  final String weekKey;
  final VillageFestivalThemeId themeId;
  final String themeLabel;
  final int daysLeftInWeek;
  final List<String> supportedGameIds;
  final bool fromServer;

  String get themeTag => 'village_festival:${themeId.name}';
}

/// Last pool build note when no lexicon rows matched the active theme (AC3).
class FestivalThemeService {
  FestivalThemeService._();

  static final FestivalThemeService instance = FestivalThemeService._();

  VillageFestivalSnapshot? _cached;
  String? lastPoolNote;

  VillageFestivalSnapshot? get cached => _cached;

  @visibleForTesting
  void seedCacheForTests(VillageFestivalSnapshot snapshot) {
    _cached = snapshot;
  }

  @visibleForTesting
  void clearCacheForTests() {
    _cached = null;
    lastPoolNote = null;
  }

  static const List<String> supportedGameIds = [
    'tone_forge',
    'talking_drum',
    'market_bargaining_simulator',
    'taxi_bus_stop_survival',
    'minimal_pair_duel',
    'echo_karaoke',
    'greeting_gauntlet',
    'script_sprint',
    'word_forge',
    'word_hunt',
  ];

  static const Map<VillageFestivalThemeId, String> themeLabels = {
    VillageFestivalThemeId.food: 'Food & market',
    VillageFestivalThemeId.family: 'Family & home',
    VillageFestivalThemeId.travel: 'Travel & journeys',
  };

  /// Upper bound on the remote festival lookup before the local fallback.
  static const Duration remoteTimeout = Duration(seconds: 3);

  Future<VillageFestivalSnapshot> loadActive({DateTime? utcNow}) async {
    final now = utcNow ?? DateTime.now().toUtc();
    if (_cached != null && utcNow != null) {
      return _cached!;
    }
    try {
      // Festival weighting is decoration: never let a slow or unreachable
      // backend hold up a game start. Falls back to the local week schedule.
      final response = await () async {
        await ApiService.initialize();
        return ApiService.get('/games/festival/village');
      }().timeout(remoteTimeout);
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final payload = data['data'];
        if (payload is Map) {
          final snap = _snapshotFromJson(payload.cast<String, dynamic>());
          _cached = snap;
          return snap;
        }
      }
    } catch (_) {
      // Offline / route not mounted: fall back to shared week algorithm.
    }
    final snap = _snapshotLocal(now);
    _cached = snap;
    return snap;
  }

  VillageFestivalSnapshot snapshotAt(DateTime utc) => _snapshotLocal(utc);

  GameLexiconPoolBuildResult applyToPool({
    required GameLexiconPoolBuildResult base,
    required List<VerifiedLexeme> sourceLexemes,
    required VillageFestivalSnapshot festival,
    required String? gameId,
  }) {
    lastPoolNote = null;
    if (gameId != null && !supportedGameIds.contains(gameId)) {
      return base;
    }
    if (base.items.isEmpty) {
      return base;
    }
    final themedCount = countThemedLexemes(sourceLexemes, festival.themeId);
    if (themedCount == 0) {
      lastPoolNote = 'no_festival_content';
      return base;
    }
    final reordered = reorderPoolForFestival(
      items: base.items,
      lexemes: sourceLexemes,
      themeId: festival.themeId,
    );
    return GameLexiconPoolBuildResult(
      items: reordered,
      failure: base.failure,
      excludedMissingAudio: base.excludedMissingAudio,
      queriedCount: base.queriedCount,
      source: '${base.source}+festival_${festival.themeId.name}',
    );
  }

  VillageFestivalSnapshot _snapshotLocal(DateTime utc) {
    final weekKey = festivalWeekKey(utc);
    final themeId = festivalThemeForWeekKey(weekKey);
    return VillageFestivalSnapshot(
      weekKey: weekKey,
      themeId: themeId,
      themeLabel: themeLabels[themeId]!,
      daysLeftInWeek: festivalDaysLeftInWeek(utc),
      supportedGameIds: List<String>.from(supportedGameIds),
      fromServer: false,
    );
  }

  VillageFestivalSnapshot _snapshotFromJson(Map<String, dynamic> json) {
    final themeRaw = (json['theme_id'] ?? 'food').toString();
    final themeId = VillageFestivalThemeId.values.firstWhere(
      (t) => t.name == themeRaw,
      orElse: () => VillageFestivalThemeId.food,
    );
    final games = json['supported_game_ids'];
    return VillageFestivalSnapshot(
      weekKey: (json['week_key'] ?? '').toString(),
      themeId: themeId,
      themeLabel: (json['theme_label'] ?? themeLabels[themeId]!).toString(),
      daysLeftInWeek: (json['days_left_in_week'] as num?)?.toInt() ??
          festivalDaysLeftInWeek(DateTime.now().toUtc()),
      supportedGameIds: games is List
          ? games.map((e) => e.toString()).toList()
          : List<String>.from(supportedGameIds),
      fromServer: true,
    );
  }
}

/// ISO week key (Thursday anchor) — matches [homeSafariWeekKey].
String festivalWeekKey(DateTime utc) {
  final d = DateTime.utc(utc.year, utc.month, utc.day);
  final weekday = d.weekday;
  final thursday = d.add(Duration(days: 4 - weekday));
  final yearStart = DateTime.utc(thursday.year, 1, 1);
  final week = ((thursday.difference(yearStart).inDays) / 7).floor() + 1;
  return '${thursday.year}-W$week';
}

VillageFestivalThemeId festivalThemeForWeekKey(String weekKey) {
  final match = RegExp(r'^(\d{4})-W(\d+)$').firstMatch(weekKey.trim());
  if (match == null) return VillageFestivalThemeId.food;
  final week = int.tryParse(match.group(2) ?? '') ?? 1;
  final index = (week - 1) % VillageFestivalThemeId.values.length;
  return VillageFestivalThemeId.values[index];
}

int festivalDaysLeftInWeek(DateTime utc) {
  final d = DateTime.utc(utc.year, utc.month, utc.day);
  return 7 - d.weekday;
}
