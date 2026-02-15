import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/structured_logger.dart';
import '../config/api_contract.dart';
import '../utils/api_service.dart';

/// When true, skip backend API sync in updateMastery (for tests).
@visibleForTesting
bool kGrammarProgressSkipBackendSync = false;

class GrammarProgressNotifier extends Notifier<Map<String, GrammarMastery>> {
  static const String _storageKey = 'grammar_progress';

  @override
  Map<String, GrammarMastery> build() {
    _loadFromLocal();
    return {};
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        state = data.map((key, value) => MapEntry(
              key,
              GrammarMastery.fromJson(value as Map<String, dynamic>),
            ));
      }
    } catch (e) {
      logger.error('Error loading grammar progress', tag: 'grammar_progress', error: e);
    }
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(state.map((key, value) => MapEntry(key, value.toJson())));
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      logger.error('Error saving grammar progress', tag: 'grammar_progress', error: e);
    }
  }

  Future<void> syncWithBackend() async {
    try {
      final response = await ApiService.get(
        ApiContract.url('/api/grammar/progress'),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final progressMap = <String, GrammarMastery>{};
        
        if (data['progress'] is Map) {
          (data['progress'] as Map).forEach((key, value) {
            if (value is Map) {
              progressMap[key.toString()] = GrammarMastery.fromJson(
                Map<String, dynamic>.from(value),
              );
            }
          });
        }

        state = progressMap;
        await _saveToLocal();
      }
    } catch (e) {
      logger.error('Error syncing grammar progress', tag: 'grammar_progress', error: e);
    }
  }

  Future<void> updateMastery(String topicId, int score, int totalExercises) async {
    final current = state[topicId] ?? GrammarMastery(topicId: topicId, masteryPercentage: 0);
    
    final newMastery = GrammarMastery(
      topicId: topicId,
      masteryPercentage: ((score / totalExercises) * 100).clamp(0, 100),
      exercisesCompleted: current.exercisesCompleted + totalExercises,
      lastPracticed: DateTime.now(),
      averageScore: ((current.averageScore * current.exercisesCompleted + score) /
              (current.exercisesCompleted + totalExercises))
          .clamp(0, 100),
    );

    state = {...state, topicId: newMastery};
    await _saveToLocal();

    if (kGrammarProgressSkipBackendSync) return;

    try {
      await ApiService.post(
        ApiContract.url('/api/grammar/progress'),
        data: {
          'topicId': topicId,
          'score': score,
          'totalExercises': totalExercises,
          'masteryPercentage': newMastery.masteryPercentage,
        },
      );
    } catch (e) {
      logger.error('Error updating grammar progress on backend', tag: 'grammar_progress', error: e);
    }
  }

  List<String> getTopicsForReview() {
    final now = DateTime.now();
    return state.entries
        .where((entry) {
          final mastery = entry.value;
          if (mastery.masteryPercentage < 80) return true;
          
          final daysSinceLastPractice = now.difference(mastery.lastPracticed).inDays;
          final reviewInterval = _getReviewInterval(mastery.masteryPercentage);
          return daysSinceLastPractice >= reviewInterval;
        })
        .map((entry) => entry.key)
        .toList();
  }

  int _getReviewInterval(double masteryPercentage) {
    if (masteryPercentage >= 90) return 30;
    if (masteryPercentage >= 80) return 14;
    if (masteryPercentage >= 60) return 7;
    return 3;
  }

  GrammarMastery? getMastery(String topicId) {
    return state[topicId];
  }
}

final grammarProgressProvider = NotifierProvider<GrammarProgressNotifier, Map<String, GrammarMastery>>(
  () => GrammarProgressNotifier(),
);

class GrammarMastery {
  final String topicId;
  final double masteryPercentage;
  final int exercisesCompleted;
  final DateTime lastPracticed;
  final double averageScore;

  GrammarMastery({
    required this.topicId,
    required this.masteryPercentage,
    this.exercisesCompleted = 0,
    DateTime? lastPracticed,
    this.averageScore = 0,
  }) : lastPracticed = lastPracticed ?? DateTime.now();

  factory GrammarMastery.fromJson(Map<String, dynamic> json) {
    return GrammarMastery(
      topicId: json['topicId']?.toString() ?? '',
      masteryPercentage: (json['masteryPercentage'] ?? 0).toDouble(),
      exercisesCompleted: json['exercisesCompleted'] ?? 0,
      lastPracticed: json['lastPracticed'] != null
          ? DateTime.parse(json['lastPracticed'].toString())
          : DateTime.now(),
      averageScore: (json['averageScore'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'masteryPercentage': masteryPercentage,
      'exercisesCompleted': exercisesCompleted,
      'lastPracticed': lastPracticed.toIso8601String(),
      'averageScore': averageScore,
    };
  }
}
