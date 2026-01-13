import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/tribe_vs_tribe_model.dart';
import 'gamification_services_provider.dart';
import 'base_provider.dart';
import 'api_provider.dart';

final tribeVsTribeProvider =
    NotifierProvider<TribeVsTribeProvider, BaseProviderState>(() {
  return TribeVsTribeProvider();
});

/// Tribe vs Tribe Events Provider
class TribeVsTribeProvider extends Notifier<BaseProviderState>
    with BaseProviderMixin {
  TribeVsTribeEvent? _currentEvent;
  final Map<String, int> _tribeScores = {}; // tribeId -> score

  TribeVsTribeEvent? get currentEvent => _currentEvent;
  Map<String, int> get tribeScores => Map.unmodifiable(_tribeScores);

  @override
  BaseProviderState build() {
    loadCurrentEvent();
    return BaseProviderState();
  }

  /// Load current event
  Future<void> loadCurrentEvent() async {
    state = state.copyWith(isLoading: true);

    try {
      // Fetch from backend competitions API (source-of-truth).
      final competitionsService = ref.read(competitionsServiceProvider);
      final competitions = await competitionsService.getCompetitions(
        status: 'active',
        type: 'tribe_vs_tribe',
      );

      if (competitions.isEmpty) {
        _currentEvent = null;
        _tribeScores.clear();
        return;
      }

      final comp = competitions.first as Map<String, dynamic>;
      final id = (comp['_id'] ?? comp['id'] ?? '').toString();
      final name = (comp['name'] ?? 'Tribe Battle').toString();
      final start = DateTime.tryParse(comp['start_at']?.toString() ?? '') ?? DateTime.now();
      final end = DateTime.tryParse(comp['end_at']?.toString() ?? '') ?? start.add(const Duration(days: 2));

      _currentEvent = TribeVsTribeEvent(
        id: id,
        name: name,
        description: (comp['description'] ?? 'Compete with other tribes! Earn XP for your tribe.').toString(),
        startDate: start,
        endDate: end,
        participatingTribes: const [], // derived from results below
      );

      // Load results into local cache for fast UI rendering.
      final results = await competitionsService.getCompetitionResults(id);
      final rows = (results['results'] as List?) ?? const [];
      _tribeScores.clear();
      for (final r in rows) {
        final m = Map<String, dynamic>.from(r as Map);
        final tribeName = (m['subject_name'] ?? '').toString();
        final points = (m['points'] is int) ? m['points'] as int : int.tryParse('${m['points']}') ?? 0;
        if (tribeName.isNotEmpty) _tribeScores[tribeName] = points;
      }
    } catch (e) {
      debugPrint('Error loading tribe vs tribe event: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  DateTime _getNextWeekendStart(DateTime now) {
    final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    final saturday = now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
    return DateTime(saturday.year, saturday.month, saturday.day, 0, 0);
  }

  /// Contribute XP to tribe
  Future<void> contributeToTribe(String tribeId, int xp) async {
    try {
      _tribeScores[tribeId] = (_tribeScores[tribeId] ?? 0) + xp;
      // Note: Backend currently derives tribe-vs-tribe totals from canonical events,
      // so direct “submit points” is intentionally not done here.
      state = state.copyWith();
    } catch (e) {
      debugPrint('Error contributing to tribe: $e');
    }
  }

  /// Get leaderboard
  List<MapEntry<String, int>> getLeaderboard() {
    final entries = _tribeScores.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}

