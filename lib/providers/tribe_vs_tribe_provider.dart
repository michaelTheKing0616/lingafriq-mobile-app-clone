import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/tribe_vs_tribe_model.dart';
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
      // TODO: Fetch from backend API
      // For now, create mock event
      final now = DateTime.now();
      final weekendStart = _getNextWeekendStart(now);

      _currentEvent = TribeVsTribeEvent(
        id: 'event_${weekendStart.millisecondsSinceEpoch}',
        name: 'Weekend Tribe Battle',
        description: 'Compete with other tribes! Earn XP for your tribe.',
        startDate: weekendStart,
        endDate: weekendStart.add(const Duration(days: 2)),
        participatingTribes: ['yoruba', 'igbo', 'hausa', 'swahili', 'zulu'],
      );

      // Mock scores
      _tribeScores.clear();
      _tribeScores['yoruba'] = 1250;
      _tribeScores['igbo'] = 980;
      _tribeScores['hausa'] = 1100;
      _tribeScores['swahili'] = 890;
      _tribeScores['zulu'] = 1050;
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
      // TODO: Sync to backend
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

