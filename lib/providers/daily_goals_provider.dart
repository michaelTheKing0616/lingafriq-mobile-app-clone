import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/models/daily_goal_model.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'base_provider.dart';

final dailyGoalsProvider = NotifierProvider<DailyGoalsProvider, BaseProviderState>(() {
  return DailyGoalsProvider();
});

class DailyGoalsProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  final List<DailyGoal> _goals = [];
  int _currentStreak = 0;
  DateTime? _lastActivityDate;

  List<DailyGoal> get goals => List.unmodifiable(_goals);
  int get currentStreak => _currentStreak;
  bool get hasActiveStreak => _currentStreak > 0;

  @override
  BaseProviderState build() {
    _loadGoals();
    _loadStreak();
    _initializeDailyGoals();
    _syncWithBackend();
    return BaseProviderState();
  }

  Future<void> _syncWithBackend() async {
    try {
      final backendGoals = await ref.read(apiProvider.notifier).getDailyGoals();
      if (backendGoals.containsKey('goals') && backendGoals.containsKey('streak')) {
        final backendStreak = backendGoals['streak'] as int? ?? 0;
        if (backendStreak > _currentStreak) {
          _currentStreak = backendStreak;
          await _saveStreak();
        }
        // TODO: Sync individual goals if needed
      }
    } catch (e) {
      debugPrint('Error syncing daily goals with backend: $e');
      // Silently fail - local state is primary
    }
  }

  void _initializeDailyGoals() {
    if (_goals.isEmpty || !_goals.any((g) => g.isToday)) {
      _goals.clear();
      _goals.addAll([
        DailyGoal(
          id: 1,
          type: 'lessons',
          target: 3,
          current: 0,
          date: DateTime.now(),
          completed: false,
          streak: _currentStreak,
        ),
        DailyGoal(
          id: 2,
          type: 'quizzes',
          target: 2,
          current: 0,
          date: DateTime.now(),
          completed: false,
          streak: _currentStreak,
        ),
        DailyGoal(
          id: 3,
          type: 'games',
          target: 1,
          current: 0,
          date: DateTime.now(),
          completed: false,
          streak: _currentStreak,
        ),
        DailyGoal(
          id: 4,
          type: 'chat_minutes',
          target: 10,
          current: 0,
          date: DateTime.now(),
          completed: false,
          streak: _currentStreak,
        ),
      ]);
      _saveGoals();
    }
  }

  void updateGoalProgress(String type, int increment) {
    final today = DateTime.now();
    final goal = _goals.firstWhere(
      (g) => g.type == type && g.isToday,
      orElse: () => DailyGoal(
        id: _goals.length + 1,
        type: type,
        target: _getDefaultTarget(type),
        current: increment,
        date: today,
        completed: false,
        streak: _currentStreak,
      ),
    );

    final index = _goals.indexWhere((g) => g.id == goal.id && g.isToday);
    final updatedGoal = DailyGoal(
      id: goal.id,
      type: goal.type,
      target: goal.target,
      current: goal.current + increment,
      date: goal.date,
      completed: (goal.current + increment) >= goal.target,
      streak: goal.streak,
      lastCompletedDate: (goal.current + increment) >= goal.target ? DateTime.now() : goal.lastCompletedDate,
    );

    if (index >= 0) {
      _goals[index] = updatedGoal;
    } else {
      _goals.add(updatedGoal);
    }

    _checkStreak();
    _saveGoals();
    _syncStreakToBackend(); // Sync streak to backend
    state = state.copyWith();
  }


  int _getDefaultTarget(String type) {
    switch (type) {
      case 'lessons':
        return 3;
      case 'quizzes':
        return 2;
      case 'games':
        return 1;
      case 'chat_minutes':
        return 10;
      case 'words_learned':
        return 20;
      default:
        return 1;
    }
  }

  void _checkStreak() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (_lastActivityDate == null) {
      _currentStreak = 1;
      _lastActivityDate = today;
      return;
    }

    if (_lastActivityDate!.year == today.year &&
        _lastActivityDate!.month == today.month &&
        _lastActivityDate!.day == today.day) {
      // Already counted today
      return;
    }

    if (_lastActivityDate!.year == yesterday.year &&
        _lastActivityDate!.month == yesterday.month &&
        _lastActivityDate!.day == yesterday.day) {
      // Consecutive day
      _currentStreak++;
    } else {
      // Streak broken
      _currentStreak = 1;
    }

    _lastActivityDate = today;
    _saveStreak();
  }

  Future<void> _saveGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsJson = _goals.map((g) => g.toJson()).toList();
      await prefs.setStringList('daily_goals', goalsJson);
    } catch (e) {
      debugPrint('Error saving daily goals: $e');
    }
  }

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsJson = prefs.getStringList('daily_goals') ?? [];
      _goals.clear();
      _goals.addAll(goalsJson.map((json) => DailyGoal.fromJson(json)));
    } catch (e) {
      debugPrint('Error loading daily goals: $e');
    }
  }

  Future<void> _saveStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', _currentStreak);
      if (_lastActivityDate != null) {
        await prefs.setString('last_activity_date', _lastActivityDate!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving streak: $e');
    }
  }

  Future<void> _loadStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentStreak = prefs.getInt('current_streak') ?? 0;
      final lastDateStr = prefs.getString('last_activity_date');
      if (lastDateStr != null) {
        _lastActivityDate = DateTime.parse(lastDateStr);
      }
    } catch (e) {
      debugPrint('Error loading streak: $e');
    }
  }

  /// Refresh goals - reload from storage and sync with backend
  Future<void> refreshGoals() async {
    await _loadGoals();
    await _loadStreak();
    _initializeDailyGoals();
    await _syncWithBackend();
    state = state.copyWith();
  }

  /// Sync streak to backend
  Future<void> _syncStreakToBackend() async {
    try {
      await ref.read(apiProvider.notifier).updateDailyStreak(_currentStreak);
    } catch (e) {
      debugPrint('Error syncing streak to backend: $e');
    }
  }
}

