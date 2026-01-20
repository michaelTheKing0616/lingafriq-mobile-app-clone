import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/tribe_vs_tribe_model.dart';
import 'base_provider.dart';
import 'dio_provider.dart';
import '../utils/api.dart';
import '../utils/structured_logger.dart';

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
      // Fetch from backend API
      final response = await ref.read(client).get(
        '${Api.baseurl}api/tribes/events/current',
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        // Parse event data
        _currentEvent = TribeVsTribeEvent(
          id: data['id']?.toString() ?? '',
          name: data['name'] ?? 'Tribe Battle',
          description: data['description'] ?? 'Compete with other tribes! Earn XP for your tribe.',
          startDate: data['start_date'] != null 
              ? DateTime.parse(data['start_date']) 
              : DateTime.now(),
          endDate: data['end_date'] != null 
              ? DateTime.parse(data['end_date']) 
              : DateTime.now().add(const Duration(days: 2)),
          participatingTribes: (data['participating_tribes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [],
        );

        // Parse tribe scores
        _tribeScores.clear();
        if (data['scores'] is Map) {
          final scores = data['scores'] as Map<String, dynamic>;
          scores.forEach((tribeId, score) {
            _tribeScores[tribeId] = (score is int) ? score : (score as num).toInt();
          });
        }
      } else {
        // Fallback: Create event for next weekend if no active event
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

        // Initialize scores to 0
        _tribeScores.clear();
        for (var tribe in _currentEvent!.participatingTribes) {
          _tribeScores[tribe] = 0;
        }
      }
    } catch (e) {
      logger.error('Error loading tribe vs tribe event', tag: 'tribe-vs-tribe', error: e);
      // Fallback on error
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

      _tribeScores.clear();
      for (var tribe in _currentEvent!.participatingTribes) {
        _tribeScores[tribe] = 0;
      }
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
      // Update local state immediately for responsive UI
      _tribeScores[tribeId] = (_tribeScores[tribeId] ?? 0) + xp;
      state = state.copyWith();

      // Sync to backend
      try {
        final response = await ref.read(client).post(
          Api.tribeDepositXP(tribeId),
          data: {
            'xp': xp,
            'event_id': _currentEvent?.id,
          },
        );

        if (response.statusCode == 200 && response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          // Update with server-authoritative score
          if (data['total_xp'] != null) {
            _tribeScores[tribeId] = (data['total_xp'] as num).toInt();
          }
        }
      } catch (syncError) {
        logger.error('Error syncing tribe XP contribution to backend', tag: 'tribe-vs-tribe', error: syncError);
        // Continue - local state is already updated
      }
    } catch (e) {
      logger.error('Error contributing to tribe', tag: 'tribe-vs-tribe', error: e);
      rethrow;
    }
  }

  /// Get leaderboard
  List<MapEntry<String, int>> getLeaderboard() {
    final entries = _tribeScores.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}

